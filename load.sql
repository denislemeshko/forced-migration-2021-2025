\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE refugee_stage
(LIKE refugee_trend INCLUDING DEFAULTS)
ON COMMIT DROP;

\copy refugee_stage FROM '/imports/ukraine_germany.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

INSERT INTO refugee_trend (
    year, origin, asylum, refugees,
    change_people, change_percent
)
SELECT
    year, origin, asylum, refugees,
    change_people, change_percent
FROM refugee_stage
ON CONFLICT (year, origin, asylum)
DO UPDATE SET
    refugees = EXCLUDED.refugees,
    change_people = EXCLUDED.change_people,
    change_percent = EXCLUDED.change_percent;

COMMIT;

SELECT COUNT(*) AS row_count FROM refugee_trend;