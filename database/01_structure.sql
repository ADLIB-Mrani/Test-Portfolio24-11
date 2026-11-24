-- Carnet SD : conception propre au projet Test-Portfolio24-11.
-- PostgreSQL 15+ ; installation initiale, sans suppression d'objets existants.
-- Un échec provoque l'annulation de ce fichier entier.
BEGIN;
CREATE SCHEMA atelier_sd;
REVOKE ALL ON SCHEMA atelier_sd FROM PUBLIC;

CREATE TABLE atelier_sd.referentiel (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text NOT NULL UNIQUE CHECK (btrim(code) <> ''),
    titre text NOT NULL CHECK (btrim(titre) <> ''),
    version text NOT NULL CHECK (btrim(version) <> ''),
    origine text NOT NULL,
    est_institutionnel boolean NOT NULL DEFAULT false
);

CREATE TABLE atelier_sd.axe (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    referentiel_id uuid NOT NULL REFERENCES atelier_sd.referentiel(id),
    code text NOT NULL CHECK (btrim(code) <> ''),
    titre text NOT NULL CHECK (btrim(titre) <> ''),
    description text NOT NULL,
    UNIQUE (referentiel_id, code)
);

CREATE TABLE atelier_sd.objectif (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    axe_id uuid NOT NULL REFERENCES atelier_sd.axe(id),
    code text NOT NULL CHECK (btrim(code) <> ''),
    libelle text NOT NULL CHECK (btrim(libelle) <> ''),
    critere_observable text NOT NULL CHECK (btrim(critere_observable) <> ''),
    UNIQUE (axe_id, code)
);

CREATE TABLE atelier_sd.periode (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text NOT NULL UNIQUE CHECK (code ~ '^S[1-6]$'),
    semestre smallint NOT NULL UNIQUE CHECK (semestre BETWEEN 1 AND 6),
    debut date,
    fin date,
    CHECK (code = 'S' || semestre::text),
    CHECK (debut IS NULL OR fin IS NULL OR fin >= debut)
);

CREATE TABLE atelier_sd.provenance (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text NOT NULL UNIQUE CHECK (btrim(code) <> ''),
    titre text NOT NULL CHECK (btrim(titre) <> ''),
    nature text NOT NULL CHECK (nature IN ('document', 'depot', 'declaration')),
    url text CHECK (url ~ '^https?://[^[:space:]]+$'),
    empreinte_sha256 text CHECK (empreinte_sha256 ~ '^[0-9a-f]{64}$'),
    commentaire text,
    publie boolean NOT NULL DEFAULT false
);

