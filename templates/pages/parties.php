<?php
/**
 * @var list<array{date: string, adversaires: string, score: int, mots: int, statut: string}> $parties
 * @var bool $etatVide  vrai pour la démonstration de l'état sans partie
 */

use Boogle\Core\Csrf;

$classesStatut = ['Terminée' => 'terminee', 'En cours' => 'en-cours', 'Abandonnée' => 'abandonnee'];
?>
<section class="tableau-de-bord">
    <div class="entete-page">
        <div>
            <h1>Vos parties</h1>
            <?php if ($parties === []): ?>
                <p class="carte-soustitre">Aucune partie pour l’instant.</p>
            <?php else: ?>
                <p class="carte-soustitre"><?= count($parties) ?> parties · données de démonstration ·
                    <a class="lien" href="/?page=parties&amp;etat=vide">Voir l’état vide</a></p>
            <?php endif; ?>
        </div>
        <?php if ($parties !== []): ?>
            <form method="post" action="/?page=nouvelle-partie">
                <?= Csrf::champ() ?>
                <button class="bouton bouton--plein" type="submit">Nouvelle partie</button>
            </form>
        <?php endif; ?>
    </div>

    <?php if ($parties === []): ?>
        <div class="carte etat-vide">
            <div class="grille grille--vide" aria-hidden="true">
                <?php for ($i = 0; $i < 16; $i++): ?><span class="de"></span><?php endfor; ?>
            </div>
            <h2>Votre grille vous attend</h2>
            <p>Lancez votre première partie : 16 lettres, trois minutes, autant de mots que possible. Elle apparaîtra ici.</p>
            <form method="post" action="/?page=nouvelle-partie">
                <?= Csrf::champ() ?>
                <button class="bouton bouton--plein" type="submit">Nouvelle partie</button>
            </form>
            <?php if ($etatVide): ?>
                <p class="etat-vide-note">Démonstration : le lancement de partie sera disponible avec le moteur de jeu.
                    <a class="lien" href="/?page=parties">Retour à la liste d’exemple</a></p>
            <?php endif; ?>
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
