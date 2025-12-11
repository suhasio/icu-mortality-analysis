-- Create MV for aggregated vitals of cohort patients
DROP MATERIALIZED VIEW IF EXISTS vitals_agg;
CREATE MATERIALIZED VIEW vitals_agg AS
WITH
    vitals_filtered AS (
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
                220045, -- HR
                220210, -- RR
                220179, -- SBP
                220180, -- DBP
                223761, -- Temp
                220277  -- SpO2
            )
            AND ce.valuenum IS NOT NULL
            AND ce.charttime BETWEEN c.intime AND c.intime  + INTERVAL '24 hours'
            AND ((ce.itemid = 220045 AND ce.valuenum BETWEEN 0 AND 250)        -- HR
                OR (ce.itemid = 220210 AND ce.valuenum BETWEEN 0 AND 60)       -- RR
                OR (ce.itemid = 220179 AND ce.valuenum BETWEEN 30 AND 250)     -- SBP
                OR (ce.itemid = 220180 AND ce.valuenum BETWEEN 10 AND 150)     -- DBP
                OR (ce.itemid = 223761 AND ce.valuenum BETWEEN 75 AND 115)      -- Temp
                OR (ce.itemid = 220277 AND ce.valuenum BETWEEN 50 AND 100)     -- SpO₂
            )
    )
SELECT
    subject_id,
    stay_id,
    AVG(CASE WHEN itemid = 220045 THEN valuenum END) AS hr_mean,
    AVG(CASE WHEN itemid = 220210 THEN valuenum END) AS rr_mean,
    AVG(CASE WHEN itemid = 220179 THEN valuenum END) AS sbp_mean,
    AVG(CASE WHEN itemid = 220180 THEN valuenum END) AS dbp_mean,
    AVG(CASE WHEN itemid = 223761 THEN valuenum END) AS temp_mean,
    AVG(CASE WHEN itemid = 220277 THEN valuenum END) AS spo2_mean
FROM
    vitals_filtered
GROUP BY
    subject_id,
    stay_id;

-- View vitals_agg
SELECT
    *
FROM
    vitals_agg;


-- View vitals_agg AVG
SELECT
    AVG(hr_mean), AVG(rr_mean), AVG(sbp_mean), AVG(dbp_mean), AVG(temp_mean), AVG(spo2_mean), 1 as one
FROM
    vitals_agg
GROUP BY one;


-- View vitals_agg MAX
SELECT
    MAX(hr_mean), MAX(rr_mean), MAX(sbp_mean), MAX(dbp_mean), MAX(temp_mean), MAX(spo2_mean), 1 as one
FROM
    vitals_agg
GROUP BY one;

-- View vitals_agg MIN
SELECT
    MIN(hr_mean), MIN(rr_mean), MIN(sbp_mean), MIN(dbp_mean), MIN(temp_mean), MIN(spo2_mean), 1 as one
FROM
    vitals_agg
GROUP BY one;

    