-- =====================================================================
-- Customer Transactions Analysis (MySQL 8)
-- Period of analysis: 01.06.2015 - 01.06.2016
-- Tables: customer_final (client profile), Transactions (purchases)
-- =====================================================================

CREATE DATABASE final_project;

-- ---------------------------------------------------------------------
-- Data preparation
-- ---------------------------------------------------------------------

-- customer_final was imported via the Table Data Import Wizard.
-- Empty strings are replaced with NULL so missing values are handled correctly.
UPDATE customer_final SET Gender = NULL WHERE Gender = '';
UPDATE customer_final SET Age = NULL WHERE Age = '';
ALTER TABLE customer_final MODIFY Age INT NULL;

-- Transactions table is created manually and loaded from CSV
DROP TABLE IF EXISTS Transactions;

CREATE TABLE Transactions (
    date_new       DATE,
    Id_check       INT,
    ID_client      INT,
    Count_products DECIMAL(10,3),
    Sum_payment    DECIMAL(10,2)
);

LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\transactions_final.csv"
INTO TABLE Transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


-- =====================================================================
-- Task 1. Clients with a continuous history: purchases in each of the
-- 12 months of the period. Average check, average monthly spend and
-- number of transactions per client.
-- =====================================================================
WITH MonthlyActivity AS (
    SELECT
        ID_client,
        DATE_FORMAT(date_new, '%Y-%m') AS month
    FROM Transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
    GROUP BY ID_client, month
),
FullYearClients AS (
    SELECT ID_client
    FROM MonthlyActivity
    GROUP BY ID_client
    HAVING COUNT(DISTINCT month) = 12
)
SELECT
    t.ID_client,
    ROUND(AVG(t.Sum_payment), 2)    AS avg_check,
    ROUND(SUM(t.Sum_payment) / 12, 2) AS avg_monthly_sum,
    COUNT(*)                        AS total_transactions
FROM Transactions t
JOIN FullYearClients f ON t.ID_client = f.ID_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY t.ID_client
ORDER BY t.ID_client;


-- =====================================================================
-- Task 2. Monthly metrics
-- =====================================================================

-- 2a. Average check per month
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    ROUND(AVG(Sum_payment), 2)     AS avg_check_per_month
FROM Transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month
ORDER BY month;

-- 2b. Number of operations per month
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(*)                       AS total_operations
FROM Transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month
ORDER BY month;

