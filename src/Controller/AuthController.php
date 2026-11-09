<?php
declare(strict_types=1);

namespace Boogle\Controller;

use Boogle\Core\Database;
use Boogle\Core\Router;
use Boogle\Core\Session;
use Boogle\Core\View;
use Boogle\Repository\TentativeConnexionRepository;
use Boogle\Repository\UtilisateurRepository;
use Boogle\Service\AuthService;
use Boogle\Service\ConnexionVerrouilleeException;

/** Actions de création de compte, de connexion et de déconnexion. */
final class AuthController
{
    private ?AuthService $auth = null;

    public function formulaireInscription(): void
    {
        if (Session::estConnecte()) {
            Router::rediriger('parties');
        }

        self::rendreInscription();
    }

    public function inscription(): void
    {
        $pseudo = $this->champ('pseudo');
        $email = $this->champ('email');

        $erreurs = $this->auth()->inscrire(
            $pseudo,
            $email,
            $this->champ('mot_de_passe'),
            $this->champ('confirmation')
        );

        if ($erreurs !== []) {
            self::rendreInscription($erreurs, ['pseudo' => $pseudo, 'email' => $email], 422);
            return;
        }

        Session::ajouterMessage('succes', 'Votre compte est créé. Vous pouvez maintenant vous connecter.');
        Router::rediriger('accueil');
    }

    public function connexion(): void
    {
        $email = $this->champ('email');

        try {
            $utilisateur = $this->auth()->connecter($email, $this->champ('mot_de_passe'), $this->adresseIp());
        } catch (ConnexionVerrouilleeException) {
            AccueilController::rendre([
                'erreurConnexion' => 'Trop de tentatives échouées. Réessayez dans quelques minutes.',
                'ancien'          => ['connexion_email' => $email],
            ], 429);
            return;
        }

        if ($utilisateur === null) {
            // Même message que le compte existe ou non.
            AccueilController::rendre([
                'erreurConnexion' => 'Adresse e-mail ou mot de passe incorrect.',
                'ancien'          => ['connexion_email' => $email],
            ], 422);
            return;
        }

        Session::connecter($utilisateur->id, $utilisateur->pseudo);
        Session::ajouterMessage('succes', 'Connexion réussie.');
        Router::rediriger('parties');
    }

    public function deconnexion(): void
    {
        Session::deconnecter();
        // La session précédente est détruite : on en ouvre une neuve pour porter le message.
        Session::demarrer();
        Session::ajouterMessage('info', 'Vous êtes déconnecté.');
        Router::rediriger('accueil');
    }

    /**
     * @param array<string, string> $erreurs
     * @param array<string, string> $ancien
     */
    private static function rendreInscription(array $erreurs = [], array $ancien = [], int $statut = 200): void
    {
        View::rendre('inscription', [
            'titre'   => 'Créer un compte',
            'erreurs' => $erreurs,
            'ancien'  => $ancien,
        ], $statut);
    }

    private function auth(): AuthService
    {
        if ($this->auth === null) {
            $pdo = Database::connexion();
            $this->auth = new AuthService(new UtilisateurRepository($pdo), new TentativeConnexionRepository($pdo));
        }

        return $this->auth;
    }

    /** Lit un champ de formulaire texte ; toute valeur qui n'est pas une chaîne devient une chaîne vide. */
    private function champ(string $nom): string
    {
        $valeur = $_POST[$nom] ?? '';

        return is_string($valeur) ? $valeur : '';
    }

    /**
     * Adresse IP du visiteur. Derrière le proxy de Render, on prend la dernière adresse de
     * X-Forwarded-For : c'est celle ajoutée par le proxy, le visiteur ne peut pas la falsifier.
     */
    private function adresseIp(): string
    {
        $transmise = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? '';
        if (is_string($transmise) && $transmise !== '') {
            $adresses = array_map('trim', explode(',', $transmise));
            $derniere = end($adresses);
            if ($derniere !== false && filter_var($derniere, FILTER_VALIDATE_IP) !== false) {
                return $derniere;
            }
        }

        return (string) ($_SERVER['REMOTE_ADDR'] ?? '0.0.0.0');
    }
}
