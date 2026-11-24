-- Références rédigées pour ce projet ; aucun horaire du professeur importé.
-- Les objectifs ci-dessous sont personnels, pas des codes AC officiels.
BEGIN;
INSERT INTO atelier_sd.referentiel (code, titre, version, origine, est_institutionnel)
VALUES ('SD-CARNET', 'Objectifs opérationnels du carnet SD', '2026.1',
        'Conception du projet ; axes inspirés du cadrage BUT SD fourni par l’étudiant. À rapprocher du référentiel institutionnel avant toute validation d’AC.', false)
ON CONFLICT (code) DO NOTHING;

INSERT INTO atelier_sd.axe (referentiel_id, code, titre, description)
SELECT r.id, v.code, v.titre, v.description
FROM atelier_sd.referentiel r CROSS JOIN (VALUES
    ('C1', 'Préparer et organiser les données', 'Décrire les sources, structurer les informations et contrôler leur qualité.'),
    ('C2', 'Construire une analyse', 'Choisir une méthode, expliciter ses hypothèses et examiner ses limites.'),
    ('C3', 'Restituer et argumenter', 'Présenter un résultat compréhensible et justifier les choix auprès du destinataire.'),
    ('C4', 'Réaliser un outil décisionnel', 'Développer, vérifier et faire évoluer une solution utilisable.')
) AS v(code, titre, description)
WHERE r.code = 'SD-CARNET' ON CONFLICT (referentiel_id, code) DO NOTHING;

INSERT INTO atelier_sd.objectif (axe_id, code, libelle, critere_observable)
SELECT a.id, v.code, v.libelle, v.critere
FROM (VALUES
    ('C1', 'MOD-01', 'Concevoir un modèle à partir des besoins du portfolio', 'Présenter les cardinalités et expliquer au moins deux contraintes de cohérence.'),
    ('C1', 'SRC-02', 'Distinguer une mesure sourcée d’une estimation', 'Retrouver le document ou la déclaration qui accompagne une durée.'),
    ('C2', 'CAL-01', 'Définir un indicateur de temps sans double comptage', 'Vérifier que la somme des contributions correspond au temps de la séance.'),
    ('C2', 'LIM-02', 'Rendre visibles les données absentes et les limites', 'Afficher séparément les durées inconnues, estimées et sourcées.'),
    ('C3', 'ARG-01', 'Expliquer le lien entre un livrable et un objectif', 'Rédiger une argumentation spécifique au livrable, avec un résultat observable.'),
    ('C3', 'DOC-02', 'Documenter des choix pour un lecteur extérieur', 'Fournir un dictionnaire et un exemple que le lecteur peut reproduire.'),
    ('C4', 'TST-01', 'Vérifier le comportement par des cas limites', 'Exécuter des contrôles de confidentialité et des cas de données invalides.'),
    ('C4', 'EVO-02', 'Faire évoluer un modèle sans casser l’existant', 'Installer une version indépendante et expliquer la stratégie de raccordement.')
) AS v(axe_code, code, libelle, critere)
JOIN atelier_sd.axe a ON a.code = v.axe_code
JOIN atelier_sd.referentiel r ON r.id = a.referentiel_id AND r.code = 'SD-CARNET'
ON CONFLICT (axe_id, code) DO NOTHING;

INSERT INTO atelier_sd.periode (code, semestre)
SELECT 'S' || n::text, n FROM generate_series(1, 6) n ON CONFLICT (code) DO NOTHING;

INSERT INTO atelier_sd.outil (code, nom) VALUES
    ('postgresql', 'PostgreSQL'), ('sql', 'SQL'), ('github', 'GitHub'), ('supabase', 'Supabase')
ON CONFLICT (code) DO NOTHING;

INSERT INTO atelier_sd.provenance (code, titre, nature, url, commentaire)
VALUES ('DEPOT-CARNET', 'Dépôt de conception du carnet SD', 'depot',
        'https://github.com/ADLIB-Mrani/Test-Portfolio24-11',
        'Preuve de conception du modèle. Ne justifie aucune durée de formation.')
ON CONFLICT (code) DO NOTHING;

INSERT INTO atelier_sd.dossier (slug, titre, categorie, resume, contexte, contribution, resultat)
VALUES ('conception-carnet-sd', 'Conception d’un carnet d’apprentissage SD', 'projet',
        'Modèle PostgreSQL indépendant pour relier des séances, des livrables et des objectifs.',
        'Proposer une autre organisation que les exemples de base fournis par l’enseignant.',
        'Conception préparée avec l’aide de ChatGPT ; les choix doivent être compris et relus par l’étudiant.',
        'Scripts, vues de calcul, règles de lecture et tests SQL reproductibles.')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO atelier_sd.dossier_outil (dossier_id, outil_id, usage_precis)
SELECT d.id, o.id, v.usage_precis
FROM (VALUES
    ('postgresql', 'Contraintes relationnelles et vues de synthèse.'),
    ('sql', 'Définition du modèle et contrôles reproductibles.'),
    ('github', 'Versionnement des scripts et de leur justification.'),
    ('supabase', 'Installation et vérification sur PostgreSQL hébergé.')
) AS v(code, usage_precis)
JOIN atelier_sd.outil o ON o.code = v.code
JOIN atelier_sd.dossier d ON d.slug = 'conception-carnet-sd'
ON CONFLICT (dossier_id, outil_id) DO NOTHING;
-- Le dossier reste un brouillon. Aucune séance, durée, relecture ou acquisition fictive.
COMMIT;
