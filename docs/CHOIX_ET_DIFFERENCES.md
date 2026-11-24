# Démarche et différences de conception

## Besoin retenu

Le portfolio doit permettre d’expliquer des réalisations et de rapprocher des temps de travail, des compétences et des preuves. Le carnet modélise cette démarche : **ce qui a été fait, pendant combien de temps, avec quelle source, et ce qui permet d’en parler**.

Il s’agit d’une conception distincte. Le changement ne repose pas seulement sur les noms des tables : l’unité de suivi, les cardinalités, le calcul du temps et le lien avec les livrables diffèrent.

## Lecture des propositions reçues

`init_db.sql` crée quatre tables : compétences, années, activités et apprentissages critiques. `init_dbVersionComplete.sql` ajoute les preuves, soit cinq tables créées. Dans cette seconde version, chaque preuve désigne un apprentissage critique et chaque activité possède une seule compétence.

Le fichier `readme.txt` décrit une application SQLite et un graphique Chart.js. Les scripts SQL reçus emploient notamment `CASCADE` et la notation `$$`, qui relèvent de PostgreSQL ; la version du carnet vise explicitement PostgreSQL 15+.

La première proposition contient aussi une compétence de test `C5`. Elle n’a pas été reprise. Les listes de cours, les volumes horaires et les noms des fichiers de preuve n’ont pas été importés : ils ne démontrent pas les données personnelles de l’étudiant.

## Comparaison des décisions

| Proposition du professeur | Conception du carnet | Conséquence |
| --- | --- | --- |
| Une activité correspond à une compétence | Une séance a plusieurs répartitions pondérées | Une même séance peut contribuer à C1 et C2 sans doubler le total |
| Une durée entière en heures | Minutes et qualité de la mesure | 1 h 30 peut être représentée ; estimation et source restent distinctes |
| Les horaires sont insérés avec les cours | Les durées personnelles sont saisies avec une provenance | Aucun horaire de l’exemple n’est présenté comme un fait personnel |
| Activités regroupées par numéro de semestre | Périodes référencées et dossiers couvrant plusieurs séances | Un projet peut se poursuivre sur plusieurs semestres |
| Preuve attachée directement à un AC | Livrable, argumentation et objectif en relation plusieurs à plusieurs | Un fichier est stocké une fois et peut servir à plusieurs explications |
| Pas d’avis daté dans les propositions | Relectures historisées | On distingue la présence d’un document et l’avis porté sur son argumentation |
| Lien AC-compétence reconstruit à partir du code dans la version complète | Clé étrangère explicite entre objectif et axe | Aucun chiffre du code n’est interprété automatiquement |
| Scripts commençant par supprimer des tables | Installation dans un nouveau schéma, sans suppression | Le portfolio existant garde ses données et ses points d’entrée |
| Pas de publication définie dans ces fichiers | Brouillons, publication par niveau et politiques SQL | Publier un dossier ne publie pas tous ses documents par défaut |

Les compétences et les semestres appartiennent au domaine commun du BUT : conserver ces notions ne constitue pas en soi une différence de conception. Les huit objectifs du carnet sont des propositions de travail rédigées pour cette version, sans reprendre la liste des AC fournis. Ils ne remplacent pas le référentiel institutionnel.

## Pourquoi des poids plutôt que plusieurs durées complètes ?

Pour une séance de 90 minutes, des poids 1 et 2 affectent 30 minutes à un axe et 60 à l’autre. La somme reste 90. Les poids sont une décision documentée de l’auteur ; ils ne représentent pas une mesure indépendante du temps réellement passé dans chaque compétence.

Une activité sans répartition reste dans le bilan du dossier et apparaît dans le compteur des séances non réparties. Une durée inconnue reste `NULL`. Les heures estimées ne sont pas additionnées silencieusement aux heures sourcées.

## Références d’inspiration

Fichiers joints par l’étudiant, lus le 24 novembre 2026. Ils ne sont pas distribués dans le dépôt.

| Fichier | Empreinte SHA-256 |
| --- | --- |
| `init_db.sql` | `198b001795f7292e985a5b9686ea42ef38962ea18342500ae3b6b492f039e0ae` |
| `init_dbVersionComplete.sql` | `84191b01fc1218c4b8cfec859b3b00f8467e9627f10fb60d6398b601f4945ffc` |
| `readme.txt` | `6c8eabe7e778dbb4f5d8c674f439dc0cd3cee30b67a5deed2bf268c0c7ccd7f0` |

Ces empreintes identifient les documents étudiés ; elles ne mesurent pas un taux d’originalité. Ce document décrit les choix effectivement implémentés, à expliquer et adapter par l’étudiant.
