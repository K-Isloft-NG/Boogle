<?php
declare(strict_types=1);

namespace Boogle\Controller;

use Boogle\Core\Router;
use Boogle\Core\Session;
use Boogle\Core\View;

/**
 * Liste des parties. Les données sont fictives : le moteur de jeu n'est pas encore branché.
 * Le paramètre etat=vide affiche la démonstration de l'état sans partie.
 */
final class PartieController
{
    private const PARTIES_DEMO = [
        ['date' => '09/11/2026', 'adversaires' => 'Marie',         'score' => 12, 'mots' => 5,  'statut' => 'En cours'],
        ['date' => '08/11/2026', 'adversaires' => 'Marie, Paul',   'score' => 42, 'mots' => 14, 'statut' => 'Terminée'],
        ['date' => '05/11/2026', 'adversaires' => 'Jean',          'score' => 37, 'mots' => 12, 'statut' => 'Terminée'],
        ['date' => '02/11/2026', 'adversaires' => 'Marie, Camille', 'score' => 18, 'mots' => 7,  'statut' => 'Abandonnée'],
        ['date' => '29/10/2026', 'adversaires' => 'Paul',          'score' => 55, 'mots' => 19, 'statut' => 'Terminée'],
    ];

    public function liste(): void
    {
        $etatVide = ($_GET['etat'] ?? '') === 'vide';

        View::rendre('parties', [
            'titre'    => 'Vos parties',
            'parties'  => $etatVide ? [] : self::PARTIES_DEMO,
            'etatVide' => $etatVide,
        ]);
    }

    public function nouvelle(): void
    {
        Session::ajouterMessage('info', 'La création de partie sera disponible avec le moteur de jeu.');
        Router::rediriger('parties');
    }
}
