-- Supprime les sept index candidats des mesures de Boggle.
-- Dépendance : sql/02_schema_boggle.sql.
-- Exécution : psql -X -v ON_ERROR_STOP=1 -d <base> -f sql/05_suppression_index.sql
-- À lancer uniquement sur une base locale ou une branche de développement.

BEGIN;

DROP INDEX IF EXISTS boggle.ix_partie_donnees_gin;
DROP INDEX IF EXISTS boggle.ix_partie_donnees_gin_path;
DROP INDEX IF EXISTS boggle.ix_partie_joueurs_gin_path;
DROP INDEX IF EXISTS boggle.ix_partie_grille_gin;
DROP INDEX IF EXISTS boggle.ix_partie_meilleur_score;
DROP INDEX IF EXISTS boggle.ix_partie_statut_date_fin;
DROP INDEX IF EXISTS boggle.ix_partie_dictionnaire;

COMMIT;
