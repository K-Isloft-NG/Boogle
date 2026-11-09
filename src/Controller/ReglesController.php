<?php
declare(strict_types=1);

namespace Boogle\Controller;

use Boogle\Core\View;

/** Page d'explication des règles du jeu. */
final class ReglesController
{
    public function afficher(): void
    {
        View::rendre('comment_jouer', ['titre' => 'Comment jouer']);
    }
}
