-- Index de recherche des parties Boggle.
-- Dépendance : sql/02_schema_boggle.sql.
-- Exécution : psql -X -v ON_ERROR_STOP=1 -d <base> -f sql/05_index.sql
-- Tester sur une base locale ou une branche de développement avant la production.

BEGIN;

-- Le GIN global accélère le confinement sur config et le filtre jsonpath.
CREATE INDEX IF NOT EXISTS ix_partie_donnees_gin_path
    ON boggle.partie USING gin (donnees jsonb_path_ops);

-- Le filtre sur le sous-document joueurs exige cette même expression.
CREATE INDEX IF NOT EXISTS ix_partie_joueurs_gin_path
    ON boggle.partie USING gin ((donnees -> 'joueurs') jsonb_path_ops);

-- Le GIN de grille accélère la recherche de cases rares avec ?, ?| et ?&.
CREATE INDEX IF NOT EXISTS ix_partie_grille_gin
    ON boggle.partie USING gin ((donnees -> 'grille'));

-- Le B-tree indexe le score du premier joueur classé pour les seuils.
CREATE INDEX IF NOT EXISTS ix_partie_meilleur_score
    ON boggle.partie USING btree (((donnees #>> '{resultat,classement,0,score}')::integer));

-- Le B-tree combine l'égalité sur le statut et l'intervalle de dates.
CREATE INDEX IF NOT EXISTS ix_partie_statut_date_fin
    ON boggle.partie USING btree (statut, date_fin);

COMMIT;
