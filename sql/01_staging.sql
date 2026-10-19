CREATE TABLE IF NOT EXISTS staging.validations_brutes(
    id      BIGSERIAL PRIMARY KEY,
    time        TEXT,
    badge       TEXT,
    sattion     TEXT,
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