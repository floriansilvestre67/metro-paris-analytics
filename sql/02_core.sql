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

