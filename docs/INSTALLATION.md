# Installation et utilisation

## Installation déjà réalisée

Le schéma `atelier_sd` est installé dans le projet Supabase `portfolio-but-sd`, référence `osxllzjvcptlhnzmdidn`, en région Paris. Le schéma `portfolio` et sa vue publique restent ceux du site en ligne. Aucune nouvelle infrastructure payante n’a été créée pour ce carnet.

Dans Supabase Studio, sélectionner le projet puis le schéma `atelier_sd` dans l’éditeur de tables. Pour les vues et les requêtes, utiliser l’éditeur SQL. Les requêtes administrateur peuvent voir les brouillons : cela ne reflète pas la vue d’un visiteur.

## Reproduire dans une base neuve

Prérequis : PostgreSQL 15+, un client `psql`, et un rôle propriétaire de la base. Sur Supabase, `anon` et `authenticated` sont déjà fournis. Sur une base locale isolée uniquement, créer ces rôles avec `tests/roles_ci.sql` avant l’installation.

Configurer la connexion avec les variables habituelles `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER` et `PGPASSWORD`, en gardant les valeurs réelles hors du dépôt. Puis lancer :

```bash
make installer
make verifier
make exemple
```

Le Makefile exécute les fichiers 01, 02, 03 et 04 dans l’ordre. Sans `make`, utiliser `psql -X -v ON_ERROR_STOP=1 -f database/01_structure.sql`, puis les trois fichiers suivants.

`01_structure.sql` est une installation initiale, pas une opération de réinitialisation. Si le schéma existe, PostgreSQL échoue et annule ce fichier ; il ne détruit pas la version installée. Une évolution doit être un nouveau script explicite, revu pour la base concernée. `04_demarrage.sql` ajoute uniquement les références absentes et ne remet pas les données modifiées à leurs valeurs d’origine.

## Lire le point d’entrée JSON

Le point d’entrée est une vue distincte, sans changement des schémas exposés du projet :

```text
GET https://osxllzjvcptlhnzmdidn.supabase.co/rest/v1/atelier_sd_snapshot?select=payload
apikey: <clé publiable active du projet>
```

Une clé moderne `sb_publishable_…` se transmet dans `apikey`, pas comme un JWT Bearer. Ne pas utiliser de clé secrète ou `service_role` pour un visiteur. Le schéma `atelier_sd` n’a pas besoin d’être ajouté aux schémas exposés par l’API : le point d’entrée se trouve dans `public`, et ses vues internes respectent les droits et RLS du lecteur.

Le fichier `.env.example` indique les deux noms de variables attendus par le petit lecteur Node.js facultatif :

```bash
node examples/lire_api.mjs
```

Ce lecteur utilise les variables déjà fournies par le système ; il ne charge pas automatiquement un fichier `.env`. La sortie contient les données publiées, jamais la clé. Le Node.js nécessaire à cet exemple doit prendre en charge `fetch` (version 18+).

Au départ, `dossiers` vaut `[]` pour un visiteur : le seul dossier est un brouillon. Les temps sont `null`, puisque rien n’a encore été saisi. Cette réponse vide est attendue.

## Ajouter ses propres données

Créer un dossier puis ses séances. Pour chaque séance, indiquer le semestre, la qualité de durée et les répartitions expliquées. Ajouter les livrables diffusables et leurs argumentations. Les requêtes de `database/05_requetes.sql` aident à relire les résultats.

Publier un dossier avec `publication = 'public'` ne suffit pas à publier ses enfants : chaque séance, livrable, argumentation et relecture exige aussi `publie = true`. L’administrateur doit relire les commentaires et les liens avant cette décision. Pour revenir à une consultation privée, remettre le dossier en brouillon masque son contenu aux visiteurs.

L’exemple SQL livre une séance fictive de 90 minutes, ventilée 30/60. Il termine par `ROLLBACK` : il ne crée pas un horaire personnel durable.

## Raccordement au site

Le portfolio déployé utilise un autre contrat JSON. Pour le raccorder au carnet, il faudra adapter le lecteur serveur et les écrans aux dossiers, séances et indicateurs de cette version. Changer seulement le nom de la vue dans le code actuel ne suffit pas. Aucun basculement automatique n’est effectué par les scripts de ce dépôt.

Références techniques : [vues et RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [sécuriser l’API](https://supabase.com/docs/guides/api/securing-your-api), [vues PostgreSQL](https://www.postgresql.org/docs/17/sql-createview.html).
