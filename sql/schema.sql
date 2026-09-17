-- ============================================================================
-- Superstore Retail Sales Analytics - Database Schema DDL
-- Compatible with PostgreSQL, MySQL, and SQLite
-- ============================================================================

-- Table: superstore
-- Stores transactional retail line items from 2014 to 2017
DROP TABLE IF EXISTS superstore;

CREATE TABLE superstore (
    Row_ID              INTEGER PRIMARY KEY,
    Order_ID            VARCHAR(25) NOT NULL,
    Order_Date          DATE NOT NULL,
    Ship_Date           DATE NOT NULL,
    Ship_Mode           VARCHAR(25) NOT NULL,
    Customer_ID         VARCHAR(20) NOT NULL,
    Customer_Name       VARCHAR(100) NOT NULL,
    Segment             VARCHAR(25) NOT NULL,
    Country             VARCHAR(50) NOT NULL,
    City                VARCHAR(50) NOT NULL,
    State               VARCHAR(50) NOT NULL,
    Postal_Code         VARCHAR(10),
    Region              VARCHAR(20) NOT NULL,
    Product_ID          VARCHAR(30) NOT NULL,
    Category            VARCHAR(30) NOT NULL,
    Sub_Category        VARCHAR(30) NOT NULL,
    Product_Name        VARCHAR(255) NOT NULL,
    Sales               NUMERIC(10, 2) NOT NULL,
    Quantity            INTEGER NOT NULL,
    Discount            NUMERIC(4, 2) NOT NULL,
    Profit              NUMERIC(10, 2) NOT NULL,
    
    -- Feature Engineered / Analytical Columns
    Ship_Duration_Days  INTEGER,
    Order_Year          INTEGER,
    Order_Month         INTEGER,
    Order_Month_Name    VARCHAR(10),
    Order_YearMonth     VARCHAR(7),
    Order_Quarter       VARCHAR(10),
    Profit_Margin_Pct   NUMERIC(6, 2),
    Is_Profitable       INTEGER,
    Discount_Tier       VARCHAR(30)
);

-- ============================================================================
-- Indexing Strategy for Analytical Query Optimization
-- ============================================================================

-- Speed up time-series and cohort filtering
CREATE INDEX idx_superstore_order_date ON superstore(Order_Date);
CREATE INDEX idx_superstore_year_month ON superstore(Order_YearMonth);

-- Speed up dimensional aggregations (Region, Category, Segment)
CREATE INDEX idx_superstore_region ON superstore(Region);
CREATE INDEX idx_superstore_category ON superstore(Category);
CREATE INDEX idx_superstore_sub_category ON superstore(Sub_Category);
CREATE INDEX idx_superstore_segment ON superstore(Segment);

-- Speed up customer behavioral & RFM queries
CREATE INDEX idx_superstore_customer_id ON superstore(Customer_ID);

-- Speed up discount elasticity and margin queries
CREATE INDEX idx_superstore_discount_tier ON superstore(Discount_Tier);
