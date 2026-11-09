-- Boogle : schéma du module Dev Web (L3)
-- Tables préfixées php_ ; clés primaires en SERIAL.

CREATE TABLE IF NOT EXISTS php_utilisateurs (
    id                SERIAL PRIMARY KEY,
    pseudo            VARCHAR(30)  NOT NULL UNIQUE,
    email             VARCHAR(254) NOT NULL UNIQUE,
    mot_de_passe_hash VARCHAR(255) NOT NULL,
    date_creation     TIMESTAMP    NOT NULL DEFAULT NOW()
);

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
