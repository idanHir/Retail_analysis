SELECT f.store_id,
	   s.size,
	   AVG(f.weekly_sales) average_weekly_sales,
	   SUM(f.weekly_sales) total_sales
FROM fact_sales f
JOIN dim_store s ON f.store_id = s.store_id
GROUP BY f.store_id,
		 s.store_type,
		 s.size
ORDER BY total_sales DESC;

WITH monthly_sales AS (
	SELECT store_id,
	   DATE_TRUNC('month', date)::date AS month,
	   SUM(weekly_sales) monthly_sales
	FROM fact_sales
	GROUP BY store_id, month
)  
SELECT store_id,
	   AVG(monthly_sales) avg_monthly_sales,
	   STDDEV_SAMP(monthly_sales) stddev_monthly_sales
FROM monthly_sales
GROUP BY store_id
ORDER BY avg_monthly_sales DESC;

WITH sales_with_promo AS (
    SELECT
        s.store_id,
        s.dept_id,
        s.date,
        s.weekly_sales,
        CASE
            WHEN (COALESCE(f.markdown1, 0) > 0
               OR COALESCE(f.markdown2, 0) > 0
               OR COALESCE(f.markdown3, 0) > 0
               OR COALESCE(f.markdown4, 0) > 0
               OR COALESCE(f.markdown5, 0) > 0
               OR (s.is_holiday OR COALESCE(s.is_holiday, FALSE)))
            THEN TRUE
            ELSE FALSE
        END AS is_promo_week
    FROM fact_sales AS s
    LEFT JOIN fact_features AS f
      ON s.store_id = f.store_id
     AND s.date     = f.date
),
store_promo_stats AS (
    SELECT
        store_id,
        -- Promo weeks
        AVG(CASE WHEN is_promo_week THEN weekly_sales END) AS avg_promo_sales,
        -- Non‑promo weeks
        AVG(CASE WHEN NOT is_promo_week THEN weekly_sales END) AS avg_non_promo_sales
    FROM sales_with_promo
    GROUP BY store_id
)
SELECT
    store_id,
    avg_promo_sales,
    avg_non_promo_sales,
    (avg_promo_sales - avg_non_promo_sales) AS diff,
    CASE
        WHEN avg_non_promo_sales IS NULL OR avg_non_promo_sales = 0
            THEN NULL
        ELSE (avg_promo_sales - avg_non_promo_sales) / avg_non_promo_sales
    END AS pct_lift
FROM store_promo_stats
ORDER BY pct_lift DESC NULLS LAST;

WITH total_by_dept AS (
    SELECT
        dept_id,
        SUM(weekly_sales) AS total_sales
    FROM fact_sales
    GROUP BY dept_id
),
dept_with_decile AS (
    SELECT
        dept_id,
        total_sales,
        NTILE(10) OVER (ORDER BY total_sales DESC) AS sales_decile
    FROM total_by_dept
)
SELECT
    dept_id,
    total_sales
FROM dept_with_decile
WHERE sales_decile = 1
ORDER BY total_sales DESC;

WITH sales_with_period AS (
	SELECT
		store_id,
        date,
        weekly_sales,
		EXTRACT(YEAR FROM date) AS year,
		EXTRACT(QUARTER FROM date) AS quarter
	FROM fact_sales
), total_sale AS (
	SELECT store_id,
		   year,
	   	   quarter,
	       SUM(weekly_sales) total_sales
	FROM sales_with_period
	GROUP BY year, quarter, store_id
), ranking AS (
	SELECT store_id,
		   year,
		   quarter,
		   total_sales,
		   RANK() OVER (PARTITION BY year, quarter ORDER BY total_sales DESC) AS sales_rank
	FROM total_sale
)
SELECT store_id,
	   year,
	   quarter,
	   total_sales,
	   sales_rank
FROM ranking
WHERE sales_rank <= 3
ORDER BY year, quarter, sales_rank;

WITH store_weekly AS (
    SELECT
        store_id,
        date,
        SUM(weekly_sales) AS weekly_sales_store
    FROM fact_sales
    GROUP BY store_id, date
),
prev_week AS (
    SELECT
        store_id,
        date,
        weekly_sales_store,
        LAG(weekly_sales_store) OVER (
            PARTITION BY store_id
            ORDER BY date
        ) AS prev_week_sales
    FROM store_weekly
),
perc AS (
    SELECT
        store_id,
        date,
        weekly_sales_store,
        prev_week_sales,
        CASE
            WHEN prev_week_sales IS NULL OR prev_week_sales = 0
                THEN NULL
            ELSE (weekly_sales_store - prev_week_sales) / prev_week_sales
        END AS rev_perc
    FROM prev_week
)
SELECT
    store_id,
    date,
    weekly_sales_store AS weekly_sales,
    prev_week_sales,
    rev_perc
