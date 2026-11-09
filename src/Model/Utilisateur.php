<?php
declare(strict_types=1);

namespace Boogle\Model;

final class Utilisateur
{
    public function __construct(
        public readonly int $id,
        public readonly string $pseudo,
        public readonly string $email,
        public readonly string $motDePasseHash,
    ) {
    }
}
