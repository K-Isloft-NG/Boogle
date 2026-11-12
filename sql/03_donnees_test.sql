-- Jeu de données de test pour le schéma boggle.
-- Dépendances : exécuter sql/01_schema.sql puis sql/02_schema_boggle.sql.
-- Exécution : psql -v ON_ERROR_STOP=1 -d <base> -f sql/03_donnees_test.sql
-- À ne jamais exécuter sur une base contenant des données réelles : les suppressions visent les identifiants de 9001 à 9999.
BEGIN;
SET search_path TO boggle;
DELETE FROM boggle.participation WHERE id_partie BETWEEN 9001 AND 9999;
DELETE FROM boggle.partie WHERE id_partie BETWEEN 9001 AND 9999;
DELETE FROM boggle.dictionnaire WHERE id_dictionnaire BETWEEN 9001 AND 9999;
DELETE FROM public.php_utilisateurs WHERE id BETWEEN 9001 AND 9999 AND email LIKE '%@exemple.fr';

INSERT INTO public.php_utilisateurs (id, pseudo, email, mot_de_passe_hash, date_creation, est_actif) VALUES
(9001, 'test_karl', 'test_karl@exemple.fr', 'hash_factice', '2026-11-01 12:00:00', TRUE),
(9002, 'test_mamie', 'test_mamie@exemple.fr', 'hash_factice', '2026-11-01 12:00:00', TRUE),
(9003, 'test_lea', 'test_lea@exemple.fr', 'hash_factice', '2026-11-01 12:00:00', TRUE),
(9004, 'test_hugo', 'test_hugo@exemple.fr', 'hash_factice', '2026-11-01 12:00:00', TRUE),
(9005, 'test_inactif', 'test_inactif@exemple.fr', 'hash_factice', '2026-11-01 12:00:00', FALSE);

INSERT INTO dictionnaire (id_dictionnaire, code_langue, libelle, version, nb_mots) VALUES
(9001, 'fr', 'Français (jeu de test)', 'jeu-test-1', 300000),
(9002, 'en', 'Anglais (jeu de test)', 'jeu-test-1', 120000);

