-- =========================================================
-- load_data.sql
-- Load Kaggle Retail Data Analytics CSVs into PostgreSQL
-- =========================================================

-- Optional: use a dedicated schema
-- CREATE SCHEMA IF NOT EXISTS retail;
-- SET search_path TO retail, public;

-- ---------------------------------------------------------
-- 1. Staging tables (raw CSV structure, minimal types)
-- ---------------------------------------------------------

DROP TABLE IF EXISTS stg_sales;
DROP TABLE IF EXISTS stg_features;
DROP TABLE IF EXISTS stg_stores;

CREATE TABLE stg_sales (
    store          INTEGER,
    dept           INTEGER,
    date           TEXT,
    weekly_sales   NUMERIC,
    isholiday      TEXT
);


CREATE TABLE stg_features (
    store        INTEGER,
    date         TEXT,
    temperature  TEXT,
    fuel_price   TEXT,
    markdown1    TEXT,
    markdown2    TEXT,
    markdown3    TEXT,
    markdown4    TEXT,
    markdown5    TEXT,
    cpi          TEXT,
    unemployment TEXT,
    isholiday    TEXT
);

CREATE TABLE stg_stores (
    store          INTEGER,
    store_type     TEXT,
    size           INTEGER
    -- add city/state/region columns here if present in your version
);
