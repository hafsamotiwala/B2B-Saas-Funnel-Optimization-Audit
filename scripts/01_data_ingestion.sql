CREATE DATABASE Olist_saas;
USE Olist_saas;

-- MQLs
CREATE TABLE olist_marketing_qualified_leads_dataset (
    mql_id VARCHAR(50) PRIMARY KEY,
    first_contact_date DATE,
    landing_page_id VARCHAR(50),
    origin VARCHAR(50)
);

TRUNCATE TABLE olist_marketing_qualified_leads_dataset;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_marketing_qualified_leads_dataset.csv'
INTO TABLE olist_marketing_qualified_leads_dataset
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(mql_id, @v_first_contact_date, landing_page_id, origin)
SET first_contact_date = NULLIF(@v_first_contact_date, '');

-- Closed Deals
DROP TABLE IF EXISTS olist_closed_deals_dataset;
CREATE TABLE olist_closed_deals_dataset (
    mql_id VARCHAR(50), seller_id VARCHAR(50), sdr_id VARCHAR(50), sr_id VARCHAR(50),
    won_date DATETIME, business_segment VARCHAR(100), lead_type VARCHAR(50),
    lead_behaviour_profile VARCHAR(50), has_company VARCHAR(10), has_gtin VARCHAR(10),
    average_stock VARCHAR(50), business_type VARCHAR(50),
    declared_product_catalog_size FLOAT, declared_monthly_revenue FLOAT
);

TRUNCATE TABLE olist_closed_deals_dataset;
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_closed_deals_dataset.csv'
INTO TABLE olist_closed_deals_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS
(mql_id, seller_id, sdr_id, sr_id, @v_won_date, business_segment, lead_type, lead_behaviour_profile, has_company, has_gtin, average_stock, business_type, @v_catalog, @v_revenue)
SET won_date = NULLIF(@v_won_date, ''),
    declared_product_catalog_size = NULLIF(@v_catalog, ''),
    declared_monthly_revenue = NULLIF(@v_revenue, '');

-- Orders Engine
CREATE TABLE olist_orders_dataset (
    order_id VARCHAR(50) PRIMARY KEY, customer_id VARCHAR(50), order_status VARCHAR(20),
    order_purchase_timestamp DATETIME, order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME, order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_orders_dataset.csv'
INTO TABLE olist_orders_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS
(order_id, customer_id, order_status, @v_purch, @v_appr, @v_carr, @v_cust, @v_est)
SET order_purchase_timestamp = NULLIF(@v_purch, ''),
    order_approved_at = NULLIF(@v_appr, ''),
    order_delivered_carrier_date = NULLIF(@v_carr, ''),
    order_delivered_customer_date = NULLIF(@v_cust, ''),
    order_estimated_delivery_date = NULLIF(@v_est, '');

-- Order Items
CREATE TABLE olist_order_items_dataset (
    order_id VARCHAR(50), order_item_id INT, product_id VARCHAR(50), seller_id VARCHAR(50),
    shipping_limit_date DATETIME, price DECIMAL(10,2), freight_value DECIMAL(10,2)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_order_items_dataset.csv'
INTO TABLE olist_order_items_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS
(order_id, order_item_id, product_id, seller_id, @v_ship, price, freight_value)
SET shipping_limit_date = NULLIF(@v_ship, '');

-- Reviews
DROP TABLE IF EXISTS olist_order_reviews_dataset;
CREATE TABLE olist_order_reviews_dataset (
    review_id VARCHAR(50), order_id VARCHAR(50), review_score INT,
    review_creation_date DATETIME, review_answer_timestamp DATETIME
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_order_reviews_dataset.csv'
INTO TABLE olist_order_reviews_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 ROWS
(review_id, order_id, review_score, @dummy1, @dummy2, @v_creat, @v_ans)
SET review_creation_date = NULLIF(@v_creat, ''),
    review_answer_timestamp = NULLIF(@v_ans, '');

-- Products
DROP TABLE IF EXISTS olist_products_dataset;
CREATE TABLE olist_products_dataset (
    product_id VARCHAR(50) PRIMARY KEY, product_category_name VARCHAR(100),
    product_name_lenght INT, product_description_lenght INT, product_photos_qty INT,
    product_weight_g INT, product_length_cm INT, product_height_cm INT, product_width_cm INT
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_products_dataset.csv'
IGNORE INTO TABLE olist_products_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- Sellers
CREATE TABLE olist_sellers_dataset (
    seller_id VARCHAR(50) PRIMARY KEY, seller_zip_code_prefix INT,
    seller_city VARCHAR(100), seller_state VARCHAR(5)
);	

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_sellers_dataset.csv'
INTO TABLE olist_sellers_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- Customers
DROP TABLE IF EXISTS olist_customers_dataset;
CREATE TABLE olist_customers_dataset (
    customer_id VARCHAR(50) PRIMARY KEY, customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT, customer_city VARCHAR(100), customer_state VARCHAR(5)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_customers_dataset.csv'
INTO TABLE olist_customers_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- Payments
CREATE TABLE olist_order_payments_dataset (
    order_id VARCHAR(50), payment_sequential INT, payment_type VARCHAR(20),
    payment_installments INT, payment_value DECIMAL(10,2)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\olist_order_payments_dataset.csv'
INTO TABLE olist_order_payments_dataset
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

-- Translations
CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(100), product_category_name_english VARCHAR(100)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;

