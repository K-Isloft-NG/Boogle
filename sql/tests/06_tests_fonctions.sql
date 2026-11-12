-- Contrôles des fonctions Boggle sur le petit jeu de données.
-- Dépendances : sql/03_donnees_test.sql et sql/06_fonctions.sql.
-- Exécution : psql -X -v ON_ERROR_STOP=1 -d <base> -f sql/tests/06_tests_fonctions.sql
-- À exécuter sur une base locale de test. Les écritures sont annulées.

\echo 'CT-FN-01 : affichage de 9001, neuf propositions dans le bon ordre (écarts attendus : 0)'
WITH obtenu AS (
    SELECT a.ordinality, a.joueur, a.rang, a.score_joueur, a.mot, a.chemin,
           a.t_ms, a.valide, a.points, a.motif_rejet
    FROM boggle.afficher_partie(9001) WITH ORDINALITY AS a
), attendu AS (
    VALUES
        (1, 'test_karl',  1, 3, 'OUI',  '10 > 5 > 2',    10000, true,  1, NULL),
        (2, 'test_karl',  1, 3, 'VIRE', '6 > 2 > 3 > 7', 20000, true,  1, NULL),
        (3, 'test_karl',  1, 3, 'RIVE', '3 > 2 > 6 > 7', 30000, true,  1, NULL),
        (4, 'test_karl',  1, 3, 'TOIT', NULL,            40000, false, 0, 'absent_grille'),
        (5, 'test_karl',  1, 3, 'VI',   '6 > 2',         50000, false, 0, 'trop_court'),
        (6, 'test_mamie', 2, 2, 'VIE',  '6 > 2 > 7',     10000, true,  1, NULL),
        (7, 'test_mamie', 2, 2, 'OUI',  '10 > 5 > 2',    20000, true,  1, NULL),
        (8, 'test_mamie', 2, 2, 'VIE',  '6 > 2 > 7',     30000, false, 0, 'doublon'),
        (9, 'test_mamie', 2, 2, 'GAIR', '0 > 1 > 2 > 3', 40000, false, 0, 'absent_dictionnaire')
), differences AS (
    (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
    UNION ALL
    (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'CT-FN-01 : métadonnées et grille exacte de 9001 (écarts attendus : 0)'
SELECT (count(*) <> 9 OR count(*) FILTER (
    WHERE a.id_partie = 9001 AND a.statut = 'terminee'
      AND a.date_debut = timestamptz '2026-11-02 18:05+01'
      AND a.date_fin = timestamptz '2026-11-02 18:08+01'
      AND a.dictionnaire = 'fr jeu-test-1' AND a.grille = 'G A I R | R U V E | QU E O T | A S M J'
      AND a.abandon_t_ms IS NULL
) <> 9)::integer AS ecarts
FROM boggle.afficher_partie(9001) a;

\echo 'CT-FN-02 : partie 9004 en attente, une ligne sans proposition (écarts attendus : 0)'
SELECT (count(*) <> 1 OR count(*) FILTER (
    WHERE a.statut = 'en_attente' AND a.joueur = 'test_lea' AND a.score_joueur = 0
      AND a.rang IS NULL AND a.date_debut IS NULL AND a.date_fin IS NULL
      AND a.mot IS NULL AND a.chemin IS NULL AND a.t_ms IS NULL
      AND a.valide IS NULL AND a.points IS NULL AND a.motif_rejet IS NULL
) <> 1)::integer AS ecarts
FROM boggle.afficher_partie(9004) a;

\echo 'CT-FN-02 : partie 9003 en cours, deux lignes sans rang (écarts attendus : 0)'
SELECT (count(*) <> 2 OR count(*) FILTER (
    WHERE a.statut = 'en_cours' AND a.rang IS NULL AND a.date_fin IS NULL
) <> 2)::integer AS ecarts
FROM boggle.afficher_partie(9003) a;

\echo 'CT-FN-02 : partie 9006, grille 3 x 5 et dictionnaire anglais (écarts attendus : 0)'
SELECT (count(*) <> 7 OR count(*) FILTER (
    WHERE a.dictionnaire = 'en jeu-test-1' AND a.grille = 'C A T S E | R O D E N | B U N I T'
) <> 7)::integer AS ecarts
FROM boggle.afficher_partie(9006) a;

\echo 'CT-FN-02 : identifiant de partie inexistant (écarts attendus : 0)'
SELECT count(*) AS ecarts FROM boggle.afficher_partie(-1);

\echo 'CT-FN-02 : partie sans joueur, une ligne avec joueur NULL (écarts attendus : 0)'
BEGIN;
UPDATE boggle.partie AS p SET donnees = jsonb_set(p.donnees, '{joueurs}', '[]')
WHERE p.id_partie = 9004;
SELECT (count(*) <> 1 OR count(*) FILTER (
    WHERE a.joueur IS NULL AND a.mot IS NULL AND a.score_joueur IS NULL
) <> 1)::integer AS ecarts
FROM boggle.afficher_partie(9004) a;
ROLLBACK;

\echo 'CT-FN-03 : classements 9001, 9002 (ex aequo), 9003 (provisoire) et 9006 (écarts attendus : 0)'
WITH obtenu AS (
    SELECT p.id_partie, c.ordinality, c.rang, c.id_utilisateur, c.pseudo, c.score
    FROM (VALUES (9001), (9002), (9003), (9006)) AS p(id_partie)
    CROSS JOIN LATERAL boggle.classement_partie(p.id_partie) WITH ORDINALITY AS c
), attendu AS (
    VALUES
        (9001, 1, 1, 9001, 'test_karl',  3), (9001, 2, 2, 9002, 'test_mamie', 2),
        (9002, 1, 1, 9004, 'test_hugo',  2), (9002, 2, 1, 9003, 'test_lea',   2),
        (9003, 1, 1, 9004, 'test_hugo',  1), (9003, 2, 1, 9001, 'test_karl',  1),
        (9006, 1, 1, 9002, 'test_mamie', 4), (9006, 2, 2, 9004, 'test_hugo',  2)
), differences AS (
    (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
    UNION ALL
    (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'CT-FN-03 : classement inexistant (écarts attendus : 0)'
SELECT count(*) AS ecarts FROM boggle.classement_partie(-1);

\echo 'CT-FN-04 : parties de 9001 dans le bon ordre et partie de 9005 (écarts attendus : 0)'
WITH obtenu AS (
    SELECT u.id_utilisateur, p.ordinality, p.id_partie, p.statut, p.date_debut,
           p.score, p.rang, p.nb_joueurs
    FROM (VALUES (9001), (9005)) AS u(id_utilisateur)
    CROSS JOIN LATERAL boggle.parties_du_joueur(u.id_utilisateur) WITH ORDINALITY AS p
), attendu AS (
    VALUES
        (9001, 1, 9003, 'en_cours', timestamptz '2026-11-04 18:05+01', 1, NULL, 2),
        (9001, 2, 9001, 'terminee', timestamptz '2026-11-02 18:05+01', 3, 1,    2),
        (9005, 1, 9005, 'annulee',  timestamptz '2026-11-06 18:05+01', 0, NULL, 2)
), differences AS (
    (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
    UNION ALL
    (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'CT-FN-07 : partie terminée, classement remplacé, date passée et deux participations (écarts attendus : 0)'
BEGIN;
SELECT boggle.enregistrer_partie(
    p.id_dictionnaire, p.statut, p.date_debut, p.date_fin,
    jsonb_set(p.donnees, '{resultat}', '{"classement":[]}')
) AS id_cree
FROM boggle.partie p WHERE p.id_partie = 9001
\gset
SELECT (count(*) <> 1 OR count(*) FILTER (
    WHERE p.id_partie > 0 AND p.id_partie <> 9001
      AND p.statut = 'terminee' AND p.id_dictionnaire = 9001
      AND p.date_creation = p.date_debut AND p.date_debut < now()
      AND p.donnees->'resultat' = '{"classement":[
           {"id_utilisateur":9001,"rang":1,"score":3},
           {"id_utilisateur":9002,"rang":2,"score":2}
      ]}'::jsonb
      AND (SELECT array_agg(pa.id_utilisateur ORDER BY pa.id_utilisateur)
           FROM boggle.participation pa WHERE pa.id_partie = p.id_partie) = ARRAY[9001,9002]
) <> 1)::integer AS ecarts
FROM boggle.partie p WHERE p.id_partie = :id_cree;
ROLLBACK;

\echo 'CT-FN-07 : partie en attente, dates optionnelles et JSON conservé (écarts attendus : 0)'
BEGIN;
SELECT boggle.enregistrer_partie(p.id_dictionnaire, p.statut, NULL, NULL, p.donnees) AS id_cree
FROM boggle.partie p WHERE p.id_partie = 9004
\gset
SELECT (count(*) <> 1 OR count(*) FILTER (
    WHERE p.statut = 'en_attente' AND p.date_debut IS NULL AND p.date_fin IS NULL
      AND p.date_creation = now() AND p.donnees = ref.donnees
) <> 1)::integer AS ecarts
FROM boggle.partie p
JOIN boggle.partie ref ON ref.id_partie = 9004
WHERE p.id_partie = :id_cree;
ROLLBACK;

\echo 'CT-FN-07 : contraintes lors des écritures (trois erreurs attendues)'
BEGIN;
-- Le détail d'une ligne refusée peut contenir son identifiant de séquence.
\set VERBOSITY terse
SAVEPOINT utilisateur_inconnu;
\echo 'Erreur attendue : fk_participation_utilisateur'
\set ON_ERROR_STOP off
SELECT boggle.enregistrer_partie(
    p.id_dictionnaire, p.statut, p.date_debut, p.date_fin,
    jsonb_set(p.donnees, '{joueurs,0,id_utilisateur}', '-1')
)
FROM boggle.partie p WHERE p.id_partie = 9001;
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT utilisateur_inconnu;

SAVEPOINT dictionnaire_inconnu;
\echo 'Erreur attendue : fk_partie_dictionnaire'
\set ON_ERROR_STOP off
SELECT boggle.enregistrer_partie(-1, p.statut, p.date_debut, p.date_fin, p.donnees)
FROM boggle.partie p WHERE p.id_partie = 9001;
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT dictionnaire_inconnu;

SAVEPOINT grille_absente;
\echo 'Erreur attendue : ck_partie_donnees_cles'
\set ON_ERROR_STOP off
SELECT boggle.enregistrer_partie(p.id_dictionnaire, p.statut, p.date_debut, p.date_fin, p.donnees - 'grille')
FROM boggle.partie p WHERE p.id_partie = 9001;
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT grille_absente;
\set VERBOSITY default
ROLLBACK;

\echo 'CT-FN-05 : six parties, onze contrôles dans le bon ordre, 66 résultats à 0'
WITH attendu AS (
    SELECT p.id_partie, c.ordinality, c.controle, 0 AS ecarts
    FROM generate_series(9001, 9006) AS p(id_partie)
    CROSS JOIN unnest(ARRAY[
        'partie_existe', 'joueurs_sans_participation', 'participations_hors_json',
        'score_somme_points', 'proposition_incoherente', 'doublon_non_signale',
        'classement_incoherent', 'cases_invalides', 'chemins_incoherents',
        'chemin_absent_incoherent', 'abandon_incoherent'
    ]) WITH ORDINALITY AS c(controle, ordinality)
), obtenu AS (
    SELECT p.id_partie, c.ordinality, c.controle, c.ecarts
    FROM generate_series(9001, 9006) AS p(id_partie)
    CROSS JOIN LATERAL boggle.controler_partie(p.id_partie) WITH ORDINALITY AS c
), differences AS (
    (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
    UNION ALL
    (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'CT-FN-05 : partie inexistante, partie_existe à 1 et autres à 0 (écarts attendus : 0)'
SELECT (count(*) <> 11 OR count(*) FILTER (
    WHERE c.ecarts = CASE WHEN c.controle = 'partie_existe' THEN 1 ELSE 0 END
) <> 11 OR count(*) FILTER (WHERE c.controle = 'partie_existe') <> 1)::integer AS ecarts
FROM boggle.controler_partie(-1) c;

\echo 'CT-FN-02 : abandon valide répété sur les cinq lignes du joueur, sans incohérence (écarts attendus : 0)'
BEGIN;
UPDATE boggle.partie AS p
SET donnees = jsonb_set(p.donnees, '{joueurs,0,abandon_t_ms}', '55000')
WHERE p.id_partie = 9001;
SELECT (count(*) <> 9 OR count(*) FILTER (
    WHERE a.joueur = 'test_karl' AND a.abandon_t_ms = 55000
) <> 5 OR count(*) FILTER (
    WHERE a.joueur = 'test_mamie' AND a.abandon_t_ms IS NULL
) <> 4)::integer AS ecarts
FROM boggle.afficher_partie(9001) a;
SELECT (count(*) <> 11 OR count(*) FILTER (WHERE c.ecarts = 0) <> 11)::integer AS ecarts
FROM boggle.controler_partie(9001) c;
ROLLBACK;

\echo 'CT-FN-07 : résultat absent, classement avec ex aequo créé et partie cohérente (écarts attendus : 0)'
BEGIN;
SELECT boggle.enregistrer_partie(
    p.id_dictionnaire, p.statut, p.date_debut, p.date_fin, p.donnees - 'resultat'
) AS id_cree
FROM boggle.partie p WHERE p.id_partie = 9002
\gset
SELECT (count(*) <> 1 OR count(*) FILTER (
    WHERE p.donnees->'resultat' = '{"classement":[
        {"id_utilisateur":9003,"rang":1,"score":2},
        {"id_utilisateur":9004,"rang":1,"score":2}
    ]}'::jsonb
) <> 1)::integer AS ecarts
FROM boggle.partie p WHERE p.id_partie = :id_cree;
SELECT (count(*) <> 11 OR count(*) FILTER (WHERE c.ecarts = 0) <> 11)::integer AS ecarts
FROM boggle.controler_partie(:id_cree) c;
ROLLBACK;

\echo 'CT-FN-06 a : score du premier joueur modifié (écarts attendus par rapport au diagnostic : 0)'
BEGIN;
UPDATE boggle.partie SET donnees = jsonb_set(donnees, '{joueurs,0,score}', '4') WHERE id_partie = 9001;
WITH diagnostic AS (
    SELECT coalesce(jsonb_object_agg(c.controle, c.ecarts) FILTER (WHERE c.ecarts <> 0), '{}') AS observe
    FROM boggle.controler_partie(9001) c
)
SELECT d.observe, '{"score_somme_points":1,"classement_incoherent":1}'::jsonb AS attendu,
       (d.observe IS DISTINCT FROM '{"score_somme_points":1,"classement_incoherent":1}'::jsonb)::integer AS ecarts
FROM diagnostic d;
ROLLBACK;

\echo 'CT-FN-06 b : participation supprimée (écarts attendus par rapport au diagnostic : 0)'
BEGIN;
DELETE FROM boggle.participation WHERE id_partie = 9001 AND id_utilisateur = 9001;
WITH diagnostic AS (
    SELECT coalesce(jsonb_object_agg(c.controle, c.ecarts) FILTER (WHERE c.ecarts <> 0), '{}') AS observe
    FROM boggle.controler_partie(9001) c
)
SELECT d.observe, '{"joueurs_sans_participation":1}'::jsonb AS attendu,
       (d.observe IS DISTINCT FROM '{"joueurs_sans_participation":1}'::jsonb)::integer AS ecarts
FROM diagnostic d;
ROLLBACK;

\echo 'CT-FN-06 c : joueur JSON sans participation (écarts attendus par rapport au diagnostic : 0)'
BEGIN;
UPDATE boggle.partie
SET donnees = jsonb_set(donnees, '{joueurs}',
    (donnees->'joueurs') || '[{"id_utilisateur":9003,"score":0,"propositions":[]}]')
WHERE id_partie = 9003;
WITH diagnostic AS (
    SELECT coalesce(jsonb_object_agg(c.controle, c.ecarts) FILTER (WHERE c.ecarts <> 0), '{}') AS observe
    FROM boggle.controler_partie(9003) c
)
SELECT d.observe, '{"joueurs_sans_participation":1}'::jsonb AS attendu,
       (d.observe IS DISTINCT FROM '{"joueurs_sans_participation":1}'::jsonb)::integer AS ecarts
FROM diagnostic d;
ROLLBACK;

\echo 'CT-FN-06 d : zéro point pour une proposition valide (écarts attendus par rapport au diagnostic : 0)'
BEGIN;
UPDATE boggle.partie SET donnees = jsonb_set(donnees, '{joueurs,0,propositions,0,points}', '0') WHERE id_partie = 9001;
WITH diagnostic AS (
    SELECT coalesce(jsonb_object_agg(c.controle, c.ecarts) FILTER (WHERE c.ecarts <> 0), '{}') AS observe
    FROM boggle.controler_partie(9001) c
)
SELECT d.observe, '{"score_somme_points":1,"proposition_incoherente":1}'::jsonb AS attendu,
       (d.observe IS DISTINCT FROM '{"score_somme_points":1,"proposition_incoherente":1}'::jsonb)::integer AS ecarts
FROM diagnostic d;
ROLLBACK;

\echo 'CT-FN-06 e : VIE reconstitué avec un saut non adjacent (écarts attendus par rapport au diagnostic : 0)'
BEGIN;
UPDATE boggle.partie SET donnees = jsonb_set(donnees, '{joueurs,1,propositions,0,chemin}', '[6,2,9]') WHERE id_partie = 9001;
WITH diagnostic AS (
    SELECT coalesce(jsonb_object_agg(c.controle, c.ecarts) FILTER (WHERE c.ecarts <> 0), '{}') AS observe
    FROM boggle.controler_partie(9001) c
)
SELECT d.observe, '{"chemins_incoherents":1}'::jsonb AS attendu,
       (d.observe IS DISTINCT FROM '{"chemins_incoherents":1}'::jsonb)::integer AS ecarts
FROM diagnostic d;
ROLLBACK;

\echo 'CT-FN-06 f : case inutilisée en minuscules (écarts attendus par rapport au diagnostic : 0)'
BEGIN;
UPDATE boggle.partie SET donnees = jsonb_set(donnees, '{grille,15}', '"j"') WHERE id_partie = 9001;
WITH diagnostic AS (
    SELECT coalesce(jsonb_object_agg(c.controle, c.ecarts) FILTER (WHERE c.ecarts <> 0), '{}') AS observe
    FROM boggle.controler_partie(9001) c
)
SELECT d.observe, '{"cases_invalides":1}'::jsonb AS attendu,
       (d.observe IS DISTINCT FROM '{"cases_invalides":1}'::jsonb)::integer AS ecarts
FROM diagnostic d;
ROLLBACK;

\echo 'CT-FN-06 g : rang du classement modifié (écarts attendus par rapport au diagnostic : 0)'
BEGIN;
UPDATE boggle.partie SET donnees = jsonb_set(donnees, '{resultat,classement,0,rang}', '99') WHERE id_partie = 9001;
WITH diagnostic AS (
    SELECT coalesce(jsonb_object_agg(c.controle, c.ecarts) FILTER (WHERE c.ecarts <> 0), '{}') AS observe
    FROM boggle.controler_partie(9001) c
)
SELECT d.observe, '{"classement_incoherent":1}'::jsonb AS attendu,
       (d.observe IS DISTINCT FROM '{"classement_incoherent":1}'::jsonb)::integer AS ecarts
FROM diagnostic d;
ROLLBACK;

\echo 'CT-FN-06 h : chemin ajouté à TOIT, rejeté pour absent_grille (écarts attendus par rapport au diagnostic : 0)'
BEGIN;
UPDATE boggle.partie SET donnees = jsonb_set(donnees, '{joueurs,0,propositions,3,chemin}', '[10,5,2]') WHERE id_partie = 9001;
WITH diagnostic AS (
    SELECT coalesce(jsonb_object_agg(c.controle, c.ecarts) FILTER (WHERE c.ecarts <> 0), '{}') AS observe
    FROM boggle.controler_partie(9001) c
)
SELECT d.observe, '{"chemins_incoherents":1,"chemin_absent_incoherent":1}'::jsonb AS attendu,
       (d.observe IS DISTINCT FROM '{"chemins_incoherents":1,"chemin_absent_incoherent":1}'::jsonb)::integer AS ecarts
FROM diagnostic d;
ROLLBACK;

\echo 'CT-FN-06 i : chemin adjacent reconstituant VIV, avec la case 6 répétée (écarts attendus par rapport au diagnostic : 0)'
BEGIN;
UPDATE boggle.partie
SET donnees = jsonb_set(jsonb_set(donnees, '{joueurs,1,propositions,0,chemin}', '[6,2,6]'),
                       '{joueurs,1,propositions,0,mot}', '"VIV"')
WHERE id_partie = 9001;
WITH diagnostic AS (
    SELECT coalesce(jsonb_object_agg(c.controle, c.ecarts) FILTER (WHERE c.ecarts <> 0), '{}') AS observe
    FROM boggle.controler_partie(9001) c
)
SELECT d.observe, '{"chemins_incoherents":1}'::jsonb AS attendu,
       (d.observe IS DISTINCT FROM '{"chemins_incoherents":1}'::jsonb)::integer AS ecarts
FROM diagnostic d;
ROLLBACK;

\echo 'CT-FN-06 j : abandon avant la dernière proposition (écarts attendus par rapport au diagnostic : 0)'
BEGIN;
UPDATE boggle.partie SET donnees = jsonb_set(donnees, '{joueurs,0,abandon_t_ms}', '45000') WHERE id_partie = 9001;
WITH diagnostic AS (
    SELECT coalesce(jsonb_object_agg(c.controle, c.ecarts) FILTER (WHERE c.ecarts <> 0), '{}') AS observe
    FROM boggle.controler_partie(9001) c
)
SELECT d.observe, '{"abandon_incoherent":1}'::jsonb AS attendu,
       (d.observe IS DISTINCT FROM '{"abandon_incoherent":1}'::jsonb)::integer AS ecarts
FROM diagnostic d;
ROLLBACK;
