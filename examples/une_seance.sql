-- Démonstration fictive : les données sont annulées à la fin de ce fichier.
-- Exécuter comme propriétaire de la base après l'installation.
BEGIN;
INSERT INTO atelier_sd.dossier (slug, titre, categorie, resume)
VALUES ('exemple-seance-90', 'Démonstration fictive annulée', 'formation', 'Expliquer une répartition du temps.');

INSERT INTO atelier_sd.seance (dossier_id, periode_id, repere, description, duree_minutes, qualite_duree)
SELECT d.id, p.id, 'EXEMPLE-90', 'Exemple fictif de nettoyage et analyse', 90, 'estimee'
FROM atelier_sd.dossier d CROSS JOIN atelier_sd.periode p
WHERE d.slug = 'exemple-seance-90' AND p.code = 'S5';

INSERT INTO atelier_sd.repartition (seance_id, axe_id, poids, justification)
SELECT s.id, a.id, v.poids, v.justification
FROM atelier_sd.seance s JOIN atelier_sd.dossier d ON d.id = s.dossier_id
CROSS JOIN (VALUES ('C1', 1, 'Un tiers pour préparer le jeu de données.'),
                   ('C2', 2, 'Deux tiers pour examiner les résultats.')) AS v(code, poids, justification)
JOIN atelier_sd.axe a ON a.code = v.code
JOIN atelier_sd.referentiel r ON r.id = a.referentiel_id AND r.code = 'SD-CARNET'
WHERE d.slug = 'exemple-seance-90' AND s.repere = 'EXEMPLE-90';

SELECT v.axe_code, v.coefficient, v.minutes_ponderees
FROM atelier_sd.v_ventilation v JOIN atelier_sd.dossier d ON d.id = v.dossier_id
WHERE d.slug = 'exemple-seance-90' ORDER BY v.axe_code;
-- Résultat attendu : C1 = 30 minutes, C2 = 60 minutes ; somme = 90.
ROLLBACK;
