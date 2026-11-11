-- =============================================================================
-- SAÉ Boggle · Module L2 (R3.07 SQL et Programmation)
-- Étape 2 : script DDL de création du schéma
--
-- Source      : 01_conception/MCD_MLD.md (v2)
-- SGBD        : PostgreSQL 13 ou supérieur
-- Dépendance  : sql/01_schema.sql, à exécuter avant ce script.
-- Exécution   : psql -v ON_ERROR_STOP=1 -d <base> -f sql/02_schema_boggle.sql
--
-- ATTENTION   : le script supprime puis recrée le schéma "boggle".
--               Toutes les données de ce schéma sont perdues. Réservé au
--               développement.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 0. Schéma dédié
--    Isole les objets du projet du schéma "public" : le script peut être rejoué
--    sans risque pour d'autres objets de la base.
-- -----------------------------------------------------------------------------
DROP SCHEMA IF EXISTS boggle CASCADE;
CREATE SCHEMA boggle;
SET search_path TO boggle;


-- -----------------------------------------------------------------------------
-- 2. Table dictionnaire
--    Version du dictionnaire (.lex du moteur L1) ayant servi à valider une partie.
-- -----------------------------------------------------------------------------
CREATE TABLE dictionnaire (
    id_dictionnaire  SERIAL,
    code_langue      CHAR(2)       NOT NULL,
    libelle          VARCHAR(100)  NOT NULL,
    version          VARCHAR(20)   NOT NULL,
    nb_mots          INTEGER,

    CONSTRAINT pk_dictionnaire
        PRIMARY KEY (id_dictionnaire),
    CONSTRAINT uq_dictionnaire_langue_version
        UNIQUE (code_langue, version),
    CONSTRAINT ck_dictionnaire_code_langue
        CHECK (code_langue ~ '^[a-z]{2}$'),
    CONSTRAINT ck_dictionnaire_nb_mots
        CHECK (nb_mots > 0)
);

COMMENT ON TABLE dictionnaire IS 'Dictionnaires de référence utilisés par le moteur de jeu (L1).';


-- -----------------------------------------------------------------------------
-- 3. Table partie
--    RG4 : un seul dictionnaire par partie. RG5 : cycle de vie par statut.
--    RG6 : la colonne donnees (JSONB) suit l'interface du moteur L1.
-- -----------------------------------------------------------------------------
CREATE TABLE partie (
    id_partie        SERIAL,
    statut           VARCHAR(12)  NOT NULL DEFAULT 'en_attente',
    date_creation    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    date_debut       TIMESTAMPTZ,
    date_fin         TIMESTAMPTZ,
    donnees          JSONB        NOT NULL,
    id_dictionnaire  INTEGER      NOT NULL,

    CONSTRAINT pk_partie
        PRIMARY KEY (id_partie),
    CONSTRAINT fk_partie_dictionnaire
        FOREIGN KEY (id_dictionnaire)
        REFERENCES dictionnaire (id_dictionnaire)
        ON DELETE RESTRICT,

    -- Statut et chronologie ------------------------------------------------------
    CONSTRAINT ck_partie_statut
        CHECK (statut IN ('en_attente', 'en_cours', 'terminee', 'annulee')),
    CONSTRAINT ck_partie_debut_apres_creation
        CHECK (date_debut >= date_creation),
    CONSTRAINT ck_partie_fin_apres_debut
        CHECK (date_fin >= date_debut),
    -- Une partie en attente n'a pas encore commencé.
    CONSTRAINT ck_partie_en_attente_sans_debut
        CHECK (statut <> 'en_attente' OR date_debut IS NULL),
    -- Une partie en cours ou terminée a forcément commencé.
    CONSTRAINT ck_partie_commencee_avec_debut
        CHECK (statut NOT IN ('en_cours', 'terminee') OR date_debut IS NOT NULL),
    -- Une partie terminée a forcément une date de fin...
    CONSTRAINT ck_partie_terminee_avec_fin
        CHECK (statut <> 'terminee' OR date_fin IS NOT NULL),
    -- ...et une partie pas encore finie n'en a pas.
    CONSTRAINT ck_partie_non_finie_sans_fin
        CHECK (statut NOT IN ('en_attente', 'en_cours') OR date_fin IS NULL),

    -- Structure minimale du JSON (opérateurs JSONB : ?&, ->, #>, #>>) -----------
    -- Les clés obligatoires sont présentes à la racine de l'objet.
    CONSTRAINT ck_partie_donnees_cles
        CHECK (
            jsonb_typeof(donnees) = 'object'
            AND donnees ?& ARRAY['version_format', 'config', 'grille', 'joueurs']
        ),
    CONSTRAINT ck_partie_donnees_joueurs_tableau
        CHECK (jsonb_typeof(donnees -> 'joueurs') = 'array'),
    -- La grille contient exactement lignes x colonnes cases.
    -- CASE garantit l'ordre d'évaluation : PostgreSQL n'assure pas le
    -- court-circuit d'un AND, et jsonb_array_length() échoue sur un non-tableau.
    CONSTRAINT ck_partie_donnees_grille
        CHECK (
            CASE
                WHEN jsonb_typeof(donnees -> 'grille') = 'array'
                 AND jsonb_typeof(donnees #> '{config,lignes}') = 'number'
                 AND jsonb_typeof(donnees #> '{config,colonnes}') = 'number'
                THEN (donnees #>> '{config,lignes}')::INTEGER >= 1
                 AND (donnees #>> '{config,colonnes}')::INTEGER >= 1
                 AND jsonb_array_length(donnees -> 'grille')
                     = (donnees #>> '{config,lignes}')::INTEGER
                     * (donnees #>> '{config,colonnes}')::INTEGER
                ELSE FALSE
            END
        )
);

COMMENT ON TABLE  partie         IS 'Parties de Boggle. Le détail de jeu est stocké en JSONB (consigne L2).';
COMMENT ON COLUMN partie.donnees IS 'Config, grille, solutions, joueurs et propositions, résultat. Format : 01_conception/MCD_MLD.md, section 5.';


-- -----------------------------------------------------------------------------
-- 4. Table participation (association PARTICIPER)
--    Garantit l'intégrité référentielle joueur <-> partie, que le JSON ne peut
--    pas assurer seul.
-- -----------------------------------------------------------------------------
CREATE TABLE participation (
    id_partie       INTEGER      NOT NULL,
    id_utilisateur  INTEGER      NOT NULL,
    date_rejoint    TIMESTAMPTZ  NOT NULL DEFAULT now(),

    CONSTRAINT pk_participation
        PRIMARY KEY (id_partie, id_utilisateur),
    CONSTRAINT fk_participation_partie
        FOREIGN KEY (id_partie)
        REFERENCES partie (id_partie)
        ON DELETE CASCADE,
    CONSTRAINT fk_participation_utilisateur
        FOREIGN KEY (id_utilisateur)
        REFERENCES public.php_utilisateurs (id)
        ON DELETE RESTRICT
);

-- La clé primaire (id_partie, id_utilisateur) indexe déjà la recherche par
-- partie. Cet index couvre la recherche inverse : les parties d'un joueur.
CREATE INDEX ix_participation_utilisateur
    ON participation (id_utilisateur);

COMMENT ON TABLE participation IS 'Joueurs inscrits à chaque partie (association PARTICIPER).';

COMMIT;
