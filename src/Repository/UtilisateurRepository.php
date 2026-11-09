<?php
declare(strict_types=1);

namespace Boogle\Repository;

use Boogle\Model\Utilisateur;
use PDO;
use PDOException;

/** Accès à la table php_utilisateurs. Toutes les requêtes sont préparées. */
final class UtilisateurRepository
{
    public function __construct(private readonly PDO $pdo)
    {
    }

    public function trouverParEmail(string $email): ?Utilisateur
    {
        $requete = $this->pdo->prepare(
            'SELECT id, pseudo, email, mot_de_passe_hash FROM php_utilisateurs WHERE email = :email'
        );
        $requete->execute([':email' => $email]);
        $ligne = $requete->fetch();

        if ($ligne === false) {
            return null;
        }

        return new Utilisateur(
            (int) $ligne['id'],
            (string) $ligne['pseudo'],
            (string) $ligne['email'],
            (string) $ligne['mot_de_passe_hash']
        );
    }

    public function pseudoExiste(string $pseudo): bool
    {
        $requete = $this->pdo->prepare('SELECT 1 FROM php_utilisateurs WHERE LOWER(pseudo) = LOWER(:pseudo)');
        $requete->execute([':pseudo' => $pseudo]);

        return $requete->fetchColumn() !== false;
    }

    /**
     * Crée un compte et retourne son identifiant.
     * Retourne null si une contrainte d'unicité est violée (e-mail ou pseudo déjà pris).
     */
    public function creer(string $pseudo, string $email, string $motDePasseHash): ?int
    {
        try {
            $requete = $this->pdo->prepare(
                'INSERT INTO php_utilisateurs (pseudo, email, mot_de_passe_hash)
                 VALUES (:pseudo, :email, :hash) RETURNING id'
            );
            $requete->execute([
                ':pseudo' => $pseudo,
                ':email'  => $email,
                ':hash'   => $motDePasseHash,
            ]);

            return (int) $requete->fetchColumn();
        } catch (PDOException $erreur) {
            // Classe SQLSTATE 23 : violation de contrainte d'intégrité.
            if (str_starts_with((string) ($erreur->errorInfo[0] ?? ''), '23')) {
                return null;
            }
            throw $erreur;
        }
    }
}
