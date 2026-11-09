<?php
declare(strict_types=1);

namespace Boogle\Core;

/** Jeton aléatoire lié à la session, exigé sur toute requête POST. */
final class Csrf
{
    public static function jeton(): string
    {
        if (empty($_SESSION['csrf_token'])) {
            $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        }

        return $_SESSION['csrf_token'];
    }

    public static function renouveler(): void
    {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }

    /** Champ caché à placer dans chaque formulaire POST. */
    public static function champ(): string
    {
        return '<input type="hidden" name="csrf_token" value="' . e(self::jeton()) . '">';
    }

    public static function verifier(): void
    {
        $envoye = $_POST['csrf_token'] ?? '';
        $attendu = $_SESSION['csrf_token'] ?? '';

        if (!is_string($envoye) || !is_string($attendu) || $attendu === '' || !hash_equals($attendu, $envoye)) {
            http_response_code(403);
            exit('Requête refusée.');
        }
    }
}
