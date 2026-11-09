<?php
/**
 * Mise en page commune.
 *
 * @var string $titre
 * @var string $contenu   HTML déjà produit par un gabarit de page (ses données sont échappées avec e())
 * @var list<array{type: string, texte: string}> $messages
 */

use Boogle\Core\Csrf;
use Boogle\Core\Session;
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($titre) ?> | Boogle</title>
    <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body>
    <a class="lien-evitement" href="#contenu">Aller au contenu</a>

    <header class="entete">
        <a class="marque" href="/">Boogle</a>
        <?php if (Session::estConnecte()): ?>
            <div class="session">
                <span class="session-pseudo"><?= e(Session::pseudo()) ?></span>
                <form method="post" action="/?page=deconnexion">
                    <?= Csrf::champ() ?>
                    <button class="bouton bouton--discret" type="submit">Se déconnecter</button>
                </form>
            </div>
        <?php endif; ?>
    </header>

    <main class="contenu" id="contenu">
        <?php foreach ($messages as $message): ?>
            <p class="message message--<?= e($message['type']) ?>" role="<?= $message['type'] === 'erreur' ? 'alert' : 'status' ?>"><?= e($message['texte']) ?></p>
        <?php endforeach; ?>

        <?= $contenu ?>
    </main>

    <footer class="pied">
        <p>Boogle, projet de SAÉ, BUT Informatique.</p>
    </footer>
</body>
</html>
