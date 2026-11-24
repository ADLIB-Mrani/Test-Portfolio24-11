-- À exécuter avec le rôle administrateur du projet Supabase.
-- Les visiteurs, connectés ou non, peuvent seulement lire les contenus publiés.
BEGIN;
REVOKE ALL ON SCHEMA atelier_sd FROM anon, authenticated;
REVOKE ALL ON ALL TABLES IN SCHEMA atelier_sd FROM anon, authenticated;
GRANT USAGE ON SCHEMA atelier_sd TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA atelier_sd TO anon, authenticated;

CREATE POLICY reference_lisible ON atelier_sd.referentiel FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY axe_lisible ON atelier_sd.axe FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY objectif_lisible ON atelier_sd.objectif FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY periode_lisible ON atelier_sd.periode FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY outil_lisible ON atelier_sd.outil FOR SELECT TO anon, authenticated USING (true);
CREATE POLICY provenance_publiee ON atelier_sd.provenance FOR SELECT TO anon, authenticated USING (publie);
CREATE POLICY dossier_public ON atelier_sd.dossier FOR SELECT TO anon, authenticated
    USING (publication = 'public');
CREATE POLICY seance_publique ON atelier_sd.seance FOR SELECT TO anon, authenticated
    USING (publie AND EXISTS (SELECT 1 FROM atelier_sd.dossier d WHERE d.id = dossier_id));
CREATE POLICY repartition_publique ON atelier_sd.repartition FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM atelier_sd.seance s WHERE s.id = seance_id));
CREATE POLICY livrable_public ON atelier_sd.livrable FOR SELECT TO anon, authenticated
    USING (publie AND EXISTS (SELECT 1 FROM atelier_sd.dossier d WHERE d.id = dossier_id));
CREATE POLICY argumentation_publique ON atelier_sd.argumentation FOR SELECT TO anon, authenticated
    USING (publie AND EXISTS (SELECT 1 FROM atelier_sd.livrable l WHERE l.id = livrable_id));
CREATE POLICY relecture_publique ON atelier_sd.relecture FOR SELECT TO anon, authenticated
    USING (publie AND EXISTS (SELECT 1 FROM atelier_sd.argumentation a WHERE a.id = argumentation_id));
CREATE POLICY association_outil_publique ON atelier_sd.dossier_outil FOR SELECT TO anon, authenticated
    USING (EXISTS (SELECT 1 FROM atelier_sd.dossier d WHERE d.id = dossier_id));

-- Point d'entrée distinct de public.portfolio_snapshot, utilisé par le site actuel.
-- Pas de fonction privilégiée : chaque vue respecte les politiques du rôle appelant.
CREATE VIEW public.atelier_sd_snapshot WITH (security_invoker = true) AS
SELECT jsonb_build_object(
    'version', 'carnet-sd-1',
    'dossiers', coalesce((SELECT jsonb_agg(jsonb_build_object(
        'slug', b.slug, 'titre', b.titre, 'categorie', b.categorie, 'resume', b.resume,
        'outils', b.outils, 'livrables', b.nb_livrables,
        'objectifsIllustres', b.nb_objectifs_illustres,
        'minutesSourcees', b.minutes_sourcees, 'minutesEstimees', b.minutes_estimees,
        'dureesInconnues', b.nb_durees_inconnues,
        'seancesNonReparties', b.nb_seances_non_reparties
    ) ORDER BY b.slug) FROM atelier_sd.v_bilan_dossier b), '[]'::jsonb),
    'tempsParAxe', coalesce((SELECT jsonb_agg(jsonb_build_object(
        'referentiel', rf.code, 'versionReferentiel', rf.version,
        'axe', a.code, 'titre', a.titre,
        'minutesSourcees', t.minutes_sourcees,
        'minutesEstimees', t.minutes_estimees,
        'dureesInconnues', coalesce(t.nb_durees_inconnues, 0)
    ) ORDER BY rf.code, a.code) FROM atelier_sd.axe a
    JOIN atelier_sd.referentiel rf ON rf.id = a.referentiel_id LEFT JOIN (
        SELECT axe_id, sum(minutes_sourcees) AS minutes_sourcees,
               sum(minutes_estimees) AS minutes_estimees,
               sum(nb_durees_inconnues) AS nb_durees_inconnues
        FROM atelier_sd.v_heures_par_axe GROUP BY axe_id
    ) t ON t.axe_id = a.id), '[]'::jsonb),
    'note', 'Répartition pondérée du temps saisi. Un livrable et un avis ne constituent pas une validation officielle d’apprentissage critique.'
) AS payload;
REVOKE ALL ON public.atelier_sd_snapshot FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.atelier_sd_snapshot TO anon, authenticated;
COMMENT ON VIEW public.atelier_sd_snapshot IS
    'Version expérimentale indépendante du portfolio déployé. Lecture publique filtrée par RLS.';
COMMIT;
