CREATE TABLE IF NOT EXISTS staging.validations_brutes(
    id      BIGSERIAL PRIMARY KEY,
    time        TEXT,
    badge       TEXT,
    station     TEXT,
    type        TEXT,
    date_chargement TIMESTAMP DEFAULT now() 
);

CREATE TABLE IF NOT EXISTS staging.stations_referentiel (
    id                  BIGSERIAL PRIMARY KEY,
    id_line             TEXT,
    libelle_line        TEXT,
    libelle_station     TEXT,
    longitude           TEXT,
    latitude            TEXT,
    finish              TEXT,
    commune_nom         TEXT,
    commune_code_insee  TEXT,
    date_chargement     TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS staging.correspondance_noms (
    nom_validations  TEXT,
    nom_referentiel  TEXT,
    commentaire      TEXT,
    date_chargement  TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS staging.communes_retenues (
    commune_code_insee  TEXT,
    commune_nom         TEXT,
    commentaire         TEXT,
    date_chargement     TIMESTAMP DEFAULT now()
);

-- Ajout des jours fériers et vacances 

CREATE TABLE IF NOT EXISTS staging.vacances_scolaires (
    date              TEXT,
    vacances_zone_a   TEXT,
    vacances_zone_b   TEXT,
    vacances_zone_c   TEXT,
    nom_vacances      TEXT,
    date_chargement   TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS staging.jours_feries (
    date              TEXT,
    annee             TEXT,
    zone              TEXT,
    nom_jour_ferie    TEXT,
    date_chargement   TIMESTAMP DEFAULT now()
);
