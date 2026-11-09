<?php
declare(strict_types=1);

namespace Boogle\Service;

use Boogle\Core\Config;
use Boogle\Model\Utilisateur;
use Boogle\Repository\TentativeConnexionRepository;
use Boogle\Repository\UtilisateurRepository;
use DateTimeImmutable;
use DateTimeZone;

/** Règles métier de l'inscription et de la connexion. */
final class AuthService
{
    private const ECHECS_MAX_PAR_EMAIL = 5;
    private const ECHECS_MAX_PAR_IP = 20;
    private const FENETRE = '-15 minutes';
    private const CONSERVATION = '-1 hour';

    /**
     * Empreinte bcrypt d'une valeur aléatoire inconnue. Quand le compte n'existe pas, on vérifie
     * quand même le mot de passe contre cette empreinte : le temps de réponse reste comparable.
     */
    private const HASH_FACTICE = '$2y$10$3KiKJ.j7wJehFCcAa.XrP.wmgJ.w1NXTm3E93n/gH1Pttcr3tAROS';

    public function __construct(
        private readonly UtilisateurRepository $utilisateurs,
        private readonly TentativeConnexionRepository $tentatives,
    ) {
    }

    /**
     * Crée un compte si les données sont valides.
     *
     * @return array<string, string> erreurs par champ ; tableau vide si le compte a été créé
     */
    public function inscrire(string $pseudo, string $email, string $motDePasse, string $confirmation): array
    {
        $pseudo = trim($pseudo);
        $email = self::normaliserEmail($email);
        $erreurs = [];

        if (mb_strlen($pseudo) < 3 || mb_strlen($pseudo) > 30 || preg_match('/^[\p{L}\p{N}_-]+$/u', $pseudo) !== 1) {
            $erreurs['pseudo'] = 'Le pseudo doit contenir de 3 à 30 caractères : lettres, chiffres, tiret ou tiret bas.';
        }

        if (strlen($email) > 254 || filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            $erreurs['email'] = 'Saisissez une adresse e-mail valide.';
        }

        if (mb_strlen($motDePasse) < 12) {
            $erreurs['mot_de_passe'] = 'Le mot de passe doit contenir au moins 12 caractères.';
        } elseif (strlen($motDePasse) > 72) {
            // bcrypt ignore tout ce qui dépasse 72 octets : on refuse plutôt que de tronquer en silence.
            $erreurs['mot_de_passe'] = 'Le mot de passe ne doit pas dépasser 72 caractères.';
        }

        if ($motDePasse !== $confirmation) {
            $erreurs['confirmation'] = 'Les deux mots de passe ne correspondent pas.';
        }

        if ($erreurs !== []) {
            return $erreurs;
        }

        if ($this->utilisateurs->pseudoExiste($pseudo)) {
            return ['pseudo' => 'Ce pseudo est déjà utilisé.'];
        }

        $creation = $this->utilisateurs->creer($pseudo, $email, password_hash($motDePasse, PASSWORD_DEFAULT));
        if ($creation === null) {
            // Message volontairement neutre : il ne confirme pas qu'une adresse e-mail est déjà inscrite.
            return ['email' => 'Impossible de créer un compte avec ces informations.'];
        }

        return [];
    }

    /**
     * Vérifie les identifiants. Retourne l'utilisateur, ou null si l'e-mail ou le mot de passe est faux.
     *
     * @throws ConnexionVerrouilleeException si trop d'échecs récents pour cet e-mail ou cette adresse IP
     */
    public function connecter(string $email, string $motDePasse, string $adresseIp): ?Utilisateur
    {
        $email = self::normaliserEmail($email);
        $emailHmac = self::pseudonymiser($email);
        $ipHmac = self::pseudonymiser($adresseIp);
        $maintenant = new DateTimeImmutable('now', new DateTimeZone('UTC'));

        $this->tentatives->purger($maintenant->modify(self::CONSERVATION));

        $depuis = $maintenant->modify(self::FENETRE);
        if (
            $this->tentatives->echecsParEmail($emailHmac, $depuis) >= self::ECHECS_MAX_PAR_EMAIL
            || $this->tentatives->echecsParIp($ipHmac, $depuis) >= self::ECHECS_MAX_PAR_IP
        ) {
            throw new ConnexionVerrouilleeException();
        }

        $utilisateur = $this->utilisateurs->trouverParEmail($email);
        $hash = $utilisateur?->motDePasseHash ?? self::HASH_FACTICE;
        $valide = password_verify($motDePasse, $hash) && $utilisateur !== null;

        $this->tentatives->enregistrer($emailHmac, $ipHmac, $valide, $maintenant);

        return $valide ? $utilisateur : null;
    }

    private static function normaliserEmail(string $email): string
    {
        return mb_strtolower(trim($email));
    }

    private static function pseudonymiser(string $valeur): string
    {
        return hash_hmac('sha256', $valeur, Config::obtenir('SEL_APPLICATIF'));
    }
}
