-- Contrôles et distribution du jeu de volume de Boggle.
-- Utiliser le même -v nb_parties que pour le chargement (défaut : 10000).
\if :{?nb_parties}
\else
    \set nb_parties 10000
\endif

\echo 'Participations absentes du JSON (écarts attendus : 0)'
WITH absentes AS (
    SELECT id_partie, id_utilisateur
    FROM boggle.participation
    WHERE id_partie >= 100001
    EXCEPT ALL
    SELECT p.id_partie, (j->>'id_utilisateur')::integer
    FROM boggle.partie p
    CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS j
    WHERE p.id_partie >= 100001
)
SELECT count(*) AS ecarts FROM absentes;

\echo 'Joueurs JSON absents des participations (écarts attendus : 0)'
WITH absents AS (
    SELECT p.id_partie, (j->>'id_utilisateur')::integer
    FROM boggle.partie p
    CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS j
    WHERE p.id_partie >= 100001
    EXCEPT ALL
    SELECT id_partie, id_utilisateur
    FROM boggle.participation
    WHERE id_partie >= 100001
)
SELECT count(*) AS ecarts FROM absents;

\echo 'Scores différents de la somme des points valides (écarts attendus : 0)'
SELECT count(*) AS ecarts
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS j
WHERE p.id_partie >= 100001
  AND (j->>'score')::integer IS DISTINCT FROM (
      SELECT coalesce(sum((proposition->>'points')::integer), 0)
      FROM jsonb_array_elements(j->'propositions') AS proposition
      WHERE (proposition->>'valide')::boolean IS TRUE
  );

\echo 'Propositions valides avec points ou motif incorrects (écarts attendus : 0)'
SELECT count(*) AS ecarts
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS j
CROSS JOIN LATERAL jsonb_array_elements(j->'propositions') AS proposition
WHERE p.id_partie >= 100001
  AND (proposition->>'valide')::boolean IS TRUE
  AND ((proposition->>'points')::integer IS NULL
       OR (proposition->>'points')::integer < 1
       OR proposition->>'motif_rejet' IS NOT NULL);

\echo 'Propositions rejetées avec points ou motif incorrects (écarts attendus : 0)'
SELECT count(*) AS ecarts
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS j
CROSS JOIN LATERAL jsonb_array_elements(j->'propositions') AS proposition
WHERE p.id_partie >= 100001
  AND (proposition->>'valide')::boolean IS NOT TRUE
  AND ((proposition->>'valide') IS NULL
       OR (proposition->>'points')::integer IS DISTINCT FROM 0
       OR NOT coalesce(proposition->>'motif_rejet' IN
           ('absent_grille', 'absent_dictionnaire', 'trop_court', 'doublon'), false));

