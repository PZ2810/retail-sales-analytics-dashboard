-- ============================================================================
-- Superstore Retail Sales Analytics - Core Business & Analytical Queries
-- ============================================================================
-- Author: Data Analyst Portfolio
-- Dataset: Superstore Sales Dataset (9,994 transactions, 2014 - 2017)
-- Compatible with: PostgreSQL, MySQL 8.0+, SQLite
-- ============================================================================


-- ============================================================================
-- 1. EXECUTIVE KPI OVERVIEW
-- Question: What are the overall topline financial and operational KPIs?
-- Business Context: Provides leadership with a snapshot of total revenue, profit, 
-- overall profit margin, order volume, customer base, and average order value.
-- ============================================================================
SELECT 
    ROUND(SUM(Sales), 2)                                            AS Total_Revenue,
    ROUND(SUM(Profit), 2)                                           AS Total_Profit,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                      AS Profit_Margin_Pct,
    COUNT(DISTINCT Order_ID)                                        AS Total_Orders,
    COUNT(DISTINCT Customer_ID)                                     AS Total_Customers,
    ROUND(SUM(Sales) / COUNT(DISTINCT Order_ID), 2)                 AS Avg_Order_Value,
    ROUND(AVG(Discount) * 100.0, 2)                                 AS Avg_Discount_Pct,
    ROUND(AVG(Ship_Duration_Days), 1)                              AS Avg_Shipping_Days
FROM superstore;


-- ============================================================================
-- 2. CATEGORY PERFORMANCE: REVENUE VS. PROFIT DIVERGENCE
-- Question: Which product categories drive the highest revenue vs. profit?
-- Business Insight: Furniture generates $742K in sales (32% of total revenue) 
-- but only delivers $18.5K in profit (a meager 2.49% margin). Technology and 
-- Office Supplies both generate healthy ~17% margins.
-- ============================================================================
SELECT 
    Category,
    COUNT(DISTINCT Order_ID)                                        AS Total_Orders,
    ROUND(SUM(Sales), 2)                                            AS Total_Revenue,
    ROUND(SUM(Sales) * 100.0 / (SELECT SUM(Sales) FROM superstore), 2) AS Revenue_Share_Pct,
    ROUND(SUM(Profit), 2)                                           AS Total_Profit,
    ROUND(SUM(Profit) * 100.0 / (SELECT SUM(Profit) FROM superstore), 2) AS Profit_Share_Pct,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                      AS Profit_Margin_Pct
FROM superstore
GROUP BY Category
ORDER BY Total_Profit DESC;


