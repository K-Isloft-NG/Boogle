<?php
declare(strict_types=1);

namespace Boogle\Service;

use RuntimeException;

/** Levée quand trop de tentatives de connexion ont échoué récemment. */
final class ConnexionVerrouilleeException extends RuntimeException
{
}
