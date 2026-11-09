<?php
/**
 * @var array<string, string> $erreurs
 * @var array<string, string> $ancien
 */

use Boogle\Core\Csrf;

/** Attributs ARIA d'un champ selon qu'il a une erreur ou non. */
$aria = static function (string $champ, string $idErreur, string $aide = '') use ($erreurs): string {
    $decrit = trim($aide . (isset($erreurs[$champ]) ? ' ' . $idErreur : ''));
    $attributs = $decrit !== '' ? ' aria-describedby="' . $decrit . '"' : '';

    return $attributs . (isset($erreurs[$champ]) ? ' aria-invalid="true"' : '');
};
?>
<section class="carte carte--auth carte--centree" aria-labelledby="titre-inscription">
    <h1 id="titre-inscription">Créer un compte</h1>

    <?php if ($erreurs !== []): ?>
        <p class="message message--erreur" role="alert">Le compte n’a pas pu être créé. Corrigez les points signalés ci-dessous.</p>
    <?php endif; ?>

    <form method="post" action="/?page=inscription">
        <?= Csrf::champ() ?>

        <div class="champ">
            <label for="inscription-pseudo">Pseudo</label>
            <p class="aide" id="aide-pseudo">Visible par les autres joueurs.</p>
            <input type="text" id="inscription-pseudo" name="pseudo" minlength="3" maxlength="30" autocomplete="nickname" required
                   value="<?= e($ancien['pseudo'] ?? '') ?>"<?= $aria('pseudo', 'erreur-pseudo', 'aide-pseudo') ?>>
            <?php if (isset($erreurs['pseudo'])): ?>
                <p class="champ-erreur" id="erreur-pseudo"><?= e($erreurs['pseudo']) ?></p>
            <?php endif; ?>
        </div>

        <div class="champ">
            <label for="inscription-email">Adresse e-mail</label>
            <input type="email" id="inscription-email" name="email" maxlength="254" autocomplete="email" required
                   value="<?= e($ancien['email'] ?? '') ?>"<?= $aria('email', 'erreur-email') ?>>
            <?php if (isset($erreurs['email'])): ?>
                <p class="champ-erreur" id="erreur-email"><?= e($erreurs['email']) ?></p>
            <?php endif; ?>
        </div>

        <div class="champ">
            <label for="inscription-mdp">Mot de passe</label>
            <p class="aide" id="aide-mdp">12 caractères minimum. Une phrase facile à retenir convient très bien.</p>
            <input type="password" id="inscription-mdp" name="mot_de_passe" minlength="12" maxlength="72" autocomplete="new-password" required
                   <?= $aria('mot_de_passe', 'erreur-mdp', 'aide-mdp') ?>>
            <?php if (isset($erreurs['mot_de_passe'])): ?>
                <p class="champ-erreur" id="erreur-mdp"><?= e($erreurs['mot_de_passe']) ?></p>
            <?php endif; ?>
        </div>

        <div class="champ">
            <label for="inscription-confirmation">Confirmer le mot de passe</label>
            <input type="password" id="inscription-confirmation" name="confirmation" minlength="12" maxlength="72" autocomplete="new-password" required
                   <?= $aria('confirmation', 'erreur-confirmation') ?>>
            <?php if (isset($erreurs['confirmation'])): ?>
                <p class="champ-erreur" id="erreur-confirmation"><?= e($erreurs['confirmation']) ?></p>
            <?php endif; ?>
        </div>

        <button class="bouton bouton--plein" type="submit">Créer mon compte</button>
    </form>

    <p class="carte-pied">Déjà inscrit ? <a class="lien" href="/">Se connecter</a></p>
</section>
