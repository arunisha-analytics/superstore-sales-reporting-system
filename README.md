# Automated Sales Reporting System (Excel → MySQL → Power BI)

An end-to-end reporting pipeline on the Superstore sales dataset (9,994 order lines, 2015–2018). Raw data is cleaned in Excel Power Query, stored and analysed in MySQL, visualised in Power BI, and summarised in an Excel MIS report.

**Flow:** Superstore CSV → Excel Power Query (clean) → MySQL (store and analyse) → Power BI dashboard + Excel MIS report

## Files in this repository

| File | Purpose |
|---|---|
| `Superstore_Sales_Reporting_System.xlsx` | Excel workbook: dashboard, MIS report, summary tables, clean data, data-quality log |
| `01_mysql_superstore.sql` | MySQL tables, validation checks, 3 reporting views, 14 analysis queries |
| `03_PowerQuery_M_Code.txt` | Power Query code for Orders, People and Returns |
| `Superstore_Sales_Reporting.pbix` | Power BI report (3 pages) |
| `Superstore_Sales_Reporting.pdf` | PDF export of the Power BI report |
| `clean_orders.csv`, `people.csv`, `returns.csv` | Cleaned data used in MySQL and Power BI |

## Step 1: Excel - clean and prepare
- The source CSV holds three tables stacked in one file (orders, people, returns). I split them into separate tables.
- Removed 1 exact duplicate order line (compared on every column except Row ID): 9,994 → 9,993 lines.
- Filled 11 blank Postal Codes (all Burlington, Vermont) and kept codes as 5-digit text.
- Reduced the returns list from 800 rows to 296 unique returned orders.
- Added data validation (dropdowns for Segment, Region, Category, Ship Mode; limits on Quantity, Discount, Sales).
- Added helper columns (year, month, ship days, margin, Returned?, Salesperson) using IF, MATCH and INDEX-MATCH. XLOOKUP versions are in the `Formula_Guide` sheet.
- Built 7 summary tables with SUMIFS / COUNTIFS / AVERAGEIFS and a live Data Quality Log.
- Built a dropdown-driven dashboard (KPIs and 5 charts) and a monthly MIS report with prior-year comparison.

## Step 2: MySQL - store and analyse
- Created typed tables with primary keys, indexes and CHECK constraints, and loaded the cleaned CSV files.
- Validation queries: row counts, ship date before order date, duplicates, orphan records.
- Three reporting views for Power BI: `vw_orders_enriched`, `vw_monthly_sales`, `vw_sales_by_region_category`.
- Analysis queries using JOINs, CTEs, GROUP BY / HAVING, CASE and window functions (LAG, RANK, ROW_NUMBER).

## Step 3: Power BI - visualise
- 3 report pages: Executive Overview, Products and Discounts, Customers and Geography.
- Date table, calculated columns (Returned, Salesperson, Discount Band) and 11 DAX measures.
- Slicers for year, region, category and segment.

## Key findings
1. **Overall:** $2.30M sales, $286K profit, 12.5% margin, 5,009 orders, average order value $458.56.
2. **Growth:** Sales rose from $484K (2015) to $733K (2018). 2018 grew 20.4% over 2017.
3. **Furniture is the weak spot:** its margin is 2.5% against 17.0% for Office Supplies and 17.4% for Technology.
4. **Three sub-categories lose money:** Tables (-$17.7K), Bookcases (-$3.5K) and Supplies (-$1.2K).
5. **Discounts above 20% destroy profit:** no discount earns a 29.5% margin, while 21-30% discounts run at -10.1%, 31-50% at -24.8%, and over 50% at -119.2%.
6. **Returns:** 296 of 5,009 orders (5.9%) were returned.

**Recommendation:** cap discounts at 20% and review pricing on Tables and Bookcases.

## Skills demonstrated
Excel (Power Query, data validation, SUMIFS, INDEX-MATCH, XLOOKUP, MIS reporting) · SQL (MySQL, joins, CTEs, window functions, views) · Power BI (data model, DAX, slicers, dashboards) · data cleaning and validation.

*Data source: Sample Superstore dataset (public sample data).*
