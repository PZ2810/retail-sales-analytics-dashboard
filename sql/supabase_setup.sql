-- ============================================================================
-- Supabase SQL Editor Setup: Create 'superstore' table
-- Paste and run this directly in Supabase -> SQL Editor
-- ============================================================================

DROP TABLE IF EXISTS superstore CASCADE;

CREATE TABLE superstore (
    row_id              BIGINT PRIMARY KEY,
    order_id            TEXT NOT NULL,
    order_date          DATE NOT NULL,
    ship_date           DATE NOT NULL,
    ship_mode           TEXT,
    customer_id         TEXT,
    customer_name       TEXT,
    segment             TEXT,
    country             TEXT,
    city                TEXT,
    state               TEXT,
    postal_code         TEXT,
    region              TEXT,
    product_id          TEXT,
    category            TEXT,
    sub_category        TEXT,
    product_name        TEXT,
    sales               NUMERIC(10, 2),
    quantity            INTEGER,
    discount            NUMERIC(4, 2),
    profit              NUMERIC(10, 2),
    ship_duration_days  INTEGER,
    order_year          INTEGER,
    order_month         INTEGER,
    order_month_name    TEXT,
    order_yearmonth     TEXT,
    order_quarter       TEXT,
    profit_margin_pct   NUMERIC(6, 2),
    is_profitable       INTEGER,
    discount_tier       TEXT
);

-- Analytical indexes
CREATE INDEX idx_sb_order_date ON superstore(order_date);
CREATE INDEX idx_sb_region ON superstore(region);
CREATE INDEX idx_sb_category ON superstore(category);
CREATE INDEX idx_sb_segment ON superstore(segment);
CREATE INDEX idx_sb_discount_tier ON superstore(discount_tier);

-- Enable public read and write access for dataset analysis
ALTER TABLE superstore ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read and insert"
ON superstore
FOR ALL
TO public
USING (true)
WITH CHECK (true);
