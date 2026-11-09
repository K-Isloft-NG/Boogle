<?php
declare(strict_types=1);

namespace Boogle\Controller;

use Boogle\Core\Router;
use Boogle\Core\Session;
use Boogle\Core\View;

/** Liste des parties. Les données sont fictives : le moteur de jeu n'est pas encore branché. */
final class PartieController
{
    private const PARTIES_DEMO = [
        ['date' => '08/11/2026', 'adversaires' => 'Marie, Paul',   'score' => 42, 'mots' => 14, 'statut' => 'Terminée'],
        ['date' => '05/11/2026', 'adversaires' => 'Jean',          'score' => 37, 'mots' => 12, 'statut' => 'Terminée'],
        ['date' => '02/11/2026', 'adversaires' => 'Marie, Claude', 'score' => 18, 'mots' => 7,  'statut' => 'Abandonnée'],
        ['date' => '29/10/2026', 'adversaires' => 'Paul',          'score' => 55, 'mots' => 19, 'statut' => 'Terminée'],
    ];

    public function liste(): void
    {
        View::rendre('parties', [
            'titre'  => 'Mes parties',
            'parties' => self::PARTIES_DEMO,
        ]);
    }

    public function nouvelle(): void
    {
        Session::ajouterMessage('info', 'La création de partie sera disponible avec le moteur de jeu.');
        Router::rediriger('parties');
    }
}
