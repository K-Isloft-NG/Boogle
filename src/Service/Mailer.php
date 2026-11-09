<?php
declare(strict_types=1);

namespace Boogle\Service;

use Boogle\Core\Config;

/** Envoi d'e-mails transactionnels par l'API HTTP de Brevo. */
final class Mailer
{
    private const URL_API = 'https://api.brevo.com/v3/smtp/email';

    /** Retourne true si Brevo a accepté le message. */
    public function envoyer(string $destinataire, string $sujet, string $texte, string $html): bool
    {
        $corps = json_encode([
            'sender'      => ['name' => 'Boogle', 'email' => Config::obtenir('MAIL_EXPEDITEUR')],
            'to'          => [['email' => $destinataire]],
            'subject'     => $sujet,
            'textContent' => $texte,
            'htmlContent' => $html,
        ], JSON_THROW_ON_ERROR);

        $contexte = stream_context_create([
            'http' => [
                'method'        => 'POST',
                'header'        => implode("\r\n", [
                    'Content-Type: application/json',
                    'Accept: application/json',
                    'api-key: ' . Config::obtenir('BREVO_API_KEY'),
                ]),
                'content'       => $corps,
                'timeout'       => 10,
                'ignore_errors' => true,
            ],
        ]);

        $reponse = @file_get_contents(self::URL_API, false, $contexte);
        $statut = isset($http_response_header[0]) && preg_match('/\s(\d{3})\s?/', $http_response_header[0], $m) === 1
            ? (int) $m[1]
            : 0;

        if ($statut < 200 || $statut >= 300) {
            // On journalise le code HTTP et la réponse de Brevo, jamais la clé d'API.
            error_log(sprintf('Envoi d’e-mail refusé par Brevo (HTTP %d) : %s', $statut, substr((string) $reponse, 0, 300)));
            return false;
        }

        return true;
    }
}