FROM perc
WHERE rev_perc < -0.2
ORDER BY store_id, date;

-- Store segmentation by size and promotion response

WITH size_tertiles AS (
    -- Global quartiles of store size
    SELECT
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY size) AS q1,
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY size) AS q2
    FROM dim_store
),

sales_with_segment AS (
    -- Attach size and size_segment to each store-week row
    SELECT
        f.store_id,
        f.date,
        f.weekly_sales,
        f.is_holiday,
        d.size,
        CASE
            WHEN d.size <  q.q1 THEN 'small'
            WHEN d.size <= q.q2 THEN 'medium'
            ELSE                    'large'
        END AS size_segment
    FROM fact_sales        AS f
    JOIN dim_store         AS d ON f.store_id = d.store_id
    CROSS JOIN size_tertiles AS q
),

sales_with_promo AS (
    -- Add a promo flag: any markdown > 0 OR holiday
    SELECT
        s.store_id,
        s.date,
        s.weekly_sales,
        s.is_holiday,
        s.size,
        s.size_segment,
        CASE
            WHEN s.is_holiday
                 OR COALESCE(f.markdown1, 0) > 0
                 OR COALESCE(f.markdown2, 0) > 0
                 OR COALESCE(f.markdown3, 0) > 0
                 OR COALESCE(f.markdown4, 0) > 0
                 OR COALESCE(f.markdown5, 0) > 0
            THEN TRUE
            ELSE FALSE
        END AS is_promo_week
    FROM sales_with_segment AS s
    LEFT JOIN fact_features AS f
      ON s.store_id = f.store_id
     AND s.date     = f.date
),

segment_promo_stats AS (
    -- Segment-level averages: promo vs non-promo weeks
    SELECT
        size_segment,
        AVG(CASE WHEN is_promo_week     THEN weekly_sales END) AS avg_promo_sales,
        AVG(CASE WHEN NOT is_promo_week THEN weekly_sales END) AS avg_non_promo_sales
    FROM sales_with_promo
    GROUP BY size_segment
)

SELECT
    size_segment,
    avg_promo_sales,
    avg_non_promo_sales,
    (avg_promo_sales - avg_non_promo_sales) AS diff,
    CASE
        WHEN avg_non_promo_sales IS NULL OR avg_non_promo_sales = 0
            THEN NULL
        ELSE (avg_promo_sales - avg_non_promo_sales) / avg_non_promo_sales
    END AS pct_lift
FROM segment_promo_stats
ORDER BY size_segment;


WITH sales_with_promo AS (
    -- Tag promo vs non-promo weeks
    SELECT
        s.store_id,
        s.date,
        s.weekly_sales,
        s.is_holiday,
        CASE
            WHEN s.is_holiday
                 OR COALESCE(f.markdown1, 0) > 0
                 OR COALESCE(f.markdown2, 0) > 0
                 OR COALESCE(f.markdown3, 0) > 0
                 OR COALESCE(f.markdown4, 0) > 0
                 OR COALESCE(f.markdown5, 0) > 0
            THEN TRUE
            ELSE FALSE
        END AS is_promo_week
    FROM fact_sales AS s
    LEFT JOIN fact_features AS f
      ON s.store_id = f.store_id
     AND s.date     = f.date
),

non_promo_medians AS (
    -- Per-store median weekly_sales over non-promo weeks
    SELECT
        store_id,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY weekly_sales) AS non_promo_median
    FROM sales_with_promo
    WHERE NOT is_promo_week
    GROUP BY store_id
)

SELECT
    s.store_id,
    s.date,
    s.weekly_sales,
    m.non_promo_median
FROM sales_with_promo AS s
JOIN non_promo_medians AS m
  ON s.store_id = m.store_id
WHERE
    s.is_promo_week
    AND s.weekly_sales < m.non_promo_median;


