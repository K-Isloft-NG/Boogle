<?php
declare(strict_types=1);

require __DIR__ . '/../src/bootstrap.php';

use Boogle\Controller\AccueilController;
use Boogle\Controller\AuthController;
use Boogle\Controller\PartieController;
use Boogle\Core\Router;

// Liste blanche des pages : toute valeur de ?page= absente de ce tableau renvoie une erreur 404.
$routeur = new Router([
    'accueil' => [
        'controleur' => AccueilController::class,
        'action'     => 'afficher',
        'methodes'   => ['GET'],
        'prive'      => false,
    ],
    'inscription' => [
        'controleur' => AuthController::class,
        'action'     => 'inscription',
        'methodes'   => ['POST'],
        'prive'      => false,
    ],
    'connexion' => [
        'controleur' => AuthController::class,
        'action'     => 'connexion',
        'methodes'   => ['POST'],
        'prive'      => false,
    ],
    'deconnexion' => [
        'controleur' => AuthController::class,
        'action'     => 'deconnexion',
        'methodes'   => ['POST'],
        'prive'      => true,
    ],
    'parties' => [
        'controleur' => PartieController::class,
        'action'     => 'liste',
        'methodes'   => ['GET'],
        'prive'      => true,
    ],
    'nouvelle-partie' => [
        'controleur' => PartieController::class,
        'action'     => 'nouvelle',
        'methodes'   => ['POST'],
        'prive'      => true,
    ],
]);

$routeur->repartir();
