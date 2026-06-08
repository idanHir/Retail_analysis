# Retail Sales SQL Case Study and Dashboard

This project is a retail analytics case study built to demonstrate **SQL problem-solving**, metric design, and the ability to translate query outputs into a simple business dashboard. The main focus of the project is the SQL analysis: writing queries that answer business questions about store performance, seasonality, promotions, holidays, and macroeconomic conditions, then using Python and Streamlit to present those results interactively. [cite:310][cite:315]

The repository combines two layers:
- A SQL layer that produces the analytical outputs.
- A Streamlit dashboard layer that visualizes those outputs for easier interpretation. [cite:314][cite:316]

## Project goal

The primary goal of this project is to showcase SQL skills in a practical business setting. The dashboard is included to make the SQL results easier to communicate, but the central deliverable is the analytical thinking behind the queries: defining the right aggregations, comparisons, segments, and KPIs to answer real retail questions. [cite:310][cite:315]

From a portfolio perspective, this project highlights:
- Writing analytical SQL queries against retail data.
- Using grouping, aggregation, filtering, ranking, and comparative logic.
- Translating business questions into measurable outputs.
- Turning query results into a lightweight decision-support dashboard. [cite:311][cite:317]

## Business context

The dataset represents a retail chain operating across multiple stores, with weekly sales influenced by promotions, holidays, and external macroeconomic factors. The analysis aims to understand which stores perform best, how sales evolve over time, how store size affects holiday uplift, and whether macro conditions such as CPI and unemployment are associated with different sales environments. [cite:295][cite:296]

The project is designed like a real analytics assignment: start from a set of business questions, answer them in SQL, export clean analytical tables, and then build a presentation layer on top of those outputs. [cite:304][cite:321]

## Repository contents

Typical files in this repository include:

- `retail_dashboard.py` — Streamlit application that reads CSV outputs from the SQL queries and renders the dashboard.
- SQL script file(s) — queries used to answer the business questions and create the exported result tables.
- CSV output files — query results used by the dashboard.
- `README.md` — project documentation and usage guide.
- `requirements.txt` — Python dependencies for the dashboard, if included. [cite:314][cite:317]

An example structure could look like this:

```text
.
├── README.md
├── retail_dashboard.py
├── requirements.txt
├── sql/
│   └── retail_case_study.sql
└── outputs/
    ├── q2_monthly_sales.csv
    ├── q5_top_stores_quarter.csv
    ├── q7_size_segment_impact.csv
    ├── q9_macro_grid.csv
    └── q10_store_summary.csv
```

## Tools and technologies

This project uses:
- SQL for the main analytical work and metric generation.
- PostgreSQL (or another relational SQL engine, depending on your environment) for querying the retail dataset.
- Python for reading query outputs and supporting the dashboard.
- Streamlit for the front-end dashboard.
- Pandas and Plotly for data transformation and visualization inside the app. [cite:304][cite:309]

## SQL-first workflow

The analytical workflow for this project is intentionally SQL-first:

1. Define the business question.
2. Write a SQL query that answers it clearly and reproducibly.
3. Export the query result as a clean table or CSV.
4. Use the exported result in the dashboard.
5. Add business interpretation on top of the result. [cite:310][cite:315]

This means the dashboard does not replace the SQL work. It depends on it. Every visual in the app is based on a query output that was intentionally designed to answer a specific analytical question. [cite:314][cite:317]

## Business questions answered in SQL

The project is organized around several business questions. Each one is first solved in SQL and then surfaced in the dashboard.

### Q2: How do store sales change over time?

This query aggregates sales at the monthly level by store, making it possible to compare store-level trends and seasonality over time. It helps identify stores with stable growth, declining performance, or stronger seasonal patterns. [cite:296][cite:304]

**Expected output columns**
- `store_id`
- `month`
- `monthly_sales`

**SQL skills demonstrated**
- Date transformation and truncation.
- Grouping by store and time period.
- Aggregation using `SUM`.
- Producing time-series outputs ready for visualization. [cite:311][cite:321]

### Q5: Which stores are the top performers in each quarter?

This query ranks stores by total sales within a selected quarter, allowing comparison of top-performing stores over time. It shows understanding of ranking logic and business-oriented performance measurement. [cite:297][cite:302]

**Expected output columns**
- `store_id`
- `year`
- `quarter`
- `total_sales`
- `rank`

**SQL skills demonstrated**
- Quarterly aggregation.
- Window functions such as `RANK()` or `DENSE_RANK()`.
- Partitioning by time period.
- Sorting and top-N analysis. [cite:311][cite:315]

### Q7: How do holidays or promotional periods affect stores of different sizes?

This query compares average sales during holiday or promo periods against non-holiday or non-promo periods, grouped by store size segment. This question is especially useful because it goes beyond raw totals and asks whether the impact of promotions differs structurally across store types. [cite:296][cite:299]

**Expected output columns**
- `size_segment`
- `avg_promo_sales`
- `avg_non_promo_sales`
- `diff`
- `pct_lift`

**SQL skills demonstrated**
- Conditional aggregation.
- Case-based segmentation into size bins.
- Comparative KPI design.
- Business interpretation of uplift metrics. [cite:297][cite:307]

### Q9: How do macroeconomic conditions relate to store sales?

This query groups stores into CPI and unemployment buckets and calculates average weekly sales for each macro environment. Rather than testing a formal statistical correlation, it provides a business-friendly view of how stores perform under different combinations of inflation and labor-market conditions. [cite:296][cite:305]

**Expected output columns**
- `cpi_bucket`
- `unemp_bucket`
- `avg_weekly_sales`

**SQL skills demonstrated**
- Bucketing continuous variables into business-friendly categories.
- Multi-dimensional grouping.
- Aggregation across environmental segments.
- Creating outputs designed for matrix or heatmap visualization. [cite:297][cite:321]

