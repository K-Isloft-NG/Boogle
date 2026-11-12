-- Fonctions SQL du schéma Boggle pour consulter, contrôler et enregistrer une partie.
-- Dépendances : sql/01_schema.sql et sql/02_schema_boggle.sql.
-- Exécution : psql -X -v ON_ERROR_STOP=1 -d <base> -f sql/06_fonctions.sql

BEGIN;

-- Une fonction qui renvoie une table s'appelle avec SELECT. Une procédure
-- s'appelle avec CALL. STABLE convient aux lectures du même instantané.
-- Les noms des tables incluent leur schéma pour éviter de dépendre de search_path.

CREATE OR REPLACE FUNCTION boggle.afficher_partie(p_id_partie integer)
RETURNS TABLE (
    id_partie integer, statut text, date_debut timestamptz, date_fin timestamptz,
    dictionnaire text, grille text, joueur text, rang integer, score_joueur integer,
    mot text, chemin text, t_ms integer, valide boolean, points integer,
    motif_rejet text, abandon_t_ms integer
)
LANGUAGE sql STABLE RETURNS NULL ON NULL INPUT
AS $fonction$
    SELECT p.id_partie, p.statut::text, p.date_debut, p.date_fin,
           d.code_langue::text || ' ' || d.version, g.grille, u.pseudo::text,
           (c.valeur->>'rang')::integer, (j.valeur->>'score')::integer,
           pr.valeur->>'mot', ch.chemin, (pr.valeur->>'t_ms')::integer,
           (pr.valeur->>'valide')::boolean, (pr.valeur->>'points')::integer,
           pr.valeur->>'motif_rejet', (j.valeur->>'abandon_t_ms')::integer
    FROM boggle.partie p
    JOIN boggle.dictionnaire d ON d.id_dictionnaire = p.id_dictionnaire
    CROSS JOIN LATERAL (
        SELECT string_agg(l.cases, ' | ' ORDER BY l.numero) AS grille
        FROM (
            SELECT (ca.position - 1) / (p.donnees#>>'{config,colonnes}')::integer AS numero,
                   string_agg(ca.lettre, ' ' ORDER BY ca.position) AS cases
            FROM jsonb_array_elements_text(p.donnees->'grille')
                 WITH ORDINALITY AS ca(lettre, position)
            GROUP BY (ca.position - 1) / (p.donnees#>>'{config,colonnes}')::integer
        ) l
    ) g
    -- Les jointures externes gardent la partie ou le joueur si le tableau est vide.
    LEFT JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS j(valeur) ON true
    LEFT JOIN public.php_utilisateurs u ON u.id = (j.valeur->>'id_utilisateur')::integer
    LEFT JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(p.donnees#>'{resultat,classement}') = 'array'
             THEN p.donnees#>'{resultat,classement}' ELSE '[]'::jsonb END
    ) AS c(valeur) ON c.valeur->'id_utilisateur' = j.valeur->'id_utilisateur'
    LEFT JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(j.valeur->'propositions') = 'array'
             THEN j.valeur->'propositions' ELSE '[]'::jsonb END
    ) AS pr(valeur) ON true
    CROSS JOIN LATERAL (
        SELECT string_agg(i.indice, ' > ' ORDER BY i.position) AS chemin
        FROM jsonb_array_elements_text(
            CASE WHEN jsonb_typeof(pr.valeur->'chemin') = 'array'
                 THEN pr.valeur->'chemin' ELSE '[]'::jsonb END
        ) WITH ORDINALITY AS i(indice, position)
    ) ch
    WHERE p.id_partie = p_id_partie
    ORDER BY (c.valeur->>'rang')::integer NULLS LAST, u.pseudo, (pr.valeur->>'t_ms')::integer;
$fonction$;

COMMENT ON FUNCTION boggle.afficher_partie(integer) IS
    'Affiche la grille, les joueurs et leurs propositions, avec le classement enregistré.';

CREATE OR REPLACE FUNCTION boggle.classement_partie(p_id_partie integer)
RETURNS TABLE (rang integer, id_utilisateur integer, pseudo text, score integer)
LANGUAGE sql STABLE RETURNS NULL ON NULL INPUT
AS $fonction$
    WITH joueurs AS (
        SELECT (j.valeur->>'id_utilisateur')::integer AS id_utilisateur,
               (j.valeur->>'score')::integer AS score
        FROM boggle.partie p
        CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS j(valeur)
        WHERE p.id_partie = p_id_partie
    ), classes AS (
        SELECT rank() OVER (ORDER BY j.score DESC)::integer AS rang,
               j.id_utilisateur, j.score
        FROM joueurs j
    )
    SELECT c.rang, c.id_utilisateur, u.pseudo::text, c.score
    FROM classes c
    LEFT JOIN public.php_utilisateurs u ON u.id = c.id_utilisateur
    ORDER BY c.rang, u.pseudo;
$fonction$;

COMMENT ON FUNCTION boggle.classement_partie(integer) IS
    'Classe les joueurs par leur score enregistré, avec un même rang pour les ex aequo.';

CREATE OR REPLACE FUNCTION boggle.parties_du_joueur(p_id_utilisateur integer)
RETURNS TABLE (
    id_partie integer, statut text, date_debut timestamptz,
    score integer, rang integer, nb_joueurs integer
)
LANGUAGE sql STABLE RETURNS NULL ON NULL INPUT
AS $fonction$
    SELECT p.id_partie, p.statut::text, p.date_debut, (j.valeur->>'score')::integer,
           (c.valeur->>'rang')::integer, jsonb_array_length(p.donnees->'joueurs')
    FROM boggle.participation pa
    JOIN boggle.partie p ON p.id_partie = pa.id_partie
    LEFT JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS j(valeur)
        ON j.valeur->'id_utilisateur' = to_jsonb(pa.id_utilisateur)
    LEFT JOIN LATERAL jsonb_array_elements(
        CASE WHEN p.statut = 'terminee' AND jsonb_typeof(p.donnees#>'{resultat,classement}') = 'array'
             THEN p.donnees#>'{resultat,classement}' ELSE '[]'::jsonb END
    ) AS c(valeur) ON c.valeur->'id_utilisateur' = to_jsonb(pa.id_utilisateur)
    WHERE pa.id_utilisateur = p_id_utilisateur
    ORDER BY p.date_debut DESC NULLS LAST, p.id_partie DESC;
$fonction$;

COMMENT ON FUNCTION boggle.parties_du_joueur(integer) IS
    'Liste les parties du joueur en partant de ses participations.';

CREATE OR REPLACE FUNCTION boggle.enregistrer_partie(
    p_id_dictionnaire integer, p_statut text, p_date_debut timestamptz,
    p_date_fin timestamptz, p_donnees jsonb
)
RETURNS integer
LANGUAGE sql VOLATILE
AS $fonction$
    WITH joueurs AS (
        SELECT (j.valeur->>'id_utilisateur')::integer AS id_utilisateur, j.valeur
        FROM jsonb_array_elements(
            CASE WHEN jsonb_typeof(p_donnees->'joueurs') = 'array'
                 THEN p_donnees->'joueurs' ELSE '[]'::jsonb END
        ) AS j(valeur)
    ), classes AS (
        -- Le score vient du jeu. Seul le rang est calculé ici.
        SELECT j.id_utilisateur, (j.valeur->>'score')::integer AS score,
               rank() OVER (ORDER BY (j.valeur->>'score')::integer DESC) AS rang
        FROM joueurs j
    ), nouvelle_partie AS (
        INSERT INTO boggle.partie AS p (id_dictionnaire, statut, date_creation, date_debut, date_fin, donnees)
        SELECT p_id_dictionnaire, p_statut,
               -- Une partie saisie après son début doit garder une chronologie valide.
               CASE WHEN p_date_debut IS NULL THEN now() ELSE least(now(), p_date_debut) END,
               p_date_debut, p_date_fin,
               CASE WHEN p_statut = 'terminee' AND jsonb_typeof(p_donnees) = 'object'
                    THEN jsonb_set(p_donnees, '{resultat}', jsonb_build_object('classement', (
                        SELECT coalesce(jsonb_agg(
                            jsonb_build_object('id_utilisateur', c.id_utilisateur, 'rang', c.rang, 'score', c.score)
                            ORDER BY c.rang, c.id_utilisateur
                        ), '[]'::jsonb)
                        FROM classes c
                    )))
                    ELSE p_donnees
               END
        RETURNING p.id_partie
    ), nouvelles_participations AS (
        -- RETURNING transmet l'identifiant. Les deux INSERT réussissent ou échouent ensemble.
        INSERT INTO boggle.participation (id_partie, id_utilisateur)
        SELECT p.id_partie, j.id_utilisateur
        FROM nouvelle_partie p CROSS JOIN joueurs j
    )
    SELECT p.id_partie FROM nouvelle_partie p;
$fonction$;

COMMENT ON FUNCTION boggle.enregistrer_partie(integer, text, timestamptz, timestamptz, jsonb) IS
    'Insère une partie et ses participations ensemble. Pour une partie terminée, reconstruit le classement.';

CREATE OR REPLACE FUNCTION boggle.controler_partie(p_id_partie integer)
RETURNS TABLE (controle text, ecarts integer)
LANGUAGE sql STABLE RETURNS NULL ON NULL INPUT
AS $fonction$
    WITH partie_lue AS (
        SELECT p.id_partie, p.statut, p.donnees, p.donnees#>'{resultat,classement}' AS classement,
               CASE WHEN jsonb_typeof(p.donnees#>'{config,colonnes}') = 'number'
                    THEN (p.donnees#>>'{config,colonnes}')::numeric END AS colonnes,
               CASE WHEN jsonb_typeof(p.donnees#>'{config,duree_s}') = 'number'
                    THEN (p.donnees#>>'{config,duree_s}')::numeric END AS duree_s
        FROM boggle.partie p
        WHERE p.id_partie = p_id_partie
    ), joueurs AS (
        SELECT j.position AS position_joueur, j.valeur,
               CASE WHEN jsonb_typeof(j.valeur->'id_utilisateur') = 'number'
                    THEN (j.valeur->>'id_utilisateur')::numeric END AS id_utilisateur,
               CASE WHEN jsonb_typeof(j.valeur->'score') = 'number'
                    THEN (j.valeur->>'score')::numeric END AS score,
               CASE WHEN jsonb_typeof(j.valeur->'abandon_t_ms') = 'number'
                    THEN (j.valeur->>'abandon_t_ms')::numeric END AS abandon_t_ms
        FROM partie_lue p
        CROSS JOIN LATERAL jsonb_array_elements(
            CASE WHEN jsonb_typeof(p.donnees->'joueurs') = 'array'
                 THEN p.donnees->'joueurs' ELSE '[]'::jsonb END
        ) WITH ORDINALITY AS j(valeur, position)
    ), propositions AS (
        SELECT j.position_joueur, pr.position AS position_proposition,
               pr.valeur->>'mot' AS mot, pr.valeur->'chemin' AS chemin,
               pr.valeur->>'motif_rejet' AS motif_rejet,
               CASE WHEN jsonb_typeof(pr.valeur->'valide') = 'boolean'
                    THEN (pr.valeur->>'valide')::boolean END AS valide,
               CASE WHEN jsonb_typeof(pr.valeur->'points') = 'number'
                         AND pr.valeur->>'points' ~ '^-?[0-9]{1,10}$'
                    THEN (pr.valeur->>'points')::bigint END AS points,
               CASE WHEN jsonb_typeof(pr.valeur->'t_ms') = 'number'
                    THEN (pr.valeur->>'t_ms')::numeric END AS t_ms
        FROM joueurs j
        CROSS JOIN LATERAL jsonb_array_elements(
            CASE WHEN jsonb_typeof(j.valeur->'propositions') = 'array'
                 THEN j.valeur->'propositions' ELSE '[]'::jsonb END
        ) WITH ORDINALITY AS pr(valeur, position)
    ), sommes AS (
        SELECT pr.position_joueur, sum(pr.points) FILTER (WHERE pr.valide) AS points_valides
        FROM propositions pr
        GROUP BY pr.position_joueur
    ), doublons AS (
        SELECT count(*) - 1 AS repetitions
        FROM propositions pr
        WHERE pr.valide IS TRUE
        GROUP BY pr.position_joueur, pr.mot
        HAVING count(*) > 1
    ), classement_attendu AS (
        SELECT j.id_utilisateur, j.score, rank() OVER (ORDER BY j.score DESC NULLS LAST) AS rang
        FROM joueurs j
    ), classement_lu AS (
        SELECT CASE WHEN jsonb_typeof(c.valeur->'id_utilisateur') = 'number'
                    THEN (c.valeur->>'id_utilisateur')::numeric END AS id_utilisateur,
               CASE WHEN jsonb_typeof(c.valeur->'score') = 'number'
                    THEN (c.valeur->>'score')::numeric END AS score,
               CASE WHEN jsonb_typeof(c.valeur->'rang') = 'number'
                    THEN (c.valeur->>'rang')::numeric END AS rang
        FROM partie_lue p
        CROSS JOIN LATERAL jsonb_array_elements(
            CASE WHEN jsonb_typeof(p.classement) = 'array' THEN p.classement ELSE '[]'::jsonb END
        ) AS c(valeur)
    ), ecarts_classement AS (
        (SELECT a.id_utilisateur, a.score, a.rang FROM classement_attendu a
         EXCEPT ALL SELECT l.id_utilisateur, l.score, l.rang FROM classement_lu l)
        UNION ALL
        (SELECT l.id_utilisateur, l.score, l.rang FROM classement_lu l
         EXCEPT ALL SELECT a.id_utilisateur, a.score, a.rang FROM classement_attendu a)
    ), cases AS (
        SELECT ca.position - 1 AS indice,
               CASE WHEN jsonb_typeof(ca.valeur) = 'string' THEN ca.valeur#>>'{}' END AS lettre
        FROM partie_lue p
        CROSS JOIN LATERAL jsonb_array_elements(
            CASE WHEN jsonb_typeof(p.donnees->'grille') = 'array'
                 THEN p.donnees->'grille' ELSE '[]'::jsonb END
        ) WITH ORDINALITY AS ca(valeur, position)
    ), indices_lus AS (
        SELECT pr.position_joueur, pr.position_proposition, i.position,
               CASE WHEN jsonb_typeof(i.valeur) = 'number' THEN (i.valeur#>>'{}')::numeric END AS indice
        FROM propositions pr
        CROSS JOIN LATERAL jsonb_array_elements(
            CASE WHEN jsonb_typeof(pr.chemin) = 'array' THEN pr.chemin ELSE '[]'::jsonb END
        ) WITH ORDINALITY AS i(valeur, position)
    ), coordonnees AS (
        -- La jointure retrouve la lettre et exclut les indices hors de la grille.
        -- Le quotient et le reste donnent la ligne et la colonne de chaque case.
        SELECT i.position_joueur, i.position_proposition, i.position, c.indice, c.lettre,
               CASE WHEN p.colonnes BETWEEN 1 AND 2147483647
                    THEN c.indice / p.colonnes::integer END AS ligne,
               CASE WHEN p.colonnes BETWEEN 1 AND 2147483647
                    THEN c.indice % p.colonnes::integer END AS colonne
        FROM indices_lus i
        CROSS JOIN partie_lue p
        LEFT JOIN cases c ON c.indice = i.indice
    ), pas AS (
        SELECT c.*, lag(c.ligne) OVER trajet AS ligne_precedente,
                    lag(c.colonne) OVER trajet AS colonne_precedente
        FROM coordonnees c
        WINDOW trajet AS (PARTITION BY c.position_joueur, c.position_proposition ORDER BY c.position)
    ), chemins AS (
        SELECT c.position_joueur, c.position_proposition,
               string_agg(c.lettre, '' ORDER BY c.position) AS mot_reconstitue,
               count(DISTINCT c.indice) = count(*) AND count(c.lettre) = count(*)
                   AND bool_and(c.position = 1 OR (
                       abs(c.ligne - c.ligne_precedente) <= 1
                       AND abs(c.colonne - c.colonne_precedente) <= 1
                   )) AS valide
        FROM pas c
        GROUP BY c.position_joueur, c.position_proposition
    )
    SELECT v.code, v.nombre::integer
    FROM (VALUES
        (1, 'partie_existe', (NOT EXISTS (SELECT 1 FROM partie_lue))::integer),
        (2, 'joueurs_sans_participation', (
            SELECT count(*) FROM joueurs j
            WHERE NOT EXISTS (
                SELECT 1 FROM boggle.participation pa
                WHERE pa.id_partie = p_id_partie AND pa.id_utilisateur = j.id_utilisateur
            )
        )),
        (3, 'participations_hors_json', (
            SELECT count(*) FROM boggle.participation pa
            JOIN partie_lue p ON p.id_partie = pa.id_partie
            WHERE NOT EXISTS (SELECT 1 FROM joueurs j WHERE j.id_utilisateur = pa.id_utilisateur)
        )),
        (4, 'score_somme_points', (
            SELECT count(*) FROM joueurs j
            LEFT JOIN sommes s ON s.position_joueur = j.position_joueur
            WHERE j.score IS DISTINCT FROM coalesce(s.points_valides, 0)
        )),
        (5, 'proposition_incoherente', (
            SELECT count(*) FROM propositions pr
            WHERE NOT coalesce(
                (pr.valide AND pr.points >= 1 AND pr.motif_rejet IS NULL)
                OR (NOT pr.valide AND pr.points = 0 AND pr.motif_rejet IN
                    ('absent_grille', 'absent_dictionnaire', 'trop_court', 'doublon')),
                false
            )
        )),
        (6, 'doublon_non_signale', (SELECT coalesce(sum(d.repetitions), 0) FROM doublons d)),
        (7, 'classement_incoherent', (
            SELECT count(*) FROM partie_lue p
            WHERE CASE WHEN p.statut = 'terminee'
                       THEN jsonb_typeof(p.classement) IS DISTINCT FROM 'array'
                            OR EXISTS (SELECT 1 FROM ecarts_classement)
                       ELSE p.donnees ? 'resultat' END
        )),
        (8, 'cases_invalides', (
            SELECT count(*) FROM cases c WHERE NOT coalesce(c.lettre ~ '^[A-Z]{1,2}$', false)
        )),
        (9, 'chemins_incoherents', (
            SELECT count(*) FROM propositions pr
            LEFT JOIN chemins c ON c.position_joueur = pr.position_joueur
                               AND c.position_proposition = pr.position_proposition
            WHERE pr.chemin <> 'null'::jsonb
              AND NOT coalesce(c.valide AND c.mot_reconstitue = pr.mot, false)
        )),
        (10, 'chemin_absent_incoherent', (
            SELECT count(*) FROM propositions pr
            WHERE pr.valide IS FALSE AND pr.motif_rejet = 'absent_grille' AND pr.chemin <> 'null'::jsonb
        )),
        (11, 'abandon_incoherent', (
            SELECT count(*) FROM joueurs j CROSS JOIN partie_lue p
            WHERE j.valeur->'abandon_t_ms' <> 'null'::jsonb
              AND NOT CASE
                    WHEN p.duree_s BETWEEN 0 AND 2147483647 AND j.abandon_t_ms >= 0
                         AND j.abandon_t_ms = trunc(j.abandon_t_ms)
                    THEN j.abandon_t_ms <= p.duree_s * 1000
                         AND NOT EXISTS (
                             SELECT 1 FROM propositions pr
                             WHERE pr.position_joueur = j.position_joueur AND pr.t_ms > j.abandon_t_ms
                         )
                    ELSE false END
        ))
    ) AS v(ordre, code, nombre)
    ORDER BY v.ordre;
$fonction$;

COMMENT ON FUNCTION boggle.controler_partie(integer) IS
    'Vérifie onze invariants de cohérence entre la partie, son JSON et les participations.';

COMMIT;