\echo 'Parties terminées avec classement incorrect (écarts attendus : 0)'
WITH attendu AS (
    SELECT p.id_partie, (j->>'id_utilisateur')::integer AS id_utilisateur,
           (j->>'score')::integer AS score,
           rank() OVER (PARTITION BY p.id_partie ORDER BY (j->>'score')::integer DESC) AS rang
    FROM boggle.partie p
    CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS j
    WHERE p.id_partie >= 100001 AND p.statut = 'terminee'
), classement AS (
    SELECT p.id_partie, (c->>'id_utilisateur')::integer, (c->>'score')::integer, (c->>'rang')::bigint
    FROM boggle.partie p
    CROSS JOIN LATERAL jsonb_array_elements(p.donnees#>'{resultat,classement}') AS c
    WHERE p.id_partie >= 100001 AND p.statut = 'terminee'
), differences AS (
    (SELECT * FROM attendu EXCEPT ALL SELECT * FROM classement)
    UNION ALL
    (SELECT * FROM classement EXCEPT ALL SELECT * FROM attendu)
)
SELECT count(DISTINCT id_partie) AS ecarts FROM differences;

\echo 'Parties en attente avec proposition (écarts attendus : 0)'
SELECT count(*) AS ecarts
FROM boggle.partie p
WHERE p.id_partie >= 100001 AND p.statut = 'en_attente'
  AND EXISTS (
      SELECT 1 FROM jsonb_array_elements(p.donnees->'joueurs') AS j
      WHERE jsonb_array_length(j->'propositions') > 0
  );

\echo 'Parties non terminées avec résultat (écarts attendus : 0)'
SELECT count(*) AS ecarts
FROM boggle.partie
WHERE id_partie >= 100001 AND statut <> 'terminee' AND donnees ? 'resultat';

\echo 'Comptages de volume (nombre = attendu)'
SELECT 'parties' AS objet, count(*) AS nombre, :'nb_parties'::integer AS attendu
FROM boggle.partie WHERE id_partie >= 100001
UNION ALL
SELECT 'utilisateurs', count(*), 300
FROM public.php_utilisateurs WHERE id >= 100001 AND email LIKE '%@volume.exemple.fr'
UNION ALL
SELECT 'dictionnaires', count(*), 2
FROM boggle.dictionnaire WHERE id_dictionnaire >= 100001;

\echo 'Distribution des statuts (cibles : 80 %, 8 %, 6 %, 6 %)'
SELECT statut, count(*) AS parties, round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS pourcentage
FROM boggle.partie
WHERE id_partie >= 100001
GROUP BY statut
ORDER BY parties DESC, statut;

\echo 'Grilles avec Z, W et QU (cibles : environ 5 %, 5 % et 30 %)'
SELECT round(100.0 * count(*) FILTER (WHERE donnees->'grille' ? 'Z') / nullif(count(*), 0), 2) AS pourcentage_z,
       round(100.0 * count(*) FILTER (WHERE donnees->'grille' ? 'W') / nullif(count(*), 0), 2) AS pourcentage_w,
       round(100.0 * count(*) FILTER (WHERE donnees->'grille' ? 'QU') / nullif(count(*), 0), 2) AS pourcentage_qu
FROM boggle.partie WHERE id_partie >= 100001;

\echo 'Joueurs par partie (cible : 3 en moyenne)'
SELECT min(jsonb_array_length(donnees->'joueurs')) AS minimum,
       round(avg(jsonb_array_length(donnees->'joueurs')), 2) AS moyenne,
       max(jsonb_array_length(donnees->'joueurs')) AS maximum
FROM boggle.partie WHERE id_partie >= 100001;

\echo 'Parties par utilisateur sur les 300 (cible moyenne : environ 1 % des parties)'
WITH parties_par_joueur AS (
    SELECT u.id, count(p.id_partie) AS parties
    FROM public.php_utilisateurs u
    LEFT JOIN boggle.participation p ON p.id_utilisateur = u.id AND p.id_partie >= 100001
    WHERE u.id BETWEEN 100001 AND 100300 AND u.email LIKE '%@volume.exemple.fr'
    GROUP BY u.id
)
SELECT min(parties) AS minimum, round(avg(parties), 2) AS moyenne, max(parties) AS maximum,
       max(parties) FILTER (WHERE id = 100001) AS parties_vol_000001
FROM parties_par_joueur;

\echo 'Propositions et taux de validité (cible de validité : environ 70 %)'
SELECT count(*) AS propositions,
       round(100.0 * count(*) FILTER (WHERE (proposition->>'valide')::boolean IS TRUE)
             / nullif(count(*), 0), 2) AS pourcentage_valides
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS j
CROSS JOIN LATERAL jsonb_array_elements(j->'propositions') AS proposition
WHERE p.id_partie >= 100001;

\echo 'Durées (en secondes) et tailles de grille (cibles : 75 %, 15 %, 10 %)'
SELECT (donnees#>>'{config,duree_s}')::integer AS duree_s, count(*) AS parties
FROM boggle.partie WHERE id_partie >= 100001
GROUP BY duree_s
ORDER BY duree_s;

SELECT (donnees#>>'{config,lignes}')::integer AS lignes,
       (donnees#>>'{config,colonnes}')::integer AS colonnes,
       count(*) AS parties, round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS pourcentage
FROM boggle.partie WHERE id_partie >= 100001
GROUP BY lignes, colonnes
ORDER BY parties DESC;

\echo 'Dictionnaires (cibles : 85 % FR, 15 % EN, aucune case QU pour EN)'
SELECT d.code_langue, count(*) AS parties,
       round(100.0 * count(*) / sum(count(*)) OVER (), 2) AS pourcentage,
       count(*) FILTER (WHERE p.donnees->'grille' ? 'QU') AS grilles_avec_qu
FROM boggle.partie p
JOIN boggle.dictionnaire d ON d.id_dictionnaire = p.id_dictionnaire
WHERE p.id_partie >= 100001
GROUP BY d.code_langue
ORDER BY d.code_langue;
