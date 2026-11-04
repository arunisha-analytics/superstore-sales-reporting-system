/* ============================================================================
   AUTOMATED SALES REPORTING SYSTEM  -  STEP 2: SQL (MySQL 8.0+)
   Dataset : Sample Superstore (cleaned in Excel / Power Query in Step 1)
   Input   : clean_orders.csv, people.csv, returns.csv  (provided with the project)
   Output  : tables + reporting views that Power BI connects to in Step 3
   Run     : MySQL Workbench -> open this file -> run section by section
   ========================================================================= */

/* ---------------------------------------------------------------------------
   SECTION 1 - DATABASE AND TABLES
   --------------------------------------------------------------------------- */
CREATE DATABASE IF NOT EXISTS superstore_db;
USE superstore_db;

DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS people;
DROP TABLE IF EXISTS returns;

CREATE TABLE orders (
    row_id        INT            NOT NULL,
    order_id      VARCHAR(20)    NOT NULL,
    order_date    DATE           NOT NULL,
    ship_date     DATE           NOT NULL,
    ship_mode     VARCHAR(20)    NOT NULL,
    customer_id   VARCHAR(15)    NOT NULL,
    customer_name VARCHAR(60)    NOT NULL,
    segment       VARCHAR(20)    NOT NULL,
    country       VARCHAR(30)    NOT NULL,
    city          VARCHAR(40)    NOT NULL,
    state         VARCHAR(40)    NOT NULL,
    postal_code   CHAR(5)        NOT NULL,
    region        VARCHAR(15)    NOT NULL,
    product_id    VARCHAR(20)    NOT NULL,
    category      VARCHAR(20)    NOT NULL,
    sub_category  VARCHAR(20)    NOT NULL,
    product_name  VARCHAR(200)   NOT NULL,
    sales         DECIMAL(12,4)  NOT NULL,
    quantity      INT            NOT NULL,
    discount      DECIMAL(4,2)   NOT NULL,
    profit        DECIMAL(12,4)  NOT NULL,
    PRIMARY KEY (row_id),
    INDEX idx_order_id   (order_id),
    INDEX idx_order_date (order_date),
    INDEX idx_region     (region),
    INDEX idx_customer   (customer_id),
    CONSTRAINT chk_qty  CHECK (quantity >= 1),
    CONSTRAINT chk_disc CHECK (discount BETWEEN 0 AND 1)
);

CREATE TABLE people (
    salesperson VARCHAR(50) NOT NULL,
    region      VARCHAR(15) NOT NULL,
    PRIMARY KEY (region)
);

CREATE TABLE returns (
    order_id VARCHAR(20) NOT NULL,
    returned CHAR(3)     NOT NULL DEFAULT 'Yes',
    PRIMARY KEY (order_id)
);

/* ---------------------------------------------------------------------------
   SECTION 2 - LOAD THE CSV FILES
   Option A (easiest): MySQL Workbench -> right-click table -> Table Data Import Wizard
   Option B (script) : needs local_infile enabled:  SET GLOBAL local_infile = 1;
                       and the connection option  OPT_LOCAL_INFILE=1
   Change the paths below to where you saved the files (use forward slashes).
   --------------------------------------------------------------------------- */
LOAD DATA LOCAL INFILE 'C:/superstore/clean_orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/superstore/people.csv'
INTO TABLE people
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/superstore/returns.csv'
INTO TABLE returns
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES (order_id, returned);

/* ---------------------------------------------------------------------------
   SECTION 3 - DATA VALIDATION CHECKS (run after loading)
   Expected: 9993 orders rows, 4 people rows, 296 returns rows, every other check = 0
   --------------------------------------------------------------------------- */
SELECT 'orders rows'  AS check_name, COUNT(*) AS result FROM orders
UNION ALL SELECT 'people rows',  COUNT(*) FROM people
UNION ALL SELECT 'returns rows', COUNT(*) FROM returns
UNION ALL SELECT 'ship before order', COUNT(*) FROM orders WHERE ship_date < order_date
UNION ALL SELECT 'orders without region match in people',
             COUNT(*) FROM orders o LEFT JOIN people p ON o.region = p.region WHERE p.region IS NULL
UNION ALL SELECT 'duplicate lines (all columns except row_id)', COUNT(*) FROM (
             SELECT order_id, product_id, sales, quantity, discount, profit
             FROM orders GROUP BY order_id, product_id, sales, quantity, discount, profit, order_date, customer_id
             HAVING COUNT(*) > 1) d
