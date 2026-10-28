CREATE TABLE IF NOT EXISTS core.dim_date (
    id_date       INTEGER PRIMARY KEY,
    date          DATE NOT NULL UNIQUE,
    annee         SMALLINT NOT NULL,
    mois          SMALLINT NOT NULL,
    nom_mois      TEXT NOT NULL,
    jour_mois     SMALLINT NOT NULL,
    jour_semaine  SMALLINT NOT NULL,
    nom_jour      TEXT NOT NULL,
    est_weekend   BOOLEAN NOT NULL,
    est_ferie     BOOLEAN NOT NULL DEFAULT false,
    est_vacances  BOOLEAN NOT NULL DEFAULT false
);

TRUNCATE core.dim_date CASCADE;

INSERT INTO core.dim_date
    (id_date, date, annee, mois, nom_mois,
     jour_mois, jour_semaine, nom_jour, est_weekend)
SELECT
    TO_CHAR(d, 'YYYYMMDD')::INTEGER,
    d::DATE,
    EXTRACT(YEAR FROM d),
    EXTRACT(MONTH FROM d),
    (ARRAY['janvier','février','mars','avril','mai','juin','juillet',
           'août','septembre','octobre','novembre','décembre'])[EXTRACT(MONTH FROM d)::INTEGER],
    EXTRACT(DAY FROM d),
    EXTRACT(ISODOW FROM d),
    (ARRAY['lundi','mardi','mercredi','jeudi','vendredi','samedi','dimanche'])[EXTRACT(ISODOW FROM d)::INTEGER],
    EXTRACT(ISODOW FROM d) IN (6, 7)
FROM generate_series('2020-01-01'::DATE, '2026-12-31'::DATE, INTERVAL '1 day') AS d;




CREATE TABLE IF NOT EXISTS core.dim_heure (
    id_heure         SMALLINT PRIMARY KEY,
    horaire          TIME NOT NULL UNIQUE,
    heure            SMALLINT NOT NULL,
    minute           SMALLINT NOT NULL,
    quart_heure      TIME NOT NULL,
    tranche_horaire  TEXT NOT NULL,
    est_pointe       BOOLEAN NOT NULL
);

TRUNCATE core.dim_heure CASCADE;

INSERT INTO core.dim_heure
    (id_heure, horaire, heure, minute, quart_heure, tranche_horaire, est_pointe)
SELECT
    (m / 60) * 100 + m % 60,
    MAKE_TIME(m / 60, m % 60, 0),
    m / 60,
    m % 60,
    MAKE_TIME(m / 60, (m % 60 / 15) * 15, 0),
    CASE
        WHEN m < 7 * 60           THEN 'nuit'
        WHEN m < 9 * 60 + 30      THEN 'pointe du matin'
        WHEN m < 16 * 60 + 30     THEN 'journée'
        WHEN m < 19 * 60 + 30     THEN 'pointe du soir'
        ELSE                           'soirée'
    END,
    (m >= 7 * 60 AND m < 9 * 60 + 30) OR (m >= 16 * 60 + 30 AND m < 19 * 60 + 30)
FROM generate_series(0, 1439) AS m;


-- Ajout Jours fériés
UPDATE core.dim_date AS d
SET est_ferie = true
FROM staging.jours_feries AS f
WHERE d.date = f.date::DATE;

-- Ajout Vacances scolaires (zone C : Paris)
UPDATE core.dim_date AS d
SET est_vacances = true
FROM staging.vacances_scolaires AS v
WHERE d.date = v.date::DATE
  AND v.vacances_zone_c = 'True';