<?php
use Boogle\Core\Session;

// Exemple : A, N, E forment le mot ANE ; les cases se touchent en diagonale.
$lettres = GRILLE_DEMO;
$actives = [5, 8, 13];
$description = 'Grille de 16 lettres où les cases A, N et E sont mises en évidence : elles forment le mot ANE';
?>
<article class="regles-detail">
    <h1>Comment jouer</h1>
    <p class="chapeau">Boogle se joue sur une grille de 16 lettres. Votre but : trouver le plus de mots possible avant la fin du temps.</p>

    <h2>La grille</h2>
    <p>Chaque partie commence par une grille de 4 lettres sur 4, tirée au hasard. Certaines cases affichent deux lettres liées, comme QU : elles comptent ensemble, comme une seule case.</p>

    <h2>Former un mot</h2>
    <p>Un mot se forme en reliant des lettres voisines. Deux cases sont voisines quand elles se touchent : sur la même ligne, sur la même colonne ou en diagonale. Une même case ne peut pas servir deux fois dans un mot.</p>

    <figure class="grille-demo">
        <?php require RACINE . '/templates/partials/grille.php'; ?>
        <figcaption class="legende">Exemple : A, N puis E forment le mot ANE. Le A et le N se touchent en diagonale, tout comme le N et le E.</figcaption>
    </figure>

    <h2>Les mots acceptés</h2>
    <ul>
        <li>Un mot compte au moins 3 lettres.</li>
        <li>Il doit figurer dans le dictionnaire du jeu.</li>
        <li>Les accents ne sont pas à saisir : le mot ÂNE s’écrit ANE.</li>
    </ul>

    <h2>Le temps et les points</h2>
    <p>Une partie dure trois minutes. Chaque mot valide rapporte des points, et les mots longs en rapportent davantage.</p>

    <h2>Gagner</h2>
    <p>Quand le temps est écoulé, les scores sont comparés. Le joueur qui a le plus de points remporte la partie.</p>

    <p class="actions">
        <?php if (Session::estConnecte()): ?>
            <a class="bouton bouton--plein" href="/?page=parties">Voir mes parties</a>
        <?php else: ?>
            <a class="bouton bouton--plein" href="/?page=inscription">Créer un compte pour jouer</a>
        <?php endif; ?>
    </p>
</article>
