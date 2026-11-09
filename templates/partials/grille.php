<?php
/**
 * Grille de 16 lettres (4 x 4).
 *
 * @var list<string> $lettres
 * @var list<int> $actives     positions (de 0 à 15) des cases mises en évidence
 * @var string $description    texte lu par les lecteurs d'écran
 */
?>
<div class="grille" role="img" aria-label="<?= e($description) ?>">
    <?php foreach ($lettres as $position => $lettre): ?>
        <span class="de<?= in_array($position, $actives, true) ? ' de--actif' : '' ?>"><?= e($lettre) ?></span>
    <?php endforeach; ?>
</div>
