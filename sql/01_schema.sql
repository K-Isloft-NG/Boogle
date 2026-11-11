-- Boogle : schéma du module Dev Web (L3)
-- Tables préfixées php_ ; clés primaires en SERIAL.
-- php_utilisateurs est la table des joueurs pour tout le projet : le module L2
-- y fait référence (boggle.participation.id_utilisateur). Ne pas renommer la table ni la colonne id.

CREATE TABLE IF NOT EXISTS php_utilisateurs (
    id                SERIAL PRIMARY KEY,
    pseudo            VARCHAR(30)  NOT NULL UNIQUE,
    email             VARCHAR(254) NOT NULL UNIQUE,
    mot_de_passe_hash VARCHAR(255) NOT NULL,
    date_creation     TIMESTAMP    NOT NULL DEFAULT NOW(),
    -- Un joueur qui a joué n'est jamais supprimé : son compte est désactivé.
    est_actif         BOOLEAN      NOT NULL DEFAULT TRUE
);

-- Mise à niveau d'une base créée avant l'ajout de est_actif (sans effet sur une base neuve).
ALTER TABLE php_utilisateurs ADD COLUMN IF NOT EXISTS est_actif BOOLEAN NOT NULL DEFAULT TRUE;

-- Unicité du pseudo sans tenir compte de la casse, en plus du contrôle fait en PHP.
CREATE UNIQUE INDEX IF NOT EXISTS idx_utilisateurs_pseudo_minuscule ON php_utilisateurs (LOWER(pseudo));

-- Jeton de réinitialisation : on ne stocke que le hash (SHA-256) du jeton envoyé par e-mail.
CREATE TABLE IF NOT EXISTS php_reinitialisations_mdp (
    id              SERIAL PRIMARY KEY,
    utilisateur_id  INTEGER   NOT NULL REFERENCES php_utilisateurs(id) ON DELETE CASCADE,
    jeton_hash      CHAR(64)  NOT NULL UNIQUE,
    date_expiration TIMESTAMP NOT NULL,
    utilise         BOOLEAN   NOT NULL DEFAULT FALSE,
    date_creation   TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Traces de connexion + limitation des tentatives (e-mail et IP pseudonymisés par HMAC).
CREATE TABLE IF NOT EXISTS php_tentatives_connexion (
    id             SERIAL PRIMARY KEY,
    email_hmac     CHAR(64)  NOT NULL,
    ip_hmac        CHAR(64)  NOT NULL,
    succes         BOOLEAN   NOT NULL,
    date_tentative TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tentatives_email ON php_tentatives_connexion (email_hmac, date_tentative);
CREATE INDEX IF NOT EXISTS idx_tentatives_ip    ON php_tentatives_connexion (ip_hmac, date_tentative);