-- 2c. Average number of operations per month
SELECT
    ROUND(COUNT(*) / COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')), 2) AS avg_operations_per_month
FROM Transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01';

-- 2d. Unique clients per month
SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month,
    COUNT(DISTINCT ID_client)      AS unique_clients
FROM Transactions
WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
GROUP BY month
ORDER BY month;

-- 2e. Average number of clients per month
SELECT
    ROUND(SUM(monthly_clients) / COUNT(*), 2) AS avg_clients_per_month
FROM (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(DISTINCT ID_client)      AS monthly_clients
    FROM Transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
    GROUP BY month
) AS MonthlyClients;

-- 2f. Each month's share of annual operations and revenue
WITH MonthlyStats AS (
    SELECT
        DATE_FORMAT(date_new, '%Y-%m') AS month,
        COUNT(*)                       AS operations,
        SUM(Sum_payment)               AS total_sum
    FROM Transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
    GROUP BY month
),
TotalStats AS (
    SELECT
        COUNT(*)         AS total_operations,
        SUM(Sum_payment) AS total_sum
    FROM Transactions
    WHERE date_new >= '2015-06-01' AND date_new < '2016-06-01'
)
SELECT
    m.month,
    m.operations,
    m.total_sum,
    ROUND(m.operations / t.total_operations * 100, 2) AS operation_share_percent,
    ROUND(m.total_sum / t.total_sum * 100, 2)         AS sum_share_percent
FROM MonthlyStats m
CROSS JOIN TotalStats t
ORDER BY m.month;

-- 2g. Gender split (M / F / NA) of operations and revenue by month
SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month,
    COALESCE(c.Gender, 'NA')         AS gender,
    COUNT(*)                         AS operations,
    ROUND(COUNT(*) * 100.0
          / SUM(COUNT(*)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')), 2) AS operation_percent,
    ROUND(SUM(t.Sum_payment), 2)     AS total_payment,
    ROUND(SUM(t.Sum_payment) * 100.0
          / SUM(SUM(t.Sum_payment)) OVER (PARTITION BY DATE_FORMAT(t.date_new, '%Y-%m')), 2) AS payment_percent
FROM Transactions t
JOIN customer_final c ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01' AND t.date_new < '2016-06-01'
GROUP BY month, gender
ORDER BY month, gender;


-- =====================================================================
-- Task 3. Age groups (10-year step, separate NA group)
-- =====================================================================

-- 3a. Total operations and revenue by age group for the whole period
WITH ClientAgeGroups AS (
    SELECT
        Id_client,
        CASE
            WHEN Age IS NULL THEN 'NA'
            WHEN Age < 10 THEN '0-9'
            WHEN Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN Age BETWEEN 60 AND 69 THEN '60-69'
            WHEN Age BETWEEN 70 AND 79 THEN '70-79'
            WHEN Age BETWEEN 80 AND 89 THEN '80-89'
            ELSE '90+'
        END AS age_group
    FROM customer_final
)
SELECT
    ag.age_group,
    COUNT(*)                     AS total_transactions,
    ROUND(SUM(t.Sum_payment), 2) AS total_payment
FROM Transactions t
JOIN ClientAgeGroups ag ON t.ID_client = ag.Id_client
GROUP BY ag.age_group
ORDER BY ag.age_group;

-- 3b. Quarterly metrics by age group: average payment and share of
--     operations and revenue within each quarter
WITH ClientAgeGroups AS (
    SELECT
        Id_client,
        CASE
            WHEN Age IS NULL THEN 'NA'
            WHEN Age < 10 THEN '0-9'
            WHEN Age BETWEEN 10 AND 19 THEN '10-19'
            WHEN Age BETWEEN 20 AND 29 THEN '20-29'
            WHEN Age BETWEEN 30 AND 39 THEN '30-39'
            WHEN Age BETWEEN 40 AND 49 THEN '40-49'
            WHEN Age BETWEEN 50 AND 59 THEN '50-59'
            WHEN Age BETWEEN 60 AND 69 THEN '60-69'
            WHEN Age BETWEEN 70 AND 79 THEN '70-79'
            WHEN Age BETWEEN 80 AND 89 THEN '80-89'
            ELSE '90+'
        END AS age_group
    FROM customer_final
),
TxWithAgeGroup AS (
    SELECT
        t.*,
        ag.age_group,
        CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS year_quarter
    FROM Transactions t
    JOIN ClientAgeGroups ag ON t.ID_client = ag.Id_client
),
QuarterStats AS (
    SELECT
        age_group,
        year_quarter,
        COUNT(*)                   AS transaction_count,
        ROUND(AVG(Sum_payment), 2) AS avg_payment,
        SUM(Sum_payment)           AS total_payment
    FROM TxWithAgeGroup
    GROUP BY age_group, year_quarter
),
TotalPerQuarter AS (
    SELECT
        year_quarter,
        SUM(transaction_count) AS total_tx,
        SUM(total_payment)     AS total_pay
    FROM QuarterStats
    GROUP BY year_quarter
)
SELECT
    q.age_group,
    q.year_quarter,
    q.transaction_count,
    q.avg_payment,
    ROUND(q.total_payment, 2)                         AS group_payment,
    ROUND(q.transaction_count * 100.0 / t.total_tx, 2) AS tx_percent,
    ROUND(q.total_payment * 100.0 / t.total_pay, 2)    AS payment_percent
FROM QuarterStats q
JOIN TotalPerQuarter t ON q.year_quarter = t.year_quarter
ORDER BY q.year_quarter, q.age_group;
