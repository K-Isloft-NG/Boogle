-- Requêtes JSONB sur les parties de Boggle.
-- Dépendances : sql/01_schema.sql, sql/02_schema_boggle.sql, sql/03_donnees_test.sql.
-- Exécution : psql -d <base> -f sql/04_requetes_json.sql

-- 1. Configuration des parties : ->, ->>. Attendu : 6 lignes, dont 9006 en 3 x 5.
\echo 'Requête 1'
SELECT p.id_partie, (p.donnees->'config'->>'lignes')::integer AS lignes,
       (p.donnees->'config'->>'colonnes')::integer AS colonnes,
       (p.donnees->'config'->>'duree_s')::integer AS duree_s,
       (p.donnees->'config'->>'lignes')::integer * (p.donnees->'config'->>'colonnes')::integer AS cases
FROM boggle.partie p
ORDER BY id_partie;

-- 2. Grille dépliée : jsonb_array_elements_text et WITH ORDINALITY. Attendu : 16 cases, QU à la position 8.
\echo 'Requête 2'
SELECT (case_grille.position - 1)::integer AS position, case_grille.lettre
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements_text(p.donnees->'grille') WITH ORDINALITY AS case_grille(lettre, position)
WHERE p.id_partie = 9001
ORDER BY position;

-- 3. Grilles contenant QU : ?. Attendu : parties 9001 à 9005.
-- Équivalent : jsonb_exists(p.donnees->'grille', 'QU'). En PHP, PDO peut
-- confondre ? avec un paramètre : utiliser la fonction ou écrire ??.
\echo 'Requête 3'
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'grille' ? 'QU'
ORDER BY id_partie;

-- 4a. Grilles contenant QU ou Z : ?|. Attendu : parties 9001 à 9005.
\echo 'Requête 4a'
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'grille' ?| ARRAY['QU', 'Z']
ORDER BY id_partie;

-- 4b. Grilles contenant QU et J : ?&. Attendu : parties 9001 à 9005.
\echo 'Requête 4b'
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'grille' ?& ARRAY['QU', 'J']
ORDER BY id_partie;

-- 5. Parties du joueur 9001 dans le JSON : @>. Attendu : 9001 et 9003.
\echo 'Requête 5'
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'joueurs' @> '[{"id_utilisateur":9001}]'::jsonb
ORDER BY id_partie;

-- 6. Parties du joueur 9001 par participation. Attendu : 9001 et 9003.
\echo 'Requête 6'
SELECT p.id_partie FROM boggle.partie p
JOIN boggle.participation pa ON pa.id_partie = p.id_partie
WHERE pa.id_utilisateur = 9001
ORDER BY id_partie;

-- 7. Scores du joueur 9001 : jsonb_array_elements et ->>. Attendu : 3 pour 9001, 1 pour 9003.
\echo 'Requête 7'
SELECT p.id_partie, u.pseudo::text, (joueur->>'score')::integer AS score
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
JOIN public.php_utilisateurs u ON u.id = (joueur->>'id_utilisateur')::integer
WHERE u.id = 9001
ORDER BY id_partie;

-- 8. Mots valides du joueur 9001 en partie 9001 : double dépliage et ->. Attendu : OUI, VIRE, RIVE.
\echo 'Requête 8'
SELECT proposition->>'mot' AS mot, proposition->'chemin' AS chemin, (proposition->>'points')::integer AS points
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
CROSS JOIN LATERAL jsonb_array_elements(joueur->'propositions') AS proposition
WHERE p.id_partie = 9001 AND (joueur->>'id_utilisateur')::integer = 9001
  AND (proposition->>'valide')::boolean IS TRUE
ORDER BY mot;

-- 9. Rejets par motif : jsonb_array_elements et ->>. Attendu : 4, 2, 1 et 1 selon le motif.
\echo 'Requête 9'
SELECT proposition->>'motif_rejet' AS motif_rejet, count(*) AS nombre
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
CROSS JOIN LATERAL jsonb_array_elements(joueur->'propositions') AS proposition
WHERE (proposition->>'valide')::boolean IS FALSE
GROUP BY proposition->>'motif_rejet'
ORDER BY motif_rejet;

-- 10a. Chemins présents : #>, #>>, jsonb_array_length et jsonb_typeof. Attendu : 21 propositions.
-- Un null JSON renvoyé par -> est distinct de NULL SQL. Vérifier le type
-- avant jsonb_array_length évite de calculer la longueur de null JSON.
\echo 'Requête 10a'
SELECT p.id_partie, joueur->>'id_utilisateur' AS id_joueur, proposition#>>'{mot}' AS mot,
       proposition#>'{chemin}' AS chemin, jsonb_array_length(proposition#>'{chemin}') AS longueur
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
CROSS JOIN LATERAL jsonb_array_elements(joueur->'propositions') AS proposition
WHERE jsonb_typeof(proposition#>'{chemin}') = 'array'
ORDER BY id_partie, id_joueur, mot;

-- 10b. Chemins null JSON : -> et jsonb_typeof. Attendu : 4 propositions.
\echo 'Requête 10b'
SELECT count(*) AS sans_chemin
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
CROSS JOIN LATERAL jsonb_array_elements(joueur->'propositions') AS proposition
WHERE jsonb_typeof(proposition->'chemin') = 'null';

-- 11. Classements des parties 9001 et 9002 : #> et jsonb_array_elements. Attendu : 4 joueurs, dont 2 ex aequo.
\echo 'Requête 11'
SELECT p.id_partie, u.pseudo::text, (classement->>'rang')::integer AS rang, (classement->>'score')::integer AS score
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees#>'{resultat,classement}') AS classement
JOIN public.php_utilisateurs u ON u.id = (classement->>'id_utilisateur')::integer
WHERE p.statut = 'terminee' AND p.id_partie IN (9001, 9002)
ORDER BY id_partie, rang, pseudo;

-- 12. Modification temporaire : jsonb_set, ||, -. Attendu : 240, clé ajoutée, solutions absente puis état initial.
\echo 'Requête 12 : modification puis annulation'
BEGIN;
UPDATE boggle.partie
SET donnees = (jsonb_set(donnees, '{config,duree_s}', '240'::jsonb) || '{"test_temporaire":true}'::jsonb) - 'solutions'
WHERE id_partie = 9001;
SELECT donnees#>>'{config,duree_s}' AS duree_s, donnees->>'test_temporaire' AS test_temporaire,
       donnees ? 'solutions' AS solutions_presentes
FROM boggle.partie WHERE id_partie = 9001;
ROLLBACK;
SELECT donnees#>>'{config,duree_s}' AS duree_s, donnees ? 'test_temporaire' AS test_temporaire_present,
       donnees ? 'solutions' AS solutions_presentes
FROM boggle.partie WHERE id_partie = 9001;

-- 13. Mots valides les plus trouvés : jsonb_array_elements et ->>. Attendu : OUI en tête avec 5.
\echo 'Requête 13'
SELECT proposition->>'mot' AS mot, count(*) AS nombre
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
CROSS JOIN LATERAL jsonb_array_elements(joueur->'propositions') AS proposition
WHERE (proposition->>'valide')::boolean IS TRUE
GROUP BY proposition->>'mot'
ORDER BY nombre DESC, mot;

-- 14. Parties avec doublon : @? (jsonpath). Attendu : 9001.
-- Contrairement à @>, jsonpath peut filtrer directement une propriété imbriquée.
\echo 'Requête 14'
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees @? '$.joueurs[*].propositions[*] ? (@.motif_rejet == "doublon")'
ORDER BY id_partie;

