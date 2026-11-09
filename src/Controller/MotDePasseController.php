<?php
declare(strict_types=1);

namespace Boogle\Controller;

use Boogle\Core\Database;
use Boogle\Core\Router;
use Boogle\Core\Session;
use Boogle\Core\View;
use Boogle\Repository\ReinitialisationRepository;
use Boogle\Repository\UtilisateurRepository;
use Boogle\Service\Mailer;
use Boogle\Service\ReinitialisationService;

/** Récupération de compte : demande du lien, puis choix d'un nouveau mot de passe. */
final class MotDePasseController
{
    public function formulaireOubli(): void
    {
        View::rendre('mot_de_passe_oublie', ['titre' => 'Mot de passe oublié', 'envoye' => false]);
    }

    public function demande(): void
    {
        $this->service()->demander($this->champ('email'));

        // Même réponse que l'adresse soit connue ou non.
        View::rendre('mot_de_passe_oublie', ['titre' => 'Mot de passe oublié', 'envoye' => true]);
    }

    public function formulaireReinitialisation(): void
    {
        $jeton = $_GET['jeton'] ?? '';
        $jeton = is_string($jeton) ? $jeton : '';

        View::rendre('reinitialisation', [
            'titre'   => 'Nouveau mot de passe',
            'jeton'   => $jeton,
            'valide'  => $this->service()->jetonValide($jeton),
            'erreurs' => [],
        ]);
    }

    public function reinitialisation(): void
    {
        $jeton = $this->champ('jeton');
        $erreurs = $this->service()->reinitialiser($jeton, $this->champ('mot_de_passe'), $this->champ('confirmation'));

        if ($erreurs !== []) {
            View::rendre('reinitialisation', [
                'titre'   => 'Nouveau mot de passe',
                'jeton'   => $jeton,
                'valide'  => !isset($erreurs['jeton']),
                'erreurs' => $erreurs,
            ], 422);
            return;
        }

        Session::ajouterMessage('succes', 'Votre mot de passe a été modifié. Vous pouvez vous connecter.');
        Router::rediriger('accueil');
    }

    private function service(): ReinitialisationService
    {
        $pdo = Database::connexion();

        return new ReinitialisationService(
            $pdo,
            new UtilisateurRepository($pdo),
            new ReinitialisationRepository($pdo),
            new Mailer()
        );
    }

    private function champ(string $nom): string
    {
        $valeur = $_POST[$nom] ?? '';

        return is_string($valeur) ? $valeur : '';
    }
}
