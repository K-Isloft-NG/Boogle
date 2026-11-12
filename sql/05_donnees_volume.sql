-- Jeu de volume reproductible pour mesurer les requêtes sur Boggle.
-- Dépendances : sql/01_schema.sql et sql/02_schema_boggle.sql.
-- Exécution : psql -v ON_ERROR_STOP=1 -d <base> -f sql/05_donnees_volume.sql
-- Ajouter -v nb_parties=50000 pour changer le nombre de parties (défaut : 10000).
-- Base locale ou branche de développement uniquement. Jamais en production.
-- Les chemins sont synthétiques : les cases ne sont pas vérifiées par le moteur.

\if :{?nb_parties}
\else
    \set nb_parties 10000
\endif

SELECT :'nb_parties'::integer BETWEEN 1 AND 2147383647 AS volume_valide
\gset
\if :volume_valide
\else
    \echo 'nb_parties doit être un entier positif compatible avec les identifiants de partie.'
    \quit
\endif

BEGIN;

DELETE FROM boggle.participation WHERE id_partie >= 100001;
DELETE FROM boggle.partie WHERE id_partie >= 100001;
DELETE FROM boggle.dictionnaire WHERE id_dictionnaire >= 100001;
DELETE FROM public.php_utilisateurs
WHERE id >= 100001 AND email LIKE '%@volume.exemple.fr';

INSERT INTO public.php_utilisateurs (id, pseudo, email, mot_de_passe_hash, est_actif, date_creation)
SELECT 100000 + n, 'vol_' || lpad(n::text, 6, '0'),
       'vol_' || lpad(n::text, 6, '0') || '@volume.exemple.fr',
       'hash_factice', true, TIMESTAMP '2026-06-01 07:00'
FROM generate_series(1, 300) AS numeros(n);

INSERT INTO boggle.dictionnaire (id_dictionnaire, code_langue, libelle, version, nb_mots)
VALUES (100001, 'fr', 'Français (volume)', 'volume-1', 300000),
       (100002, 'en', 'Anglais (volume)', 'volume-1', 120000);

