-- Contrôles des requêtes JSON sur le jeu de données de test.
-- À lancer sans les données de volume (sql/05_donnees_volume.sql) : les requêtes portent sur toute la table.
-- Chaque contrôle doit afficher 0 écart.

\echo 'Contrôle 1 : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie, (p.donnees->'config'->>'lignes')::integer AS lignes,
       (p.donnees->'config'->>'colonnes')::integer AS colonnes,
       (p.donnees->'config'->>'duree_s')::integer AS duree_s,
       (p.donnees->'config'->>'lignes')::integer * (p.donnees->'config'->>'colonnes')::integer AS cases
FROM boggle.partie p
), attendu AS (
VALUES (9001,4,4,180,16),(9002,4,4,120,16),(9003,4,4,180,16),(9004,4,4,180,16),(9005,4,4,180,16),(9006,3,5,120,15)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 2 : écarts attendus 0'
WITH obtenu AS (
SELECT (case_grille.position - 1)::integer AS position, case_grille.lettre
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements_text(p.donnees->'grille') WITH ORDINALITY AS case_grille(lettre, position)
WHERE p.id_partie = 9001
), attendu AS (
VALUES (0,'G'),(1,'A'),(2,'I'),(3,'R'),(4,'R'),(5,'U'),(6,'V'),(7,'E'),(8,'QU'),(9,'E'),(10,'O'),(11,'T'),(12,'A'),(13,'S'),(14,'M'),(15,'J')
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 3 : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'grille' ? 'QU'
), attendu AS (
VALUES (9001),(9002),(9003),(9004),(9005)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 4a : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'grille' ?| ARRAY['QU', 'Z']
), attendu AS (
VALUES (9001),(9002),(9003),(9004),(9005)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 4b : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'grille' ?& ARRAY['QU', 'J']
), attendu AS (
VALUES (9001),(9002),(9003),(9004),(9005)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 5 : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'joueurs' @> '[{"id_utilisateur":9001}]'::jsonb
), attendu AS (
VALUES (9001),(9003)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 6 : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie FROM boggle.partie p
JOIN boggle.participation pa ON pa.id_partie = p.id_partie
WHERE pa.id_utilisateur = 9001
), attendu AS (
VALUES (9001),(9003)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 7 : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie, u.pseudo::text, (joueur->>'score')::integer AS score
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
JOIN public.php_utilisateurs u ON u.id = (joueur->>'id_utilisateur')::integer
WHERE u.id = 9001
), attendu AS (
VALUES (9001,'test_karl',3),(9003,'test_karl',1)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 8 : écarts attendus 0'
WITH obtenu AS (
SELECT proposition->>'mot' AS mot, proposition->'chemin' AS chemin, (proposition->>'points')::integer AS points
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
CROSS JOIN LATERAL jsonb_array_elements(joueur->'propositions') AS proposition
WHERE p.id_partie = 9001 AND (joueur->>'id_utilisateur')::integer = 9001
  AND (proposition->>'valide')::boolean IS TRUE
), attendu AS (
VALUES ('OUI','[10,5,2]'::jsonb,1),('VIRE','[6,2,3,7]'::jsonb,1),('RIVE','[3,2,6,7]'::jsonb,1)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 9 : écarts attendus 0'
WITH obtenu AS (
SELECT proposition->>'motif_rejet' AS motif_rejet, count(*) AS nombre
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
CROSS JOIN LATERAL jsonb_array_elements(joueur->'propositions') AS proposition
WHERE (proposition->>'valide')::boolean IS FALSE
GROUP BY proposition->>'motif_rejet'
), attendu AS (
VALUES ('absent_grille',4::bigint),('absent_dictionnaire',2::bigint),('doublon',1::bigint),('trop_court',1::bigint)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 10a : écarts attendus 0'
WITH obtenu AS (
SELECT count(*) FROM (
SELECT p.id_partie, joueur->>'id_utilisateur' AS id_joueur, proposition#>>'{mot}' AS mot,
       proposition#>'{chemin}' AS chemin, jsonb_array_length(proposition#>'{chemin}') AS longueur
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
CROSS JOIN LATERAL jsonb_array_elements(joueur->'propositions') AS proposition
WHERE jsonb_typeof(proposition#>'{chemin}') = 'array'
) AS chemins
), attendu AS (
VALUES (21::bigint)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 10b : écarts attendus 0'
WITH obtenu AS (
SELECT count(*) AS sans_chemin
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
CROSS JOIN LATERAL jsonb_array_elements(joueur->'propositions') AS proposition
WHERE jsonb_typeof(proposition->'chemin') = 'null'
), attendu AS (
VALUES (4::bigint)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 11 : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie, u.pseudo::text, (classement->>'rang')::integer AS rang, (classement->>'score')::integer AS score
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees#>'{resultat,classement}') AS classement
JOIN public.php_utilisateurs u ON u.id = (classement->>'id_utilisateur')::integer
WHERE p.statut = 'terminee' AND p.id_partie IN (9001, 9002)
), attendu AS (
VALUES (9001,'test_karl',1,3),(9001,'test_mamie',2,2),(9002,'test_lea',1,2),(9002,'test_hugo',1,2)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 12 : modification temporaire, écarts attendus 0'
BEGIN;
UPDATE boggle.partie
SET donnees = (jsonb_set(donnees, '{config,duree_s}', '240'::jsonb) || '{"test_temporaire":true}'::jsonb) - 'solutions'
WHERE id_partie = 9001;
SELECT CASE WHEN count(*) = 1 AND bool_and(donnees#>>'{config,duree_s}' = '240' AND donnees->>'test_temporaire' = 'true' AND NOT donnees ? 'solutions') THEN 0 ELSE 1 END AS ecarts
FROM boggle.partie WHERE id_partie = 9001;
ROLLBACK;
\echo 'Contrôle 12 après ROLLBACK : écarts attendus 0'
SELECT CASE WHEN count(*) = 1 AND bool_and(donnees#>>'{config,duree_s}' = '180' AND NOT donnees ? 'test_temporaire' AND donnees ? 'solutions') THEN 0 ELSE 1 END AS ecarts
FROM boggle.partie WHERE id_partie = 9001;

\echo 'Contrôle 13 : écarts attendus 0'
WITH obtenu AS (
SELECT proposition->>'mot' AS mot, count(*) AS nombre
FROM boggle.partie p
CROSS JOIN LATERAL jsonb_array_elements(p.donnees->'joueurs') AS joueur
CROSS JOIN LATERAL jsonb_array_elements(joueur->'propositions') AS proposition
WHERE (proposition->>'valide')::boolean IS TRUE
GROUP BY proposition->>'mot'
), attendu AS (
VALUES ('OUI',5::bigint),('VIE',2::bigint),('VIRE',1::bigint),('RIVE',1::bigint),('QUE',1::bigint),('RUE',1::bigint),('AIR',1::bigint),('UNITE',1::bigint),('CODE',1::bigint),('DEN',1::bigint),('CAT',1::bigint),('BUN',1::bigint)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 14 : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees @? '$.joueurs[*].propositions[*] ? (@.motif_rejet == "doublon")'
), attendu AS (
VALUES (9001)
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 5 et 6 : mêmes parties : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'joueurs' @> '[{"id_utilisateur":9001}]'::jsonb
), attendu AS (
SELECT p.id_partie FROM boggle.partie p
JOIN boggle.participation pa ON pa.id_partie = p.id_partie
WHERE pa.id_utilisateur = 9001
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

\echo 'Contrôle 3 et 4a : mêmes parties : écarts attendus 0'
WITH obtenu AS (
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'grille' ? 'QU'
), attendu AS (
SELECT p.id_partie FROM boggle.partie p
WHERE p.donnees->'grille' ?| ARRAY['QU', 'Z']
), differences AS (
 (SELECT * FROM obtenu EXCEPT ALL SELECT * FROM attendu)
 UNION ALL
 (SELECT * FROM attendu EXCEPT ALL SELECT * FROM obtenu)
)
SELECT count(*) AS ecarts FROM differences;

