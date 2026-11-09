<?php
declare(strict_types=1);

namespace Boogle\Controller;

use Boogle\Core\Router;
use Boogle\Core\Session;
use Boogle\Core\View;

final class AccueilController
{
    public function afficher(): void
    {
        if (Session::estConnecte()) {
            Router::rediriger('parties');
        }

        self::rendre();
    }

    /**
     * Affiche la page d'accueil avec le formulaire de connexion.
     *
     * @param array<string, mixed> $donnees
     */
    public static function rendre(array $donnees = [], int $statut = 200): void
    {
        View::rendre('accueil', $donnees + [
            'titre'           => 'Accueil',
            'erreurConnexion' => null,
            'ancien'          => [],
        ], $statut);
    }
}
