# Vérifications du 24 novembre 2026

## Base hébergée

Installation effectuée dans le projet Supabase existant `portfolio-but-sd`, PostgreSQL 17, schéma `atelier_sd`. La migration de structure est nommée `create_carnet_sd_v1` ; les références ont ensuite été ajoutées séparément.

Le script `tests/contrats.sql` a renvoyé **« 20 contrats SQL réussis ; fixtures annulées »**. Les fixtures sont créées dans une sous-transaction volontairement annulée. Une erreur inattendue fait échouer le test et annule aussi ses écritures.

| Domaine | Cas vérifiés |
| --- | --- |
| Temps | Conservation de 90 minutes, répartition 30/60 et durée inconnue conservée |
| Contraintes | Durée négative, durée sourcée sans provenance, poids nul, doublon, parent absent, mauvais protocole de lien et semestre 7 refusés |
| Confidentialité | Rôle `anon` réellement utilisé ; dossier privé, enfant d’un dossier privé, livrable privé et avis privé masqués |
| Agrégats | Outils et livrables multiples sans multiplication du temps ; inconnues et séances non réparties distinguées |
| Point public | Dossier publié présent et dossier privé absent de la charge JSON |
| Relecture | Dernier avis visible retenu, sans compter l’ancien avis favorable |
| Écriture | Écriture anonyme refusée ; aucune édition conférée au rôle connecté |

Après le test : **13 tables**, RLS activé sur les 13, **8 objectifs**, **0 séance**, **1 dossier brouillon**, **0 fixture persistante**. Le site existant conserve son projet et la même empreinte de données avant/après l’installation.

La lecture REST a aussi été vérifiée avec le script Node.js livré et une clé publiable active : version `carnet-sd-1`, aucun dossier publié, quatre axes et durées `null`. La clé ne figure pas dans la réponse. Les huit requêtes de lecture du fichier 05 s’exécutent sans erreur.

## Conseillers Supabase

Le contrôle de sécurité du projet ne signale aucune anomalie. Le contrôle de performance ne signale aucune clé étrangère sans index dans `atelier_sd`.

Certains index de la nouvelle base sont encore inutilisés, ce qui est attendu sans séances réelles. Le conseiller signale aussi trois clés étrangères non indexées dans l’ancien schéma `portfolio`, hors de cette version. Ces objets n’ont pas été modifiés. Références : [index de clés étrangères](https://supabase.com/docs/guides/database/database-linter?lint=0001_unindexed_foreign_keys), [index encore inutilisés](https://supabase.com/docs/guides/database/database-linter?lint=0005_unused_index).

## Reproduction

Le workflow GitHub utilise un conteneur PostgreSQL 17 de test et des rôles sans connexion `anon` / `authenticated`. Il exécute l’installation et les mêmes contrats SQL. Il n’a ni clé Supabase ni accès à la base hébergée. Son résultat est visible dans l’onglet Actions du dépôt.

La [vérification GitHub sur une base vierge](https://github.com/ADLIB-Mrani/Test-Portfolio24-11/actions/runs/45441101823) a réussi pour le commit `ffc35d190f8f8bf4ea1ee7ec6348dcc6ab8ba41d` : installation, contrats et exemple annulé.

L’exemple de séance reste annulé après exécution. Aucun test n’invente une durée enregistrée de manière permanente.

## Limites de cette livraison

Les tests portent sur le modèle et ses accès SQL, pas sur de nouvelles pages web. Le site existant n’est pas raccordé à ce contrat. Il n’y a pas d’interface d’édition, de compte enseignant, de calendrier scolaire complet ni d’import automatique du référentiel institutionnel. Une relecture est une information saisie par l’administrateur et ne certifie pas l’identité d’un évaluateur.
