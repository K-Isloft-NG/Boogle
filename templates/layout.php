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
    <link rel="preload" href="/assets/fonts/geist-sans-latin-400-normal.woff2" as="font" type="font/woff2" crossorigin>
    <link rel="stylesheet" href="/assets/css/style.css">
</head>
<body>
    <a class="lien-evitement" href="#contenu">Aller au contenu</a>

    <header class="entete">
        <div class="entete-interieur">
            <a class="marque" href="/">
                <span class="marque-logo" aria-hidden="true"><?php for ($i = 0; $i < 9; $i++): ?><span></span><?php endfor; ?></span>
                Boogle
            </a>
            <nav class="entete-nav" aria-label="Navigation principale">
                <a class="lien" href="/?page=comment-jouer">Comment jouer</a>
                <?php if (Session::estConnecte()): ?>
                    <div class="session">
                        <span class="session-texte">Connecté : <strong><?= e(Session::pseudo()) ?></strong></span>
                        <form method="post" action="/?page=deconnexion">
                            <?= Csrf::champ() ?>
                            <button class="bouton bouton--secondaire" type="submit">Se déconnecter</button>
                        </form>
                    </div>
                <?php endif; ?>
            </nav>
        </div>
    </header>

    <main class="contenu" id="contenu">
        <?php foreach ($messages as $message): ?>
            <p class="message message--<?= e($message['type']) ?>" role="<?= $message['type'] === 'erreur' ? 'alert' : 'status' ?>"><?= e($message['texte']) ?></p>
        <?php endforeach; ?>

        <?= $contenu ?>
    </main>

    <footer class="pied">
        <p>Boogle, projet de SAÉ, BUT Informatique, Université Gustave Eiffel.</p>
    </footer>
</body>
</html>
