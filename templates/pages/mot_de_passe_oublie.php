<?php
/** @var bool $envoye */

use Boogle\Core\Csrf;
?>
<section class="carte carte--auth carte--centree" aria-labelledby="titre-oubli">
    <h1 id="titre-oubli">Mot de passe oublié</h1>

    <?php if ($envoye): ?>
        <p class="message message--succes" role="status">Si un compte existe pour cette adresse, un e-mail vient d’être envoyé. Pensez à regarder dans les courriers indésirables.</p>
    <?php else: ?>
        <p class="carte-soustitre">Indiquez votre adresse e-mail. Nous vous enverrons un lien pour choisir un nouveau mot de passe.</p>

        <form method="post" action="/?page=mot-de-passe-oublie">
            <?= Csrf::champ() ?>

            <div class="champ">
                <label for="oubli-email">Adresse e-mail</label>
                <input type="email" id="oubli-email" name="email" maxlength="254" autocomplete="email" required>
            </div>

            <button class="bouton bouton--plein" type="submit">Envoyer le lien</button>
        </form>
    <?php endif; ?>

    <p class="carte-pied"><a class="lien" href="/">Retour à la connexion</a></p>
</section>
