




CREATE TABLE IF NOT EXISTS core.dim_ligne (
    id_ligne        SERIAL PRIMARY KEY,
    code_ligne      TEXT NOT NULL UNIQUE,
    ordre_tri       SMALLINT NOT NULL
);

TRUNCATE core.dim_ligne RESTART IDENTITY CASCADE ;

INSERT INTO core.dim_ligne (code_ligne, ordre_tri)
SELECT DISTINCT 
    libelle_line,
    regexp_replace(libelle_line, '\D', '', 'g')::INTEGER * 10 
        + CASE WHEN libelle_line ILIKE '%bis%' THEN 5 ELSE 0 END AS ordre_tri
FROM staging.stations_referentiel
WHERE commune_code_insee IN (
    SELECT C.commune_code_insee 
    From staging.communes_retenues AS C 
);











CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE OR REPLACE FUNCTION core.normaliser_nom(nom TEXT)
RETURNS TEXT AS $$
    SELECT trim(
        regexp_replace(
            regexp_replace(lower(core.unaccent(nom)), '[-''’‘ʼ`´]', ' ', 'g'),
            '\s+', ' ', 'g'
        )
    )
$$ LANGUAGE sql STABLE;

CREATE TABLE IF NOT EXISTS core.dim_station (
    station_id          SERIAL PRIMARY KEY,
    nom                 TEXT NOT NULL,
    nom_normalise       TEXT NOT NULL UNIQUE,
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,
    commune_nom         TEXT,
    commune_code_insee  TEXT,
    departement         TEXT,
    nb_lignes           SMALLINT,
    est_correspondance  BOOLEAN
);

TRUNCATE core.dim_station RESTART IDENTITY CASCADE;

INSERT INTO core.dim_station
    (nom, nom_normalise, latitude, longitude,
     commune_nom, commune_code_insee, departement)
SELECT
    MIN(libelle_station),
    core.normaliser_nom(libelle_station),
    AVG(latitude::DOUBLE PRECISION),
    AVG(longitude::DOUBLE PRECISION),
    MIN(commune_nom),
    MIN(code_insee),
    LEFT(MIN(code_insee), 2)
FROM (
    SELECT *,
        CASE WHEN commune_code_insee IN ('93200', '93210') THEN '93066'
             ELSE commune_code_insee
        END AS code_insee
    FROM staging.stations_referentiel
    WHERE commune_code_insee IN (SELECT commune_code_insee FROM staging.communes_retenues)
) AS s
GROUP BY core.normaliser_nom(libelle_station);

INSERT INTO core.dim_station (nom, nom_normalise)
SELECT MIN(v.station), core.normaliser_nom(COALESCE(c.nom_referentiel, v.station))
FROM (SELECT DISTINCT station FROM staging.validations_brutes) AS v
LEFT JOIN staging.correspondance_noms c
       ON core.normaliser_nom(c.nom_validations) = core.normaliser_nom(v.station)
WHERE core.normaliser_nom(COALESCE(c.nom_referentiel, v.station))
      NOT IN (SELECT nom_normalise FROM core.dim_station)
GROUP BY 2;








CREATE TABLE IF NOT EXISTS core.station_ligne (
    id_station  INTEGER NOT NULL REFERENCES core.dim_station (station_id),
    id_ligne    INTEGER NOT NULL REFERENCES core.dim_ligne (id_ligne),
    PRIMARY KEY (id_station, id_ligne)
);

TRUNCATE core.station_ligne;

INSERT INTO core.station_ligne (id_station, id_ligne)
SELECT  DISTINCT s.station_id , l.id_ligne 
From staging.stations_referentiel AS r
JOIN core.dim_station AS s ON s.nom_normalise = core.normaliser_nom(r.libelle_station)
JOIN core.dim_ligne as l ON l.code_ligne = r.libelle_line 
WHERE r.commune_code_insee IN (SELECT commune_code_insee FROM staging.communes_retenues);


UPDATE core.dim_station AS s
SET nb_lignes          = sl.nb,
    est_correspondance = sl.nb > 1
FROM (
    SELECT id_station, COUNT(*) AS nb
    FROM core.station_ligne
    GROUP BY id_station
) AS sl
WHERE s.station_id = sl.id_station;






