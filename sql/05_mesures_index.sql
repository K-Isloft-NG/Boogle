-- Compare les plans avec et sans les index candidats sur 10 000 parties.
-- Dépendances : sql/01_schema.sql, sql/02_schema_boggle.sql et sql/05_donnees_volume.sql.
-- Exécution depuis la racine : psql -X -v ON_ERROR_STOP=1 -d <base> -f sql/05_mesures_index.sql
-- À lancer uniquement sur une base locale ou une branche de développement.
-- Les index candidats sont supprimés au début et à la fin.

\i sql/05_suppression_index.sql

-- Désactive les parcours parallèles pour réduire la variation des mesures.
SET max_parallel_workers_per_gather = 0;
SHOW shared_buffers;
SHOW work_mem;
SHOW random_page_cost;
SELECT version();

-- Charge les pages de données avant les trois passages par requête.
SELECT sum(pg_column_size(donnees)) AS octets_documents FROM boggle.partie;

-- M7 utilise le seuil 23, soit 307 parties sur 10 000 dans le jeu de volume.
-- Les requêtes sont conservées dans des variables pour garder le même filtre.
SELECT
    $sql$SELECT id_partie FROM boggle.partie
WHERE donnees -> 'grille' ? 'Z'$sql$ AS m1,
    $sql$SELECT id_partie FROM boggle.partie
WHERE donnees -> 'grille' ? 'QU'$sql$ AS m2,
    $sql$SELECT id_partie FROM boggle.partie
WHERE donnees -> 'joueurs' @> '[{"id_utilisateur": 100001}]'::jsonb$sql$ AS m3,
    $sql$SELECT p.id_partie FROM boggle.partie p
JOIN boggle.participation pa ON pa.id_partie = p.id_partie
WHERE pa.id_utilisateur = 100001$sql$ AS m4,
    $sql$SELECT id_partie FROM boggle.partie
WHERE donnees @? '$.joueurs[*] ? (@.id_utilisateur == 100001)'$sql$ AS m5,
    $sql$SELECT id_partie FROM boggle.partie
WHERE donnees @> '{"config": {"lignes": 5, "duree_s": 300}}'::jsonb$sql$ AS m6,
    $sql$SELECT id_partie FROM boggle.partie
