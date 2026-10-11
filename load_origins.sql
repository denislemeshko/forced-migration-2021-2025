\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE origins_stage
(LIKE refugee_origins INCLUDING DEFAULTS)
ON COMMIT DROP;

\copy origins_stage FROM '/imports/origins.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

INSERT INTO refugee_origins (
    year, origin, refugees, change_people, change_percent
)
SELECT
    year, origin, refugees, change_people, change_percent
FROM origins_stage
ON CONFLICT (year, origin)
DO UPDATE SET
    refugees = EXCLUDED.refugees,
    change_people = EXCLUDED.change_people,
    change_percent = EXCLUDED.change_percent;

COMMIT;

SELECT origin, COUNT(*) AS year_count
FROM refugee_origins
GROUP BY origin
ORDER BY origin;