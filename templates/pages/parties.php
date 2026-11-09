<?php
/**
 * @var string $titre
 * @var list<array{date: string, adversaires: string, score: int, mots: int, statut: string}> $parties
 */

use Boogle\Core\Csrf;
?>
<section>
    <div class="entete-page">
        <h1>Mes parties</h1>
        <form method="post" action="/?page=nouvelle-partie">
            <?= Csrf::champ() ?>
            <button class="bouton" type="submit">Nouvelle partie</button>
        </form>
    </div>

    <p class="aide">Ces parties sont des données de démonstration. Elles seront remplacées par vos vraies parties.</p>

    <table class="tableau">
        <caption class="sr-seulement">Liste de vos parties</caption>
        <thead>
            <tr>
                <th scope="col">Date</th>
                <th scope="col">Adversaires</th>
                <th scope="col">Score</th>
                <th scope="col">Mots trouvés</th>
                <th scope="col">Statut</th>
            </tr>
        </thead>
        <tbody>
            <?php foreach ($parties as $partie): ?>
                <tr>
                    <td><?= e($partie['date']) ?></td>
                    <td><?= e($partie['adversaires']) ?></td>
                    <td><?= e($partie['score']) ?></td>
                    <td><?= e($partie['mots']) ?></td>
                    <td><?= e($partie['statut']) ?></td>
                </tr>
            <?php endforeach; ?>
        </tbody>
    </table>
</section>
