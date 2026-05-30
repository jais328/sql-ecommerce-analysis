# 🛒 SQL E-Commerce Analysis — Brazilian Olist Dataset

## Project Overview
End-to-end SQL analysis on 100K+ real transactions from Brazil's 
largest e-commerce marketplace. This project applies banking and 
finance concepts — RFM segmentation, CLV analysis, cohort retention, 
payment risk modeling — on e-commerce data using PostgreSQL.

---

## Dataset
- **Source:** [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Tables:** 9 tables, 100K+ orders, 93K customers, 112K order items
- **Period:** October 2016 — October 2018
- **Tool:** PostgreSQL 18 + pgAdmin

---

## Business Questions Answered

| # | Question | Key Concept |
|---|---|---|
| RFM | Who are our best customers? | NTILE, Window Functions |
| Q1 | What is month-over-month revenue growth? | LAG(), CTE |
| Q2 | Which categories generate most revenue? | Multi-table JOIN, COALESCE |
| Q3 | What % of customers return to buy again? | Cohort Analysis, Self JOIN |
| Q4 | What is each customer segment worth? | CLV, CASE WHEN |
| Q5 | Which payment methods have highest failure rate? | Conditional Aggregation, RANK() |
| Q6 | What is daily cumulative revenue trend? | ROWS BETWEEN, Window Frame |

---

## Key Findings

**RFM Segmentation**
- Champions (24% of customers) generate 46% of total revenue
- Lost segment (12%) contributes only 3.2% — low priority for re-engagement

**Revenue Trend**
- Revenue scaled 3x in Q1 2017 within just 3 months of real launch
- November 2016 data gap identified — possible operational issue

**Category Analysis**
- Top 3 categories (bed_bath_table, health_beauty, computers) = 24.59% of revenue
- office_furniture highest AOV at $362 with untapped volume potential

**Cohort Retention**
- Less than 1% repeat purchase rate across all cohorts
- Platform heavily dependent on new customer acquisition

**CLV Analysis**
- Top 4.6% customers (High Value) generate 25.53% of total revenue
- High Value avg annual CLV = $53,658 vs Micro Value $2,707 — 20x difference

**Payment Risk**
- not_defined payment type = 100% failure rate — critical data quality bug
- Voucher highest real failure rate at 2.81% vs credit card 1.16%
- Debit card safest at 0.85% but heavily underutilized

**Cumulative Revenue**
- First 8 days of launch = only 0.30% of total 2-year revenue
- Consistent daily growth from January 2017 onwards

---

## SQL Concepts Used
- CTEs (Common Table Expressions)
- Window Functions — LAG(), RANK(), NTILE(), SUM() OVER()
- Window Frames — ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
- Multi-table JOINs (up to 4 tables)
- Conditional Aggregation — CASE WHEN inside SUM()
- COALESCE() for null handling
- Date functions — TO_CHAR(), EXTRACT(), DATE()

---

## Files
| File | Description |
|---|---|
| 00_rfm_analysis.sql | RFM customer segmentation |
| 01_mom_revenue_trend.sql | Month-over-month revenue with LAG() |
| 02_category_revenue.sql | Top categories by revenue and AOV |
| 03_cohort_retention.sql | Monthly cohort retention analysis |
| 04_clv_analysis.sql | Customer lifetime value segmentation |
| 05_payment_risk.sql | Payment failure and risk analysis |
| 06_cumulative_revenue.sql | Daily running total and cumulative % |

---

## Author
**Ritik Jais** | Aspiring Data Analyst
- PostgreSQL | SQL | Data Analysis
