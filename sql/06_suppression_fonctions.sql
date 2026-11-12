-- Supprime les cinq fonctions SQL du schéma Boggle.
-- Dépendance : sql/02_schema_boggle.sql.
-- Exécution : psql -X -v ON_ERROR_STOP=1 -d <base> -f sql/06_suppression_fonctions.sql

BEGIN;

DROP FUNCTION IF EXISTS boggle.afficher_partie(integer);
DROP FUNCTION IF EXISTS boggle.classement_partie(integer);
DROP FUNCTION IF EXISTS boggle.parties_du_joueur(integer);
DROP FUNCTION IF EXISTS boggle.controler_partie(integer);
DROP FUNCTION IF EXISTS boggle.enregistrer_partie(integer, text, timestamptz, timestamptz, jsonb);

COMMIT;
