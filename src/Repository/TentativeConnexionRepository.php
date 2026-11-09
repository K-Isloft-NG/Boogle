<?php
declare(strict_types=1);

namespace Boogle\Repository;

use DateTimeImmutable;
use PDO;

/**
 * Traces des tentatives de connexion, utilisées pour limiter le brute force.
 * L'e-mail et l'adresse IP ne sont jamais stockés en clair : seulement leur empreinte HMAC.
 * Les dates sont écrites et comparées en UTC par PHP, pour ne dépendre d'aucun fuseau du serveur SQL.
 */
final class TentativeConnexionRepository
{
    private const FORMAT_DATE = 'Y-m-d H:i:s';

    public function __construct(private readonly PDO $pdo)
    {
    }

    public function enregistrer(string $emailHmac, string $ipHmac, bool $succes, DateTimeImmutable $date): void
    {
        $requete = $this->pdo->prepare(
            'INSERT INTO php_tentatives_connexion (email_hmac, ip_hmac, succes, date_tentative)
             VALUES (:email, :ip, :succes, :date)'
        );
        $requete->bindValue(':email', $emailHmac);
        $requete->bindValue(':ip', $ipHmac);
        $requete->bindValue(':succes', $succes, PDO::PARAM_BOOL);
        $requete->bindValue(':date', $date->format(self::FORMAT_DATE));
        $requete->execute();
    }

    public function echecsParEmail(string $emailHmac, DateTimeImmutable $depuis): int
    {
        $requete = $this->pdo->prepare(
            'SELECT COUNT(*) FROM php_tentatives_connexion
             WHERE email_hmac = :empreinte AND succes = FALSE AND date_tentative >= :depuis'
        );
        $requete->execute([':empreinte' => $emailHmac, ':depuis' => $depuis->format(self::FORMAT_DATE)]);

        return (int) $requete->fetchColumn();
    }

    public function echecsParIp(string $ipHmac, DateTimeImmutable $depuis): int
    {
        $requete = $this->pdo->prepare(
            'SELECT COUNT(*) FROM php_tentatives_connexion
             WHERE ip_hmac = :empreinte AND succes = FALSE AND date_tentative >= :depuis'
        );
        $requete->execute([':empreinte' => $ipHmac, ':depuis' => $depuis->format(self::FORMAT_DATE)]);

        return (int) $requete->fetchColumn();
    }

    /** Supprime les tentatives plus anciennes que la date donnée. */
    public function purger(DateTimeImmutable $avant): void
    {
        $requete = $this->pdo->prepare('DELETE FROM php_tentatives_connexion WHERE date_tentative < :avant');
        $requete->execute([':avant' => $avant->format(self::FORMAT_DATE)]);
    }
}
