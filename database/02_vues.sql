-- Agrégats indépendants : le nombre de livrables/outils ne multiplie pas le temps.
BEGIN;
CREATE VIEW atelier_sd.v_ventilation WITH (security_invoker = true) AS
WITH poids_seance AS (
    SELECT seance_id, sum(poids) AS total_poids
    FROM atelier_sd.repartition GROUP BY seance_id
)
SELECT s.id AS seance_id, s.dossier_id, s.periode_id, s.repere, s.qualite_duree,
       a.id AS axe_id, a.code AS axe_code, s.duree_minutes,
       r.poids::numeric / p.total_poids AS coefficient,
       s.duree_minutes::numeric * r.poids / p.total_poids AS minutes_ponderees
FROM atelier_sd.seance s
JOIN atelier_sd.repartition r ON r.seance_id = s.id
JOIN poids_seance p ON p.seance_id = s.id
JOIN atelier_sd.axe a ON a.id = r.axe_id;

CREATE VIEW atelier_sd.v_heures_par_axe WITH (security_invoker = true) AS
SELECT dossier_id, axe_id, axe_code,
       sum(minutes_ponderees) FILTER (WHERE qualite_duree = 'sourcee') AS minutes_sourcees,
       sum(minutes_ponderees) FILTER (WHERE qualite_duree = 'estimee') AS minutes_estimees,
       round(sum(minutes_ponderees) FILTER (WHERE qualite_duree = 'sourcee') / 60, 2) AS heures_sourcees,
       round(sum(minutes_ponderees) FILTER (WHERE qualite_duree = 'estimee') / 60, 2) AS heures_estimees,
       count(*) AS nb_seances,
       count(*) FILTER (WHERE qualite_duree = 'inconnue') AS nb_durees_inconnues
FROM atelier_sd.v_ventilation GROUP BY dossier_id, axe_id, axe_code;

CREATE VIEW atelier_sd.v_couverture_objectifs WITH (security_invoker = true) AS
WITH derniers_avis AS (
    SELECT DISTINCT ON (argumentation_id) argumentation_id, avis
    FROM atelier_sd.relecture
    ORDER BY argumentation_id, relu_le DESC, id DESC
)
SELECT o.id AS objectif_id, o.code, o.libelle, a.code AS axe_code,
       count(ar.id) AS nb_argumentations,
       count(ar.id) FILTER (WHERE da.avis = 'argumente') AS nb_avis_argumentes,
       count(ar.id) FILTER (WHERE da.avis = 'a_retravailler') AS nb_avis_a_retravailler
FROM atelier_sd.objectif o
JOIN atelier_sd.axe a ON a.id = o.axe_id
LEFT JOIN atelier_sd.argumentation ar ON ar.objectif_id = o.id
LEFT JOIN derniers_avis da ON da.argumentation_id = ar.id
GROUP BY o.id, o.code, o.libelle, a.code;

CREATE VIEW atelier_sd.v_bilan_dossier WITH (security_invoker = true) AS
WITH temps AS (
    SELECT s.dossier_id, count(*) AS nb_seances,
           sum(s.duree_minutes) FILTER (WHERE s.qualite_duree = 'sourcee') AS minutes_sourcees,
           sum(s.duree_minutes) FILTER (WHERE s.qualite_duree = 'estimee') AS minutes_estimees,
           count(*) FILTER (WHERE s.qualite_duree = 'inconnue') AS nb_durees_inconnues,
           count(*) FILTER (WHERE NOT EXISTS (
               SELECT 1 FROM atelier_sd.repartition r WHERE r.seance_id = s.id
           )) AS nb_seances_non_reparties
    FROM atelier_sd.seance s GROUP BY s.dossier_id
), pieces AS (
    SELECT dossier_id, count(*) AS nb_livrables FROM atelier_sd.livrable GROUP BY dossier_id
), objectifs AS (
    SELECT l.dossier_id, count(DISTINCT ar.objectif_id) AS nb_objectifs_illustres
    FROM atelier_sd.argumentation ar
    JOIN atelier_sd.livrable l ON l.id = ar.livrable_id GROUP BY l.dossier_id
), outils AS (
    SELECT d.dossier_id, jsonb_agg(o.nom ORDER BY o.nom) AS outils
    FROM atelier_sd.dossier_outil d JOIN atelier_sd.outil o ON o.id = d.outil_id
    GROUP BY d.dossier_id
)
SELECT d.id AS dossier_id, d.slug, d.titre, d.categorie, d.resume, d.publication,
       coalesce(t.nb_seances, 0) AS nb_seances,
       t.minutes_sourcees, t.minutes_estimees,
       coalesce(t.nb_durees_inconnues, 0) AS nb_durees_inconnues,
       coalesce(t.nb_seances_non_reparties, 0) AS nb_seances_non_reparties,
       coalesce(p.nb_livrables, 0) AS nb_livrables,
       coalesce(ob.nb_objectifs_illustres, 0) AS nb_objectifs_illustres,
       coalesce(outils.outils, '[]'::jsonb) AS outils
FROM atelier_sd.dossier d
LEFT JOIN temps t ON t.dossier_id = d.id
LEFT JOIN pieces p ON p.dossier_id = d.id
LEFT JOIN objectifs ob ON ob.dossier_id = d.id
LEFT JOIN outils ON outils.dossier_id = d.id;
COMMIT;
