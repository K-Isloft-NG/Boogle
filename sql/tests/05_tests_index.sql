-- Vérifie les index retenus et les résultats des huit requêtes de mesure.
-- Dépendances : sql/05_donnees_volume.sql et sql/05_index.sql.
-- Exécution : psql -X -v ON_ERROR_STOP=1 -d <base> -f sql/tests/05_tests_index.sql
-- À lancer uniquement sur une base locale ou une branche de développement.

BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY;

\echo 'Présence, méthode et validité des index retenus (écarts attendus : 0)'
WITH attendus(nom, methode) AS (
    VALUES
        ('ix_partie_donnees_gin_path', 'gin'),
        ('ix_partie_joueurs_gin_path', 'gin'),
        ('ix_partie_grille_gin', 'gin'),
        ('ix_partie_meilleur_score', 'btree'),
        ('ix_partie_statut_date_fin', 'btree')
), observes AS (
    SELECT c.relname, am.amname, i.indisvalid, i.indisready
    FROM pg_index i
    JOIN pg_class c ON c.oid = i.indexrelid
    JOIN pg_am am ON am.oid = c.relam
    WHERE i.indrelid = 'boggle.partie'::regclass
)
SELECT a.nom AS index, CASE WHEN o.relname IS NULL THEN 1 ELSE 0 END AS ecarts
FROM attendus a
LEFT JOIN observes o
    ON o.relname = a.nom AND o.amname = a.methode AND o.indisvalid AND o.indisready
ORDER BY a.nom;

