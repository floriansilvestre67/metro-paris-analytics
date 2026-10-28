

-- ============================================================
-- 1. Correspondance nom brut -> station
--    Calculée une fois par nom (quelques centaines) plutôt qu'une fois
--    par validation (75 millions), pour ne pas appeler normaliser_nom
--    75 millions de fois.
-- ============================================================

CREATE TABLE IF NOT EXISTS core.correspondance_station (
    nom_brut    TEXT PRIMARY KEY,
    id_station  INTEGER NOT NULL REFERENCES core.dim_station (id_station)
);

TRUNCATE core.correspondance_station;

INSERT INTO core.correspondance_station (nom_brut, id_station)
SELECT v.station, s.id_station
FROM (SELECT DISTINCT station FROM staging.validations_brutes WHERE station IS NOT NULL) AS v
LEFT JOIN staging.correspondance_noms AS c
       ON core.normaliser_nom(c.nom_validations) = core.normaliser_nom(v.station)
JOIN core.dim_station AS s
       ON s.nom_normalise = core.normaliser_nom(COALESCE(c.nom_referentiel, v.station));


-- ============================================================
-- 2. Les tables : rejets et faits (partitionnée par année)
-- ============================================================

CREATE TABLE IF NOT EXISTS core.rejets (
    id_rejet      BIGSERIAL PRIMARY KEY,
    id_staging    BIGINT NOT NULL,
    table_source  TEXT NOT NULL,
    raison        TEXT NOT NULL,
    time          TEXT,
    badge         TEXT,
    station       TEXT,
    type          TEXT,
    date_rejet    TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS core.fait_validation (
    id_validation  BIGINT    NOT NULL,
    horodatage     TIMESTAMP NOT NULL,
    id_date        INTEGER   NOT NULL REFERENCES core.dim_date (id_date),
    id_heure       SMALLINT  NOT NULL REFERENCES core.dim_heure (id_heure),
    id_station     INTEGER   NOT NULL REFERENCES core.dim_station (id_station),
    badge          INTEGER   NOT NULL,
    type           TEXT      NOT NULL CHECK (type IN ('entree', 'sortie')),
    PRIMARY KEY (id_validation, horodatage)
);



-- ============================================================
-- 3. Contrôle de chaque validation (une seule lecture des 75 M de lignes)
--    raison = NULL  -> ligne valide
--    raison remplie -> ligne rejetée, première règle non respectée
-- ============================================================

DROP TABLE IF EXISTS staging.validations_controlees;

CREATE UNLOGGED TABLE staging.validations_controlees AS
SELECT
    v.id,
    v.time,
    v.badge,
    v.station,
    v.type,
    cs.id_station,
    CASE
        WHEN v.time IS NULL OR NOT pg_input_is_valid(v.time, 'timestamp')
            THEN 'date invalide'
        WHEN v.time::TIMESTAMP <  '2020-01-01' OR v.time::TIMESTAMP >= '2027-01-01'
            THEN 'date hors période'
        WHEN v.badge IS NULL OR v.badge !~ '^[0-9]{1,9}$' -- badge avec autre chose que des chiffres 
            THEN 'badge invalide'
        WHEN v.type IS NULL OR v.type NOT IN ('entrée', 'sortie')
            THEN 'type inconnu'
        WHEN cs.id_station IS NULL
            THEN 'station inconnue'
        WHEN ROW_NUMBER() OVER (PARTITION BY v.time, v.badge, v.station, v.type
                                ORDER BY v.id) > 1
            THEN 'doublon'
    END AS raison
FROM staging.validations_brutes AS v
LEFT JOIN core.correspondance_station AS cs ON cs.nom_brut = v.station;


-- ============================================================
-- 4. Répartition : rejets d'un côté, faits de l'autre
-- ============================================================

TRUNCATE core.rejets RESTART IDENTITY;

INSERT INTO core.rejets (id_staging, table_source, raison, time, badge, station, type)
SELECT id, 'validations_brutes', raison, time, badge, station, type
FROM staging.validations_controlees
WHERE raison IS NOT NULL;

TRUNCATE core.fait_validation;

INSERT INTO core.fait_validation
    (id_validation, horodatage, id_date, id_heure, id_station, badge, type)
SELECT
    id,
    h,
    TO_CHAR(h, 'YYYYMMDD')::INTEGER,
    (EXTRACT(HOUR FROM h) * 100 + EXTRACT(MINUTE FROM h))::SMALLINT,
    id_station,
    badge::INTEGER,
    CASE type WHEN 'entrée' THEN 'entree' ELSE 'sortie' END
FROM (
    SELECT *, time::TIMESTAMP AS h
    FROM staging.validations_controlees
    WHERE raison IS NULL
) AS valides;


-- ============================================================
-- 5. Index (créés après le chargement : bien plus rapide)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_fv_badge_horodatage
    ON core.fait_validation (badge, horodatage);
CREATE INDEX IF NOT EXISTS idx_fv_station
    ON core.fait_validation (id_station);
CREATE INDEX IF NOT EXISTS idx_fv_horodatage_brin
    ON core.fait_validation USING BRIN (horodatage);


-- ============================================================
-- 6. Nettoyage et statistiques
-- ============================================================

DROP TABLE staging.validations_controlees;

ANALYZE core.fait_validation;