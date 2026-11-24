# Dictionnaire des données

Les identifiants techniques sont des UUID générés par PostgreSQL. Les scripts de données retrouvent les relations par des clés métier ; ils ne supposent pas que l’identifiant généré vaut 1, 2 ou une UUID fixée à l’avance. `id` est la clé primaire sauf pour les deux tables d’association indiquées.

| Table | Colonnes principales | Règles |
| --- | --- | --- |
| `referentiel` | `code`, `titre`, `version`, `origine`, `est_institutionnel` | Code unique ; le référentiel livré est personnel |
| `axe` | `referentiel_id`, `code`, `titre`, `description` | Code unique dans un référentiel ; lien explicite au référentiel |
| `objectif` | `axe_id`, `code`, `libelle`, `critere_observable` | Code unique dans un axe ; critère observable obligatoire |
| `periode` | `code`, `semestre`, `debut`, `fin` | S1 à S6 ; code cohérent avec le semestre ; dates facultatives et ordonnées |
| `provenance` | `code`, `titre`, `nature`, `url`, `empreinte_sha256`, `commentaire`, `publie` | Code unique ; URL HTTP(S) et empreinte de 64 caractères hexadécimaux si présentes |
| `dossier` | `slug`, `titre`, `categorie`, `resume`, `contexte`, `contribution`, `resultat`, `publication`, `cree_le` | Slug unique ; brouillon initial ; date avec fuseau horaire |
| `seance` | `dossier_id`, `periode_id`, `provenance_id`, `repere`, `jour`, `description`, `duree_minutes`, `qualite_duree`, `publie` | Repère unique dans le dossier ; durée et qualité cohérentes ; source obligatoire si sourcée |
| `repartition` | `seance_id`, `axe_id`, `poids`, `justification` | Clé composée séance/axe ; poids 1 à 100 ; justification obligatoire |
| `livrable` | `dossier_id`, `provenance_id`, `repere`, `titre`, `format`, `url`, `publie` | Repère unique dans le dossier ; lien HTTP(S) obligatoire |
| `argumentation` | `livrable_id`, `objectif_id`, `explication`, `positionnement`, `publie` | Couple livrable/objectif unique ; une explication par objectif |
| `relecture` | `argumentation_id`, `auteur_affiche`, `avis`, `commentaire`, `relu_le`, `publie` | Avis daté et attribué ; historique ; aucun statut de validation officielle |
| `outil` | `code`, `nom` | Code unique, en minuscules sans espace |
| `dossier_outil` | `dossier_id`, `outil_id`, `usage_precis` | Clé composée dossier/outil ; usage expliqué dans le contexte du dossier |

## Vocabulaires contrôlés

| Colonne | Valeurs admises |
| --- | --- |
| `provenance.nature` | `document`, `depot`, `declaration` |
| `dossier.categorie` | `formation`, `projet`, `alternance`, `personnel` |
| `dossier.publication` | `brouillon`, `public`, `archive` |
| `seance.qualite_duree` | `inconnue`, `estimee`, `sourcee` |
| `livrable.format` | `code`, `rapport`, `visualisation`, `autre` |
| `argumentation.positionnement` | `decouverte`, `application`, `autonomie` |
| `relecture.avis` | `a_retravailler`, `argumente` |

Le positionnement est une appréciation personnelle. Les relectures sont des avis éditoriaux saisis par l’administrateur, sans authentification d’un enseignant ni valeur de certification.

## Suppression et index

Les clés étrangères empêchent de supprimer un parent encore utilisé. Seules les répartitions d’une séance et les associations d’outils d’un dossier suivent leur parent avec `ON DELETE CASCADE`, car ces lignes n’existent pas indépendamment de lui. Il n’existe aucun script de remise à zéro du schéma.

Les clés étrangères sont couvertes par une clé primaire, une contrainte unique ou un index dédié. L’index de relecture commence par l’argumentation puis la date, afin de retrouver le dernier avis. Aucun index n’est supprimé sur le seul constat qu’une base neuve ne l’a pas encore utilisé.
