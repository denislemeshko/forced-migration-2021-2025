\set ON_ERROR_STOP on

CREATE TABLE IF NOT EXISTS refugee_trend (
    year integer NOT NULL,
    origin text NOT NULL,
    asylum text NOT NULL,
    refugees bigint NOT NULL CHECK (refugees >= 0),
    change_people bigint,
    change_percent numeric(12, 2),
    PRIMARY KEY (year, origin, asylum)
);

CREATE TABLE IF NOT EXISTS refugee_origins (
    year integer NOT NULL,
    origin text NOT NULL,
    refugees bigint NOT NULL CHECK (refugees >= 0),
    change_people bigint,
    change_percent numeric(12, 2),
    PRIMARY KEY (year, origin)
);

CREATE TABLE IF NOT EXISTS refugee_world (
    year integer PRIMARY KEY,
    refugees bigint NOT NULL CHECK (refugees >= 0)
);

ALTER TABLE refugee_origins
ADD COLUMN IF NOT EXISTS oip bigint CHECK (oip >= 0);

