-- ============================================================
-- Olist Advanced SQL Business Case Study
-- 01_create_tables.sql  — schema + foreign keys (8 tables)
-- ============================================================
CREATE DATABASE IF NOT EXISTS olist;
USE olist;

-- Drop in reverse-dependency order so FKs don't block
DROP TABLE IF EXISTS order_reviews;
DROP TABLE IF EXISTS order_payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS sellers;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS category_translation;

-- ---------- Dimension / lookup tables first ----------
CREATE TABLE customers (
    customer_id              VARCHAR(50) PRIMARY KEY,
    customer_unique_id       VARCHAR(50),
    customer_zip_code_prefix VARCHAR(10),
    customer_city            VARCHAR(60),
    customer_state           CHAR(2)
);

CREATE TABLE sellers (
    seller_id              VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city            VARCHAR(60),
    seller_state           CHAR(2)
);

CREATE TABLE category_translation (
    product_category_name         VARCHAR(80) PRIMARY KEY,
    product_category_name_english VARCHAR(80)
);

CREATE TABLE products (
    product_id                 VARCHAR(50) PRIMARY KEY,
    product_category_name      VARCHAR(80),
    product_name_lenght        INT,
    product_description_lenght INT,
    product_photos_qty         INT,
    product_weight_g           INT,
    product_length_cm          INT,
    product_height_cm          INT,
    product_width_cm           INT
);

-- ---------- Fact tables ----------
CREATE TABLE orders (
    order_id                      VARCHAR(50) PRIMARY KEY,
    customer_id                   VARCHAR(50),
    order_status                  VARCHAR(20),
    order_purchase_timestamp      DATETIME,
    order_approved_at             DATETIME NULL,
    order_delivered_carrier_date  DATETIME NULL,
    order_delivered_customer_date DATETIME NULL,
    order_estimated_delivery_date DATETIME NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id            VARCHAR(50),
    order_item_id       INT,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date DATETIME NULL,
    price               DECIMAL(10,2),
    freight_value       DECIMAL(10,2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id)  REFERENCES sellers(seller_id)
);

CREATE TABLE order_payments (
    order_id             VARCHAR(50),
    payment_sequential   INT,
    payment_type         VARCHAR(20),
    payment_installments INT,
    payment_value        DECIMAL(10,2),
    PRIMARY KEY (order_id, payment_sequential),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE order_reviews (
    review_id               VARCHAR(50),
    order_id                VARCHAR(50),
    review_score            TINYINT,
    review_comment_title    VARCHAR(150),
    review_comment_message  TEXT,
    review_creation_date    DATETIME NULL,
    review_answer_timestamp DATETIME NULL,
    PRIMARY KEY (review_id, order_id)
);