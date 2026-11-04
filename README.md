Automated Sales Reporting System (Excel → SQL → Power BI)
An end-to-end reporting pipeline on the Superstore sales dataset (9,994 order lines, 2015–2018). Raw data is cleaned in Excel Power Query, stored and analysed in MySQL, visualised in Power BI, and summarised in an Excel MIS report, so the same report can be refreshed without manual rework.
Architecture
```
Superstore CSV ──► Excel Power Query (clean) ──► MySQL (store + analyse) ──► Power BI (dashboard)
                          │                                                         │
                          └──────────────► Excel MIS report + dashboard ◄───────────┘
```
What is in this folder
File	Purpose
`Superstore_Sales_Reporting_System.xlsx`	Finished Excel workbook: Dashboard, MIS_Report, summary tables, clean data, data-quality log
`01_mysql_superstore.sql`	Tables, load, validation checks, 3 reporting views, 14 analysis queries
`02_PowerBI_Build_Guide.md`	Step-by-step Power BI build, all DAX measures, page layouts
`03_PowerQuery_M_Code.txt`	Paste-ready Power Query code for Orders, People and Returns
`clean_orders.csv`, `people.csv`, `returns.csv`	Cleaned data for MySQL and Power BI
Step 1 – Excel: clean and prepare
The source CSV holds three tables stacked in one file (orders, people, returns). Split them into separate tables.
Removed 1 exact duplicate order line (compared on every column except Row ID); 9,994 → 9,993 lines.
Filled 11 blank Postal Codes (all Burlington, Vermont) and kept codes as 5-digit text.
Reduced the returns list from 800 rows to 296 unique returned orders.
Added data validation (dropdowns for Segment, Region, Category, Ship Mode; limits on Quantity, Discount, Sales).
Added helper columns: year, month, ship days, margin, `Returned?` and `Salesperson` using IF, MATCH, INDEX-MATCH; XLOOKUP versions are in `Formula_Guide`.
Built 7 summary tables with SUMIFS / COUNTIFS / AVERAGEIFS and a live `Data_Quality_Log`.
Built a dropdown-driven dashboard (KPIs + 5 charts) and a monthly MIS report with prior-year comparison.
Step 2 – SQL: store and analyse
Created typed tables with primary keys, indexes and CHECK constraints; loaded the CSVs.
Validation queries (row counts, ship-before-order, duplicates, orphan records).
Views `vw_orders_enriched`, `vw_monthly_sales`, `vw_sales_by_region_category` for Power BI.
Analysis using JOINs, CTEs, GROUP BY / HAVING, CASE, and window functions (LAG, RANK, ROW_NUMBER, running totals).
Step 3 – Power BI: visualise
3 report pages (Executive Overview, Products and Discounts, Customers and Geography), a date table, 15 DAX measures and synced slicers. See the guide.
Key findings (verified against the data)
Overall: $2.30M sales, $286K profit, 12.5% margin, 5,009 orders, average order $458.56.
Growth: Sales rose from $484K (2015) to $733K (2018); 2018 grew 20.4% over 2017. 2016 dipped 2.8%.
Furniture is the weak spot: Furniture margin is 2.5% against 17.0% for Office Supplies and 17.4% for Technology.
Three sub-categories lose money: Tables (−$17.7K), Bookcases (−$3.5K) and Supplies (−$1.2K).
Discounts above 20% destroy profit: lines with no discount earn a 29.5% margin; 21–30% discounts run at −10.1%, 31–50% at −24.8%, and over 50% at −119.2%.
Regions: West earns the most profit ($108K, 14.9% margin); Central has the weakest margin (7.9%).
Returns: 296 of 5,009 orders (5.9%) were returned.
Recommendation: cap discounts at 20% and review pricing on Tables and Bookcases, since these two areas account for most of the profit leakage.

Skills demonstrated
Excel (Power Query, data validation, PivotTable-style summaries, SUMIFS, INDEX-MATCH, XLOOKUP, IF, charts, MIS reporting) · SQL (MySQL, joins, CTEs, window functions, views) · Power BI (data model, DAX, slicers, dashboards) · data cleaning and validation · business insight writing.
---
