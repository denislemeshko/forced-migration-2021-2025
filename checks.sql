\set ON_ERROR_STOP on

DO $$
BEGIN
    IF EXISTS (
        SELECT y.year, c.origin
        FROM generate_series(2021, 2025) AS y(year)
        CROSS JOIN (
            VALUES ('UKR'), ('SYR'), ('AFG')
        ) AS c(origin)

        EXCEPT

        SELECT year, origin
        FROM refugee_origins
    ) THEN
        RAISE EXCEPTION 'Missing country-year records';
    END IF;

    IF EXISTS (
        SELECT generate_series(2021, 2025)

        EXCEPT

        SELECT year
        FROM refugee_world
    ) THEN
        RAISE EXCEPTION 'Missing world-year records';
    END IF;

    RAISE NOTICE 'PASS: all expected years and origins are present';
END
$$;