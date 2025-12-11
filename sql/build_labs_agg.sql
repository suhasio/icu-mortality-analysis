-- Create MV for aggregated labs of cohort patients
DROP MATERIALIZED VIEW IF EXISTS labs_agg;
CREATE MATERIALIZED VIEW labs_agg AS
WITH
    labs_filtered AS (
        SELECT
            ce.subject_id,
            ce.stay_id,
            ce.itemid,
            ce.valuenum,
            ce.charttime
        FROM
            mimiciv_icu.chartevents ce
            JOIN cohort_clean c ON ce.subject_id = c.subject_id
        WHERE
            ce.itemid IN (
                220546, -- WBC
                220545, -- Hematocrit
                220228, -- Hemoglobin
                227457, -- Platelets
                220645, -- Sodium
                227442, -- Potassium
                220602, -- Chloride
                220615, -- Creatinine
                225625, -- Calcium
                227443, -- Bicarbonate
                220621, -- Glucose
                225668 -- Lactic Acid
            )
            AND ce.valuenum IS NOT NULL
            AND ce.charttime BETWEEN c.intime AND c.intime  + INTERVAL '24 hours'
            AND ((itemid = 220546 AND valuenum BETWEEN 0.1 AND 200)     -- WBC
                OR (itemid = 220228 AND valuenum BETWEEN 1 AND 25)      -- Hemoglobin
                OR (itemid = 220545 AND valuenum BETWEEN 5 AND 70)      -- Hematocrit
                OR (itemid = 227457 AND valuenum BETWEEN 5 AND 2000)    -- Platelets
                OR (itemid = 220645 AND valuenum BETWEEN 90 AND 200)    -- Sodium
                OR (itemid = 227442 AND valuenum BETWEEN 1 AND 10)      -- Potassium
                OR (itemid = 220602 AND valuenum BETWEEN 60 AND 140)    -- Chloride
                OR (itemid = 220615 AND valuenum BETWEEN 0 AND 20)      -- Creatinine
                OR (itemid = 225625 AND valuenum BETWEEN 3 AND 20)      -- Calcium
                OR (itemid = 227443 AND valuenum BETWEEN 3 AND 60)      -- Bicarbonate
                OR (itemid = 220621 AND valuenum BETWEEN 10 AND 1000)   -- Glucose
                OR (itemid = 225668  AND valuenum BETWEEN 0 AND 20)     -- Lactic Acid
            )
    )
SELECT
    subject_id,
    stay_id,
    AVG(CASE WHEN itemid = 220546 THEN valuenum END) AS wbc_mean,
    AVG(CASE WHEN itemid = 220545 THEN valuenum END) AS hct_mean,
    AVG(CASE WHEN itemid = 220228 THEN valuenum END) AS hgb_mean,
    AVG(CASE WHEN itemid = 227457 THEN valuenum END) AS platelets_mean,
    AVG(CASE WHEN itemid = 220645 THEN valuenum END) AS sodium_mean,
    AVG(CASE WHEN itemid = 227442 THEN valuenum END) AS potassium_mean,
    AVG(CASE WHEN itemid = 220602 THEN valuenum END) AS chloride_mean,
    AVG(CASE WHEN itemid = 220615 THEN valuenum END) AS creatinine_mean,
    AVG(CASE WHEN itemid = 225625 THEN valuenum END) AS calcium_mean,
    AVG(CASE WHEN itemid = 227443 THEN valuenum END) AS bicarbonate_mean,
    AVG(CASE WHEN itemid = 220621 THEN valuenum END) AS glucose_mean,
    AVG(CASE WHEN itemid = 225668 THEN valuenum END) AS lactic_mean
FROM
    labs_filtered
GROUP BY
    subject_id,
    stay_id;

-- View labs_agg
SELECT
    *
FROM
    labs_agg;
