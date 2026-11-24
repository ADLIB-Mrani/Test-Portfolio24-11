-- Exécuter comme administrateur après les quatre fichiers d'installation.
-- Les fixtures sont annulées dans une sous-transaction, même en cas d'échec.
-- Les erreurs attendues sont capturées par leur SQLSTATE précis.
DO $test$
DECLARE
    d_public uuid; d_prive uuid; periode uuid; source_test uuid;
    axe1 uuid; axe2 uuid; obj1 uuid; obj2 uuid;
    s90 uuid; s30 uuid; s_inconnue uuid; s60 uuid;
    l1 uuid; l2 uuid; l_prive uuid; ar1 uuid;
    suffixe text := replace(gen_random_uuid()::text, '-', '');
    interdit boolean;
    valeur numeric;
    bilan record;
BEGIN
  BEGIN
    SELECT a.id INTO STRICT axe1 FROM atelier_sd.axe a
    JOIN atelier_sd.referentiel r ON r.id = a.referentiel_id
    WHERE r.code = 'SD-CARNET' AND a.code = 'C1';
    SELECT a.id INTO STRICT axe2 FROM atelier_sd.axe a
    JOIN atelier_sd.referentiel r ON r.id = a.referentiel_id
    WHERE r.code = 'SD-CARNET' AND a.code = 'C2';
    INSERT INTO atelier_sd.objectif (axe_id, code, libelle, critere_observable)
    VALUES (axe1, 'TEST-MOD-' || suffixe, 'Objectif de test', 'Fixture annulée') RETURNING id INTO obj1;
    INSERT INTO atelier_sd.objectif (axe_id, code, libelle, critere_observable)
    VALUES (axe1, 'TEST-SRC-' || suffixe, 'Autre objectif de test', 'Fixture annulée') RETURNING id INTO obj2;
    SELECT id INTO STRICT periode FROM atelier_sd.periode WHERE code = 'S5';
    INSERT INTO atelier_sd.provenance (code, titre, nature)
    VALUES ('TEST-' || suffixe, 'Fixture annulée', 'document') RETURNING id INTO source_test;
    INSERT INTO atelier_sd.dossier (slug, titre, categorie, resume, publication)
    VALUES ('test-public-' || suffixe, 'Fixture publique', 'projet', 'Fixture annulée', 'public') RETURNING id INTO d_public;
    INSERT INTO atelier_sd.dossier (slug, titre, categorie, resume)
    VALUES ('test-prive-' || suffixe, 'Fixture privée', 'projet', 'Fixture annulée') RETURNING id INTO d_prive;
    INSERT INTO atelier_sd.seance (dossier_id, periode_id, repere, description, duree_minutes, qualite_duree, provenance_id, publie)
    VALUES (d_public, periode, 'T90', 'Fixture sourcée', 90, 'sourcee', source_test, true) RETURNING id INTO s90;
    INSERT INTO atelier_sd.seance (dossier_id, periode_id, repere, description, duree_minutes, qualite_duree, publie)
    VALUES (d_public, periode, 'T30', 'Fixture estimée', 30, 'estimee', true) RETURNING id INTO s30;
    INSERT INTO atelier_sd.seance (dossier_id, periode_id, repere, description, publie)
    VALUES (d_public, periode, 'TNULL', 'Fixture non chiffrée', true) RETURNING id INTO s_inconnue;
    INSERT INTO atelier_sd.seance (dossier_id, periode_id, repere, description, duree_minutes, qualite_duree, provenance_id, publie)
    VALUES (d_public, periode, 'T60', 'Fixture non répartie', 60, 'sourcee', source_test, true) RETURNING id INTO s60;
    INSERT INTO atelier_sd.seance (dossier_id, periode_id, repere, description, duree_minutes, qualite_duree, publie)
    VALUES (d_public, periode, 'CACHE', 'Séance privée dans un dossier public', 999, 'estimee', false),
           (d_prive, periode, 'CACHE', 'Parent privé', 6000, 'estimee', true);
    INSERT INTO atelier_sd.repartition (seance_id, axe_id, poids, justification) VALUES
        (s90, axe1, 1, 'Fixture 1/3'), (s90, axe2, 2, 'Fixture 2/3'),
        (s30, axe2, 1, 'Fixture estimée'), (s_inconnue, axe1, 1, 'Durée inconnue');
    INSERT INTO atelier_sd.livrable (dossier_id, repere, titre, format, url, publie)
    VALUES (d_public, 'L1', 'Fixture SQL', 'code', 'https://example.invalid/test-1', true) RETURNING id INTO l1;
    INSERT INTO atelier_sd.livrable (dossier_id, repere, titre, format, url, publie)
    VALUES (d_public, 'L2', 'Fixture rapport', 'rapport', 'https://example.invalid/test-2', true) RETURNING id INTO l2;
    INSERT INTO atelier_sd.livrable (dossier_id, repere, titre, format, url)
    VALUES (d_public, 'PRIVE', 'Livrable non publié', 'code', 'https://example.invalid/private') RETURNING id INTO l_prive;
    INSERT INTO atelier_sd.argumentation (livrable_id, objectif_id, explication, positionnement, publie)
    VALUES (l1, obj1, 'Lien spécifique à l’objectif de modélisation', 'application', true) RETURNING id INTO ar1;
    INSERT INTO atelier_sd.argumentation (livrable_id, objectif_id, explication, positionnement, publie) VALUES
        (l1, obj2, 'Autre objectif, même fichier', 'decouverte', true),
        (l2, obj1, 'Autre livrable', 'application', true),
        (l_prive, obj1, 'Le parent privé doit masquer cette ligne', 'application', true);
    INSERT INTO atelier_sd.relecture (argumentation_id, auteur_affiche, avis, commentaire, relu_le, publie) VALUES
        (ar1, 'Test uniquement', 'argumente', 'Ancien avis', '2026-01-01T10:00:00Z', true),
        (ar1, 'Test uniquement', 'a_retravailler', 'Avis suivant', '2026-01-02T10:00:00Z', true),
        (ar1, 'Test privé', 'argumente', 'Avis non diffusé', '2026-01-03T10:00:00Z', false);
    INSERT INTO atelier_sd.dossier_outil (dossier_id, outil_id, usage_precis)
    SELECT d_public, id, 'Fixture pour détecter le double comptage' FROM atelier_sd.outil WHERE code IN ('sql', 'github');

    -- 1 : la ventilation conserve les minutes, avant tout arrondi.
    SELECT sum(minutes_ponderees) INTO valeur FROM atelier_sd.v_ventilation WHERE seance_id = s90;
    IF valeur IS DISTINCT FROM 90::numeric THEN RAISE EXCEPTION '1: conservation du temps'; END IF;
    -- 2 : deux axes ne reçoivent pas chacun les 90 minutes.
    SELECT minutes_ponderees INTO STRICT valeur FROM atelier_sd.v_ventilation WHERE seance_id = s90 AND axe_id = axe1;
    IF valeur IS DISTINCT FROM 30::numeric THEN RAISE EXCEPTION '2: ventilation 1/3'; END IF;
    -- 3 : une durée inconnue reste NULL.
    SELECT minutes_ponderees INTO STRICT valeur FROM atelier_sd.v_ventilation WHERE seance_id = s_inconnue;
    IF valeur IS NOT NULL THEN RAISE EXCEPTION '3: durée inconnue'; END IF;

    -- 4 : pas de durée négative.
    interdit := false;
    BEGIN
      INSERT INTO atelier_sd.seance (dossier_id, periode_id, repere, description, duree_minutes, qualite_duree)
      VALUES (d_public, periode, 'INVALIDE', 'Négatif', -1, 'estimee');
    EXCEPTION WHEN check_violation THEN interdit := true; END;
    IF NOT interdit THEN RAISE EXCEPTION '4: durée négative acceptée'; END IF;
    -- 5 : pas de durée dite sourcée sans provenance.
    interdit := false;
    BEGIN
      INSERT INTO atelier_sd.seance (dossier_id, periode_id, repere, description, duree_minutes, qualite_duree)
      VALUES (d_public, periode, 'INVALIDE', 'Sans source', 30, 'sourcee');
    EXCEPTION WHEN check_violation THEN interdit := true; END;
    IF NOT interdit THEN RAISE EXCEPTION '5: provenance absente acceptée'; END IF;
    -- 6 : un poids nul est interdit.
    interdit := false;
    BEGIN
      INSERT INTO atelier_sd.repartition VALUES (s60, axe1, 0, 'Invalide');
    EXCEPTION WHEN check_violation THEN interdit := true; END;
    IF NOT interdit THEN RAISE EXCEPTION '6: poids nul accepté'; END IF;
    -- 7 : une même séance ne reçoit pas deux fois le même axe.
    interdit := false;
    BEGIN
      INSERT INTO atelier_sd.repartition VALUES (s90, axe1, 1, 'Doublon');
    EXCEPTION WHEN unique_violation THEN interdit := true; END;
    IF NOT interdit THEN RAISE EXCEPTION '7: doublon accepté'; END IF;
    -- 8 : les parents référencés doivent exister.
    interdit := false;
    BEGIN
      INSERT INTO atelier_sd.repartition VALUES (gen_random_uuid(), axe1, 1, 'Orphelin');
    EXCEPTION WHEN foreign_key_violation THEN interdit := true; END;
    IF NOT interdit THEN RAISE EXCEPTION '8: référence orpheline'; END IF;
    -- 9 : les liens exécutables ne sont pas des ressources web.
    interdit := false;
    BEGIN
      INSERT INTO atelier_sd.livrable (dossier_id, repere, titre, format, url)
      VALUES (d_public, 'INVALIDE', 'Script', 'autre', 'javascript:alert(1)');
    EXCEPTION WHEN check_violation THEN interdit := true; END;
    IF NOT interdit THEN RAISE EXCEPTION '9: protocole de lien accepté'; END IF;
    -- 10 : semestre inexistant refusé.
    interdit := false;
    BEGIN INSERT INTO atelier_sd.periode (code, semestre) VALUES ('S7', 7);
    EXCEPTION WHEN check_violation THEN interdit := true; END;
    IF NOT interdit THEN RAISE EXCEPTION '10: semestre 7 accepté'; END IF;

    CREATE TEMP TABLE carnet_test_context AS SELECT d_public AS dossier_public, d_prive AS dossier_prive,
        s90 AS seance90, axe1 AS axe1_id, obj1 AS objectif1, l_prive AS livrable_prive,
        (SELECT slug FROM atelier_sd.dossier WHERE id = d_public) AS slug_public,
        (SELECT slug FROM atelier_sd.dossier WHERE id = d_prive) AS slug_prive;
    GRANT SELECT ON carnet_test_context TO anon, authenticated;
    EXECUTE 'SET LOCAL ROLE anon';
    -- 11 : le test exécute effectivement les requêtes comme visiteur.
    IF current_user <> 'anon' THEN RAISE EXCEPTION '11: rôle de test incorrect'; END IF;
    -- 12 : dossier privé absent de la table et de la vue.
    IF EXISTS (SELECT 1 FROM atelier_sd.dossier WHERE id = (SELECT dossier_prive FROM carnet_test_context))
       OR EXISTS (SELECT 1 FROM atelier_sd.v_bilan_dossier WHERE dossier_id = (SELECT dossier_prive FROM carnet_test_context))
    THEN RAISE EXCEPTION '12: dossier privé visible'; END IF;
    -- 13 : enfants publiés d’un parent privé masqués.
    IF EXISTS (SELECT 1 FROM atelier_sd.seance WHERE dossier_id = (SELECT dossier_prive FROM carnet_test_context))
    THEN RAISE EXCEPTION '13: enfant de parent privé visible'; END IF;
    -- 14 : les outils et les preuves ne multiplient pas les minutes.
    SELECT * INTO STRICT bilan FROM atelier_sd.v_bilan_dossier
    WHERE dossier_id = (SELECT dossier_public FROM carnet_test_context);
    IF bilan.minutes_sourcees IS DISTINCT FROM 150::bigint
       OR bilan.minutes_estimees IS DISTINCT FROM 30::bigint
       OR bilan.nb_seances <> 4 OR bilan.nb_livrables <> 2 OR bilan.nb_objectifs_illustres <> 2
    THEN RAISE EXCEPTION '14: agrégats ou visibilité incorrects'; END IF;
    -- 15 : absence de durée et absence d’affectation sont signalées séparément.
    IF bilan.nb_durees_inconnues <> 1 OR bilan.nb_seances_non_reparties <> 1
    THEN RAISE EXCEPTION '15: incomplétude masquée'; END IF;
    -- 16 : pas de donnée privée dans le point d’entrée public.
    IF NOT EXISTS (SELECT 1 FROM public.atelier_sd_snapshot,
        LATERAL jsonb_array_elements(payload->'dossiers') AS item
        WHERE item->>'slug' = (SELECT slug_public FROM carnet_test_context))
       OR EXISTS (SELECT 1 FROM public.atelier_sd_snapshot,
        LATERAL jsonb_array_elements(payload->'dossiers') AS item
        WHERE item->>'slug' = (SELECT slug_prive FROM carnet_test_context))
    THEN RAISE EXCEPTION '16: fuite du point public'; END IF;
    -- 17 : une argumentation publiée ne rend pas son livrable privé visible.
    IF EXISTS (SELECT 1 FROM atelier_sd.argumentation WHERE livrable_id = (SELECT livrable_prive FROM carnet_test_context))
    THEN RAISE EXCEPTION '17: livrable privé contourné'; END IF;
    -- 18 : seul le dernier avis visible est retenu.
    SELECT count(*) INTO valeur FROM atelier_sd.relecture WHERE auteur_affiche = 'Test privé';
    IF valeur <> 0 THEN RAISE EXCEPTION '18: avis privé visible'; END IF;
    SELECT nb_avis_argumentes, nb_avis_a_retravailler INTO STRICT bilan FROM atelier_sd.v_couverture_objectifs
    WHERE objectif_id = (SELECT objectif1 FROM carnet_test_context);
    IF bilan.nb_avis_argumentes <> 0 OR bilan.nb_avis_a_retravailler <> 1
    THEN RAISE EXCEPTION '18: chronologie des avis ignorée'; END IF;
    -- 19 : écritures anonymes refusées par les droits de table.
    interdit := false;
    BEGIN
      INSERT INTO atelier_sd.dossier (slug, titre, categorie, resume)
      VALUES ('tentative-anonyme', 'Refus attendu', 'projet', 'Refus attendu');
    EXCEPTION WHEN insufficient_privilege THEN interdit := true; END;
    IF NOT interdit THEN RAISE EXCEPTION '19: écriture anonyme autorisée'; END IF;
    EXECUTE 'RESET ROLE';
    -- 20 : se connecter ne confère aucun droit d’édition.
    IF has_table_privilege('authenticated', 'atelier_sd.dossier', 'INSERT')
       OR has_table_privilege('authenticated', 'atelier_sd.dossier', 'UPDATE')
       OR has_table_privilege('anon', 'atelier_sd.dossier', 'DELETE')
    THEN RAISE EXCEPTION '20: privilèges excessifs'; END IF;

    RAISE EXCEPTION USING ERRCODE = 'PZ001', MESSAGE = 'CARNET_TESTS_OK_ROLLBACK';
  EXCEPTION WHEN SQLSTATE 'PZ001' THEN
    IF SQLERRM <> 'CARNET_TESTS_OK_ROLLBACK' THEN RAISE; END IF;
    -- Ce bloc a annulé toutes les écritures, y compris les objets temporaires.
  END;
END
$test$;
SELECT '20 contrats SQL réussis ; fixtures annulées' AS resultat;