UNION ALL SELECT 'returned order ids not found in orders',
             COUNT(*) FROM returns r LEFT JOIN orders o ON r.order_id = o.order_id WHERE o.order_id IS NULL;
/* ---------------------------------------------------------------------------
   SECTION 4 - REPORTING VIEWS (Power BI connects to these)
   --------------------------------------------------------------------------- */
CREATE OR REPLACE VIEW vw_orders_enriched AS
SELECT  o.*,
        YEAR(o.order_date)                          AS order_year,
        MONTH(o.order_date)                         AS order_month,
        DATEDIFF(o.ship_date, o.order_date)         AS ship_days,
        CASE WHEN o.sales = 0 THEN 0 ELSE o.profit / o.sales END AS profit_margin,
        p.salesperson,
        CASE WHEN r.order_id IS NULL THEN 'No' ELSE 'Yes' END   AS returned
FROM    orders o
JOIN    people  p ON p.region   = o.region
LEFT JOIN returns r ON r.order_id = o.order_id;

CREATE OR REPLACE VIEW vw_monthly_sales AS
SELECT  order_year,
        order_month,
        ROUND(SUM(sales), 2)                        AS sales,
        ROUND(SUM(profit), 2)                       AS profit,
        ROUND(SUM(profit) / SUM(sales), 4)          AS profit_margin,
        COUNT(DISTINCT order_id)                    AS orders,
        SUM(quantity)                               AS units
FROM    vw_orders_enriched
GROUP BY order_year, order_month;

CREATE OR REPLACE VIEW vw_sales_by_region_category AS
SELECT  order_year, region, category, segment,
        ROUND(SUM(sales), 2)  AS sales,
        ROUND(SUM(profit), 2) AS profit,
        COUNT(DISTINCT order_id) AS orders
FROM    vw_orders_enriched
GROUP BY order_year, region, category, segment;

/* ---------------------------------------------------------------------------
   SECTION 5 - ANALYSIS QUERIES
   --------------------------------------------------------------------------- */

