
DROP TABLE IF EXISTS order_reviews, order_payments, order_items, 
                     orders, customers, products, sellers, 
                     geolocation, product_category_translation 
CASCADE;

CREATE TABLE customers (
    customer_id              VARCHAR,
    customer_unique_id       VARCHAR,
    customer_zip_code_prefix INT,
    customer_city            VARCHAR,
    customer_state           VARCHAR
);

CREATE TABLE products (
    product_id                 VARCHAR,
    product_category_name      VARCHAR,
    product_name_length        INT,
    product_description_length INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

CREATE TABLE sellers (
    seller_id              VARCHAR,
    seller_zip_code_prefix INT,
    seller_city            VARCHAR,
    seller_state           VARCHAR
);

CREATE TABLE geolocation (
    geolocation_zip_code_prefix INT,
    geolocation_lat             NUMERIC,
    geolocation_lng             NUMERIC,
    geolocation_city            VARCHAR,
    geolocation_state           VARCHAR
);

CREATE TABLE product_category_translation (
    product_category_name         VARCHAR,
    product_category_name_english VARCHAR
);

CREATE TABLE orders (
    order_id                      VARCHAR,
    customer_id                   VARCHAR,
    order_status                  VARCHAR,
    order_purchase_timestamp      TIMESTAMP,
    order_approved_at             TIMESTAMP,
    order_delivered_carrier_date  TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP
);

CREATE TABLE order_items (
    order_id            VARCHAR,
    order_item_id       INT,
    product_id          VARCHAR,
    seller_id           VARCHAR,
    shipping_limit_date TIMESTAMP,
    price               NUMERIC(10,2),
    freight_value       NUMERIC(10,2)
);

CREATE TABLE order_payments (
    order_id             VARCHAR,
    payment_sequential   INT,
    payment_type         VARCHAR,
    payment_installments INT,
    payment_value        NUMERIC(10,2)
);

CREATE TABLE order_reviews (
    review_id               VARCHAR,
    order_id                VARCHAR,
    review_score            INT,
    review_comment_title    VARCHAR,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMP,
    review_answer_timestamp TIMESTAMP
);



--Question 1 — What is the month-over-month revenue trend?


With monthly_revenue As
(Select 
TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') As month,
ROUND(Sum(p.payment_Value):: Numeric, 2) As revenue
From orders o
JOIN order_payments p on o.order_id = p.order_id
Where o.order_status = 'delivered'
group by 1)

select month, 
revenue, 
LAG(Revenue) OVER (order by month) AS prev_month_revenue,
Round((revenue - LAG(revenue) OVER (ORDER BY month))/ NULLIF(LAG(revenue) OVER (ORDER BY month), 0)* 100, 2) AS mom_growth_pct
FROM monthly_revenue
ORDER BY month;


--Q1 - Business Insights & Suggestions

--Insight 1 — Strong Growth Phase (2017)
--Revenue scaled from $255K in Jan 2017 to $828K in Mar 2017 within just 3 months — 3x growth indicating strong product-market fit in early launch phase.

--Insight 2 — Data Gap in 2016
--October and December 2016 show incomplete data with November missing entirely. Early launch phase data should be excluded from trend analysis to avoid misleading growth percentages.

--Insight 3 — Growth Stabilization (2017 Mid)
--After explosive early growth, MoM growth stabilized to 20-50% range by mid-2017 — a healthy sign of sustainable scaling rather than volatile spikes.


--Q1 - Business Suggestions

--1. Investigate November 2016 gap
--Was the platform down? Was there a supply issue? Any missing month in revenue data needs explanation in a real business setting.

--2. Focus marketing in high-growth months
--Identify which months showed highest MoM growth and check if any campaigns ran — replicate those campaigns going forward.

--3. Set monthly growth targets
--If average MoM growth was 30-40% in healthy months, use that as benchmark KPI for future months.

--4. Flag December seasonality
--Check if December consistently underperforms vs November — if yes, push aggressive discount campaigns in Dec.


--Question 2 — Which product categories generate the most revenue?

Select 
Coalesce (t.product_category_name_english,
p.product_category_name,
'Unknown') AS category,
count(Distinct o.order_id) As Total_orders,
ROUND(SUM(pay.payment_value)::NUMERIC, 2) AS total_revenue,
ROUND(AVG(pay.payment_value)::NUMERIC, 2) AS avg_order_value,
ROUND(SUM(pay.payment_value) * 100.0 / SUM(SUM(pay.payment_value)) OVER (), 2) AS revenue_pct
FROM order_items oi
JOIN orders o on oi.order_id   = o.order_id
JOIN order_payments pay ON o.order_id  = pay.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_translation t ON p.product_category_name = t.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY total_revenue DESC
LIMIT 15;

--Q2 — Business Insights & Suggestions

--Insight 1 — Top 3 categories dominate
--bed_bath_table, health_beauty, computers_accessories together contribute 24.59% of total revenue — nearly 1 in 4 rupees comes from just 3 categories.


--Insight 2 — High AOV categories are hidden gems
--office_furniture has only 1,254 orders but avg order value of $362 — highest AOV in top 15. Low volume but high ticket size = premium upsell opportunity.
--watches_gifts: $228 AOV with 5,495 orders — strong combination of volume AND value.

--Insight 3 — High orders but low AOV
--bed_bath_table leads in orders (9,272) but AOV is only $145 — customers buy frequently but in small amounts. Bundle offers can increase AOV here.

--Q2 - Business Suggestions

--1. Double down on top 3 categories
--bed_bath_table, health_beauty, computers — increase inventory, run targeted ads, negotiate better supplier deals here first.

--2. Grow office_furniture volume
--AOV is $362 but only 1,254 orders — this category has high-value buyers. B2B outreach or bulk discount campaigns can 5x this revenue.

--3. Bundle strategy for bed_bath_table
--High order volume + low AOV = perfect candidate for "Buy 2 Get 10% off" type bundling to push AOV from $145 to $180+

--4. watches_gifts for gifting campaigns
--$228 AOV + decent volume — push hard during festive seasons like Christmas, Valentine's Day with gift wrapping offers.


--Question 3 — What percentage of customers return to buy again?

WITH first_purchase AS 
(SELECT
c.customer_unique_id,
MIN(o.order_purchase_timestamp) AS first_order_date,
TO_CHAR(MIN(o.order_purchase_timestamp), 'YYYY-MM') AS cohort_month
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id),all_orders AS
(SELECT c.customer_unique_id,TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS order_month
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'),
cohort_data AS 
(SELECT
f.cohort_month,
a.order_month,
COUNT(DISTINCT a.customer_unique_id) AS active_customers
FROM first_purchase f
JOIN all_orders a USING (customer_unique_id)
GROUP BY 1, 2),
cohort_size AS 
(SELECT
cohort_month,
COUNT(DISTINCT customer_unique_id) AS total_customers
FROM first_purchase
GROUP BY 1)
SELECT
c.cohort_month,
c.order_month,
s.total_customers  AS cohort_size,
cd.active_customers,
ROUND(cd.active_customers * 100.0 / s.total_customers, 2) AS retention_pct
FROM cohort_size s
JOIN cohort_data cd  ON s.cohort_month = cd.cohort_month
JOIN (SELECT DISTINCT cohort_month, order_month 
FROM cohort_data) c 
ON s.cohort_month = c.cohort_month
AND cd.order_month = c.order_month
ORDER BY c.cohort_month, c.order_month;


--Q3 — Business Insights

--Insight 1 — Brutal truth about retention

--2016-10 cohort: 262 customers joined.
--Next month only 0.38% came back = barely 1 customer.
--2017-01 cohort: 717 customers joined.
--Next month only 0.28% came back = 2 customers.

--This e-commerce platform has extremely low repeat 
--purchase rate — most customers buy ONCE and never return.

--Insight 2 — First month is always 100%

--Every cohort shows 100% in their own month — obvious because that IS their first purchase month. Real retention starts from month 2 onwards.


-- Insight 3 — Industry context

--e-commerce marketplaces typically see <5% repeat purchase rate. Olist at ~0.3-0.7% is extremely low even by that standard — indicating customers treat it as a one-time purchase platform.


--Q3 - Business Suggestions

--1. Launch a loyalty program immediately

--Less than 1% repeat rate means 99% revenue depends on new customer acquisition — extremely expensive and unsustainable. Even getting retention to 5% would 5x revenue without any new customer spend.

--2. Post-purchase email campaigns

--30 days after first purchase — send personalized recommendations based on what they bought. Timing is critical — too early feels pushy, too late they forget the brand.

--3. Subscription model for high-frequency categories

--health_beauty and bed_bath_table are consumables — perfect for "Subscribe & Save" model. Auto-reorder every 30/60/90 days.

--4. Win-back campaign at 60 days

--If a customer hasn't returned in 60 days — trigger a discount coupon. Data shows most customers who return do so within 2-3 months or never.


--Question 4 — What is the lifetime value of each customer segment?

WITH customer_stats AS 
(SELECT
c.customer_unique_id,
COUNT(DISTINCT o.order_id)  AS total_orders,
SUM(p.payment_value)        AS total_spent,
AVG(p.payment_value)      AS avg_order_value,
MIN(o.order_purchase_timestamp) AS first_order,
MAX(o.order_purchase_timestamp) AS last_order,
EXTRACT(DAY FROM MAX(o.order_purchase_timestamp) - MIN(o.order_purchase_timestamp)) AS lifespan_days
FROM customers c
JOIN orders o   ON c.customer_id   = o.customer_id
JOIN order_payments p ON o.order_id      = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id),
clv_calculated AS 
(SELECT *,
ROUND((total_spent / NULLIF(lifespan_days, 0)) * 365, 2)  AS annual_clv,CASE
WHEN total_spent > 1000 THEN 'High Value'
WHEN total_spent > 300  THEN 'Mid Value'
WHEN total_spent > 100  THEN 'Low Value'
ELSE 'Micro Value'
END AS clv_segment
FROM customer_stats)
SELECT
clv_segment,
COUNT(*)   AS total_customers,
ROUND(AVG(total_spent)::NUMERIC, 2)    AS avg_lifetime_spend,
ROUND(AVG(avg_order_value)::NUMERIC, 2)  AS avg_order_value,
ROUND(AVG(lifespan_days)::NUMERIC, 0)  AS avg_lifespan_days,
ROUND(AVG(annual_clv)::NUMERIC, 2)  AS avg_annual_clv,
ROUND(SUM(total_spent)::NUMERIC, 2) AS total_segment_revenue,
ROUND(SUM(total_spent) * 100.0/ SUM(SUM(total_spent)) OVER (), 2)  AS revenue_contribution_pct
FROM clv_calculated
GROUP BY clv_segment
ORDER BY avg_lifetime_spend DESC;


-- Q4 — Business Insights

--Insight 1 — High Value customers are few but mighty

--High Value: only 4,265 customers (4.6% of total)but contribute 25.53% of total revenue. avg annual CLV = $53,658 — these are your VIP customers.

--Insight 2 — Mid Value is the real revenue engine

--Mid Value: 27,282 customers contributing 42.69% revenue — single largest revenue segment.avg annual CLV = $10,786.This is where most business focus should go.

--Insight 3 — Low Value is largest by count

--Low Value: 46,351 customers (50% of base) but only 28% revenue.avg lifespan = 1 day — bought once, never returned.Huge untapped potential if retention improves.

--Insight 4 — Micro Value is a drain

--Micro Value: 15,459 customers, avg spend $73.Contributing only 3.71% revenue.Cost to serve these customers may exceed their CLV.

-- Q4 --Business Suggestions

--1. Protect High Value at all costs

--4,265 customers generating 25% revenue — assign dedicated account managers, give early access to new products, free shipping always. Losing one High Value customer = losing $1,846 lifetime spend.

--2. Convert Mid Value to High Value

--They spend $482 avg — just $518 away from High Value tier. Targeted upsell campaigns with "Unlock Platinum benefits at $1000 spend" can push them up.

--3. Reactivate Low Value segment

--46,351 customers spending only $186 avg with 1 day lifespan.
--A single follow-up email with 10% discount within 30 days of
--first purchase could double this segment's revenue contribution.

--4. Deprioritize Micro Value acquisition

--$73 avg spend, $2,707 annual CLV — if CAC exceeds $50,
--this segment is unprofitable. Reduce paid ad spend targeting
--this demographic immediately.


--Question 5 — Which payment methods have the highest failure and cancellation rate?


SELECT
p.payment_type,
COUNT(*)  AS total_transactions,
SUM(CASE WHEN o.order_status = 'canceled'  
THEN 1 ELSE 0 END) AS canceled_orders,
SUM(CASE WHEN o.order_status = 'unavailable' 
THEN 1 ELSE 0 END) AS unavailable_orders,
ROUND(SUM(CASE WHEN o.order_status IN ('canceled','unavailable') 
THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)  AS failure_rate_pct,
ROUND(AVG(p.payment_value)::NUMERIC, 2)  AS avg_txn_value,
MAX(p.payment_value)  AS max_txn_value,
ROUND(AVG(p.payment_installments)::NUMERIC, 2) AS avg_installments,
RANK() OVER (ORDER BY SUM(CASE WHEN o.order_status IN ('canceled','unavailable') 
THEN 1 ELSE 0 END) * 100.0 / COUNT(*) DESC)   AS risk_rank
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
GROUP BY p.payment_type
ORDER BY failure_rate_pct DESC;

--Q5 — Business Insights

--Insight 1 — not_defined is 100% failure

--6 transactions, 6 canceled, 0 revenue.Payment type not captured = order always fails.This is a data quality + checkout bug — needs immediate engineering fix

--Insight 2 — Voucher is highest real risk

--2.81% failure rate — more than double credit card.
--11,550 transactions with 230 canceled + 94 unavailable.
--Avg value only $65.70 — low value AND high risk combination.
--Vouchers are being used on orders that then get canceled.

--Insight 3 — Credit card dominates volume

--153,590 transactions — 74% of all payments.
--Failure rate only 1.16% — acceptable for this volume.
--Avg installments 3.51 — customers splitting payments.
--Max transaction $13,664 — highest ticket purchases via credit card.

--Insight 4 — Debit card is safest

--0.85% failure rate — lowest among all methods.
--Only 3,058 transactions though — heavily underutilized.
--Avg value $142 — decent order value with lowest risk.


--Q5 -Business Suggestions

--1. Fix not_defined immediately

--100% failure rate means checkout is not capturing payment type for some transactions. Every such order is automatically canceled — pure revenue loss. Engineering ticket should be P0 priority.

--2. Restrict vouchers on high-value orders

--Voucher failure rate 2.81% vs credit card 1.16% — cap voucher usage to orders below $50. Above that, force credit/debit card. This alone reduces overall failure rate significantly.

--3. Promote debit card usage

--Lowest failure rate 0.85% but only 3,058 transactions — offer 2% cashback on debit card payments to shift volume from vouchers. Lower risk + similar order value.


--4. Monitor credit card installments

--Avg 3.51 installments means customers are splitting payments — risk of mid-installment default exists. Flag orders with 6+ installments for additional verification.


--Question 6 — What is the daily cumulative revenue and each day's contribution to total revenue?

WITH daily_revenue AS 
(SELECT
DATE(o.order_purchase_timestamp)   AS order_date,
COUNT(DISTINCT o.order_id)   AS total_orders,
ROUND(SUM(p.payment_value)::NUMERIC, 2)  AS daily_revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
AND o.order_purchase_timestamp IS NOT NULL
GROUP BY 1)
SELECT
order_date,
total_orders,
daily_revenue,
SUM(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)  AS cumulative_revenue,
ROUND(daily_revenue * 100.0/ SUM(daily_revenue) OVER () , 4)  AS pct_of_total,
ROUND(SUM(daily_revenue) OVER (ORDER BY order_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) * 100.0/ SUM(daily_revenue) OVER (), 2)  AS cumulative_pct
FROM daily_revenue
ORDER BY order_date;


-- Q6 — Business Insights

-- Insight 1 — Slow start in 2016
-- First 8 days (Oct 3-10, 2016) generated only 0.30% of total 2-year revenue.
-- Platform was in early launch phase with minimal traction.

-- Insight 2 — November 2016 data gap
-- Zero delivered orders between Oct 10 and Dec 23, 2016.
-- Possible fulfillment/operational issue in second month of launch.

-- Insight 3 — Strong ramp up in Jan 2017
-- Cumulative revenue grew from $94K to $180K in just 16 days.
-- Consistent daily orders from Jan 5, 2017 onwards — real growth phase begins.

-- Insight 4 — Cumulative % reveals inflection point
-- Track the date when cumulative_pct crosses 50% — 
-- that is the exact midpoint of all revenue generated.

-- Q6 — Business Suggestions

-- 1. Use cumulative_pct for target tracking
-- If yearly target is $10M, monitor daily cumulative.
-- If 50% not hit by mid-year — trigger emergency campaigns.

-- 2. Investigate November 2016 gap
-- Any missing month in revenue needs documented explanation.

-- 3. Set daily revenue benchmarks from 2017 data
-- Calculate avg daily revenue per quarter as KPI baseline.
-- Flag any day 30% below benchmark for ops team review.

	