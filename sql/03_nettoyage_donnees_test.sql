-- Nettoyage du jeu de données de test du schéma boggle.
-- Exécution : psql -v ON_ERROR_STOP=1 -d <base> -f sql/03_nettoyage_donnees_test.sql
-- À ne jamais exécuter sur une base contenant des données réelles : les suppressions visent les identifiants de 9001 à 9999.
BEGIN;
DELETE FROM boggle.participation WHERE id_partie BETWEEN 9001 AND 9999;
DELETE FROM boggle.partie WHERE id_partie BETWEEN 9001 AND 9999;
DELETE FROM boggle.dictionnaire WHERE id_dictionnaire BETWEEN 9001 AND 9999;
DELETE FROM public.php_utilisateurs WHERE id BETWEEN 9001 AND 9999 AND email LIKE '%@exemple.fr';
COMMIT;
