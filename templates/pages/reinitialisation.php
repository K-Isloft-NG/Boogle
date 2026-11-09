<?php
/**
 * @var string $jeton
 * @var bool $valide
 * @var array<string, string> $erreurs
 */

use Boogle\Core\Csrf;
?>
<section class="carte carte--auth carte--centree" aria-labelledby="titre-reinitialisation">
    <h1 id="titre-reinitialisation">Nouveau mot de passe</h1>

    <?php if (!$valide): ?>
        <p class="message message--erreur" role="alert">Ce lien n’est plus valide. Il a peut-être expiré ou déjà servi.</p>
        <p class="carte-pied"><a class="lien" href="/?page=mot-de-passe-oublie">Demander un nouveau lien</a></p>
    <?php else: ?>
        <?php if ($erreurs !== []): ?>
            <p class="message message--erreur" role="alert">Le mot de passe n’a pas pu être modifié. Corrigez les points signalés ci-dessous.</p>
        <?php endif; ?>

        <form method="post" action="/?page=reinitialisation">
            <?= Csrf::champ() ?>
            <input type="hidden" name="jeton" value="<?= e($jeton) ?>">

            <div class="champ">
                <label for="reinit-mdp">Nouveau mot de passe</label>
                <p class="aide" id="aide-reinit">12 caractères minimum.</p>
                <input type="password" id="reinit-mdp" name="mot_de_passe" minlength="12" maxlength="72" autocomplete="new-password" required
                       aria-describedby="aide-reinit<?= isset($erreurs['mot_de_passe']) ? ' erreur-reinit-mdp' : '' ?>"
                       <?= isset($erreurs['mot_de_passe']) ? 'aria-invalid="true"' : '' ?>>
                <?php if (isset($erreurs['mot_de_passe'])): ?>
                    <p class="champ-erreur" id="erreur-reinit-mdp"><?= e($erreurs['mot_de_passe']) ?></p>
                <?php endif; ?>
            </div>

            <div class="champ">
                <label for="reinit-confirmation">Confirmer le mot de passe</label>
                <input type="password" id="reinit-confirmation" name="confirmation" minlength="12" maxlength="72" autocomplete="new-password" required
                       <?= isset($erreurs['confirmation']) ? 'aria-invalid="true" aria-describedby="erreur-reinit-confirmation"' : '' ?>>
                <?php if (isset($erreurs['confirmation'])): ?>
                    <p class="champ-erreur" id="erreur-reinit-confirmation"><?= e($erreurs['confirmation']) ?></p>
                <?php endif; ?>
            </div>

            <button class="bouton bouton--plein" type="submit">Enregistrer</button>
        </form>
    <?php endif; ?>
</section>
