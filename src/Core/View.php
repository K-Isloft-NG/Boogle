<?php
declare(strict_types=1);

namespace Boogle\Core;

use InvalidArgumentException;

/** Rend un gabarit de page à l'intérieur de la mise en page commune. */
final class View
{
    /** @param array<string, mixed> $donnees */
    public static function rendre(string $gabarit, array $donnees = [], int $statut = 200): void
    {
        if (preg_match('/^[a-z_]+$/', $gabarit) !== 1) {
            throw new InvalidArgumentException('Nom de gabarit invalide.');
        }

        $dossier = RACINE . '/templates';
        $contenu = self::capturer($dossier . '/pages/' . $gabarit . '.php', $donnees);

        http_response_code($statut);
        echo self::capturer($dossier . '/layout.php', [
            'titre'    => $donnees['titre'] ?? 'Boogle',
            'contenu'  => $contenu,
            'messages' => Session::recupererMessages(),
        ]);
    }

    /** @param array<string, mixed> $donnees */
    private static function capturer(string $fichier, array $donnees): string
    {
        extract($donnees, EXTR_SKIP);
        ob_start();
        require $fichier;

        return (string) ob_get_clean();
    }
}
