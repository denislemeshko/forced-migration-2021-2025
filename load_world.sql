\set ON_ERROR_STOP on

BEGIN;

CREATE TEMP TABLE world_stage
(LIKE refugee_world INCLUDING DEFAULTS)
ON COMMIT DROP;

\copy world_stage FROM '/imports/world.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

INSERT INTO refugee_world (year, refugees)
SELECT year, refugees
FROM world_stage
ON CONFLICT (year)
DO UPDATE SET refugees = EXCLUDED.refugees;

COMMIT;

SELECT * FROM refugee_world ORDER BY year;