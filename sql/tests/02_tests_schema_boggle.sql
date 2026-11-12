-- =============================================================================
-- SAÉ Boggle · Module L2 · Étape 2 : tests des contraintes du DDL
--
-- Principe : chaque test tente une opération interdite à l'intérieur d'un
-- SAVEPOINT. L'erreur est attendue : on revient au SAVEPOINT et on passe au
-- test suivant. Le ROLLBACK final annule les écritures.
-- Les identifiants explicites préservent les séquences : le script est rejouable.
--
-- ATTENTION : base locale vide ou de développement uniquement. Le jeu insère
-- test1@exemple.fr et test2@exemple.fr : si ces e-mails existent, l'insertion
-- échoue, même si le ROLLBACK final annule les données insérées.
--
-- Exécution (SANS ON_ERROR_STOP, les erreurs sont le résultat attendu) :
--   psql -d <base> -f sql/tests/02_tests_schema_boggle.sql
--
-- Lecture du résultat : chaque "TEST n" doit être suivi d'une ligne ERROR
-- citant la contrainte indiquée dans "attendu".
-- =============================================================================

BEGIN;
SET search_path TO boggle;

-- -----------------------------------------------------------------------------
-- Jeu de données valide minimal (aucune erreur attendue ici)
-- -----------------------------------------------------------------------------
INSERT INTO public.php_utilisateurs (id, pseudo, email, mot_de_passe_hash, date_creation)
VALUES (8001, 'Karl', 'test1@exemple.fr', 'hash_factice', '2026-11-01 12:00:00'),
       (8002, 'Mamie_Jo', 'test2@exemple.fr', 'hash_factice', '2026-11-01 12:00:00');

INSERT INTO dictionnaire (id_dictionnaire, code_langue, libelle, version, nb_mots)
VALUES (8001, 'fr', 'Français (Wiktionary)', '2026.1', 300000);

INSERT INTO partie (id_partie, statut, date_creation, date_debut, date_fin, donnees, id_dictionnaire)
VALUES (
    8001, 'terminee', '2026-11-02 18:00:00+01',
    '2026-11-02 18:05:00+01', '2026-11-02 18:08:00+01',
    '{
       "version_format": 1,
       "config": {"lignes": 4, "colonnes": 4, "duree_s": 180,
                  "taille_min_mot": 3, "politique_score": "classique"},
       "grille": ["G","A","I","R","R","U","V","E","QU","E","O","T","A","S","M","J"],
       "solutions": ["OUI","VIE","VIRE"],
       "joueurs": [
         {"id_utilisateur": 8001, "score": 1, "propositions": [
           {"mot": "OUI", "chemin": [10,5,2], "t_ms": 12400,
            "valide": true, "points": 1, "motif_rejet": null}
         ]}
       ],
       "resultat": {"classement": [{"id_utilisateur": 8001, "rang": 1, "score": 1}]}
     }',
    8001
);

INSERT INTO participation (id_partie, id_utilisateur, date_rejoint)
VALUES (8001, 8001, '2026-11-02 18:02:00+01');

\echo '--- Jeu de données valide inséré. Début des tests (une ERROR attendue par test) ---'

-- -----------------------------------------------------------------------------
-- Table dictionnaire
-- -----------------------------------------------------------------------------
\echo 'TEST 1  code langue invalide                 attendu : ck_dictionnaire_code_langue'
SAVEPOINT test;
INSERT INTO dictionnaire (id_dictionnaire, code_langue, libelle, version) VALUES (8002, 'FR', 'x', 'v1');
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 2  dictionnaire en double               attendu : uq_dictionnaire_langue_version'
SAVEPOINT test;
INSERT INTO dictionnaire (id_dictionnaire, code_langue, libelle, version) VALUES (8003, 'fr', 'x', '2026.1');
ROLLBACK TO SAVEPOINT test;

-- -----------------------------------------------------------------------------
-- Table partie : statut et chronologie
-- -----------------------------------------------------------------------------
\echo 'TEST 3  statut inconnu                       attendu : ck_partie_statut'
SAVEPOINT test;
UPDATE partie SET statut = 'pause' WHERE id_partie = 8001;
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 4  partie terminée sans date de fin     attendu : ck_partie_terminee_avec_fin'
SAVEPOINT test;
UPDATE partie SET date_fin = NULL WHERE id_partie = 8001;
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 5  partie en attente déjà commencée     attendu : ck_partie_en_attente_sans_debut'
SAVEPOINT test;
UPDATE partie SET statut = 'en_attente', date_fin = NULL WHERE id_partie = 8001;
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 6  date de fin avant le début           attendu : ck_partie_fin_apres_debut'
SAVEPOINT test;
UPDATE partie SET date_fin = date_debut - INTERVAL '1 minute' WHERE id_partie = 8001;
ROLLBACK TO SAVEPOINT test;

-- -----------------------------------------------------------------------------
-- Table partie : structure du JSON
-- -----------------------------------------------------------------------------
\echo 'TEST 7 JSON sans clé grille                 attendu : ck_partie_donnees_cles'
SAVEPOINT test;
UPDATE partie SET donnees = donnees - 'grille' WHERE id_partie = 8001;
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 8 grille de 15 cases pour du 4x4       attendu : ck_partie_donnees_grille'
SAVEPOINT test;
UPDATE partie SET donnees = donnees #- '{grille,0}' WHERE id_partie = 8001;
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 9 joueurs n''est pas un tableau         attendu : ck_partie_donnees_joueurs_tableau'
SAVEPOINT test;
UPDATE partie SET donnees = jsonb_set(donnees, '{joueurs}', '{}') WHERE id_partie = 8001;
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 10 racine JSON qui n''est pas un objet   attendu : ck_partie_donnees_cles'
SAVEPOINT test;
UPDATE partie SET donnees = '[]' WHERE id_partie = 8001;
ROLLBACK TO SAVEPOINT test;

-- -----------------------------------------------------------------------------
-- Clés étrangères
-- -----------------------------------------------------------------------------
\echo 'TEST 11 dictionnaire inexistant              attendu : fk_partie_dictionnaire'
SAVEPOINT test;
UPDATE partie SET id_dictionnaire = 999 WHERE id_partie = 8001;
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 12 participation, joueur inexistant     attendu : fk_participation_utilisateur'
SAVEPOINT test;
INSERT INTO participation (id_partie, id_utilisateur, date_rejoint)
VALUES (8001, 999, '2026-11-02 18:02:00+01');
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 13 participation en double              attendu : pk_participation'
SAVEPOINT test;
INSERT INTO participation (id_partie, id_utilisateur, date_rejoint)
VALUES (8001, 8001, '2026-11-02 18:02:00+01');
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 14 suppression d''un joueur ayant joué   attendu : fk_participation_utilisateur'
SAVEPOINT test;
DELETE FROM public.php_utilisateurs WHERE id = 8001;
ROLLBACK TO SAVEPOINT test;

\echo 'TEST 15 suppression d''un dictionnaire utilisé attendu : fk_partie_dictionnaire'
SAVEPOINT test;
DELETE FROM dictionnaire WHERE id_dictionnaire = 8001;
ROLLBACK TO SAVEPOINT test;

-- -----------------------------------------------------------------------------
-- Cas valide : suppression en cascade (aucune erreur attendue)
-- -----------------------------------------------------------------------------
\echo 'TEST 16 cascade partie -> participation      attendu : nb_participations_restantes = 0'
DELETE FROM partie WHERE id_partie = 8001;
SELECT count(*) AS nb_participations_restantes FROM participation WHERE id_partie = 8001;

ROLLBACK;
