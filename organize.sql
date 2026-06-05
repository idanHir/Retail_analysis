-- dim_store
INSERT INTO dim_store (store_id, store_type, size)
SELECT DISTINCT
    store        AS store_id,
    store_type,
    size
FROM stg_stores;

-- dim_department
-- The original dataset only has Dept numbers; we map them to IDs.
-- If you later create names, you can update dim_department.dept_name.

INSERT INTO dim_department (dept_id, dept_name)
SELECT DISTINCT
    dept AS dept_id,
    NULL::TEXT AS dept_name
FROM stg_sales
ORDER BY dept;

-- ---------------------------------------------------------
-- 4. Populate fact tables with cleaning/casting
-- ---------------------------------------------------------

-- fact_sales
INSERT INTO fact_sales (store_id, dept_id, date, weekly_sales, is_holiday)
SELECT
    s.store                      AS store_id,
    s.dept                       AS dept_id,
    TO_DATE(s.date, 'DD/MM/YYYY')   -- adjust format if needed
                                   AS date,
    s.weekly_sales,
    CASE
        WHEN LOWER(TRIM(s.isholiday)) = 'true'
            THEN TRUE
        ELSE FALSE
    END                           AS is_holiday
FROM stg_sales AS s;

-- fact_features
INSERT INTO fact_features (
    store_id,
    date,
    temperature,
    fuel_price,
    markdown1,
    markdown2,
    markdown3,
    markdown4,
    markdown5,
    cpi,
    unemployment
)
SELECT
    f.store                                   AS store_id,
    TO_DATE(f.date, 'DD/MM/YYYY')            AS date,  -- or 'DD/MM/YYYY' if needed
    NULLIF(f.temperature, 'NA')::NUMERIC     AS temperature,
    NULLIF(f.fuel_price,  'NA')::NUMERIC     AS fuel_price,
    NULLIF(f.markdown1,   'NA')::NUMERIC     AS markdown1,
    NULLIF(f.markdown2,   'NA')::NUMERIC     AS markdown2,
    NULLIF(f.markdown3,   'NA')::NUMERIC     AS markdown3,
    NULLIF(f.markdown4,   'NA')::NUMERIC     AS markdown4,
    NULLIF(f.markdown5,   'NA')::NUMERIC     AS markdown5,
    NULLIF(f.cpi,         'NA')::NUMERIC     AS cpi,
    NULLIF(f.unemployment,'NA')::NUMERIC     AS unemployment
FROM stg_features f;
-- ---------------------------------------------------------
-- 5. Basic sanity checks
-- ---------------------------------------------------------

-- Count rows loaded
SELECT 'dim_store'      AS table, COUNT(*) FROM dim_store
UNION ALL
SELECT 'dim_department' AS table, COUNT(*) FROM dim_department
UNION ALL
SELECT 'fact_sales'     AS table, COUNT(*) FROM fact_sales
UNION ALL
SELECT 'fact_features'  AS table, COUNT(*) FROM fact_features;

-- Date ranges
SELECT
    MIN(date) AS min_date,
    MAX(date) AS max_date
FROM fact_sales;

-- Join coverage: how many sales rows have a matching feature row
SELECT
    COUNT(*)                                         AS total_sales_rows,
    COUNT(f2.*)                                      AS with_feature_row
FROM fact_sales s
LEFT JOIN fact_features f2
  ON s.store_id = f2.store_id
 AND s.date     = f2.date;