### Q10: Which stores perform best overall, and how volatile are they?

This query creates an executive summary table at the store level, combining total sales, average weekly sales, variability, and holiday-related performance. It is useful as a final KPI table because it brings multiple performance dimensions into one output. [cite:295][cite:302]

**Expected output columns**
- `store_id`
- `total_sales`
- `avg_weekly_sales`
- `volatility`
- `sales_rank`
- `avg_holiday_sales`
- `avg_non_holiday_sales`
- `holiday_diff`
- `holiday_pct_lift`

**SQL skills demonstrated**
- Multi-metric aggregation.
- Ranking and KPI design.
- Statistical summary logic such as variation or standard deviation.
- Combining descriptive and comparative store metrics in one table. [cite:297][cite:307]

## What the SQL work demonstrates

This project is meant to showcase more than syntax. It demonstrates how SQL can be used to structure business thinking. In particular, the SQL layer shows the ability to: [cite:310][cite:315]

- Convert business questions into measurable definitions.
- Choose the right grain for analysis, such as weekly, monthly, quarterly, or segmented by store type.
- Build KPIs that are meaningful to decision-makers, not just technically correct.
- Use ranking, bucketing, conditional logic, and aggregations to produce decision-ready outputs. [cite:311][cite:321]

## Dashboard overview

The Streamlit dashboard is a presentation layer built on top of the SQL outputs. Its role is to help a reviewer or interviewer explore the results quickly and understand the business implications of each query. [cite:300][cite:309]

The dashboard includes:
- A monthly sales trend chart from Q2.
- A top-stores-by-quarter view from Q5.
- A holiday or promo impact by size-segment view from Q7.
- A CPI/unemployment heatmap from Q9.
- A store summary KPI table from Q10. [cite:295][cite:314]

## How the dashboard supports the SQL story

Each chart in the dashboard is directly tied to a SQL output. This is important because the dashboard is not intended to hide the analytical work behind visuals; instead, it helps communicate the output of the queries more clearly. [cite:310][cite:317]

For example:
- The Q2 chart visualizes monthly aggregation logic.
- The Q5 bar chart visualizes ranking logic.
- The Q7 comparison chart visualizes conditional aggregation and segmentation.
- The Q9 heatmap visualizes bucketing and grouped aggregation.
- The Q10 table visualizes multi-KPI summarization. [cite:314][cite:321]

## Expected input files for the dashboard

The dashboard expects CSV files exported from the SQL queries. A typical set of outputs is:

| File | Purpose |
|------|---------|
| `q2_monthly_sales.csv` | Monthly sales trend by store |
| `q5_top_stores_quarter.csv` | Top-performing stores by quarter |
| `q7_size_segment_impact.csv` | Holiday or promo effect by store size segment |
| `q9_macro_grid.csv` | Average weekly sales by CPI and unemployment bucket |
| `q10_store_summary.csv` | Store-level KPI summary table |

These files are generated from the SQL layer and then consumed by the dashboard. [cite:314][cite:317]

## How to run the project

### Prerequisites

- Python 3.10 or later.
- Access to the SQL scripts and exported CSV outputs.
- Installed Python packages such as `streamlit`, `pandas`, and `plotly`. [cite:300][cite:309]

### Installation

```bash
pip install -r requirements.txt
```

If there is no `requirements.txt`, install the core packages manually:

```bash
pip install streamlit pandas plotly
```

### Run the dashboard

```bash
streamlit run retail_dashboard.py
```

After launching the app, point it to the folder containing the exported CSV files. [cite:300][cite:303]

## Suggested SQL script organization

To make the SQL work easy to review, it helps to organize the SQL file with clearly labeled sections for each business question. For example: [cite:313][cite:315]

```sql
-- Q2: Monthly sales by store

-- Q5: Top stores by quarter

-- Q7: Holiday/promo uplift by size segment

-- Q9: Macro grid by CPI and unemployment bucket

-- Q10: Store summary KPIs
```

This structure makes it easier for an interviewer to scan the project and understand the reasoning behind each query. [cite:310][cite:323]

## What to highlight in an interview

This project is strongest when discussed as a SQL case study with a dashboard on top. A good way to frame it is:

- The core challenge was defining the right SQL outputs for each business question.
- The dashboard was built only after the outputs were designed and validated.
- The value of the project is not just that it looks good, but that each visual comes from a deliberate SQL decision. [cite:310][cite:315]

A concise interview message could be:

> This project was built to demonstrate SQL skills in a realistic retail setting. The dashboard is there to make the query outputs easier to explore, but the key work was designing the SQL logic behind trend analysis, ranking, segmentation, uplift measurement, and macro-based grouping. [cite:310][cite:323]

## Limitations

This project has a few natural limitations:

- The dashboard is based on exported CSVs rather than a live database connection.
- The macro analysis in Q9 is descriptive and bucket-based, not a formal regression model.
- The insights are only as strong as the assumptions used in the segmentation and metric definitions.
- The dashboard is intentionally lightweight because the primary focus is the SQL layer. [cite:305][cite:317]

## Possible next steps

If this project were extended further, useful next steps would include:

- Connecting the dashboard directly to the database.
- Adding the raw SQL files in a dedicated `sql/` folder.
- Including a data dictionary for all source tables.
- Adding query comments and performance notes.
- Extending Q9 with regression or correlation analysis in Python.
- Deploying the Streamlit app publicly for easier review. [cite:316][cite:319]

## Summary

This repository is a SQL-centered retail analytics project supported by a simple dashboard. The main objective is to show the ability to answer business questions with SQL, structure meaningful analytical outputs, and communicate those outputs clearly through an interactive interface. [cite:310][cite:317]