-- L'ordre des identifiants est fixé avant le calcul de l'empreinte.
-- La même requête d'empreinte est évaluée dans les deux configurations.
SELECT $sql$
WITH
m1 AS (
    SELECT id_partie FROM boggle.partie
    WHERE donnees -> 'grille' ? 'Z'
),
m2 AS (
    SELECT id_partie FROM boggle.partie
    WHERE donnees -> 'grille' ? 'QU'
),
m3 AS (
    SELECT id_partie FROM boggle.partie
    WHERE donnees -> 'joueurs' @> '[{"id_utilisateur": 100001}]'::jsonb
),
m4 AS (
    SELECT p.id_partie FROM boggle.partie p
    JOIN boggle.participation pa ON pa.id_partie = p.id_partie
    WHERE pa.id_utilisateur = 100001
),
m5 AS (
    SELECT id_partie FROM boggle.partie
    WHERE donnees @? '$.joueurs[*] ? (@.id_utilisateur == 100001)'
),
m6 AS (
    SELECT id_partie FROM boggle.partie
    WHERE donnees @> '{"config": {"lignes": 5, "duree_s": 300}}'::jsonb
),
m7 AS (
    SELECT id_partie FROM boggle.partie
    WHERE (donnees #>> '{resultat,classement,0,score}')::integer >= 23
),
m8 AS (
    SELECT id_partie FROM boggle.partie
    WHERE statut = 'terminee'
      AND date_fin >= TIMESTAMPTZ '2026-07-01 00:00+02'
      AND date_fin <  TIMESTAMPTZ '2026-07-08 00:00+02'
),
requetes AS (
    SELECT 'M1' AS mesure, count(*) AS nombre,
           md5(coalesce(string_agg(id_partie::text, ',' ORDER BY id_partie), '')) AS empreinte
    FROM m1
    UNION ALL
    SELECT 'M2' AS mesure, count(*) AS nombre,
           md5(coalesce(string_agg(id_partie::text, ',' ORDER BY id_partie), '')) AS empreinte
    FROM m2
    UNION ALL
    SELECT 'M3' AS mesure, count(*) AS nombre,
           md5(coalesce(string_agg(id_partie::text, ',' ORDER BY id_partie), '')) AS empreinte
    FROM m3
    UNION ALL
    SELECT 'M4' AS mesure, count(*) AS nombre,
           md5(coalesce(string_agg(id_partie::text, ',' ORDER BY id_partie), '')) AS empreinte
    FROM m4
    UNION ALL
    SELECT 'M5' AS mesure, count(*) AS nombre,
           md5(coalesce(string_agg(id_partie::text, ',' ORDER BY id_partie), '')) AS empreinte
    FROM m5
    UNION ALL
    SELECT 'M6' AS mesure, count(*) AS nombre,
           md5(coalesce(string_agg(id_partie::text, ',' ORDER BY id_partie), '')) AS empreinte
    FROM m6
    UNION ALL
    SELECT 'M7' AS mesure, count(*) AS nombre,
           md5(coalesce(string_agg(id_partie::text, ',' ORDER BY id_partie), '')) AS empreinte
    FROM m7
    UNION ALL
    SELECT 'M8' AS mesure, count(*) AS nombre,
           md5(coalesce(string_agg(id_partie::text, ',' ORDER BY id_partie), '')) AS empreinte
    FROM m8
)
SELECT jsonb_object_agg(mesure, jsonb_build_array(nombre, empreinte)) AS resultats
FROM requetes
$sql$ AS calcul_resultats
\gset

:calcul_resultats
\gset avec_

SET LOCAL enable_indexscan = off;
SET LOCAL enable_bitmapscan = off;
SET LOCAL enable_indexonlyscan = off;

:calcul_resultats
\gset sans_

\echo 'M1 : nombre et empreinte avec et sans parcours d’index (écarts attendus : 0)'
SELECT CASE WHEN :'avec_resultats'::jsonb -> 'M1' = :'sans_resultats'::jsonb -> 'M1'
            THEN 0 ELSE 1 END AS ecarts;

\echo 'M2 : nombre et empreinte avec et sans parcours d’index (écarts attendus : 0)'
SELECT CASE WHEN :'avec_resultats'::jsonb -> 'M2' = :'sans_resultats'::jsonb -> 'M2'
            THEN 0 ELSE 1 END AS ecarts;

\echo 'M3 : nombre et empreinte avec et sans parcours d’index (écarts attendus : 0)'
SELECT CASE WHEN :'avec_resultats'::jsonb -> 'M3' = :'sans_resultats'::jsonb -> 'M3'
            THEN 0 ELSE 1 END AS ecarts;

\echo 'M4 : nombre et empreinte avec et sans parcours d’index (écarts attendus : 0)'
SELECT CASE WHEN :'avec_resultats'::jsonb -> 'M4' = :'sans_resultats'::jsonb -> 'M4'
            THEN 0 ELSE 1 END AS ecarts;

\echo 'M5 : nombre et empreinte avec et sans parcours d’index (écarts attendus : 0)'
SELECT CASE WHEN :'avec_resultats'::jsonb -> 'M5' = :'sans_resultats'::jsonb -> 'M5'
            THEN 0 ELSE 1 END AS ecarts;

\echo 'M6 : nombre et empreinte avec et sans parcours d’index (écarts attendus : 0)'
SELECT CASE WHEN :'avec_resultats'::jsonb -> 'M6' = :'sans_resultats'::jsonb -> 'M6'
            THEN 0 ELSE 1 END AS ecarts;

\echo 'M7 : nombre et empreinte avec et sans parcours d’index (écarts attendus : 0)'
SELECT CASE WHEN :'avec_resultats'::jsonb -> 'M7' = :'sans_resultats'::jsonb -> 'M7'
            THEN 0 ELSE 1 END AS ecarts;

\echo 'M8 : nombre et empreinte avec et sans parcours d’index (écarts attendus : 0)'
SELECT CASE WHEN :'avec_resultats'::jsonb -> 'M8' = :'sans_resultats'::jsonb -> 'M8'
            THEN 0 ELSE 1 END AS ecarts;

\echo 'M3, M4 et M5 : mêmes identifiants (écarts attendus : 0)'
WITH
m3 AS (
    SELECT id_partie FROM boggle.partie
    WHERE donnees -> 'joueurs' @> '[{"id_utilisateur": 100001}]'::jsonb
),
m4 AS (
    SELECT p.id_partie FROM boggle.partie p
    JOIN boggle.participation pa ON pa.id_partie = p.id_partie
    WHERE pa.id_utilisateur = 100001
),
m5 AS (
    SELECT id_partie FROM boggle.partie
    WHERE donnees @? '$.joueurs[*] ? (@.id_utilisateur == 100001)'
),
differences AS (
    (SELECT id_partie FROM m3 EXCEPT ALL SELECT id_partie FROM m4)
    UNION ALL
    (SELECT id_partie FROM m4 EXCEPT ALL SELECT id_partie FROM m3)
    UNION ALL
    (SELECT id_partie FROM m3 EXCEPT ALL SELECT id_partie FROM m5)
    UNION ALL
    (SELECT id_partie FROM m5 EXCEPT ALL SELECT id_partie FROM m3)
)
SELECT count(*) AS ecarts FROM differences;

ROLLBACK;
