-- Nettoyage du jeu de données de test du schéma boggle.
-- Exécution : psql -v ON_ERROR_STOP=1 -d <base> -f sql/03_nettoyage_donnees_test.sql
-- À ne jamais exécuter sur une base contenant des données réelles : les suppressions se font par seuil d'identifiant (>= 9000).
BEGIN;
DELETE FROM boggle.participation WHERE id_partie >= 9000;
DELETE FROM boggle.partie WHERE id_partie >= 9000;
DELETE FROM boggle.dictionnaire WHERE id_dictionnaire >= 9000;
DELETE FROM public.php_utilisateurs WHERE id >= 9000 AND email LIKE '%@exemple.fr';
COMMIT;
