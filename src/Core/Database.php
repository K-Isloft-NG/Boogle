<?php
declare(strict_types=1);

namespace Boogle\Core;

use PDO;

/** Connexion unique à PostgreSQL, partagée pendant toute la requête. */
final class Database
{
    private static ?PDO $pdo = null;

    public static function connexion(): PDO
    {
        if (self::$pdo === null) {
            $dsn = sprintf(
                'pgsql:host=%s;port=%s;dbname=%s;sslmode=%s',
                Config::obtenir('DB_HOST'),
                Config::obtenir('DB_PORT', '5432'),
                Config::obtenir('DB_NAME'),
                Config::obtenir('DB_SSLMODE', 'require')
            );

            self::$pdo = new PDO($dsn, Config::obtenir('DB_USER'), Config::obtenir('DB_PASS'), [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                // Vraies requêtes préparées côté serveur : la valeur ne devient jamais du SQL.
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]);
        }

        return self::$pdo;
    }
}
