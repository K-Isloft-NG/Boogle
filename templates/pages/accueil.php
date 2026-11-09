<?php
/**
 * @var string $titre
 * @var array<string, string> $erreursInscription
 * @var string|null $erreurConnexion
 * @var array<string, string> $ancien
 */

use Boogle\Core\Csrf;
?>
<section class="presentation">
    <h1>Trouvez des mots dans la grille. Battez vos adversaires.</h1>
    <p>Boogle est une plateforme de Boggle en ligne. Chaque partie propose une grille de 4 par 4 lettres : les joueurs cherchent le plus de mots en reliant des cases voisines, et le meilleur score l’emporte.</p>
</section>

<div class="acces">
    <section class="carte" aria-labelledby="titre-connexion">
        <h2 id="titre-connexion">Connexion</h2>

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
                <label for="connexion-mdp">Mot de passe</label>
                <input type="password" id="connexion-mdp" name="mot_de_passe" maxlength="200" autocomplete="current-password" required>
            </div>

            <button class="bouton" type="submit">Se connecter</button>
        </form>
    </section>

    <section class="carte" aria-labelledby="titre-inscription">
        <h2 id="titre-inscription">Créer un compte</h2>

        <?php if ($erreursInscription !== []): ?>
            <p class="message message--erreur" role="alert">Le compte n’a pas pu être créé. Corrigez les points signalés ci-dessous.</p>
        <?php endif; ?>

        <form method="post" action="/?page=inscription">
            <?= Csrf::champ() ?>

            <div class="champ">
                <label for="inscription-pseudo">Pseudo</label>
                <input type="text" id="inscription-pseudo" name="pseudo" minlength="3" maxlength="30" autocomplete="nickname" required
                       value="<?= e($ancien['inscription_pseudo'] ?? '') ?>"
                       <?= isset($erreursInscription['pseudo']) ? 'aria-invalid="true" aria-describedby="erreur-pseudo"' : '' ?>>
                <?php if (isset($erreursInscription['pseudo'])): ?>
                    <p class="champ-erreur" id="erreur-pseudo"><?= e($erreursInscription['pseudo']) ?></p>
                <?php endif; ?>
            </div>

            <div class="champ">
                <label for="inscription-email">Adresse e-mail</label>
                <input type="email" id="inscription-email" name="email" maxlength="254" autocomplete="email" required
                       value="<?= e($ancien['inscription_email'] ?? '') ?>"
                       <?= isset($erreursInscription['email']) ? 'aria-invalid="true" aria-describedby="erreur-email"' : '' ?>>
                <?php if (isset($erreursInscription['email'])): ?>
                    <p class="champ-erreur" id="erreur-email"><?= e($erreursInscription['email']) ?></p>
                <?php endif; ?>
            </div>

            <div class="champ">
                <label for="inscription-mdp">Mot de passe</label>
                <p class="aide" id="aide-mdp">12 caractères minimum. Une phrase facile à retenir convient très bien.</p>
                <input type="password" id="inscription-mdp" name="mot_de_passe" minlength="12" maxlength="72" autocomplete="new-password" required
                       aria-describedby="aide-mdp<?= isset($erreursInscription['mot_de_passe']) ? ' erreur-mdp' : '' ?>"
                       <?= isset($erreursInscription['mot_de_passe']) ? 'aria-invalid="true"' : '' ?>>
                <?php if (isset($erreursInscription['mot_de_passe'])): ?>
                    <p class="champ-erreur" id="erreur-mdp"><?= e($erreursInscription['mot_de_passe']) ?></p>
                <?php endif; ?>
            </div>

            <div class="champ">
                <label for="inscription-confirmation">Confirmer le mot de passe</label>
                <input type="password" id="inscription-confirmation" name="confirmation" minlength="12" maxlength="72" autocomplete="new-password" required
                       <?= isset($erreursInscription['confirmation']) ? 'aria-invalid="true" aria-describedby="erreur-confirmation"' : '' ?>>
                <?php if (isset($erreursInscription['confirmation'])): ?>
                    <p class="champ-erreur" id="erreur-confirmation"><?= e($erreursInscription['confirmation']) ?></p>
                <?php endif; ?>
            </div>

            <button class="bouton" type="submit">Créer mon compte</button>
        </form>
    </section>
</div>
