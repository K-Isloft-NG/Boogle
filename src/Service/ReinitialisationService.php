<?php
declare(strict_types=1);

namespace Boogle\Service;

use Boogle\Core\Config;
use Boogle\Repository\ReinitialisationRepository;
use Boogle\Repository\UtilisateurRepository;
use DateTimeImmutable;
use DateTimeZone;
use PDO;

/** Récupération de compte : envoi d'un lien à usage unique, puis choix d'un nouveau mot de passe. */
final class ReinitialisationService
{
    private const DUREE_VALIDITE = '+30 minutes';

    public function __construct(
        private readonly PDO $pdo,
        private readonly UtilisateurRepository $utilisateurs,
        private readonly ReinitialisationRepository $jetons,
        private readonly Mailer $mailer,
    ) {
    }

    /**
     * Envoie un lien de réinitialisation si un compte existe pour cette adresse.
     * Ne renvoie rien : l'appelant affiche le même message dans tous les cas.
     */
    public function demander(string $email): void
    {
        $email = mb_strtolower(trim($email));
        if (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            return;
        }

        $maintenant = self::maintenant();
        $this->jetons->purgerExpires($maintenant);

        $utilisateur = $this->utilisateurs->trouverParEmail($email);
        if ($utilisateur === null) {
            return;
        }

        $jeton = bin2hex(random_bytes(32));
        $this->jetons->supprimerPourUtilisateur($utilisateur->id);
        $this->jetons->creer($utilisateur->id, hash('sha256', $jeton), $maintenant->modify(self::DUREE_VALIDITE));

        $lien = rtrim(Config::obtenir('APP_URL'), '/') . '/?page=reinitialisation&jeton=' . $jeton;

        $texte = "Bonjour {$utilisateur->pseudo},\n\n"
            . "Vous avez demandé à changer votre mot de passe Boogle. Ouvrez ce lien pour en choisir un nouveau :\n\n"
            . "{$lien}\n\n"
            . "Ce lien est valable 30 minutes et ne fonctionne qu'une seule fois.\n"
            . "Si vous n'êtes pas à l'origine de cette demande, ignorez ce message : votre mot de passe reste inchangé.\n";

        $html = '<p>Bonjour ' . e($utilisateur->pseudo) . ',</p>'
            . '<p>Vous avez demandé à changer votre mot de passe Boogle.</p>'
            . '<p><a href="' . e($lien) . '">Choisir un nouveau mot de passe</a></p>'
            . '<p>Ce lien est valable 30 minutes et ne fonctionne qu’une seule fois.</p>'
            . '<p>Si vous n’êtes pas à l’origine de cette demande, ignorez ce message : votre mot de passe reste inchangé.</p>';

        if (!$this->mailer->envoyer($utilisateur->email, 'Boogle : choisir un nouveau mot de passe', $texte, $html)) {
            error_log('Réinitialisation : l’e-mail n’a pas pu être envoyé pour l’utilisateur n°' . $utilisateur->id);
        }
    }

    /** Indique si le jeton reçu dans le lien est encore utilisable. */
    public function jetonValide(string $jeton): bool
    {
        return self::formatValide($jeton)
            && $this->jetons->trouverValide(hash('sha256', $jeton), self::maintenant()) !== null;
    }

    /**
     * Remplace le mot de passe si le jeton est valide.
     *
     * @return array<string, string> erreurs par champ ; tableau vide en cas de succès
     */
    public function reinitialiser(string $jeton, string $motDePasse, string $confirmation): array
    {
        $erreurs = AuthService::validerMotDePasse($motDePasse, $confirmation);
        if ($erreurs !== []) {
            return $erreurs;
        }

        if (!self::formatValide($jeton)) {
            return ['jeton' => 'Ce lien n’est plus valide.'];
        }

        $this->pdo->beginTransaction();
        try {
            $trouve = $this->jetons->trouverValide(hash('sha256', $jeton), self::maintenant());
            if ($trouve === null || !$this->jetons->marquerUtilise($trouve['id'])) {
                $this->pdo->rollBack();
                return ['jeton' => 'Ce lien n’est plus valide.'];
            }

            $this->utilisateurs->changerMotDePasse($trouve['utilisateur_id'], password_hash($motDePasse, PASSWORD_DEFAULT));
            $this->jetons->supprimerPourUtilisateur($trouve['utilisateur_id']);
            $this->pdo->commit();
        } catch (\Throwable $erreur) {
            $this->pdo->rollBack();
            throw $erreur;
        }

        return [];
    }

    private static function formatValide(string $jeton): bool
    {
        return preg_match('/^[a-f0-9]{64}$/', $jeton) === 1;
    }

    private static function maintenant(): DateTimeImmutable
    {
        return new DateTimeImmutable('now', new DateTimeZone('UTC'));
    }
}
