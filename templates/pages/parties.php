<?php
/**
 * @var list<array{date: string, adversaires: string, score: int, mots: int, statut: string}> $parties
 */

use Boogle\Core\Csrf;

$classesStatut = ['Terminée' => 'terminee', 'En cours' => 'en-cours', 'Abandonnée' => 'abandonnee'];
?>
<section class="tableau-de-bord">
    <div class="entete-page">
        <div>
            <h1>Vos parties</h1>
            <p class="carte-soustitre"><?= count($parties) ?> parties · données de démonstration</p>
        </div>
        <form method="post" action="/?page=nouvelle-partie">
            <?= Csrf::champ() ?>
            <button class="bouton bouton--plein" type="submit">Nouvelle partie</button>
        </form>
    </div>

    <?php if ($parties === []): ?>
        <div class="carte etat-vide">
            <h2>Votre grille vous attend</h2>
            <p>Lancez votre première partie : 16 lettres, trois minutes, autant de mots que possible. Elle apparaîtra ici.</p>
        </div>
    <?php else: ?>
        <div class="carte carte--tableau">
            <table class="tableau">
                <caption class="sr-seulement">Liste de vos parties</caption>
                <thead>
                    <tr>
                        <th scope="col">Date</th>
                        <th scope="col">Adversaires</th>
                        <th scope="col" class="nombre">Score</th>
                        <th scope="col" class="nombre">Mots trouvés</th>
                        <th scope="col">Statut</th>
                    </tr>
                </thead>
                <tbody>
                    <?php foreach ($parties as $partie): ?>
                        <tr>
                            <td class="mono"><?= e($partie['date']) ?></td>
                            <td><?= e($partie['adversaires']) ?></td>
                            <td class="nombre mono"><?= e($partie['score']) ?></td>
                            <td class="nombre mono"><?= e($partie['mots']) ?></td>
                            <td><span class="statut statut--<?= e($classesStatut[$partie['statut']] ?? 'terminee') ?>"><?= e($partie['statut']) ?></span></td>
                        </tr>
                    <?php endforeach; ?>
                </tbody>
            </table>
        </div>
    <?php endif; ?>
</section>
