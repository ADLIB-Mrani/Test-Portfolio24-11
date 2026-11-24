-- Lecture seule. Les valeurs visibles dépendent du rôle PostgreSQL appelant.

-- 1. Dossiers du carnet et indicateurs calculés indépendamment.
SELECT slug, titre, nb_seances, minutes_sourcees, minutes_estimees,
       nb_durees_inconnues, nb_seances_non_reparties, nb_livrables, nb_objectifs_illustres
FROM atelier_sd.v_bilan_dossier ORDER BY slug;

-- 2. Répartition des séances entre axes, sans arrondir avant la somme.
SELECT d.slug, h.axe_code, h.heures_sourcees, h.heures_estimees, h.nb_durees_inconnues
FROM atelier_sd.v_heures_par_axe h
JOIN atelier_sd.dossier d ON d.id = h.dossier_id ORDER BY d.slug, h.axe_code;

-- 3. Par semestre : les NULL ne deviennent pas des zéros.
SELECT p.code AS semestre, v.axe_code,
       round(sum(v.minutes_ponderees) FILTER (WHERE v.qualite_duree = 'sourcee') / 60, 2) AS heures_sourcees,
       round(sum(v.minutes_ponderees) FILTER (WHERE v.qualite_duree = 'estimee') / 60, 2) AS heures_estimees,
       count(*) FILTER (WHERE v.qualite_duree = 'inconnue') AS durees_inconnues
FROM atelier_sd.v_ventilation v JOIN atelier_sd.periode p ON p.id = v.periode_id
GROUP BY p.code, v.axe_code ORDER BY p.code, v.axe_code;

-- 4. Séances saisies mais non réparties : elles restent dans le bilan du dossier.
SELECT d.slug, s.repere, s.duree_minutes, s.qualite_duree
FROM atelier_sd.seance s JOIN atelier_sd.dossier d ON d.id = s.dossier_id
WHERE NOT EXISTS (SELECT 1 FROM atelier_sd.repartition r WHERE r.seance_id = s.id);

-- 5. Objectifs illustrés et dernier avis VISIBLE de chaque argumentation.
-- Ce résultat ne signifie pas « apprentissage critique validé ».
SELECT * FROM atelier_sd.v_couverture_objectifs ORDER BY axe_code, code;

-- 6. Détail du raisonnement associé à chaque livrable.
SELECT d.slug, l.titre, o.code, ar.positionnement, ar.explication
FROM atelier_sd.argumentation ar JOIN atelier_sd.livrable l ON l.id = ar.livrable_id
JOIN atelier_sd.dossier d ON d.id = l.dossier_id
JOIN atelier_sd.objectif o ON o.id = ar.objectif_id ORDER BY d.slug, l.titre, o.code;

-- 7. Contrôle de conservation des minutes réparties ; aucune ligne attendue.
SELECT seance_id, max(duree_minutes) AS duree,
       sum(minutes_ponderees) AS minutes_reparties
FROM atelier_sd.v_ventilation WHERE duree_minutes IS NOT NULL
GROUP BY seance_id
HAVING abs(sum(minutes_ponderees) - max(duree_minutes)) > 0.00000001;

-- 8. Charge utile du point de lecture Supabase indépendant.
SELECT payload FROM public.atelier_sd_snapshot;