CREATE TABLE atelier_sd.dossier (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    titre text NOT NULL CHECK (btrim(titre) <> ''),
    categorie text NOT NULL CHECK (categorie IN ('formation', 'projet', 'alternance', 'personnel')),
    resume text NOT NULL CHECK (btrim(resume) <> ''),
    contexte text,
    contribution text,
    resultat text,
    publication text NOT NULL DEFAULT 'brouillon'
        CHECK (publication IN ('brouillon', 'public', 'archive')),
    cree_le timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE atelier_sd.seance (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_id uuid NOT NULL REFERENCES atelier_sd.dossier(id),
    periode_id uuid NOT NULL REFERENCES atelier_sd.periode(id),
    provenance_id uuid REFERENCES atelier_sd.provenance(id),
    repere text NOT NULL CHECK (btrim(repere) <> ''),
    jour date,
    description text NOT NULL CHECK (btrim(description) <> ''),
    duree_minutes integer CHECK (duree_minutes > 0),
    qualite_duree text NOT NULL DEFAULT 'inconnue'
        CHECK (qualite_duree IN ('inconnue', 'estimee', 'sourcee')),
    publie boolean NOT NULL DEFAULT false,
    UNIQUE (dossier_id, repere),
    CHECK ((qualite_duree = 'inconnue') = (duree_minutes IS NULL)),
    CHECK (qualite_duree <> 'sourcee' OR provenance_id IS NOT NULL)
);

-- Les poids sont relatifs : 1 et 2 signifient 1/3 et 2/3 de la séance.
-- Aucune duplication de la durée entière pour chaque compétence.
CREATE TABLE atelier_sd.repartition (
    seance_id uuid NOT NULL REFERENCES atelier_sd.seance(id) ON DELETE CASCADE,
    axe_id uuid NOT NULL REFERENCES atelier_sd.axe(id),
    poids smallint NOT NULL CHECK (poids BETWEEN 1 AND 100),
    justification text NOT NULL CHECK (btrim(justification) <> ''),
    PRIMARY KEY (seance_id, axe_id)
);

CREATE TABLE atelier_sd.livrable (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    dossier_id uuid NOT NULL REFERENCES atelier_sd.dossier(id),
    provenance_id uuid REFERENCES atelier_sd.provenance(id),
    repere text NOT NULL CHECK (btrim(repere) <> ''),
    titre text NOT NULL CHECK (btrim(titre) <> ''),
    format text NOT NULL CHECK (format IN ('code', 'rapport', 'visualisation', 'autre')),
    url text NOT NULL CHECK (url ~ '^https?://[^[:space:]]+$'),
    publie boolean NOT NULL DEFAULT false,
    UNIQUE (dossier_id, repere)
);

-- Un même livrable peut illustrer plusieurs objectifs avec des explications distinctes.
CREATE TABLE atelier_sd.argumentation (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    livrable_id uuid NOT NULL REFERENCES atelier_sd.livrable(id),
    objectif_id uuid NOT NULL REFERENCES atelier_sd.objectif(id),
    explication text NOT NULL CHECK (btrim(explication) <> ''),
    positionnement text NOT NULL CHECK (positionnement IN ('decouverte', 'application', 'autonomie')),
    publie boolean NOT NULL DEFAULT false,
    UNIQUE (livrable_id, objectif_id)
);

-- Avis de relecture datés ; aucune équivalence automatique avec une validation d'AC.
CREATE TABLE atelier_sd.relecture (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    argumentation_id uuid NOT NULL REFERENCES atelier_sd.argumentation(id),
    auteur_affiche text NOT NULL CHECK (btrim(auteur_affiche) <> ''),
    avis text NOT NULL CHECK (avis IN ('a_retravailler', 'argumente')),
    commentaire text NOT NULL CHECK (btrim(commentaire) <> ''),
    relu_le timestamptz NOT NULL DEFAULT clock_timestamp(),
    publie boolean NOT NULL DEFAULT false
);

CREATE TABLE atelier_sd.outil (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    code text NOT NULL UNIQUE CHECK (code ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
    nom text NOT NULL CHECK (btrim(nom) <> '')
);

CREATE TABLE atelier_sd.dossier_outil (
    dossier_id uuid NOT NULL REFERENCES atelier_sd.dossier(id) ON DELETE CASCADE,
    outil_id uuid NOT NULL REFERENCES atelier_sd.outil(id),
    usage_precis text NOT NULL CHECK (btrim(usage_precis) <> ''),
    PRIMARY KEY (dossier_id, outil_id)
);

CREATE INDEX seance_dossier_jour_idx ON atelier_sd.seance (dossier_id, jour DESC);
CREATE INDEX seance_periode_idx ON atelier_sd.seance (periode_id);
CREATE INDEX seance_provenance_idx ON atelier_sd.seance (provenance_id);
CREATE INDEX repartition_axe_idx ON atelier_sd.repartition (axe_id);
CREATE INDEX livrable_dossier_idx ON atelier_sd.livrable (dossier_id);
CREATE INDEX livrable_provenance_idx ON atelier_sd.livrable (provenance_id);
CREATE INDEX argumentation_objectif_idx ON atelier_sd.argumentation (objectif_id);
CREATE INDEX relecture_argumentation_date_idx ON atelier_sd.relecture (argumentation_id, relu_le DESC, id DESC);
CREATE INDEX dossier_outil_outil_idx ON atelier_sd.dossier_outil (outil_id);

-- Protection immédiate, avant même l'installation des accès Supabase.
ALTER TABLE atelier_sd.referentiel ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.axe ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.objectif ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.periode ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.provenance ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.dossier ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.seance ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.repartition ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.livrable ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.argumentation ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.relecture ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.outil ENABLE ROW LEVEL SECURITY;
ALTER TABLE atelier_sd.dossier_outil ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON ALL TABLES IN SCHEMA atelier_sd FROM PUBLIC;
COMMIT;