-- ============================================================================
-- 3. SUB-CATEGORY PROFITABILITY AUDIT (UNCOVERING MARGIN BLEED)
-- Question: Which sub-categories are losing money despite substantial sales volume?
-- Business Insight: Tables (-$17,725 loss), Bookcases (-$3,473 loss), and Supplies 
-- (-$1,189 loss) are net loss leaders that drag down overall retail performance.
-- ============================================================================
SELECT 
    Category,
    Sub_Category,
    ROUND(SUM(Sales), 2)                                            AS Total_Sales,
    ROUND(SUM(Profit), 2)                                           AS Total_Profit,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                      AS Profit_Margin_Pct,
    SUM(CASE WHEN Profit < 0 THEN 1 ELSE 0 END)                     AS Loss_Making_Orders,
    ROUND(SUM(CASE WHEN Profit < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Loss_Order_Pct
FROM superstore
GROUP BY Category, Sub_Category
ORDER BY Total_Profit ASC;


-- ============================================================================
-- 4. THE "DISCOUNT CLIFF" ANALYSIS
-- Question: Does offering higher discounts actually hurt profitability?
-- Business Insight: Transactions with discounts <= 20% generate strong positive 
-- margins (11.6% to 29.5%). However, discounts > 20% collapse into an average 
-- -37.3% margin, resulting in $135,376 in cumulative losses across 1,393 orders.
-- ============================================================================
SELECT 
    Discount_Tier,
    COUNT(*)                                                        AS Item_Count,
    ROUND(SUM(Sales), 2)                                            AS Total_Sales,
    ROUND(SUM(Profit), 2)                                           AS Total_Profit,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                      AS Profit_Margin_Pct,
    ROUND(AVG(Discount) * 100.0, 1)                                 AS Avg_Discount_Pct
FROM superstore
GROUP BY Discount_Tier
ORDER BY Avg_Discount_Pct ASC;


-- ============================================================================
-- 5. REGIONAL PERFORMANCE & GEOGRAPHIC MARGIN GAP
-- Question: Which geographic regions drive profitability vs. operational drag?
-- Business Insight: West ($108.4K profit, 14.9% margin) and East ($91.5K profit, 
-- 13.5% margin) lead. Central lags severely at 7.9% margin due to aggressive 
-- discounting (average discount 24.0% vs 10.9% in West).
-- ============================================================================
SELECT 
    Region,
    COUNT(DISTINCT State)                                           AS Active_States,
    COUNT(DISTINCT Order_ID)                                        AS Total_Orders,
    ROUND(SUM(Sales), 2)                                            AS Total_Sales,
    ROUND(SUM(Profit), 2)                                           AS Total_Profit,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                      AS Profit_Margin_Pct,
    ROUND(AVG(Discount) * 100.0, 1)                                 AS Avg_Discount_Pct
FROM superstore
GROUP BY Region
ORDER BY Total_Profit DESC;


-- ============================================================================
-- 6. TOP 5 PROFITABLE STATES VS. TOP 5 LOSS-MAKING STATES
-- Question: Which states generate the highest returns vs. the deepest deficits?
-- Business Insight: California ($76.4K profit) and New York ($74.0K profit) lead. 
-- Texas (-$25.7K) and Ohio (-$17.0K) suffer severe deficits driven by state-level 
-- discounting practices.
-- ============================================================================
WITH State_Metrics AS (
    SELECT 
        State,
        Region,
        ROUND(SUM(Sales), 2)                                        AS Total_Sales,
        ROUND(SUM(Profit), 2)                                       AS Total_Profit,
        ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                  AS Profit_Margin_Pct,
        ROUND(AVG(Discount) * 100.0, 1)                             AS Avg_Discount_Pct,
        RANK() OVER (ORDER BY SUM(Profit) DESC)                     AS Rank_Best,
        RANK() OVER (ORDER BY SUM(Profit) ASC)                      AS Rank_Worst
    FROM superstore
    GROUP BY State, Region
)
SELECT 
    State,
    Region,
    Total_Sales,
    Total_Profit,
    Profit_Margin_Pct,
    Avg_Discount_Pct,
    CASE 
        WHEN Rank_Best <= 5 THEN 'Top 5 Profitable'
        ELSE 'Top 5 Loss-Making'
    END AS Segment_Type
FROM State_Metrics
WHERE Rank_Best <= 5 OR Rank_Worst <= 5
ORDER BY Total_Profit DESC;


-- ============================================================================
-- 7. MONTHLY REVENUE & PROFIT TREND (SEASONALITY & Q4 SURGE)
-- Question: What is the monthly seasonal pattern in revenue and profitability?
-- Business Insight: Peak sales occur in Q4 (September through December), with 
-- November and December driving ~30% of annual revenue. Q1 (Jan/Feb) experiences 
-- a seasonal post-holiday slump.
-- ============================================================================
SELECT 
    Order_Month,
    Order_Month_Name,
    COUNT(DISTINCT Order_ID)                                        AS Order_Volume,
    ROUND(SUM(Sales), 2)                                            AS Total_Sales,
    ROUND(SUM(Profit), 2)                                           AS Total_Profit,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                      AS Profit_Margin_Pct
FROM superstore
GROUP BY Order_Month, Order_Month_Name
ORDER BY Order_Month ASC;


-- ============================================================================
-- 8. CUSTOMER SEGMENT ECONOMICS & VALUE ANALYSIS
-- Question: Which customer segment is the most valuable and profitable?
-- Business Insight: Consumer segment drives the highest absolute revenue ($1.16M, 
-- 50.5%) and profit ($134.1K). However, Home Office generates the highest 
-- profit margin (14.03%) and highest Average Order Value ($472.67).
-- ============================================================================
SELECT 
    Segment,
    COUNT(DISTINCT Customer_ID)                                     AS Unique_Customers,
    COUNT(DISTINCT Order_ID)                                        AS Total_Orders,
    ROUND(SUM(Sales), 2)                                            AS Total_Sales,
    ROUND(SUM(Profit), 2)                                           AS Total_Profit,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                      AS Profit_Margin_Pct,
    ROUND(SUM(Sales) / COUNT(DISTINCT Order_ID), 2)                 AS Avg_Order_Value,
    ROUND(SUM(Sales) / COUNT(DISTINCT Customer_ID), 2)              AS Revenue_Per_Customer
FROM superstore
GROUP BY Segment
ORDER BY Total_Sales DESC;


-- ============================================================================
-- 9. TOP 10 HIGH-VALUE CUSTOMERS (RFM FOUNDATIONS)
-- Question: Who are our highest-spending customers, and how profitable are they?
-- Business Insight: Tom Boeckenhauer and Tamara Chand top the list, generating 
-- over $6,500+ in profit with high average order values and low discount dependency.
-- ============================================================================
SELECT 
    Customer_ID,
    Customer_Name,
    Segment,
    COUNT(DISTINCT Order_ID)                                        AS Order_Frequency,
    ROUND(SUM(Sales), 2)                                            AS Total_Spend,
    ROUND(SUM(Profit), 2)                                           AS Total_Profit_Generated,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                      AS Margin_Pct,
    ROUND(AVG(Discount) * 100.0, 1)                                 AS Avg_Discount_Received
FROM superstore
GROUP BY Customer_ID, Customer_Name, Segment
ORDER BY Total_Spend DESC
LIMIT 10;


-- ============================================================================
-- 10. PRODUCT ANALYSIS: TOP 5 CASH COWS VS. TOP 5 WEALTH DESTROYERS
-- Question: Which specific products create the most value vs. destroy margin?
-- Business Insight: Canon imageCLASS 2200 Copier creates $25,199 in pure profit. 
-- Conversely, Cubify CubeX 3D Printers destroy over $12,700 in margin when discounted.
-- ============================================================================
WITH Ranked_Products AS (
    SELECT 
        Product_Name,
        Category,
        Sub_Category,
        ROUND(SUM(Sales), 2)                                        AS Total_Sales,
        ROUND(SUM(Profit), 2)                                       AS Total_Profit,
        ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                  AS Margin_Pct,
        ROW_NUMBER() OVER (ORDER BY SUM(Profit) DESC)               AS Rank_Best,
        ROW_NUMBER() OVER (ORDER BY SUM(Profit) ASC)                AS Rank_Worst
    FROM superstore
    GROUP BY Product_Name, Category, Sub_Category
)
SELECT 
    CASE 
        WHEN Rank_Best <= 5 THEN 'Top Profit Contributor'
        ELSE 'Top Loss Drain'
    END                                                             AS Product_Classification,
    Product_Name,
    Category,
    Sub_Category,
    Total_Sales,
    Total_Profit,
    Margin_Pct
FROM Ranked_Products
WHERE Rank_Best <= 5 OR Rank_Worst <= 5
ORDER BY Total_Profit DESC;


-- ============================================================================
-- 11. SHIPPING MODE EFFICIENCY & DELIVERY DURATION
-- Question: How does fulfillment latency affect customer segments and profit margins?
-- Business Insight: Standard Class delivers 59.7% of volume at 12.0% margin. 
-- Same Day delivery commands the highest profit margin (13.7%) with 0.04-day latency.
-- ============================================================================
SELECT 
    Ship_Mode,
    COUNT(DISTINCT Order_ID)                                        AS Total_Orders,
    ROUND(AVG(Ship_Duration_Days), 2)                               AS Avg_Delivery_Days,
    ROUND(SUM(Sales), 2)                                            AS Total_Sales,
    ROUND(SUM(Profit), 2)                                           AS Total_Profit,
    ROUND(SUM(Profit) * 100.0 / SUM(Sales), 2)                      AS Profit_Margin_Pct
FROM superstore
GROUP BY Ship_Mode
ORDER BY Total_Sales DESC;
