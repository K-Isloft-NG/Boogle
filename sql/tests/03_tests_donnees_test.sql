-- Contrôles du jeu de données sur une base locale de développement.
SET search_path TO boggle;

\echo 'Comptages du jeu (chaque nombre doit correspondre à attendu)'
SELECT 'utilisateurs' AS objet, count(*) AS nombre, 5 AS attendu FROM public.php_utilisateurs WHERE id BETWEEN 9001 AND 9005 AND email LIKE '%@exemple.fr'
UNION ALL SELECT 'dictionnaires', count(*), 2 FROM dictionnaire WHERE id_dictionnaire BETWEEN 9001 AND 9002
UNION ALL SELECT 'parties', count(*), 6 FROM partie WHERE id_partie BETWEEN 9001 AND 9006
UNION ALL SELECT 'participations', count(*), 11 FROM participation WHERE id_partie BETWEEN 9001 AND 9006;

\echo 'Répartition des statuts (chaque nombre doit correspondre à attendu)'
SELECT attendu.statut, count(p.id_partie) AS nombre, attendu.nombre AS attendu
FROM (VALUES ('terminee', 3), ('en_cours', 1), ('en_attente', 1), ('annulee', 1)) AS attendu(statut, nombre)
LEFT JOIN partie p ON p.statut = attendu.statut AND p.id_partie BETWEEN 9001 AND 9006
GROUP BY attendu.statut, attendu.nombre ORDER BY attendu.statut;

\echo 'Joueurs JSON absents de participation (écarts attendus : 0)'
SELECT count(*) AS ecarts FROM partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') j
WHERE p.id_partie BETWEEN 9001 AND 9006 AND NOT EXISTS (
 SELECT 1 FROM participation pa WHERE pa.id_partie = p.id_partie AND pa.id_utilisateur = (j->>'id_utilisateur')::integer);

\echo 'Participations absentes du JSON (écarts attendus : 0)'
SELECT count(*) AS ecarts FROM participation pa JOIN partie p ON p.id_partie = pa.id_partie
WHERE p.id_partie BETWEEN 9001 AND 9006 AND NOT EXISTS (
 SELECT 1 FROM jsonb_array_elements(p.donnees->'joueurs') j WHERE (j->>'id_utilisateur')::integer = pa.id_utilisateur);

\echo 'Scores et somme des points valides (écarts attendus : 0)'
SELECT count(*) AS ecarts FROM partie p CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') j
WHERE p.id_partie BETWEEN 9001 AND 9006 AND (j->>'score')::integer IS DISTINCT FROM (
 SELECT COALESCE(sum((pr->>'points')::integer), 0) FROM jsonb_array_elements(j->'propositions') pr WHERE (pr->>'valide')::boolean IS TRUE);

\echo 'Validité, points et motifs de rejet (écarts attendus : 0)'
SELECT count(*) AS ecarts FROM partie p CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') j
CROSS JOIN LATERAL jsonb_array_elements(j->'propositions') pr
WHERE p.id_partie BETWEEN 9001 AND 9006 AND NOT COALESCE(
 ((pr->>'valide')::boolean IS TRUE AND (pr->>'points')::integer >= 1 AND pr->>'motif_rejet' IS NULL)
 OR ((pr->>'valide')::boolean IS FALSE AND (pr->>'points')::integer = 0 AND pr->>'motif_rejet' IN ('absent_grille','absent_dictionnaire','trop_court','doublon')), FALSE);

\echo 'Classements : joueurs, scores et rangs des parties terminées (écarts attendus : 0)'
WITH joueurs AS (
 SELECT p.id_partie, (j->>'id_utilisateur')::integer AS id_joueur, (j->>'score')::integer AS score,
 rank() OVER (PARTITION BY p.id_partie ORDER BY (j->>'score')::integer DESC) AS rang
 FROM partie p CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') j
 WHERE p.id_partie BETWEEN 9001 AND 9006 AND p.statut = 'terminee'
), classement AS (
 SELECT p.id_partie, (c->>'id_utilisateur')::integer AS id_joueur, (c->>'score')::integer AS score, (c->>'rang')::integer AS rang
 FROM partie p CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'resultat'->'classement') c
 WHERE p.id_partie BETWEEN 9001 AND 9006 AND p.statut = 'terminee'
)
SELECT count(*) AS ecarts FROM joueurs j FULL JOIN classement c ON j.id_partie = c.id_partie AND j.id_joueur = c.id_joueur
WHERE j.id_joueur IS NULL OR c.id_joueur IS NULL OR j.score IS DISTINCT FROM c.score OR j.rang IS DISTINCT FROM c.rang;

\echo 'Motifs de rejet présents (chaque nombre doit être au moins 1)'
SELECT motifs.motif, count(pr.valeur) AS nombre, '>= 1' AS attendu
FROM (VALUES ('absent_grille'), ('absent_dictionnaire'), ('trop_court'), ('doublon')) motifs(motif)
LEFT JOIN (
 SELECT proposition AS valeur FROM partie p CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') j
 CROSS JOIN LATERAL jsonb_array_elements(j->'propositions') proposition WHERE p.id_partie BETWEEN 9001 AND 9006
) pr ON pr.valeur->>'motif_rejet' = motifs.motif GROUP BY motifs.motif ORDER BY motifs.motif;

\echo 'Grilles avec QU et grilles rectangulaires (chaque nombre doit être au moins 1)'
SELECT count(*) FILTER (WHERE donnees->'grille' @> '["QU"]'::jsonb) AS avec_qu,
 count(*) FILTER (WHERE (donnees#>>'{config,lignes}')::integer <> (donnees#>>'{config,colonnes}')::integer) AS rectangulaires,
 '>= 1 chacune' AS attendu FROM partie WHERE id_partie BETWEEN 9001 AND 9006;

\echo 'Parties en attente avec proposition (écarts attendus : 0)'
SELECT count(*) AS ecarts FROM partie p CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') j
WHERE p.id_partie BETWEEN 9001 AND 9006 AND p.statut = 'en_attente' AND jsonb_array_length(j->'propositions') > 0;

\echo 'Parties en cours avec résultat (écarts attendus : 0)'
SELECT count(*) AS ecarts FROM partie WHERE id_partie BETWEEN 9001 AND 9006 AND statut = 'en_cours' AND donnees ? 'resultat';