WITH store_weekly AS (
    SELECT
        store_id,
        date,
        SUM(weekly_sales) AS weekly_sales_store
    FROM fact_sales
    GROUP BY store_id, date
),

sales_with_features AS (
    SELECT
        sw.store_id,
        sw.date,
        sw.weekly_sales_store,
        f.cpi,
        f.unemployment
    FROM store_weekly AS sw
    JOIN fact_features AS f
      ON sw.store_id = f.store_id
     AND sw.date     = f.date
),

tertiles AS (
    SELECT
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY cpi)          AS cpi_q1,
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY cpi)          AS cpi_q2,
        PERCENTILE_CONT(0.33) WITHIN GROUP (ORDER BY unemployment) AS unemp_q1,
        PERCENTILE_CONT(0.66) WITHIN GROUP (ORDER BY unemployment) AS unemp_q2
    FROM sales_with_features
),

sales_buckets AS (
    SELECT
        s.store_id,
        s.date,
        s.weekly_sales_store,
        s.cpi,
        s.unemployment,
        CASE
            WHEN s.cpi <   e.cpi_q1 THEN 'low'
            WHEN s.cpi <= e.cpi_q2 THEN 'medium'
            ELSE                       'high'
        END AS cpi_bucket,
        CASE
            WHEN s.unemployment <  e.unemp_q1 THEN 'low'
            WHEN s.unemployment <= e.unemp_q2 THEN 'medium'
            ELSE                                 'high'
        END AS unemp_bucket
    FROM sales_with_features AS s
    CROSS JOIN tertiles AS e
),

cpi_unemp_grid AS (
    SELECT
        cpi_bucket,
        unemp_bucket,
        AVG(weekly_sales_store) AS avg_weekly_sales,
        COUNT(*)                AS weeks_count
    FROM sales_buckets
    GROUP BY
        cpi_bucket,
        unemp_bucket
)

SELECT
    cpi_bucket,
    unemp_bucket,
    avg_weekly_sales,
    weeks_count
FROM cpi_unemp_grid
ORDER BY
    cpi_bucket,
    unemp_bucket;


WITH store_sales AS (
    -- Per-store basic stats on weekly sales
    SELECT
        store_id,
        SUM(weekly_sales)              AS total_sales,
        AVG(weekly_sales)              AS avg_weekly_sales,
        STDDEV(weekly_sales)      	   AS volatility
    FROM fact_sales
    GROUP BY store_id
),

store_rank AS (
    -- Rank stores by total sales (1 = highest)
    SELECT
        store_id,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM store_sales
),

store_holiday_stats AS (
    -- Per-store average weekly sales: holiday vs non-holiday weeks
    SELECT
        store_id,
        AVG(CASE WHEN is_holiday THEN weekly_sales END)      AS avg_holiday_sales,
        AVG(CASE WHEN NOT is_holiday THEN weekly_sales END)  AS avg_non_holiday_sales
    FROM fact_sales
    GROUP BY store_id
),

store_summary AS (
    -- Combine all per-store metrics into one table
    SELECT
        ss.store_id,
        ss.total_sales,
        ss.avg_weekly_sales,
        ss.volatility,
        sr.sales_rank,
        shs.avg_holiday_sales,
        shs.avg_non_holiday_sales,
        (shs.avg_holiday_sales - shs.avg_non_holiday_sales) AS holiday_diff,
        CASE
            WHEN shs.avg_non_holiday_sales IS NULL
                 OR shs.avg_non_holiday_sales = 0
                THEN NULL
            ELSE (shs.avg_holiday_sales - shs.avg_non_holiday_sales)
                 / shs.avg_non_holiday_sales
        END AS holiday_pct_lift
    FROM store_sales        AS ss
    JOIN store_rank         AS sr  ON ss.store_id = sr.store_id
    LEFT JOIN store_holiday_stats AS shs ON ss.store_id = shs.store_id
)

SELECT
    store_id,
    ROUND(total_sales, 3) total_sales,
    ROUND(avg_weekly_sales, 3) avg_weekly_sales,
    ROUND(volatility, 3) volatility,
    sales_rank,
    ROUND(avg_holiday_sales, 3) avg_holiday_sales,
    ROUND(avg_non_holiday_sales, 3) avg_non_holiday_sales,
    ROUND(holiday_diff, 3) holiday_diff,
    ROUND(holiday_pct_lift, 3) holiday_pct_lift
FROM store_summary
ORDER BY sales_rank;