DROP TABLE IF EXISTS fact_features;
DROP TABLE IF EXISTS fact_sales;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_department;

CREATE TABLE dim_store (
	store_id INT PRIMARY KEY,
	store_type VARCHAR(50),
	size INT
);

CREATE TABLE dim_department (
	dept_id INT PRIMARY KEY,
	dept_name VARCHAR(50)
);

CREATE TABLE fact_sales (
	store_id INT,
	dept_id INT,
	FOREIGN KEY (store_id) REFERENCES dim_store(store_id),
	FOREIGN KEY (dept_id) REFERENCES dim_department(dept_id),
	date DATE,
	weekly_sales NUMERIC,
	is_holiday BOOLEAN
);

CREATE TABLE fact_features (
	store_id INT,
	date DATE,
	temperature NUMERIC,
	fuel_price NUMERIC,
	markdown1 NUMERIC,
	markdown2 NUMERIC,
	markdown3 NUMERIC,
	markdown4 NUMERIC,
	markdown5 NUMERIC,
	cpi NUMERIC,
	unemployment NUMERIC
);