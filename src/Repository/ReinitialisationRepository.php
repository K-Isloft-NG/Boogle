<?php
declare(strict_types=1);

namespace Boogle\Repository;

use DateTimeImmutable;
use PDO;

/**
 * Jetons de réinitialisation du mot de passe.
 * Seule l'empreinte SHA-256 du jeton est stockée : une fuite de la base ne donne aucun lien utilisable.
 */
final class ReinitialisationRepository
{
    private const FORMAT_DATE = 'Y-m-d H:i:s';

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function creer(int $utilisateurId, string $jetonHash, DateTimeImmutable $expiration): void
    {
        $requete = $this->pdo->prepare(
            'INSERT INTO php_reinitialisations_mdp (utilisateur_id, jeton_hash, date_expiration)
             VALUES (:utilisateur, :jeton, :expiration)'
        );
        $requete->execute([
            ':utilisateur' => $utilisateurId,
            ':jeton'       => $jetonHash,
            ':expiration'  => $expiration->format(self::FORMAT_DATE),
        ]);
    }

    /** Supprime tous les jetons d'un utilisateur : un seul lien valide à la fois. */
    public function supprimerPourUtilisateur(int $utilisateurId): void
    {
        $requete = $this->pdo->prepare('DELETE FROM php_reinitialisations_mdp WHERE utilisateur_id = :utilisateur');
        $requete->execute([':utilisateur' => $utilisateurId]);
    }

    /** Retourne l'identifiant du jeton et de l'utilisateur si le jeton est valide, non utilisé et non expiré. */
    public function trouverValide(string $jetonHash, DateTimeImmutable $maintenant): ?array
    {
        $requete = $this->pdo->prepare(
            'SELECT id, utilisateur_id FROM php_reinitialisations_mdp
             WHERE jeton_hash = :jeton AND utilise = FALSE AND date_expiration > :maintenant'
        );
        $requete->execute([':jeton' => $jetonHash, ':maintenant' => $maintenant->format(self::FORMAT_DATE)]);
        $ligne = $requete->fetch();

        return $ligne === false ? null : ['id' => (int) $ligne['id'], 'utilisateur_id' => (int) $ligne['utilisateur_id']];
    }

    /**
     * Marque le jeton comme utilisé. Retourne false s'il l'était déjà :
     * deux envois simultanés du même lien ne peuvent pas réussir tous les deux.
     */
    public function marquerUtilise(int $id): bool
    {
        $requete = $this->pdo->prepare('UPDATE php_reinitialisations_mdp SET utilise = TRUE WHERE id = :id AND utilise = FALSE');
        $requete->execute([':id' => $id]);

        return $requete->rowCount() === 1;
    }

    public function purgerExpires(DateTimeImmutable $maintenant): void
    {
        $requete = $this->pdo->prepare('DELETE FROM php_reinitialisations_mdp WHERE date_expiration < :maintenant');
        $requete->execute([':maintenant' => $maintenant->format(self::FORMAT_DATE)]);
    }
}
