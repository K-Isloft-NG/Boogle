-- Nettoyage du jeu de test sur une base locale de développement.
BEGIN;
DELETE FROM boggle.participation WHERE id_partie >= 9000;
DELETE FROM boggle.partie WHERE id_partie >= 9000;
DELETE FROM boggle.dictionnaire WHERE id_dictionnaire >= 9000;
DELETE FROM public.php_utilisateurs WHERE id >= 9000 AND email LIKE '%@exemple.fr';
COMMIT;