WHERE (donnees #>> '{resultat,classement,0,score}')::integer >= 23$sql$ AS m7,
    $sql$SELECT id_partie FROM boggle.partie
WHERE statut = 'terminee'
  AND date_fin >= TIMESTAMPTZ '2026-07-01 00:00+02'
  AND date_fin <  TIMESTAMPTZ '2026-07-08 00:00+02'$sql$ AS m8,
    $sql$SELECT id_partie FROM boggle.partie
WHERE (donnees -> 'resultat' -> 'classement' -> 0 ->> 'score')::integer >= 23$sql$ AS m7bis
\gset

-- jsonb_ops indexe les clés et les valeurs séparément.
-- jsonb_path_ops associe chemin et valeur. Souvent plus compact, il ne gère pas ?.
-- Les index d'expression portent sur le résultat de l'expression écrite.
SELECT
    $sql$CREATE INDEX ix_partie_donnees_gin
        ON boggle.partie USING gin (donnees);$sql$ AS index_1,
    $sql$CREATE INDEX ix_partie_donnees_gin_path
        ON boggle.partie USING gin (donnees jsonb_path_ops);$sql$ AS index_2,
    $sql$CREATE INDEX ix_partie_joueurs_gin_path
        ON boggle.partie USING gin ((donnees -> 'joueurs') jsonb_path_ops);$sql$ AS index_3,
    $sql$CREATE INDEX ix_partie_grille_gin
        ON boggle.partie USING gin ((donnees -> 'grille'));$sql$ AS index_4,
    $sql$CREATE INDEX ix_partie_meilleur_score
        ON boggle.partie USING btree (((donnees #>> '{resultat,classement,0,score}')::integer));$sql$ AS index_5,
    $sql$CREATE INDEX ix_partie_statut_date_fin
        ON boggle.partie USING btree (statut, date_fin);$sql$ AS index_6,
    $sql$CREATE INDEX ix_partie_dictionnaire
        ON boggle.partie USING btree (id_dictionnaire);$sql$ AS index_7
\gset

\set plan 'EXPLAIN (ANALYZE, BUFFERS) '

-- Lecture sans index candidat. Les index du schéma restent actifs.
\echo 'LECTURE sans M1'
SELECT :'plan' || :'m1' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE sans M2'
SELECT :'plan' || :'m2' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE sans M3'
SELECT :'plan' || :'m3' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE sans M4'
SELECT :'plan' || :'m4' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE sans M5'
SELECT :'plan' || :'m5' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE sans M6'
SELECT :'plan' || :'m6' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE sans M7'
SELECT :'plan' || :'m7' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE sans M8'
SELECT :'plan' || :'m8' FROM generate_series(1, 3)
\gexec

-- Lecture avec ix_partie_donnees_gin seul.
:index_1
ANALYZE boggle.partie;
\echo 'LECTURE ix_partie_donnees_gin M1'
SELECT :'plan' || :'m1' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE ix_partie_donnees_gin M2'
SELECT :'plan' || :'m2' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE ix_partie_donnees_gin M3'
SELECT :'plan' || :'m3' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE ix_partie_donnees_gin M5'
SELECT :'plan' || :'m5' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE ix_partie_donnees_gin M6'
SELECT :'plan' || :'m6' FROM generate_series(1, 3)
\gexec
DROP INDEX boggle.ix_partie_donnees_gin;

-- Lecture avec ix_partie_donnees_gin_path seul.
:index_2
ANALYZE boggle.partie;
\echo 'LECTURE ix_partie_donnees_gin_path M3'
SELECT :'plan' || :'m3' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE ix_partie_donnees_gin_path M5'
SELECT :'plan' || :'m5' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE ix_partie_donnees_gin_path M6'
SELECT :'plan' || :'m6' FROM generate_series(1, 3)
\gexec
DROP INDEX boggle.ix_partie_donnees_gin_path;

-- Lecture avec ix_partie_joueurs_gin_path seul.
:index_3
ANALYZE boggle.partie;
\echo 'LECTURE ix_partie_joueurs_gin_path M3'
SELECT :'plan' || :'m3' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE ix_partie_joueurs_gin_path M5'
SELECT :'plan' || :'m5' FROM generate_series(1, 3)
\gexec
DROP INDEX boggle.ix_partie_joueurs_gin_path;

-- Lecture avec ix_partie_grille_gin seul.
:index_4
ANALYZE boggle.partie;
\echo 'LECTURE ix_partie_grille_gin M1'
SELECT :'plan' || :'m1' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE ix_partie_grille_gin M2'
SELECT :'plan' || :'m2' FROM generate_series(1, 3)
\gexec
DROP INDEX boggle.ix_partie_grille_gin;

-- Lecture avec ix_partie_meilleur_score seul.
:index_5
ANALYZE boggle.partie;
-- M7bis calcule le même score par une autre expression. Son arbre est
-- différent de celui de l’index sur #>>, donc ce dernier ne peut pas servir.
\echo 'LECTURE ix_partie_meilleur_score M7'
SELECT :'plan' || :'m7' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE ix_partie_meilleur_score M7bis'
SELECT :'plan' || :'m7bis' FROM generate_series(1, 3)
\gexec
DROP INDEX boggle.ix_partie_meilleur_score;

-- Lecture avec ix_partie_statut_date_fin seul.
:index_6
ANALYZE boggle.partie;
\echo 'LECTURE ix_partie_statut_date_fin M8'
SELECT :'plan' || :'m8' FROM generate_series(1, 3)
\gexec
DROP INDEX boggle.ix_partie_statut_date_fin;

-- Lecture avec tous les candidats.
:index_1
:index_2
:index_3
:index_4
:index_5
:index_6
:index_7
ANALYZE boggle.partie;
\echo 'LECTURE tous M1'
SELECT :'plan' || :'m1' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE tous M2'
SELECT :'plan' || :'m2' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE tous M3'
SELECT :'plan' || :'m3' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE tous M4'
SELECT :'plan' || :'m4' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE tous M5'
SELECT :'plan' || :'m5' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE tous M6'
SELECT :'plan' || :'m6' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE tous M7'
SELECT :'plan' || :'m7' FROM generate_series(1, 3)
\gexec
\echo 'LECTURE tous M8'
SELECT :'plan' || :'m8' FROM generate_series(1, 3)
\gexec
DROP INDEX boggle.ix_partie_donnees_gin;
DROP INDEX boggle.ix_partie_donnees_gin_path;
DROP INDEX boggle.ix_partie_joueurs_gin_path;
DROP INDEX boggle.ix_partie_grille_gin;
DROP INDEX boggle.ix_partie_meilleur_score;
DROP INDEX boggle.ix_partie_statut_date_fin;
DROP INDEX boggle.ix_partie_dictionnaire;

-- Démonstration : à faible sélectivité, le coût du parcours de l'index et
-- des pages de la table peut dépasser celui d'un parcours séquentiel.
-- Le GIN global ne couvre pas l'expression donnees -> 'grille'. Désactiver
-- le parcours séquentiel ne rend pas cet index compatible. On teste aussi
-- le GIN d'expression pour observer le forçage avec un index compatible.
BEGIN;
SET LOCAL enable_seqscan = off;
:index_1
ANALYZE boggle.partie;
\echo 'LECTURE demo_global_force M2'
SELECT :'plan' || :'m2' FROM generate_series(1, 3)
\gexec
:index_4
ANALYZE boggle.partie;
\echo 'LECTURE demo_grille_force M2'
SELECT :'plan' || :'m2' FROM generate_series(1, 3)
\gexec
ROLLBACK;

-- Chaque index à maintenir peut ajouter du travail à une mise à jour du JSON.
\echo 'ECRITURE sans'
BEGIN;
EXPLAIN (ANALYZE)
UPDATE boggle.partie
SET donnees = jsonb_set(donnees, '{config,duree_s}', '240'::jsonb)
WHERE id_partie BETWEEN 100001 AND 101000;
ROLLBACK;
-- Retire les versions annulées avant la prochaine mesure d'écriture.
VACUUM boggle.partie;

:index_1
\echo 'ECRITURE ix_partie_donnees_gin'
BEGIN;
EXPLAIN (ANALYZE)
UPDATE boggle.partie
SET donnees = jsonb_set(donnees, '{config,duree_s}', '240'::jsonb)
WHERE id_partie BETWEEN 100001 AND 101000;
ROLLBACK;
-- Retire les versions annulées avant la prochaine mesure d'écriture.
VACUUM boggle.partie;

DROP INDEX boggle.ix_partie_donnees_gin;

:index_2
\echo 'ECRITURE ix_partie_donnees_gin_path'
BEGIN;
EXPLAIN (ANALYZE)
UPDATE boggle.partie
SET donnees = jsonb_set(donnees, '{config,duree_s}', '240'::jsonb)
WHERE id_partie BETWEEN 100001 AND 101000;
ROLLBACK;
-- Retire les versions annulées avant la prochaine mesure d'écriture.
VACUUM boggle.partie;

DROP INDEX boggle.ix_partie_donnees_gin_path;

:index_3
\echo 'ECRITURE ix_partie_joueurs_gin_path'
BEGIN;
EXPLAIN (ANALYZE)
UPDATE boggle.partie
SET donnees = jsonb_set(donnees, '{config,duree_s}', '240'::jsonb)
WHERE id_partie BETWEEN 100001 AND 101000;
ROLLBACK;
-- Retire les versions annulées avant la prochaine mesure d'écriture.
VACUUM boggle.partie;

DROP INDEX boggle.ix_partie_joueurs_gin_path;

:index_4
\echo 'ECRITURE ix_partie_grille_gin'
BEGIN;
EXPLAIN (ANALYZE)
UPDATE boggle.partie
SET donnees = jsonb_set(donnees, '{config,duree_s}', '240'::jsonb)
WHERE id_partie BETWEEN 100001 AND 101000;
ROLLBACK;
-- Retire les versions annulées avant la prochaine mesure d'écriture.
VACUUM boggle.partie;

DROP INDEX boggle.ix_partie_grille_gin;

:index_1
:index_2
:index_3
:index_4
:index_5
:index_6
:index_7
\echo 'ECRITURE tous'
BEGIN;
EXPLAIN (ANALYZE)
UPDATE boggle.partie
SET donnees = jsonb_set(donnees, '{config,duree_s}', '240'::jsonb)
WHERE id_partie BETWEEN 100001 AND 101000;
ROLLBACK;
-- Retire les versions annulées avant la prochaine mesure d'écriture.
VACUUM boggle.partie;

\i sql/05_suppression_index.sql