-- Les graines distinctes évitent de lier les statuts, les tailles et la langue.
-- Le masque transforme le résultat signé du hachage en entier positif ou nul.
WITH tirages_parties AS (
    SELECT i,
           mod(i, 100) AS tirage_statut,
           mod(hashtext(i::text || ':langue') & 2147483647, 100) AS tirage_langue,
           mod(hashtext(i::text || ':taille') & 2147483647, 100) AS tirage_taille,
           mod(hashtext(i::text || ':duree') & 2147483647, 4) AS tirage_duree,
           mod(hashtext(i::text || ':joueurs') & 2147483647, 3) AS tirage_joueurs,
           mod(hashtext(i::text || ':premier') & 2147483647, 300) AS premier_joueur,
           (ARRAY[7, 17, 37, 53])[1 + mod(hashtext(i::text || ':pas') & 2147483647, 4)] AS pas_joueurs
    FROM generate_series(1, :'nb_parties'::integer) AS indices(i)
), parties AS (
    SELECT i,
           CASE WHEN tirage_statut < 80 THEN 'terminee'
                WHEN tirage_statut < 88 THEN 'en_cours'
                WHEN tirage_statut < 94 THEN 'en_attente'
                ELSE 'annulee'
           END AS statut,
           TIMESTAMPTZ '2026-06-01 08:00+02' + i * INTERVAL '15 minutes' AS date_creation,
           CASE WHEN tirage_langue < 85 THEN 100001 ELSE 100002 END AS id_dictionnaire,
           CASE WHEN tirage_taille < 75 THEN 4 WHEN tirage_taille < 90 THEN 5 ELSE 3 END AS lignes,
           CASE WHEN tirage_taille < 75 THEN 4 ELSE 5 END AS colonnes,
           (ARRAY[60, 120, 180, 300])[1 + tirage_duree] AS duree_s,
           2 + tirage_joueurs AS nb_joueurs, premier_joueur, pas_joueurs
    FROM tirages_parties
), poids_lettres(lettre, poids) AS (
    VALUES ('A',1070), ('B',100), ('C',280), ('D',340), ('E',1550), ('F',110),
           ('G',110), ('H',100), ('I',770), ('J',50), ('K',40), ('L',580),
           ('M',330), ('N',710), ('O',760), ('P',300), ('Q',70), ('R',760),
           ('S',770), ('T',730), ('U',590), ('V',150), ('W',32), ('X',50),
           ('Y',70), ('Z',32)
), frequences AS (
    SELECT lettre, poids, sum(poids) OVER (ORDER BY lettre COLLATE "C") AS borne
    FROM poids_lettres
), grilles AS (
    SELECT p.i, jsonb_agg(
        CASE WHEN p.id_dictionnaire = 100001 AND tirages.qu < 255 THEN 'QU'
             ELSE f.lettre
        END ORDER BY c.position
    ) AS grille
    FROM parties p
    CROSS JOIN LATERAL generate_series(0, p.lignes * p.colonnes - 1) AS c(position)
    CROSS JOIN LATERAL (
        SELECT mod(hashtext(p.i || ':lettre:' || c.position) & 2147483647,
                   (SELECT sum(poids) FROM poids_lettres)) AS lettre,
               mod(hashtext(p.i || ':qu:' || c.position) & 2147483647, 10000) AS qu
    ) tirages
    JOIN frequences f ON tirages.lettre >= f.borne - f.poids AND tirages.lettre < f.borne
    GROUP BY p.i
), joueurs AS (
    SELECT p.i, 100001 + mod(p.premier_joueur + j.position * p.pas_joueurs, 300) AS id_utilisateur,
           p.lignes * p.colonnes AS nb_cases,
           CASE p.statut
               WHEN 'terminee' THEN 4 + mod(tirage.nombre, 11)
               WHEN 'en_cours' THEN 1 + mod(tirage.nombre, 3)
               WHEN 'annulee' THEN 1 + mod(tirage.nombre, 3)
               ELSE 0
           END AS nb_propositions,
           CASE p.statut
               WHEN 'en_cours' THEN 30000
               WHEN 'annulee' THEN 40000
               ELSE 1000 * p.duree_s
           END AS fenetre_ms,
           tirage.mot AS depart_mots
    FROM parties p
    CROSS JOIN LATERAL generate_series(0, p.nb_joueurs - 1) AS j(position)
    CROSS JOIN LATERAL (
        SELECT hashtext(p.i || ':nombre:' || j.position) & 2147483647 AS nombre,
               hashtext(p.i || ':mot:' || j.position) & 2147483647 AS mot
    ) tirage
), lexique AS (
    SELECT ARRAY['AIR','AMI','ART','BAL','CAP','MER','SEL','VIE'] AS courts,
           ARRAY['AILE','ANGE','ARBRE','AVION','BALLE','BANC','BATEAU','BOIS',
                 'BRUME','CARTE','CAVE','CIEL','CITRON','COIN','CORDE','CRABE',
                 'DANSE','ETOILE','FERME','FLEUR','FORET','FRUIT','GLACE','HERBE',
                 'JARDIN','LACET','LIGNE','LIVRE','LOUP','LUNE','MONT','PLAGE'] AS longs
), motifs AS (
    -- Le premier mot est valide. Les doublons reprennent ce mot et son chemin.
    SELECT j.*, n.numero,
           CASE WHEN n.numero = 1 OR t.rejet < 66 THEN NULL
                WHEN t.rejet < 75 THEN 'absent_grille'
                WHEN t.rejet < 84 THEN 'absent_dictionnaire'
                WHEN t.rejet < 92 THEN 'trop_court'
                ELSE 'doublon'
           END AS motif
    FROM joueurs j
    CROSS JOIN LATERAL generate_series(1, j.nb_propositions) AS n(numero)
    CROSS JOIN LATERAL (
        SELECT mod(hashtext(j.i || ':rejet:' || j.id_utilisateur || ':' || n.numero) & 2147483647, 100) AS rejet
    ) t
), mots AS (
    SELECT m.*,
           CASE WHEN motif = 'trop_court'
                THEN l.courts[1 + mod(mod(depart_mots, cardinality(l.courts)) + numero - 1, cardinality(l.courts))]
                WHEN motif = 'doublon' THEN l.longs[1 + mod(depart_mots, cardinality(l.longs))]
                ELSE l.longs[1 + mod(mod(depart_mots, cardinality(l.longs)) + numero - 1, cardinality(l.longs))]
           END AS mot,
           mod(hashtext(i || ':chemin:' || id_utilisateur || ':' ||
               CASE WHEN motif = 'doublon' THEN 1 ELSE numero END) & 2147483647, nb_cases) AS depart_chemin
    FROM motifs m
    CROSS JOIN lexique l
), propositions AS (
    SELECT i, id_utilisateur, numero, mot, motif,
           numero * fenetre_ms / (nb_propositions + 1) AS t_ms,
           -- Le barème du petit jeu est prolongé à 3 points pour six lettres.
           CASE WHEN motif IS NOT NULL THEN 0
                WHEN char_length(mot) <= 4 THEN 1
                WHEN char_length(mot) = 5 THEN 2
                ELSE 3
           END AS points,
           CASE WHEN motif <> 'absent_grille' OR motif IS NULL THEN ARRAY(
               SELECT mod(depart_chemin + c.position, nb_cases)
               FROM generate_series(0, char_length(mot) - 1) AS c(position)
               ORDER BY c.position
           ) END AS chemin
    FROM mots
), scores AS (
    SELECT i, id_utilisateur, sum(points) AS score,
           jsonb_agg(jsonb_build_object(
               'mot', mot, 'chemin', chemin, 't_ms', t_ms,
               'valide', motif IS NULL, 'points', points, 'motif_rejet', motif
           ) ORDER BY numero) AS propositions
    FROM propositions
    GROUP BY i, id_utilisateur
), joueurs_classes AS (
    SELECT j.i, j.id_utilisateur, coalesce(s.score, 0) AS score,
           coalesce(s.propositions, '[]'::jsonb) AS propositions,
           rank() OVER (PARTITION BY j.i ORDER BY coalesce(s.score, 0) DESC) AS rang
    FROM joueurs j
    LEFT JOIN scores s ON s.i = j.i AND s.id_utilisateur = j.id_utilisateur
), groupes AS (
    SELECT j.i,
           jsonb_agg(jsonb_build_object(
               'id_utilisateur', j.id_utilisateur, 'score', j.score, 'propositions', j.propositions
           ) ORDER BY j.id_utilisateur) AS joueurs,
           jsonb_agg(jsonb_build_object(
               'id_utilisateur', j.id_utilisateur, 'score', j.score, 'rang', j.rang
           ) ORDER BY j.rang, j.id_utilisateur) FILTER (WHERE p.statut = 'terminee') AS classement
    FROM joueurs_classes j
    JOIN parties p ON p.i = j.i
    GROUP BY j.i
)
INSERT INTO boggle.partie (id_partie, statut, date_creation, date_debut, date_fin, donnees, id_dictionnaire)
SELECT 100000 + p.i, p.statut, p.date_creation,
       CASE WHEN p.statut <> 'en_attente' THEN p.date_creation + INTERVAL '2 minutes' END,
       CASE p.statut
           WHEN 'terminee' THEN p.date_creation + INTERVAL '2 minutes' + p.duree_s * INTERVAL '1 second'
           WHEN 'annulee' THEN p.date_creation + INTERVAL '2 minutes 40 seconds'
       END,
       jsonb_build_object(
           'version_format', 1,
           'config', jsonb_build_object(
               'lignes', p.lignes, 'colonnes', p.colonnes, 'duree_s', p.duree_s,
               'taille_min_mot', 4, 'politique_score', 'classique'
           ),
           'grille', g.grille, 'joueurs', j.joueurs
       ) || CASE WHEN p.statut = 'terminee' THEN jsonb_build_object(
               'resultat', jsonb_build_object('classement', j.classement)
           ) ELSE '{}'::jsonb END,
       p.id_dictionnaire
FROM parties p
JOIN grilles g ON g.i = p.i
JOIN groupes j ON j.i = p.i
ORDER BY p.i;

INSERT INTO boggle.participation (id_partie, id_utilisateur, date_rejoint)
SELECT p.id_partie, (joueur->>'id_utilisateur')::integer, p.date_creation + INTERVAL '1 minute'
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
WHERE p.id_partie >= 100001;

COMMIT;

ANALYZE boggle.partie;
ANALYZE boggle.participation;

SELECT count(*) AS parties,
       (SELECT count(*) FROM boggle.participation WHERE id_partie >= 100001) AS participations,
       pg_size_pretty(pg_relation_size('boggle.partie')) AS taille_table,
       pg_size_pretty(pg_table_size('boggle.partie')) AS taille_avec_toast,
       round(avg(pg_column_size(donnees))) AS octets_moyens_document
FROM boggle.partie
WHERE id_partie >= 100001;
