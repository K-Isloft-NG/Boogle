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

/** Grille d'exemple utilisée pour illustrer le jeu : 16 lettres, lues ligne par ligne. */
const GRILLE_DEMO = ['B', 'O', 'O', 'G', 'S', 'A', 'E', 'L', 'N', 'I', 'M', 'U', 'T', 'E', 'R', 'D'];
