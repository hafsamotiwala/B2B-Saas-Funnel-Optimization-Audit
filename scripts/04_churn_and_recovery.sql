USE Olist_saas;

-- 1. Total Financial Revenue Lost (Wasted CAC + Lost Subscription ARR)
SELECT 
	COUNT(cd.seller_id) AS total_ghost_sellers,
	COUNT(cd.seller_id) * 700 AS total_wasted_cac,
    COUNT(cd.seller_id) * 50 * 12 AS annual_lost_Subscription_revenue,
    (COUNT(cd.seller_id) * 700) + (COUNT(cd.seller_id) * 50 * 12) AS total_annual_leakage
FROM olist_closed_deals_dataset cd
LEFT JOIN olist_order_items_dataset oi 
ON cd.seller_id = oi.seller_id
WHERE oi.seller_id IS NULL;  

-- 2. The Churn Zone (15-Day Momentum Loop Pacing Distribution via LAG)
WITH SellerGaps AS (
	SELECT
    seller_id, shipping_limit_date,
    LAG(shipping_limit_date, 1) OVER (PARTITION BY seller_id ORDER BY shipping_limit_date) AS prev_sale_date
    FROM olist_order_items_dataset),
InactivityStats AS(
		SELECT seller_id, 
        DATEDIFF(shipping_limit_date, prev_sale_date) AS days_between_sales
        FROM SellerGaps 
        WHERE prev_sale_date IS NOT NULL
)
SELECT 
	CASE 
		WHEN days_between_sales <= 15 THEN '0-15 Days Inactive'  
		WHEN days_between_sales <= 30 THEN '16-30 Days Inactive'  
        WHEN days_between_sales <= 60 THEN '31-60 Days Inactive'  
		ELSE '60+ days (The Churn Red Zone)'
	END AS inactivity_bucket,
    COUNT(*) AS  total_historical_events,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS probability_distribution_percentage
FROM InactivityStats
GROUP BY 1
ORDER BY 1;

-- 3. Cohort Attrition (Power Users vs Window Shoppers Lifespan)
WITH SellerLTV AS (
    SELECT 
        cd.mql_id,
        cd.seller_id,
        SUM(oi.price) AS total_revenue_generated,
        DATEDIFF(MAX(oi.shipping_limit_date), MIN(oi.shipping_limit_date)) AS lifetime_days
    FROM olist_closed_deals_dataset cd
    JOIN olist_order_items_dataset oi ON cd.seller_id = oi.seller_id
    GROUP BY 1, 2
)
SELECT 
    mql.origin,
    COUNT(DISTINCT sl.seller_id) AS total_activated_sellers,
    ROUND(AVG(sl.total_revenue_generated), 2) AS avg_seller_ltv,
    SUM(CASE WHEN sl.lifetime_days <= 30 THEN 1 ELSE 0 END) AS churned_in_month_1_count,
    SUM(CASE WHEN sl.lifetime_days <= 60 THEN 1 ELSE 0 END) AS churned_in_month_2_count,
    SUM(CASE WHEN sl.lifetime_days <= 90 THEN 1 ELSE 0 END) AS churned_in_month_3_count,
    SUM(CASE WHEN sl.lifetime_days <= 120 THEN 1 ELSE 0 END) AS churned_in_month_4_count,
    SUM(CASE WHEN sl.lifetime_days <= 150 THEN 1 ELSE 0 END) AS churned_in_month_5_count
FROM olist_marketing_qualified_leads_dataset mql
JOIN SellerLTV sl ON mql.mql_id = sl.mql_id
GROUP BY 1
ORDER BY avg_seller_ltv DESC;

-- 4. Revenue Penalties Tied to Late Deliveries (Fulfillment Gaps)
SELECT
	COUNT(DISTINCT oi.seller_id) AS frustrated_sellers_count,
    ROUND(SUM(oi.price), 2) AS revenue_at_risk,
    AVG(re.review_score) AS avg_review_score
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
JOIN olist_order_reviews_dataset re ON o.order_id = re.order_id
WHERE DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 3
  AND re.review_score = 1;

-- 5. Checkout Funnel Friction (Cancellation Rates by Payment Instrument)
SELECT 
    p.payment_type,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) AS canceled_orders_count,
    ROUND((SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) / COUNT(DISTINCT o.order_id)) * 100, 2) AS cancellation_rate_percentage
FROM olist_orders_dataset o
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
GROUP BY 1
ORDER BY cancellation_rate_percentage DESC;

-- 6. Macro Sales Revenue Volume & Month-over-Month (MoM) Growth Percentage Trends
SELECT
	DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS sales_month,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders,
	ROUND(
		((SUM(oi.price) - LAG(SUM(oi.price), 1) OVER (ORDER BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'))) /
        LAG(SUM(oi.price), 1) OVER (ORDER BY DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m'))) * 100, 2) AS mom_growth_percentage
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY 1;

-- 7. Payment Installments: High-Value vs. Low-Value Items Pacing
SELECT 
    CASE WHEN oi.price >= 150 THEN 'High-Value Items (>= $150)' ELSE 'Low-Value Items (< $150)' END AS item_tier,
    ROUND(AVG(p.payment_installments), 1) AS avg_installments,
    MAX(p.payment_installments) AS max_installments_offered
FROM olist_order_items_dataset oi
JOIN olist_order_payments_dataset p ON oi.order_id = p.order_id
GROUP BY 1;

-- 8. Long-Tail Revenue Recovery Modeling via NTILE(5)
WITH SellerPerformance AS (
    SELECT 
        oi.seller_id,
        SUM(oi.price) AS current_revenue,
        NTILE(5) OVER (ORDER BY SUM(oi.price) ASC) AS performance_quintile
    FROM olist_order_items_dataset oi
    GROUP BY oi.seller_id
)
SELECT 
    performance_quintile,
    COUNT(seller_id) AS seller_count,
    ROUND(SUM(current_revenue), 2) AS current_total_revenue,
    ROUND(SUM(current_revenue) * 0.10, 2) AS potential_10_percent_recovery_value
FROM SellerPerformance
WHERE performance_quintile = 1
GROUP BY 1;

-- 9. Activated Sellers Success Profiles (Fulfillment Delay vs Score)
SELECT
	oi.seller_id,
    AVG(re.review_score) AS avg_rating,        
    AVG(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)) AS avg_delay_days,
    COUNT(oi.order_id) AS sample_size
FROM (SELECT * FROM olist_orders_dataset LIMIT 5000) o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
JOIN olist_order_reviews_dataset re ON o.order_id = re.order_id
GROUP BY 1
HAVING avg_delay_days > 0
ORDER BY avg_rating DESC;
