<?php
declare(strict_types=1);

use Boogle\Core\Config;
use Boogle\Core\Session;

define('RACINE', dirname(__DIR__));

require __DIR__ . '/helpers.php';

// Chargement automatique des classes : Boogle\Core\Config => src/Core/Config.php
spl_autoload_register(static function (string $classe): void {
    $prefixe = 'Boogle\\';
    if (strncmp($classe, $prefixe, strlen($prefixe)) !== 0) {
        return;
    }
    $chemin = __DIR__ . '/' . str_replace('\\', '/', substr($classe, strlen($prefixe))) . '.php';
    if (is_file($chemin)) {
        require $chemin;
    }
});

// Une erreur non gérée est journalisée côté serveur, jamais détaillée à l'utilisateur.
set_exception_handler(static function (Throwable $erreur): void {
    error_log(sprintf('%s : %s (%s:%d)', get_class($erreur), $erreur->getMessage(), $erreur->getFile(), $erreur->getLine()));
    http_response_code(500);
    echo 'Une erreur est survenue. Veuillez réessayer plus tard.';
});

ini_set('display_errors', '0');

header("Content-Security-Policy: default-src 'self'; img-src 'self' data:; form-action 'self'; frame-ancestors 'none'; base-uri 'self'");
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('Referrer-Policy: strict-origin-when-cross-origin');

Config::charger(RACINE);
Config::exiger(['DB_HOST', 'DB_NAME', 'DB_USER', 'DB_PASS', 'SEL_APPLICATIF']);

Session::demarrer();
