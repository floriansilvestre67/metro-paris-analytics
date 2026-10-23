
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
            regexp_replace(lower(unaccent(nom)), '[-''’‘ʼ`´]', ' ', 'g'),
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
LEFT JOIN staging.correspondance_noms c ON c.nom_validations = v.station
WHERE core.normaliser_nom(COALESCE(c.nom_referentiel, v.station))
      NOT IN (SELECT nom_normalise FROM core.dim_station)
GROUP BY 2;
