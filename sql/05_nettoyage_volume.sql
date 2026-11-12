-- Nettoyage du jeu de volume du schéma boggle.
-- Exécution : psql -v ON_ERROR_STOP=1 -d <base> -f sql/05_nettoyage_volume.sql
-- Base locale ou branche de développement uniquement. Jamais en production.
-- Les suppressions visent les identifiants à partir de 100001.

BEGIN;

DELETE FROM boggle.participation WHERE id_partie >= 100001;
DELETE FROM boggle.partie WHERE id_partie >= 100001;
DELETE FROM boggle.dictionnaire WHERE id_dictionnaire >= 100001;
DELETE FROM public.php_utilisateurs
WHERE id >= 100001 AND email LIKE '%@volume.exemple.fr';

COMMIT;
