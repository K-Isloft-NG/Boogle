<?php
declare(strict_types=1);

require __DIR__ . '/../src/bootstrap.php';

use Boogle\Controller\AccueilController;
use Boogle\Controller\AuthController;
use Boogle\Controller\MotDePasseController;
use Boogle\Controller\PartieController;
use Boogle\Controller\ReglesController;
use Boogle\Core\Router;

// Liste blanche des pages : toute valeur de ?page= absente de ce tableau renvoie une erreur 404.
$routeur = new Router([
    'accueil' => [
        'controleur' => AccueilController::class,
        'actions'    => ['GET' => 'afficher'],
        'prive'      => false,
    ],
    'comment-jouer' => [
        'controleur' => ReglesController::class,
        'actions'    => ['GET' => 'afficher'],
        'prive'      => false,
    ],
    'connexion' => [
        'controleur' => AuthController::class,
        'actions'    => ['POST' => 'connexion'],
        'prive'      => false,
    ],
    'inscription' => [
        'controleur' => AuthController::class,
        'actions'    => ['GET' => 'formulaireInscription', 'POST' => 'inscription'],
        'prive'      => false,
    ],
    'mot-de-passe-oublie' => [
        'controleur' => MotDePasseController::class,
        'actions'    => ['GET' => 'formulaireOubli', 'POST' => 'demande'],
        'prive'      => false,
    ],
    'reinitialisation' => [
        'controleur' => MotDePasseController::class,
        'actions'    => ['GET' => 'formulaireReinitialisation', 'POST' => 'reinitialisation'],
        'prive'      => false,
    ],
    'deconnexion' => [
        'controleur' => AuthController::class,
        'actions'    => ['POST' => 'deconnexion'],
        'prive'      => true,
    ],
    'parties' => [
        'controleur' => PartieController::class,
        'actions'    => ['GET' => 'liste'],
        'prive'      => true,
    ],
    'nouvelle-partie' => [
        'controleur' => PartieController::class,
        'actions'    => ['POST' => 'nouvelle'],
        'prive'      => true,
    ],
]);

$routeur->repartir();
