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
     * Affiche la page d'accueil avec les formulaires de connexion et d'inscription.
     * Les autres contrôleurs l'utilisent pour réafficher la page avec des erreurs.
     *
     * @param array<string, mixed> $donnees
     */
    public static function rendre(array $donnees = [], int $statut = 200): void
    {
        View::rendre('accueil', $donnees + [
            'titre'             => 'Accueil',
            'erreursInscription' => [],
            'erreurConnexion'   => null,
            'ancien'            => [],
        ], $statut);
    }
}