-- Q1. Headline KPIs
SELECT  ROUND(SUM(sales), 2)                         AS total_sales,
        ROUND(SUM(profit), 2)                        AS total_profit,
        ROUND(SUM(profit) / SUM(sales) * 100, 1)     AS profit_margin_pct,
        COUNT(DISTINCT order_id)                     AS total_orders,
        SUM(quantity)                                AS units_sold,
        ROUND(SUM(sales) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM    orders;

-- Q2. Sales and profit by year with year-over-year growth (LAG window function)
WITH yearly AS (
    SELECT order_year, SUM(sales) AS sales, SUM(profit) AS profit
    FROM vw_orders_enriched GROUP BY order_year
)
SELECT  order_year,
        ROUND(sales, 2)  AS sales,
        ROUND(profit, 2) AS profit,
        ROUND((sales  / LAG(sales)  OVER (ORDER BY order_year) - 1) * 100, 1) AS sales_yoy_pct,
        ROUND((profit / LAG(profit) OVER (ORDER BY order_year) - 1) * 100, 1) AS profit_yoy_pct
FROM    yearly
ORDER BY order_year;

-- Q3. Region performance with salesperson
SELECT  region, salesperson,
        ROUND(SUM(sales), 2)  AS sales,
        ROUND(SUM(profit), 2) AS profit,
        ROUND(SUM(profit) / SUM(sales) * 100, 1) AS margin_pct
FROM    vw_orders_enriched
GROUP BY region, salesperson
ORDER BY profit DESC;

-- Q4. Category and sub-category profitability, ranked
SELECT  category, sub_category,
        ROUND(SUM(sales), 2)  AS sales,
        ROUND(SUM(profit), 2) AS profit,
        ROUND(SUM(profit) / SUM(sales) * 100, 1) AS margin_pct,
        RANK() OVER (ORDER BY SUM(profit) DESC)  AS profit_rank
FROM    orders
GROUP BY category, sub_category
ORDER BY profit_rank;

-- Q5. Loss-making sub-categories
SELECT  sub_category, ROUND(SUM(profit), 2) AS profit
FROM    orders
GROUP BY sub_category
HAVING  SUM(profit) < 0
ORDER BY profit;

-- Q6. Monthly sales with month-over-month change and running total within each year
SELECT  order_year, order_month, sales,
        ROUND((sales / LAG(sales) OVER (ORDER BY order_year, order_month) - 1) * 100, 1) AS mom_pct,
        ROUND(SUM(sales) OVER (PARTITION BY order_year ORDER BY order_month), 2)         AS ytd_sales
FROM    vw_monthly_sales
ORDER BY order_year, order_month;

-- Q7. Discount bands vs profitability (shows heavy discounts destroy margin)
SELECT  CASE WHEN discount = 0    THEN '1. No discount'
             WHEN discount <= 0.1 THEN '2. Up to 10%'
             WHEN discount <= 0.2 THEN '3. 11-20%'
             WHEN discount <= 0.3 THEN '4. 21-30%'
             WHEN discount <= 0.5 THEN '5. 31-50%'
             ELSE                      '6. Over 50%' END AS discount_band,
        COUNT(*)                      AS order_lines,
        ROUND(SUM(sales), 2)          AS sales,
        ROUND(SUM(profit), 2)         AS profit,
        ROUND(SUM(profit) / SUM(sales) * 100, 1) AS margin_pct
FROM    orders
GROUP BY discount_band
ORDER BY discount_band;

-- Q8. Top 10 customers by sales
SELECT  customer_id, customer_name, segment,
        ROUND(SUM(sales), 2)  AS sales,
        ROUND(SUM(profit), 2) AS profit,
        COUNT(DISTINCT order_id) AS orders
FROM    orders
GROUP BY customer_id, customer_name, segment
ORDER BY sales DESC
LIMIT 10;

-- Q9. Top 3 products by profit inside each category (ROW_NUMBER + PARTITION BY)
SELECT category, product_name, product_profit, rn
FROM (
    SELECT  category, product_name,
            ROUND(SUM(profit), 2) AS product_profit,
            ROW_NUMBER() OVER (PARTITION BY category ORDER BY SUM(profit) DESC) AS rn
    FROM    orders
    GROUP BY category, product_name
) ranked
WHERE rn <= 3
ORDER BY category, rn;

-- Q10. Returns analysis by category
SELECT  category,
        COUNT(DISTINCT order_id)                                        AS orders,
        COUNT(DISTINCT CASE WHEN returned = 'Yes' THEN order_id END)    AS returned_orders,
        ROUND(COUNT(DISTINCT CASE WHEN returned = 'Yes' THEN order_id END)
              / COUNT(DISTINCT order_id) * 100, 1)                      AS return_rate_pct
FROM    vw_orders_enriched
GROUP BY category
ORDER BY return_rate_pct DESC;

-- Q11. Shipping performance
SELECT  ship_mode,
        COUNT(*)                   AS order_lines,
        ROUND(AVG(ship_days), 1)   AS avg_ship_days
FROM    vw_orders_enriched
GROUP BY ship_mode
ORDER BY avg_ship_days;

-- Q12. Top 10 states by sales with share of total
SELECT  state,
        ROUND(SUM(sales), 2) AS sales,
        ROUND(SUM(sales) / (SELECT SUM(sales) FROM orders) * 100, 1) AS share_pct
FROM    orders
GROUP BY state
ORDER BY sales DESC
LIMIT 10;

-- Q13. Customers who bought in more than one year (retention view)
SELECT  customer_id, customer_name, COUNT(DISTINCT order_year) AS active_years
FROM    vw_orders_enriched
GROUP BY customer_id, customer_name
HAVING  COUNT(DISTINCT order_year) >= 3
ORDER BY active_years DESC, customer_name
LIMIT 20;

-- Q14. Best month for each year
SELECT order_year, order_month, sales
FROM (
    SELECT  order_year, order_month, sales,
            RANK() OVER (PARTITION BY order_year ORDER BY sales DESC) AS rk
    FROM    vw_monthly_sales
) t
WHERE rk = 1
ORDER BY order_year;

/* ---------------------------------------------------------------------------
   SECTION 6 - DUPLICATE CLEAN-UP (use if you load the RAW csv instead)
   Keeps the lowest row_id of each exact duplicate (ignoring row_id). MySQL 8.0+.
   --------------------------------------------------------------------------- */
DELETE FROM orders
WHERE row_id IN (
    SELECT row_id FROM (
        SELECT row_id,
               ROW_NUMBER() OVER (
                   PARTITION BY order_id, order_date, ship_date, ship_mode, customer_id, product_id,
                                sales, quantity, discount, profit
                   ORDER BY row_id) AS rn
        FROM orders) x
    WHERE rn > 1);
    SELECT COUNT(*) FROM superstore_db.orders;
