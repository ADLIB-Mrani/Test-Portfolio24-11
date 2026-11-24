# Carnet SD — une autre base pour le portfolio

Version personnelle de conception de base de données pour le portfolio de Mohamed Mrani Alaoui, préparée le 24 novembre 2026 avec l’aide de ChatGPT.

Le point de départ est un **carnet d’apprentissage** : un dossier rassemble des séances de travail, des livrables et des explications. Une séance peut mobiliser plusieurs compétences ; son temps est réparti entre elles. Un livrable peut illustrer plusieurs objectifs avec une argumentation différente pour chacun.

## Ce qui distingue cette version

| Besoin | Choix du carnet |
| --- | --- |
| Répartir une activité entre compétences | Poids relatifs, ramenés à la durée totale de la séance |
| Justifier les chiffres | Provenance et distinction entre durée sourcée, estimée ou inconnue |
| Présenter une réalisation | Dossier, outils utilisés et livrables réutilisables |
| Expliquer un apprentissage | Argumentation liée à un livrable et à un objectif |
| Faire relire | Avis datés ; dernier avis visible retenu, sans validation automatique d’AC |
| Préparer la publication | Brouillons par défaut et lecture publique filtrée dans PostgreSQL |

Les fichiers du professeur ont servi à comprendre le sujet. Leurs scripts, cours, horaires et exemples de preuves ne sont pas reproduits dans ce dépôt. Le [comparatif de conception](docs/CHOIX_ET_DIFFERENCES.md) explique les écarts de structure et les notions communes.

## État de la version

- **13 tables**, quatre vues métier et un point de lecture JSON.
- Installation effectuée dans le schéma **`atelier_sd`** du projet Supabase existant **`portfolio-but-sd`**.
- **20 contrats SQL réussis** sur PostgreSQL 17 ; fixtures annulées après les contrôles.
- Références de départ : quatre axes, six semestres, huit objectifs rédigés pour ce projet et quatre outils.
- Un dossier de conception en brouillon ; aucune durée de formation, preuve d’acquisition ou relecture fictive enregistrée.

Le site déjà déployé continue de lire son schéma `portfolio`. Cette version est indépendante : elle n’est pas encore raccordée aux pages du site. Son point d’entrée est `public.atelier_sd_snapshot`, distinct de `public.portfolio_snapshot`.

Les objectifs fournis ici sont des **objectifs personnels de travail**, pas des apprentissages critiques officiels. Les codes C1 à C4 reprennent les axes du cadrage fourni ; les intitulés sont des synthèses. Un temps saisi, un livrable ou un avis ne certifie pas une acquisition institutionnelle.

## Lire et essayer

1. Lire les [choix et différences](docs/CHOIX_ET_DIFFERENCES.md).
2. Consulter les [diagrammes et règles métier](docs/MODELE.md), puis le [dictionnaire des données](docs/DICTIONNAIRE.md).
3. Suivre l’[installation et la lecture Supabase](docs/INSTALLATION.md) pour une base neuve.
4. Essayer [une séance fictive annulée après démonstration](examples/une_seance.sql).
5. Exécuter les [requêtes métier](database/05_requetes.sql) et les [tests](tests/contrats.sql).

| Fichier | Rôle |
| --- | --- |
| `database/01_structure.sql` | Tables, clés, contraintes, index et activation de RLS |
| `database/02_vues.sql` | Répartition du temps, couverture et bilans |
| `database/03_supabase.sql` | Droits de lecture, politiques et point d’entrée JSON |
| `database/04_demarrage.sql` | Références et dossier de conception, sans heures inventées |
| `database/05_requetes.sql` | Huit exemples de lecture et de contrôle |
| `tests/contrats.sql` | Intégrité, calculs et confidentialité |
| `.github/workflows/postgres.yml` | Reproduction des contrôles sur une base PostgreSQL isolée |

Installation initiale : PostgreSQL **15 ou plus récent**. Les rôles `anon` et `authenticated` existent déjà sur Supabase. Pour un PostgreSQL de test vierge, utiliser les rôles décrits dans le guide. Aucun package Node.js n’est nécessaire pour la base.

Avec le client `psql` configuré par les variables PostgreSQL habituelles :

```bash
make installer
make verifier
```

Ne pas relancer l’installation initiale sur le schéma déjà installé : elle échoue si ce nom existe. Elle ne supprime aucun objet. Le fichier de démarrage est rejouable et ne remplace pas les données déjà modifiées.

Les [résultats de vérification](docs/VERIFICATIONS.md) donnent le périmètre testé et les limites restantes. Les choix ont été préparés avec une assistance IA ; l’étudiant doit pouvoir expliquer le modèle, ses calculs et les adaptations nécessaires à son propre travail.