INSERT INTO partie (id_partie, statut, date_creation, date_debut, date_fin, donnees, id_dictionnaire) VALUES
(9001, 'terminee', '2026-11-02 18:00:00+01', '2026-11-02 18:05:00+01', '2026-11-02 18:08:00+01',
$jeu${
  "version_format": 1,
  "config": {
    "lignes": 4,
    "colonnes": 4,
    "duree_s": 180,
    "taille_min_mot": 3,
    "politique_score": "classique"
  },
  "grille": ["G","A","I","R","R","U","V","E","QU","E","O","T","A","S","M","J"],
  "solutions": [
    "OUI",
    "VIE",
    "VIRE",
    "RIVE",
    "AIR",
    "RUE",
    "QUE"
  ],
  "joueurs": [
    {
      "id_utilisateur": 9001,
      "score": 3,
      "propositions": [
        {
          "mot": "OUI",
          "chemin": [10,5,2],
          "t_ms": 10000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "VIRE",
          "chemin": [6,2,3,7],
          "t_ms": 20000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "RIVE",
          "chemin": [3,2,6,7],
          "t_ms": 30000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "TOIT",
          "chemin": null,
          "t_ms": 40000,
          "valide": false,
          "points": 0,
          "motif_rejet": "absent_grille"
        },
        {
          "mot": "VI",
          "chemin": [6,2],
          "t_ms": 50000,
          "valide": false,
          "points": 0,
          "motif_rejet": "trop_court"
        }
      ]
    },
    {
      "id_utilisateur": 9002,
      "score": 2,
      "propositions": [
        {
          "mot": "VIE",
          "chemin": [6,2,7],
          "t_ms": 10000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "OUI",
          "chemin": [10,5,2],
          "t_ms": 20000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "VIE",
          "chemin": [6,2,7],
          "t_ms": 30000,
          "valide": false,
          "points": 0,
          "motif_rejet": "doublon"
        },
        {
          "mot": "GAIR",
          "chemin": [0,1,2,3],
          "t_ms": 40000,
          "valide": false,
          "points": 0,
          "motif_rejet": "absent_dictionnaire"
        }
      ]
    }
  ],
  "resultat": {
    "classement": [
      {
        "id_utilisateur": 9001,
        "rang": 1,
        "score": 3
      },
      {
        "id_utilisateur": 9002,
        "rang": 2,
        "score": 2
      }
    ]
  }
}$jeu$::jsonb, 9001),
(9002, 'terminee', '2026-11-03 18:00:00+01', '2026-11-03 18:05:00+01', '2026-11-03 18:07:00+01',
$jeu${
  "version_format": 1,
  "config": {
    "lignes": 4,
    "colonnes": 4,
    "duree_s": 120,
    "taille_min_mot": 3,
    "politique_score": "classique"
  },
  "grille": ["G","A","I","R","R","U","V","E","QU","E","O","T","A","S","M","J"],
  "solutions": [
    "OUI",
    "VIE",
    "VIRE",
    "RIVE",
    "AIR",
    "RUE",
    "QUE"
  ],
  "joueurs": [
    {
      "id_utilisateur": 9003,
      "score": 2,
      "propositions": [
        {
          "mot": "QUE",
          "chemin": [8,9],
          "t_ms": 10000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "RUE",
          "chemin": [4,5,9],
          "t_ms": 20000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "SUR",
          "chemin": null,
          "t_ms": 30000,
          "valide": false,
          "points": 0,
          "motif_rejet": "absent_grille"
        }
      ]
    },
    {
      "id_utilisateur": 9004,
      "score": 2,
      "propositions": [
        {
          "mot": "AIR",
          "chemin": [1,2,3],
          "t_ms": 10000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "OUI",
          "chemin": [10,5,2],
          "t_ms": 20000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        }
      ]
    }
  ],
  "resultat": {
    "classement": [
      {
        "id_utilisateur": 9003,
        "rang": 1,
        "score": 2
      },
      {
        "id_utilisateur": 9004,
        "rang": 1,
        "score": 2
      }
    ]
  }
}$jeu$::jsonb, 9001),
(9003, 'en_cours', '2026-11-04 18:00:00+01', '2026-11-04 18:05:00+01', NULL,
$jeu${
  "version_format": 1,
  "config": {
    "lignes": 4,
    "colonnes": 4,
    "duree_s": 180,
    "taille_min_mot": 3,
    "politique_score": "classique"
  },
  "grille": ["G","A","I","R","R","U","V","E","QU","E","O","T","A","S","M","J"],
  "solutions": [
    "OUI",
    "VIE",
    "VIRE",
    "RIVE",
    "AIR",
    "RUE",
    "QUE"
  ],
  "joueurs": [
    {
      "id_utilisateur": 9001,
      "score": 1,
      "propositions": [
        {
          "mot": "OUI",
          "chemin": [10,5,2],
          "t_ms": 10000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        }
      ]
    },
    {
      "id_utilisateur": 9004,
      "score": 1,
      "propositions": [
        {
          "mot": "VIE",
          "chemin": [6,2,7],
          "t_ms": 10000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        }
      ]
    }
  ]
}$jeu$::jsonb, 9001),
(9004, 'en_attente', '2026-11-05 18:00:00+01', NULL, NULL,
$jeu${
  "version_format": 1,
  "config": {
    "lignes": 4,
    "colonnes": 4,
    "duree_s": 180,
    "taille_min_mot": 3,
    "politique_score": "classique"
  },
  "grille": ["G","A","I","R","R","U","V","E","QU","E","O","T","A","S","M","J"],
  "solutions": [
    "OUI",
    "VIE",
    "VIRE",
    "RIVE",
    "AIR",
    "RUE",
    "QUE"
  ],
  "joueurs": [
    {
      "id_utilisateur": 9003,
      "score": 0,
      "propositions": []
    }
  ]
}$jeu$::jsonb, 9001),
(9005, 'annulee', '2026-11-06 18:00:00+01', '2026-11-06 18:05:00+01', '2026-11-06 18:08:00+01',
$jeu${
  "version_format": 1,
  "config": {
    "lignes": 4,
    "colonnes": 4,
    "duree_s": 180,
    "taille_min_mot": 3,
    "politique_score": "classique"
  },
  "grille": ["G","A","I","R","R","U","V","E","QU","E","O","T","A","S","M","J"],
  "solutions": [
    "OUI",
    "VIE",
    "VIRE",
    "RIVE",
    "AIR",
    "RUE",
    "QUE"
  ],
  "joueurs": [
    {
      "id_utilisateur": 9004,
      "score": 1,
      "propositions": [
        {
          "mot": "OUI",
          "chemin": [10,5,2],
          "t_ms": 10000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        }
      ]
    },
    {
      "id_utilisateur": 9005,
      "score": 0,
      "propositions": [
        {
          "mot": "ZUT",
          "chemin": null,
          "t_ms": 10000,
          "valide": false,
          "points": 0,
          "motif_rejet": "absent_grille"
        }
      ]
    }
  ]
}$jeu$::jsonb, 9001),
(9006, 'terminee', '2026-11-07 18:00:00+01', '2026-11-07 18:05:00+01', '2026-11-07 18:07:00+01',
$jeu${
  "version_format": 1,
  "config": {
    "lignes": 3,
    "colonnes": 5,
    "duree_s": 120,
    "taille_min_mot": 3,
    "politique_score": "classique"
  },
  "grille": ["C","A","T","S","E","R","O","D","E","N","B","U","N","I","T"],
  "solutions": [
    "CAT",
    "CATS",
    "CODE",
    "DEN",
    "BUN",
    "UNITE"
  ],
  "joueurs": [
    {
      "id_utilisateur": 9002,
      "score": 4,
      "propositions": [
        {
          "mot": "UNITE",
          "chemin": [11,12,13,14,8],
          "t_ms": 10000,
          "valide": true,
          "points": 2,
          "motif_rejet": null
        },
        {
          "mot": "CODE",
          "chemin": [0,6,7,8],
          "t_ms": 20000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "DEN",
          "chemin": [7,8,9],
          "t_ms": 30000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        }
      ]
    },
    {
      "id_utilisateur": 9004,
      "score": 2,
      "propositions": [
        {
          "mot": "CAT",
          "chemin": [0,1,2],
          "t_ms": 10000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "BUN",
          "chemin": [10,11,12],
          "t_ms": 20000,
          "valide": true,
          "points": 1,
          "motif_rejet": null
        },
        {
          "mot": "ATS",
          "chemin": [1,2,3],
          "t_ms": 30000,
          "valide": false,
          "points": 0,
          "motif_rejet": "absent_dictionnaire"
        },
        {
          "mot": "ZIP",
          "chemin": null,
          "t_ms": 40000,
          "valide": false,
          "points": 0,
          "motif_rejet": "absent_grille"
        }
      ]
    }
  ],
  "resultat": {
    "classement": [
      {
        "id_utilisateur": 9002,
        "rang": 1,
        "score": 4
      },
      {
        "id_utilisateur": 9004,
        "rang": 2,
        "score": 2
      }
    ]
  }
}$jeu$::jsonb, 9002);

INSERT INTO participation (id_partie, id_utilisateur, date_rejoint) VALUES
(9001, 9001, '2026-11-02 18:02:00+01'),
(9001, 9002, '2026-11-02 18:02:00+01'),
(9002, 9003, '2026-11-03 18:02:00+01'),
(9002, 9004, '2026-11-03 18:02:00+01'),
(9003, 9001, '2026-11-04 18:02:00+01'),
(9003, 9004, '2026-11-04 18:02:00+01'),
(9004, 9003, '2026-11-05 18:02:00+01'),
(9005, 9004, '2026-11-06 18:02:00+01'),
(9005, 9005, '2026-11-06 18:02:00+01'),
(9006, 9002, '2026-11-07 18:02:00+01'),
(9006, 9004, '2026-11-07 18:02:00+01');

COMMIT;
