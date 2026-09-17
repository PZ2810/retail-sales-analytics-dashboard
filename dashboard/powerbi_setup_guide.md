# 📊 Power BI Architecture & DAX Implementation Guide
### Superstore Retail Sales Analytics Dashboard

This document details the data modeling, DAX measures, and report design specifications required to reproduce the interactive executive dashboard in **Power BI Desktop** or **Tableau**.

---

## 1. Data Model & Schema Architecture (Star Schema)

For enterprise-grade reporting, avoid flat reporting tables. Structure the Superstore dataset into a clean **Star Schema**:

```
                       ┌──────────────────────┐
                       │   Dim_Date           │
                       ├──────────────────────┤
                       │ DateKey (PK)         │
                       │ Date                 │
                       │ Year                 │
                       │ Quarter              │
                       │ Month                │
                       └──────────┬───────────┘
                                  │ 1
                                  │
                                  │ *
┌──────────────────────┐       ┌──┴───────────────────┐       ┌──────────────────────┐
│   Dim_Customer       │       │   Fact_Sales         │       │   Dim_Product        │
├──────────────────────┤       ├──────────────────────┤       ├──────────────────────┤
│ Customer_ID (PK)     │1    * │ Row_ID (PK)          │ *    1│ Product_ID (PK)      │
│ Customer_Name        ├───────┤ Order_ID             ├───────┤ Product_Name         │
│ Segment              │       │ Customer_ID (FK)     │       │ Category             │
│ City, State, Region  │       │ Product_ID (FK)      │       │ Sub_Category         │
└──────────────────────┘       │ Order_Date (FK)      │       └──────────────────────┘
                               │ Ship_Date            │
                               │ Sales                │
                               │ Quantity             │
                               │ Discount             │
                               │ Profit               │
                               └──────────────────────┘
```

---

## 2. Core DAX Measures (DAX Formula Library)

Create a dedicated `_Measures` table in Power BI and implement the following business logic:

### A. Topline Financial Measures
```dax
// Total Revenue (Sales)
Total Sales = 
SUM(Fact_Sales[Sales])

// Total Profit
Total Profit = 
SUM(Fact_Sales[Profit])

// Profit Margin Percentage
Profit Margin % = 
DIVIDE([Total Profit], [Total Sales], 0)

// Total Unique Orders
Total Orders = 
DISTINCTCOUNT(Fact_Sales[Order_ID])

// Total Customers
Total Customers = 
DISTINCTCOUNT(Fact_Sales[Customer_ID])

// Average Order Value (AOV)
Average Order Value = 
DIVIDE([Total Sales], [Total Orders], 0)
```

### B. Margin & Discount Diagnostics
```dax
// Average Discount Percentage
Avg Discount Rate = 
AVERAGE(Fact_Sales[Discount])

// Total Losses Generated on Discounted Items
Deep Discount Losses = 
CALCULATE(
    [Total Profit],
    Fact_Sales[Discount] > 0.20
)

// Percentage of Unprofitable Order Items
Unprofitable Line Items % = 
VAR TotalItems = COUNTROWS(Fact_Sales)
VAR NegativeProfitItems = CALCULATE(COUNTROWS(Fact_Sales), Fact_Sales[Profit] < 0)
RETURN
DIVIDE(NegativeProfitItems, TotalItems, 0)
```

### C. Time Intelligence & Growth
```dax
// Sales Previous Year (YoY)
Sales SPLY = 
CALCULATE([Total Sales], SAMEPERIODLASTYEAR(Dim_Date[Date]))

// Year-over-Year Sales Growth %
Sales YoY Growth % = 
DIVIDE([Total Sales] - [Sales SPLY], [Sales SPLY], 0)

// Profit Previous Year (YoY)
Profit SPLY = 
CALCULATE([Total Profit], SAMEPERIODLASTYEAR(Dim_Date[Date]))

// Year-over-Year Profit Growth %
Profit YoY Growth % = 
DIVIDE([Total Profit] - [Profit SPLY], [Profit SPLY], 0)
```

---

## 3. Visual Specifications & Layout

| Visual Container | Visual Type | Fields / Dimensions | Formatting Rules |
| :--- | :--- | :--- | :--- |
| **KPI Card 1** | New Card Visual | `[Total Sales]` | Currency `$#,##0`, display unit: `$2.30M`. |
| **KPI Card 2** | New Card Visual | `[Total Profit]` | Currency `$#,##0`, color `#10b981`. |
| **KPI Card 3** | New Card Visual | `[Profit Margin %]` | Percentage `12.5%`, conditional background if `< 10%`. |
| **KPI Card 4** | New Card Visual | `[Total Orders]` | Integer `5,009`, Sub-text: `[Unprofitable Line Items %]`. |
| **Chart 1** | Line & Clustered Column | X: `Dim_Date[YearMonth]`, Y1: `[Total Sales]`, Y2: `[Total Profit]` | Dual-axis line with dashed profit trend. |
| **Chart 2** | Horizontal Bar Chart | Y: `Sub_Category`, X: `[Total Profit]` | Diverging colors: Red if `< $0`, Blue if `> $0`. |
| **Chart 3** | Clustered Column Chart | X: `Discount_Tier`, Y: `[Profit Margin %]` | Highlights 20% cliff in red. |
| **Chart 4** | Matrix / Table | Rows: `Product_Name`, Values: `[Total Sales]`, `[Total Profit]`, `[Profit Margin %]` | Conditional data bars on `[Total Profit]`. |
| **Slicers** | Tile / Dropdown Slicers | `Region`, `Segment`, `Order_Year` | Sync slicers across all pages. |

---

## 4. Key Takeaways for Stakeholder Presentation
When presenting this dashboard to senior leadership or interview panels:
1. **Highlight the Divergence**: Always contrast high-volume products with their actual bottom-line returns (e.g., Furniture sales vs profit).
2. **Quantify the Recommendation**: Don't just say "discounts hurt margins" — state the exact business outcome: *"By capping discounts at 20%, we eliminate -$135,376 in margin leakage without impacting the 86% of healthy transactions."*
