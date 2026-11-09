<?php
/**
 * @var string|null $erreurConnexion
 * @var array<string, string> $ancien
 */

use Boogle\Core\Csrf;

// Grille de démonstration : les cases actives forment le mot BOOGLE.
$lettres = GRILLE_DEMO;
$actives = [0, 1, 2, 3, 6, 7];
$description = 'Exemple de grille de 16 lettres où le mot BOOGLE est formé avec des lettres voisines';
?>
<div class="accueil">
    <section class="accueil-presentation">
        <p class="surtitre">Boggle en ligne</p>
        <h1 class="titre-principal">Trouvez des mots dans la grille. Battez vos adversaires.</h1>
        <p class="chapeau">Formez des mots avec les lettres voisines d’une grille de 16 dés. Trois minutes par partie, seul ou avec vos proches.</p>

        <div class="accueil-jeu">
            <figure class="grille-demo">
                <?php require RACINE . '/templates/partials/grille.php'; ?>
                <figcaption class="legende">B·O·O·G·L·E : 6 lettres voisines</figcaption>
            </figure>

            <div class="accueil-regles">
                <ol class="regles">
                    <li><span class="regles-numero">01</span> Une grille de 16 lettres tirée au hasard.</li>
                    <li><span class="regles-numero">02</span> Reliez des lettres qui se touchent, même en diagonale.</li>
                    <li><span class="regles-numero">03</span> Chaque mot de 3 lettres ou plus rapporte des points.</li>
                </ol>
                <p><a class="lien" href="/?page=comment-jouer">Lire les règles en détail</a></p>
            </div>
        </div>
    </section>

    <section class="carte carte--auth" aria-labelledby="titre-connexion">
        <h2 id="titre-connexion">Se connecter</h2>
        <p class="carte-soustitre">Retrouvez vos parties et vos scores.</p>

        <?php if ($erreurConnexion !== null): ?>
            <p class="message message--erreur" role="alert"><?= e($erreurConnexion) ?></p>
        <?php endif; ?>

        <form method="post" action="/?page=connexion">
            <?= Csrf::champ() ?>

            <div class="champ">
                <label for="connexion-email">Adresse e-mail</label>
                <input type="email" id="connexion-email" name="email" maxlength="254" autocomplete="username" required
                       value="<?= e($ancien['connexion_email'] ?? '') ?>">
            </div>

            <div class="champ">
                <div class="champ-ligne">
                    <label for="connexion-mdp">Mot de passe</label>
                    <a class="lien" href="/?page=mot-de-passe-oublie">Mot de passe oublié ?</a>
                </div>
                <input type="password" id="connexion-mdp" name="mot_de_passe" maxlength="200" autocomplete="current-password" required
                       <?= $erreurConnexion !== null ? 'autofocus' : '' ?>>
            </div>

            <button class="bouton bouton--plein" type="submit">Se connecter</button>
        </form>

        <p class="carte-pied">Pas encore de compte ? <a class="lien" href="/?page=inscription">Créer un compte</a></p>
    </section>
</div>
