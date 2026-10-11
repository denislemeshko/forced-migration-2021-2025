\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE origins_stage
(LIKE refugee_origins INCLUDING DEFAULTS)
ON COMMIT DROP;

\copy origins_stage (year, origin, refugees, change_people, change_percent, oip) FROM '/imports/origins.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

INSERT INTO refugee_origins (
    year, origin, refugees, change_people, change_percent, oip
)
SELECT
    year, origin, refugees, change_people, change_percent, oip
FROM origins_stage
ON CONFLICT (year, origin)
DO UPDATE SET
    refugees = EXCLUDED.refugees,
    change_people = EXCLUDED.change_people,
    change_percent = EXCLUDED.change_percent,
    oip = EXCLUDED.oip;

COMMIT;

SELECT year, origin, refugees, oip
FROM refugee_origins
WHERE origin = 'AFG'
ORDER BY year;