<?php
declare(strict_types=1);

namespace Boogle\Core;

/** Démarrage durci de la session et état de connexion de l'utilisateur. */
final class Session
{
    public static function demarrer(): void
    {
        if (session_status() === PHP_SESSION_ACTIVE) {
            return;
        }

        // Derrière le proxy de Render, PHP reçoit du HTTP : le protocole d'origine est dans X-Forwarded-Proto.
        $https = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off')
            || ($_SERVER['HTTP_X_FORWARDED_PROTO'] ?? '') === 'https';

        ini_set('session.use_strict_mode', '1');
        ini_set('session.use_only_cookies', '1');

        session_name('boogle_session');
        session_set_cookie_params([
            'lifetime' => 0,
            'path'     => '/',
            'secure'   => $https,
            'httponly' => true,
            'samesite' => 'Lax',
        ]);
        session_start();
    }

    /** Ouvre la session d'un utilisateur authentifié. */
    public static function connecter(int $identifiant, string $pseudo): void
    {
        // Nouvel identifiant de session après authentification : évite la fixation de session.
        session_regenerate_id(true);
        $_SESSION['utilisateur_id'] = $identifiant;
        $_SESSION['pseudo'] = $pseudo;
        Csrf::renouveler();
    }

    public static function estConnecte(): bool
    {
        return isset($_SESSION['utilisateur_id']);
    }

    public static function utilisateurId(): ?int
    {
        return isset($_SESSION['utilisateur_id']) ? (int) $_SESSION['utilisateur_id'] : null;
    }

    public static function pseudo(): ?string
    {
        return isset($_SESSION['pseudo']) ? (string) $_SESSION['pseudo'] : null;
    }

    public static function deconnecter(): void
    {
        $_SESSION = [];
        if (ini_get('session.use_cookies')) {
            $parametres = session_get_cookie_params();
            setcookie(session_name(), '', [
                'expires'  => time() - 3600,
                'path'     => $parametres['path'],
                'secure'   => $parametres['secure'],
                'httponly' => $parametres['httponly'],
                'samesite' => $parametres['samesite'],
            ]);
        }
        session_destroy();
    }

    /** Message affiché une seule fois à la page suivante (succès, erreur, information). */
    public static function ajouterMessage(string $type, string $texte): void
    {
        $_SESSION['messages'][] = ['type' => $type, 'texte' => $texte];
    }

    /** @return list<array{type: string, texte: string}> */
    public static function recupererMessages(): array
    {
        $messages = $_SESSION['messages'] ?? [];
        unset($_SESSION['messages']);

        return $messages;
    }
}
