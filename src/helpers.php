<?php
declare(strict_types=1);

/**
 * Échappe une valeur avant de l'écrire dans du HTML.
 * Toute donnée dynamique affichée dans une page passe par cette fonction.
 */
function e(mixed $valeur): string
{
    return htmlspecialchars((string) $valeur, ENT_QUOTES, 'UTF-8');
}
