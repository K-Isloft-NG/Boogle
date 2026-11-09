<?php
declare(strict_types=1);

namespace Boogle\Core;

use RuntimeException;

/**
 * Accès centralisé à la configuration.
 *
 * En production, les valeurs viennent des variables d'environnement (Render).
 * En local, un fichier .env.local, ignoré par Git, est lu s'il existe.
 */
final class Config
{
    private static bool $chargee = false;

    public static function charger(string $racine): void
    {
        if (self::$chargee) {
            return;
        }
        self::$chargee = true;

        $fichier = $racine . '/.env.local';
        if (!is_readable($fichier)) {
            return;
        }

        foreach (file($fichier, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $ligne) {
            $ligne = trim($ligne);
            if ($ligne === '' || $ligne[0] === '#' || !str_contains($ligne, '=')) {
                continue;
            }
            [$cle, $valeur] = explode('=', $ligne, 2);
            $cle = trim($cle);
            // Une variable déjà définie (production) reste prioritaire sur le fichier local.
            if (getenv($cle) === false) {
                putenv($cle . '=' . trim($valeur));
            }
        }
    }

    /**
     * Retourne une valeur de configuration.
     * Sans valeur par défaut, une valeur absente fait échouer l'application plutôt
     * que de la laisser tourner avec une configuration incomplète.
     */
    public static function obtenir(string $cle, ?string $defaut = null): string
    {
        $valeur = getenv($cle);
        if ($valeur !== false && $valeur !== '') {
            return $valeur;
        }
        if ($defaut !== null) {
            return $defaut;
        }
        throw new RuntimeException('Configuration manquante : ' . $cle);
    }

    /** @param list<string> $cles */
    public static function exiger(array $cles): void
    {
        foreach ($cles as $cle) {
            self::obtenir($cle);
        }
    }
}
