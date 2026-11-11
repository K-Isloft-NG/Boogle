# Note de sécurité : module PHP-Web de Boogle

Périmètre : site PHP (comptes, connexion, récupération de mot de passe, pages privées). Le moteur C, les dictionnaires Java et le chat ne sont pas encore branchés.

## Points intégrés

| Risque | Protection en place |
| --- | --- |
| Injection SQL | Requêtes PDO préparées, sans émulation (`ATTR_EMULATE_PREPARES` désactivé) |
| XSS | Échappement systématique des sorties avec `e()`, politique CSP `default-src 'self'`, polices hébergées localement |
| CSRF | Jeton aléatoire lié à la session, vérifié de façon centralisée sur chaque requête POST |
| Session | Mode strict, cookies uniquement, `HttpOnly`, `SameSite=Lax`, `Secure` en HTTPS, identifiant régénéré à la connexion |
| Mots de passe | `password_hash` (bcrypt) et `password_verify`, longueur de 12 à 72 caractères |
| Énumération de comptes | Message d'erreur unique à la connexion, vérification factice si le compte n'existe pas, message identique au reset |
| Brute force | 5 échecs par adresse e-mail et 20 par IP sur 15 minutes (réponse 429) |
| Données personnelles | E-mail et IP des tentatives conservés uniquement sous forme d'empreinte HMAC-SHA256, purgés après 1 heure |
| Récupération de compte | Jeton aléatoire de 32 octets, seul son hachage SHA-256 est stocké, validité 30 minutes, usage unique, un seul jeton actif par compte |
| Accès aux pages | Routage par liste blanche (page, méthode HTTP, accès privé ou public), aucune inclusion de fichier dérivée de l'entrée |
| Secrets | Variables d'environnement uniquement, l'application refuse de démarrer s'il en manque, `.env.local` ignoré par Git |
| Erreurs | Affichage désactivé, journalisation côté serveur sans mot de passe ni clé |
| En-têtes | `X-Frame-Options`, `X-Content-Type-Options: nosniff`, `Referrer-Policy` |

## Points contrôlés avant livraison

- Aucun `var_dump`, `phpinfo` ni page de démonstration dans le dépôt (`git grep`), dépôt propre (`git status`).
- Parcours testé sur le site en ligne : création de compte (cas valides et invalides), connexion réussie et refusée, déconnexion, accès direct à une page privée, réinitialisation (lien valide, lien déjà utilisé, adresse inconnue), page 404 sans trace technique.

## Limites connues, à traiter pour la SAÉ

- Rôle PostgreSQL dédié aux droits minimaux (le rôle actuel est propriétaire de la base).
- Nom de domaine propre avec SPF, DKIM et DMARC pour les e-mails.
- Limitation de débit étendue à l'inscription et au reset, IP client fiabilisée derrière le proxy.
- Expiration des sessions sur inactivité, HSTS, double authentification.
- Appel des exécutables C sans shell, avec liste blanche, délai maximal et limites de ressources.
- RGPD : durée de conservation des comptes, suppression de compte, mentions légales.
