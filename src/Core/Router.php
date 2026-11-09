<?php
declare(strict_types=1);

namespace Boogle\Core;

/**
 * Contrôleur frontal : seules les pages déclarées dans la liste blanche sont accessibles.
 * Le nom de page reçu dans l'URL n'est jamais utilisé comme chemin de fichier.
 */
final class Router
{
    /**
     * @param array<string, array{controleur: class-string, actions: array<string, string>, prive: bool}> $routes
     *        actions : méthode HTTP => méthode du contrôleur
     */
    public function __construct(private readonly array $routes)
    {
    }

    public function repartir(): void
    {
        $page = $_GET['page'] ?? 'accueil';
        if (!is_string($page) || !isset($this->routes[$page])) {
            View::rendre('erreur', [
                'titre'   => 'Page introuvable',
                'message' => 'Cette page n’existe pas.',
            ], 404);
            return;
        }

        $route = $this->routes[$page];
        $methode = $_SERVER['REQUEST_METHOD'] ?? 'GET';
        if ($methode === 'HEAD') {
            $methode = 'GET';
        }

        if (!isset($route['actions'][$methode])) {
            header('Allow: ' . implode(', ', array_keys($route['actions'])));
            View::rendre('erreur', [
                'titre'   => 'Méthode non autorisée',
                'message' => 'Cette action n’est pas autorisée.',
            ], 405);
            return;
        }

        if ($route['prive'] && !Session::estConnecte()) {
            Session::ajouterMessage('info', 'Connectez-vous pour accéder à cette page.');
            self::rediriger('accueil');
        }

        // Vérification centralisée : aucun formulaire POST ne peut y échapper.
        if ($methode === 'POST') {
            Csrf::verifier();
        }

        $controleur = new $route['controleur']();
        $controleur->{$route['actions'][$methode]}();
    }

    /** Redirection 303 : après un POST, le navigateur rechargera la page suivante en GET. */
    public static function rediriger(string $page): never
    {
        header('Location: /?page=' . rawurlencode($page), true, 303);
        exit;
    }
}
