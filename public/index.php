<?php
declare(strict_types=1);

// PAGE TEMPORAIRE : sert uniquement à valider le déploiement Render et la connexion Neon.
// Elle sera remplacée par le contrôleur frontal (allowlist de pages).

header('Content-Type: text/plain; charset=UTF-8');

echo "Boogle : serveur PHP en ligne.\n";

try {
    $dsn = sprintf(
        'pgsql:host=%s;port=%s;dbname=%s;sslmode=%s',
        getenv('DB_HOST') ?: '',
        getenv('DB_PORT') ?: '5432',
        getenv('DB_NAME') ?: '',
        getenv('DB_SSLMODE') ?: 'require'
    );
    new PDO($dsn, getenv('DB_USER') ?: '', getenv('DB_PASS') ?: '', [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]);
    echo "Base de données : OK\n";
} catch (Throwable $erreur) {
    error_log('Test BDD : ' . $erreur->getMessage());
    echo "Base de données : indisponible\n";
}
