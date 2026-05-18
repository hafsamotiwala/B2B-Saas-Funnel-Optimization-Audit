USE Olist_saas;

-- 1. Closed Deals Attribution by Lead Origin
SELECT
	origin,
    COUNT(mql_id) AS total_leads,
    COUNT(CASE WHEN landing_page_id IS NOT NULL THEN 1 END) AS engaged_leads,
    (SELECT 
    COUNT(*) FROM olist_closed_deals_dataset cd 
    WHERE cd.mql_id
    IN (SELECT mql_id FROM olist_marketing_qualified_leads_dataset mql2
    WHERE mql2.origin = mql.origin)) AS closed_deals
FROM olist_marketing_qualified_leads_dataset  mql
GROUP BY 1
ORDER BY total_leads DESC;

-- 2. Activation Lag / Average Days to Activation by Segment
SELECT 
	cd.business_segment,
    COUNT(cd.seller_id) AS total_won_deals,
    COUNT(DISTINCT oi.seller_id) AS activated_sellers, -- Calculate how many actually made a sale
	ROUND(AVG(DATEDIFF(oi.first_sale_date, cd.won_date)), 1) AS avg_days_to_activation-- Calculate average days to first sale
FROM olist_closed_deals_dataset cd
LEFT JOIN (
	SELECT seller_id, MIN(shipping_limit_date) AS first_sale_date
    FROM olist_order_items_dataset
    GROUP BY seller_id) oi
    ON cd.seller_id = oi.seller_id
GROUP BY 1
ORDER BY avg_days_to_activation DESC;

-- 3. Average Days to Aha Moment (Successful Fulfillment)
SELECT
	cd.business_segment,
    COUNT(oi.order_id) as sales_volume,
    AVG(DATEDIFF(oi.shipping_limit_date, cd.won_date)) AS days_to_aha
FROM olist_closed_deals_dataset cd
JOIN olist_order_items_dataset oi ON cd.seller_id = oi.seller_id
GROUP BY 1
HAVING days_to_aha > 0
ORDER BY days_to_aha ASC;    

-- 4. Activation Efficiency Rate by Segment
SELECT 
    cd.business_segment,
    COUNT(DISTINCT cd.seller_id) AS total_signed_up,
    COUNT(DISTINCT oi.seller_id) AS total_activated,
    ROUND((COUNT(DISTINCT oi.seller_id) / COUNT(DISTINCT cd.seller_id)) * 100, 2) AS activation_rate,
    ROUND(AVG(DATEDIFF(oi.first_sale, cd.won_date)), 1) AS avg_days_to_aha
FROM olist_closed_deals_dataset cd
LEFT JOIN (
    SELECT seller_id, MIN(shipping_limit_date) AS first_sale 
    FROM olist_order_items_dataset 
    GROUP BY seller_id
) oi ON cd.seller_id = oi.seller_id
GROUP BY 1
ORDER BY activation_rate ASC;

-- 5. Value per Lead Origin & Type (Fast Success Patterns < 60 Days)
SELECT
	mql.origin,
    cd.lead_type,
    COUNT(cd.seller_id) AS total_sellers,
    AVG(DATEDIFF(oi.first_sale, cd.won_date)) as avg_days_to_aha
FROM olist_closed_deals_dataset cd
JOIN olist_marketing_qualified_leads_dataset mql ON cd.mql_id = mql.mql_id
JOIN (
	SELECT seller_id, MIN(shipping_limit_date) AS first_sale
	FROM olist_order_items_dataset 
    GROUP BY seller_id
) oi ON cd.seller_id = oi.seller_id
GROUP BY 1, 2
HAVING avg_days_to_aha < 60 
ORDER BY avg_days_to_aha ASC;

-- 6. Pinpoint Specific Setup Bottlenecks for Ghost Users
SELECT 
    cd.seller_id,
    cd.business_segment,
    mql.origin,
    CASE 
        WHEN cd.declared_product_catalog_size IS NULL THEN 'Missing Product Catalog Upload'
        WHEN cd.won_date IS NOT NULL AND oi.seller_id IS NULL THEN 'Stuck in Setup Room (Zero Sales)'
        ELSE 'Active'
    END AS current_bottleneck_status
FROM olist_closed_deals_dataset cd
JOIN olist_marketing_qualified_leads_dataset mql ON cd.mql_id = mql.mql_id
LEFT JOIN olist_order_items_dataset oi ON cd.seller_id = oi.seller_id
WHERE oi.seller_id IS NULL; 

-- 7. Top 10 Performing Product Categories by Volume and Revenue
SELECT 
	t.product_category_name_english,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    COUNT(oi.order_id) AS total_sales_volume
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
JOIN product_category_name_translation t ON p.product_category_name = t.product_category_name
GROUP BY 1
ORDER BY total_revenue DESC
LIMIT 10;
