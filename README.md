# BigBasket Capstone

## Project Overview

BigBasket wants to know which product categories are meeting their revenue targets and which need attention. This repo builds that answer end to end from a single generated dataset: SQL queries against a SQLite database establish the category revenue and variance-against-target numbers, a spreadsheet workbook cross-checks those totals with its own pivot table and formulas, a published Tableau dashboard visualizes the trend and tier status per category, and a Python/Pandas notebook cleans the raw exports and cross-validates the top category and supplier findings independently of the SQL results.

## File and Folder Structure

All artifacts live flat in the repo root.

- [`generate_data.py`](generate_data.py) - script that generates the raw data.
- [`bigbasket_capstone.db`](bigbasket_capstone.db) - SQLite database, produced by `generate_data.py`.
- [`orders_raw.csv`](orders_raw.csv) - raw orders data, produced by `generate_data.py`.
- [`products.csv`](products.csv) - product catalog data, produced by `generate_data.py`.
- [`01_foundations.sql`](01_foundations.sql) - Part 1 foundational SQL queries.
- [`02_aggregation_joins.sql`](02_aggregation_joins.sql) - Part 1 aggregation and join queries.
- [`03_reporting.sql`](03_reporting.sql) - Part 1 reporting queries.
- [`verify.sql`](verify.sql) - verification queries used to cross check results.
- [`monthly_category_revenue.csv`](monthly_category_revenue.csv) - exported revenue data used in the spreadsheet and Tableau.
- [`bigbasket_capstone.xlsx`](bigbasket_capstone.xlsx) - the spreadsheet workbook (Part 2).
- [`analysis.ipynb`](analysis.ipynb) - the Part 4 Python notebook.
- [`ai_log.md`](ai_log.md) - log of AI assisted prompts used across the project.
- [`DATA_STORY.md`](DATA_STORY.md) - written interpretation of the Tableau dashboard.
- `README.md` - this file.

## How to Regenerate the Database

Run `python generate_data.py` from the repo root. It uses a fixed random seed, so it always reproduces the same 31 products, 50 customers, 500 orders (508 raw rows once duplicates and data-quality issues are injected), and 6 category targets. It writes three files into the repo root: `bigbasket_capstone.db`, `orders_raw.csv`, and `products.csv`. These three files are already committed, so this step is only needed if you want to regenerate them from scratch.

## Where the SQL Task Queries Live

- Part 1 foundations: [`01_foundations.sql`](01_foundations.sql)
- Part 1 aggregation and joins: [`02_aggregation_joins.sql`](02_aggregation_joins.sql)
- Part 1 reporting: [`03_reporting.sql`](03_reporting.sql)
- Verification: [`verify.sql`](verify.sql)

## Spreadsheet Workbook

[`bigbasket_capstone.xlsx`](bigbasket_capstone.xlsx)

## Live Tableau Public Dashboard

View the live dashboard here: [BigBasket Category Performance](https://public.tableau.com/app/profile/shally.jha/viz/BigBasketCategoryPerformance/BigBasketCategoryPerformance)

## Data Story

See [`DATA_STORY.md`](DATA_STORY.md).

## AI Usage Log

See [`ai_log.md`](ai_log.md).

## Part 4 Notebook

See [`analysis.ipynb`](analysis.ipynb).

## Methodology

### SQL date functions on SQLite

This database runs on SQLite, not BigQuery, so the SQL scripts use SQLite's own date syntax. Where BigQuery would use `EXTRACT()` and `FORMAT_DATE()`, this project uses SQLite's single `strftime()` function instead, for example `strftime('%Y-%m', order_date)` in [`03_reporting.sql`](03_reporting.sql) to group revenue by year and month in one string. This is the same date extraction and formatting concept, just expressed in SQLite's own syntax rather than BigQuery's.

### Data cleaning choices in the notebook

[`analysis.ipynb`](analysis.ipynb) makes a few deliberate choices when cleaning [`orders_raw.csv`](orders_raw.csv) and [`products.csv`](products.csv):

- Duplicate rows are removed by `order_id`, keeping the first occurrence, which brings the row count from 508 down to the expected 500.
- `city` and `category` values are cleaned of mixed casing and stray whitespace so each has its correct number of distinct values.
- Rows with a missing `amount_inr` are excluded from every revenue calculation rather than filled with 0 or a mean, since a missing revenue figure is unknown, not zero.
- `rating` is left null for Cancelled and Pending orders and is never imputed, because only Delivered orders receive a customer rating in the first place, so the nulls reflect real behavior rather than missing data.
- Outliers in `amount_inr` are capped at the IQR upper fence with `.clip()` rather than dropped, so no rows are lost. 16 Delivered rows are capped, more than the 5 synthetic extreme values `generate_data.py` injects, which shows the fence is also catching some genuinely high but real orders.

## Key Findings

### Category tier status

- Above Target: Bakery (15,410 revenue vs 12,000 target, +28.4%), Household Essentials (21,715 vs 17,000, +27.7%), Personal Care (16,382 vs 15,500, +5.7%).
- Below Target, Watch: Dairy & Eggs (14,090 vs 16,500, -14.6%, just inside the watch threshold).
- Below Target, Critical: Snacks & Beverages (10,895 vs 13,000, -16.2%), Fruits & Vegetables (9,790 vs 12,000, -18.4%, the largest shortfall).

Full detail and recommendations are in [`DATA_STORY.md`](DATA_STORY.md).

### Top category and supplier

- The SQL category revenue query ([`02_aggregation_joins.sql`](02_aggregation_joins.sql), Delivered orders only) ranks Household Essentials first at 21,715 revenue, before any data cleaning is applied.
- The Python notebook ([`analysis.ipynb`](analysis.ipynb)), run on the cleaned and capped data, also ranks Household Essentials first among Delivered orders, at 20,910 revenue. The lower figure reflects the outlier capping and missing-value exclusion applied during cleaning, and the two independently agree on which category leads.
- The notebook also finds HomeEssentials Traders as the top supplier by revenue, also at 20,910. This is a Python-only finding since the SQL scripts do not group revenue by supplier.

## Assumptions and Business Rules

- **Missing values:** rows with a missing `amount_inr` are excluded from every revenue calculation rather than filled in. `rating` is left null for Cancelled and Pending orders, since only Delivered orders are rated, and this is never imputed.
- **Outlier capping:** the IQR fence for Delivered `amount_inr` is Q1 = 90.0, Q3 = 275.0, IQR = 185.0, giving an upper fence of Q3 + 1.5 x IQR = 552.5. Values above the fence are capped to 552.5 with `.clip()`, not dropped. This affects 16 Delivered rows.
- **Tiering thresholds:** every category or product is tagged with exactly one of three tiers: Above Target when revenue is at or above its target, Below Target - Watch when the shortfall is within 15% of the target, and Below Target - Critical when the shortfall exceeds 15%. The same three-way rule is used in the SQL reporting query, the spreadsheet's nested-IF formula, and the dashboard's tier colors.
