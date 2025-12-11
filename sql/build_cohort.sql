-- Base cohort
CREATE MATERIALIZED VIEW cohort_base AS
SELECT
    subject_id,
    hadm_id,
    stay_id,
    intime,
    outtime,
    ROW_NUMBER() OVER (
        PARTITION BY
            hadm_id
        ORDER BY
            intime
    ) AS icu_order
FROM
    mimiciv_icu.icustays;


-- Keep only first ICU stay per admission
CREATE MATERIALIZED VIEW cohort_first_icu AS
SELECT
    *
FROM
    cohort_base
WHERE
    icu_order = 1;

    
-- Add age column and keep only adult (>= 18) patients
CREATE MATERIALIZED VIEW cohort_with_age AS
SELECT
    c.subject_id,
    c.hadm_id,
    c.stay_id,
    a.admittime,
    c.intime,
    c.outtime,
    p.anchor_age AS age
FROM
    cohort_first_icu c
    JOIN mimiciv_hosp.admissions a ON c.hadm_id = a.hadm_id
    JOIN mimiciv_hosp.patients p ON c.subject_id = p.subject_id
WHERE
    p.anchor_age >= 18;


-- Add mortality flag
CREATE MATERIALIZED VIEW cohort_with_mortality AS
SELECT
    c.*,
    hospital_expire_flag as mortality_flag
FROM
    cohort_with_age c
    JOIN mimiciv_hosp.admissions a ON c.hadm_id = a.hadm_id;


-- Remove intime, outtime null values and outliers for length of stay (outtime - intime)
CREATE MATERIALIZED VIEW cohort_clean AS
SELECT
    *,
    EXTRACT(EPOCH FROM (outtime - intime))/3600 AS los_hours
FROM
    cohort_with_mortality
WHERE
    intime IS NOT NULL AND
    outtime IS NOT NULL AND
    outtime > intime AND
    EXTRACT(EPOCH FROM (outtime - intime))/3600 <= 1440;


-- Get n-sizes for filtered cohorts
SELECT COUNT(*) FROM cohort_base;

SELECT COUNT(*) FROM cohort_first_icu;

SELECT COUNT(*) FROM cohort_with_age;

SELECT COUNT(*) FROM cohort_with_mortality;

SELECT COUNT(*) FROM cohort_clean;
