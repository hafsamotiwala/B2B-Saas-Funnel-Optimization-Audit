USE Olist_saas;

-- Primary Key Validation Checks
SELECT seller_id, COUNT(*)
FROM olist_sellers_dataset
GROUP BY seller_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*)
FROM olist_orders_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Missing Records Audit
SELECT 
    COUNT(*) AS total_deals,
    SUM(CASE WHEN won_date IS NULL THEN 1 ELSE 0 END) AS missing_won_dates,
    SUM(CASE WHEN seller_id IS NULL THEN 1 ELSE 0 END) AS missing_seller_ids
FROM olist_closed_deals_dataset;

-- Chronological Anomaly Detection
-- Identifies transaction logs recorded BEFORE a seller was officially won in CRM
SELECT 
    cd.seller_id,
    cd.won_date,
    MIN(oi.shipping_limit_date) AS first_sale_date
FROM olist_closed_deals_dataset AS cd
JOIN olist_order_items_dataset AS oi ON cd.seller_id = oi.seller_id
GROUP BY cd.seller_id, cd.won_date
HAVING first_sale_date < cd.won_date; 

-- Locating Missing String Translations
SELECT DISTINCT
    p.product_category_name 
FROM olist_products_dataset AS p
LEFT JOIN product_category_name_translation AS t 
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IS NULL
    AND p.product_category_name IS NOT NULL;

-- Metadata Enrichment Patch
INSERT INTO product_category_name_translation (product_category_name, product_category_name_english)
VALUES 
('pc_gamer', 'pc_gamer'),
('portateis_cozinha_e_preparadores_de_alimentos', 'kitchen_portables_and_food_preparators');
