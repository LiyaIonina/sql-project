# Customer Transactions Analysis (SQL)

Analysis of customer purchase transactions for June 2015 – June 2016 in MySQL: client retention, monthly activity and behavior by gender and age group.

**Tools:** MySQL 8, MySQL Workbench

## Data

- `customer_final`: client profiles (ID, gender, age and other attributes)
- `Transactions`: purchase transactions (date, check ID, client ID, number of products, payment amount), loaded from CSV with `LOAD DATA INFILE`

## Data preparation

- Replaced empty strings in `Gender` and `Age` with `NULL` and converted `Age` to `INT`, so that missing values are handled correctly
- Created the `Transactions` table with explicit data types and loaded the raw CSV into it

## Tasks

### 1. Clients with a continuous purchase history
Found clients who made purchases in **each of the 12 months** of the period and calculated for each of them the average check, average monthly spend and total number of transactions.

### 2. Monthly metrics
For each month of the period:
- average check
- number of operations and average number of operations per month
- number of unique clients and average number of clients per month
- each month's share of annual operations and revenue
- split of operations and revenue by gender (M / F / NA)

### 3. Age groups
Grouped clients by age in 10-year steps with a separate group for missing age, then calculated:
- total number of operations and revenue for each group over the whole period
- quarterly average payment and each group's share of operations and revenue within the quarter

## SQL techniques used

- CTEs (`WITH`) to break complex queries into readable steps
- Window functions: `SUM(...) OVER (PARTITION BY ...)` for shares within a month
- `CASE` for segmentation, `COALESCE` for missing values
- Date functions: `DATE_FORMAT`, `QUARTER`, `YEAR`
- Aggregation with `GROUP BY` / `HAVING`, `COUNT(DISTINCT ...)`
- Data cleaning with `UPDATE` and `ALTER TABLE`, loading data with `LOAD DATA INFILE`

## Files

- `customer_transactions_analysis.sql`: full script, from data preparation to all analysis queries
