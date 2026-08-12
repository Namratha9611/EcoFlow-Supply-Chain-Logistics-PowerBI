# ⚡ EcoFlow — Supply Chain & Logistics Intelligence Dashboard
## Complete Native Power BI Implementation Guide

---

## ✅ Verified Dataset Metrics (From Raw CSV — 180,519 rows)

| Metric | Verified Value |
|:---|:---|
| Total Revenue | **$36,784,735** |
| Total Net Profit | **$3,966,903** |
| Profit Margin % | **10.78%** |
| Unique Orders | **65,752** |
| Average Order Value | **$559.45** |
| On-Time Delivery Rate | **40.88%** (Advance shipping + Shipping on time) |
| Late Delivery Rate | **54.83%** |
| Shipping Canceled | **4.30%** |

### Delivery Status (Verified):
| Status | Count | % |
|:---|---:|---:|
| Late delivery | 98,977 | 54.83% |
| Advance shipping | 41,592 | 23.04% |
| Shipping on time | 32,196 | 17.84% |
| Shipping canceled | 7,754 | 4.30% |

> ✅ **On-Time = Advance shipping + Shipping on time = 40.88%** (NOT 57.3%)

---

## ⚙️ STEP 1: Power Query ETL

Open Power BI Desktop → **Get Data** → **Text/CSV** → Select `DataCoSupplyChainDataset.csv` → **Transform Data** → **Advanced Editor** → paste:

```powerquery
let
    Source = Csv.Document(
        File.Contents("c:\Data Analyst course certificate\Power BI\EcoFlow_Supply_Chain_Analytics\Dataset\DataCoSupplyChainDataset.csv"),
        [Delimiter=",", Columns=53, Encoding=1252, QuoteStyle=QuoteStyle.Csv]
    ),
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    TypedTable = Table.TransformColumnTypes(PromotedHeaders, {
        {"Days for shipping (real)", Int64.Type},
        {"Days for shipment (scheduled)", Int64.Type},
        {"Benefit per order", Currency.Type},
        {"Sales per customer", Currency.Type},
        {"Delivery Status", type text},
        {"Late_delivery_risk", Int64.Type},
        {"Category Name", type text},
        {"Customer City", type text},
        {"Customer Country", type text},
        {"Customer Fname", type text},
        {"Customer Lname", type text},
        {"Customer Segment", type text},
        {"Department Name", type text},
        {"Market", type text},
        {"Order City", type text},
        {"Order Country", type text},
        {"order date (DateOrders)", type datetime},
        {"Order Id", Int64.Type},
        {"Order Item Discount", Currency.Type},
        {"Order Item Discount Rate", type number},
        {"Order Item Id", Int64.Type},
        {"Order Item Product Price", Currency.Type},
        {"Order Item Quantity", Int64.Type},
        {"Sales", Currency.Type},
        {"Order Profit Per Order", Currency.Type},
        {"Order Region", type text},
        {"Order Status", type text},
        {"Product Name", type text},
        {"Product Price", Currency.Type},
        {"shipping date (DateOrders)", type datetime},
        {"Shipping Mode", type text}
    }),
    AddShippingDelay = Table.AddColumn(TypedTable, "Shipping Delay (Days)", each [#"Days for shipping (real)"] - [#"Days for shipment (scheduled)"], Int64.Type),
    AddIsLate = Table.AddColumn(AddShippingDelay, "Is Late Delivery", each if [Delivery Status] = "Late delivery" then 1 else 0, Int64.Type),
    AddIsOnTime = Table.AddColumn(AddIsLate, "Is On Time Delivery", each if [Delivery Status] = "Shipping on time" or [Delivery Status] = "Advance shipping" then 1 else 0, Int64.Type),
    AddLeadTimeCat = Table.AddColumn(AddIsOnTime, "Lead Time Category", each if [#"Shipping Delay (Days)"] <= 0 then "On-Time / Early" else if [#"Shipping Delay (Days)"] <= 2 then "Minor Delay (1-2 Days)" else "Major Delay (>2 Days)", type text),
    AddFullName = Table.AddColumn(AddLeadTimeCat, "Customer Full Name", each Text.Combine({Text.Trim([Customer Fname]), Text.Trim([Customer Lname])}, " "), type text)
in
    AddFullName
```

---

## 📅 STEP 2: Create `Dim_Date` Table (DAX)

**Modeling** → **New Table**:
```dax
Dim_Date = 
VAR MinDate = MIN(DataCoSupplyChainDataset[order date (DateOrders)])
VAR MaxDate = MAX(DataCoSupplyChainDataset[order date (DateOrders)])
RETURN
ADDCOLUMNS(
    CALENDAR(MinDate, MaxDate),
    "Year", YEAR([Date]),
    "Month Number", MONTH([Date]),
    "Month Name", FORMAT([Date], "mmmm"),
    "Year-Month", FORMAT([Date], "YYYY-MM"),
    "Quarter", "Q" & FORMAT([Date], "Q")
)
```

In **Model View**: Connect `Dim_Date[Date]` → `DataCoSupplyChainDataset[order date (DateOrders)]` (1-to-Many, Single Direction).

---

## 📐 STEP 3: Core DAX Measures

```dax
Total Sales = SUM(DataCoSupplyChainDataset[Sales])
-- Verified: $36,784,735

Total Profit = SUM(DataCoSupplyChainDataset[Order Profit Per Order])
-- Verified: $3,966,903

Profit Margin % = DIVIDE([Total Profit], [Total Sales], 0)
-- Verified: 10.78%

Total Orders = DISTINCTCOUNT(DataCoSupplyChainDataset[Order Id])
-- Verified: 65,752 unique orders

Average Order Value (AOV) = DIVIDE([Total Sales], [Total Orders], 0)
-- Verified: $559.45

Total Shipments = COUNTROWS(DataCoSupplyChainDataset)
-- Verified: 180,519 rows

On-Time Shipments = CALCULATE(
    COUNTROWS(DataCoSupplyChainDataset),
    DataCoSupplyChainDataset[Delivery Status] = "Advance shipping" ||
    DataCoSupplyChainDataset[Delivery Status] = "Shipping on time"
)
-- Verified: 73,788

Late Shipments = CALCULATE(
    COUNTROWS(DataCoSupplyChainDataset),
    DataCoSupplyChainDataset[Delivery Status] = "Late delivery"
)
-- Verified: 98,977

On-Time Delivery Rate % = DIVIDE([On-Time Shipments], [Total Shipments], 0)
-- Verified: 40.88%

Late Delivery Rate % = DIVIDE([Late Shipments], [Total Shipments], 0)
-- Verified: 54.83%

Avg Shipping Delay (Days) = AVERAGE(DataCoSupplyChainDataset[Shipping Delay (Days)])

Total Quantity Sold = SUM(DataCoSupplyChainDataset[Order Item Quantity])

Sales PM (Prior Month) = CALCULATE([Total Sales], PREVIOUSMONTH(Dim_Date[Date]))

Sales MoM Growth % = 
VAR Prev = [Sales PM (Prior Month)]
RETURN IF(ISBLANK(Prev) || Prev = 0, BLANK(), DIVIDE([Total Sales] - Prev, Prev, 0))
```

---

## 📊 STEP 4: Page-by-Page Visual Field Bindings

### PAGE 1 — Executive Overview & Sales
> ⚠️ Add **real Card visuals** (not text boxes) connected to DAX measures:

1. **Card** → `Total Sales` (Display: $M)
2. **Card** → `Total Profit` (Display: $M)
3. **Card** → `Profit Margin %` (Display: %)
4. **Card** → `On-Time Delivery Rate %` (Display: %, expected: **40.88%**)
5. **Card** → `Average Order Value (AOV)` (Display: $)
6. **Line Chart** → X-axis: `Dim_Date[Year-Month]`, Y-axis: `Total Sales`, Secondary: `Total Profit`
7. **Donut Chart** → Legend: `Market`, Values: `Total Sales`
8. **KPI Visual** → Value: `Total Sales`, Trend: `Dim_Date[Year-Month]`, Target: `Sales PM (Prior Month)`

### PAGE 2 — Delivery & Logistics Performance
1. **Stacked Bar Chart** → Y: `Delivery Status`, X: `Total Shipments`
2. **Clustered Column Chart** → X: `Shipping Mode`, Y: `Total Shipments`, Y2: `Late Shipments`
3. **Column Chart** → X: `Lead Time Category`, Y: `Total Shipments`
4. **Matrix** → Rows: `Order Region`, Values: `Total Shipments`, `On-Time Delivery Rate %`, `Late Delivery Rate %`, `Avg Shipping Delay (Days)`

### PAGE 3 — Product & Category Intelligence
1. **Horizontal Bar Chart** → Y: `Category Name`, X: `Total Sales`, `Total Profit`
2. **Treemap** → Category: `Department Name`, Values: `Total Sales`
3. **Table** → Columns: `Product Name`, `Total Sales`, `Total Quantity Sold`, `Profit Margin %`

### PAGE 4 — Order-Level Analysis & RLS
1. **Table** → Columns: `Order Id`, `order date (DateOrders)`, `Customer Full Name`, `Order Region`, `Category Name`, `Product Name`, `Sales`, `Order Profit Per Order`, `Delivery Status`, `Shipping Delay (Days)`
2. **Slicers** → `Order Region`, `Market`, `Shipping Mode`, `Dim_Date[Year]`

---

## 🔒 STEP 5: Row-Level Security (RLS)
**Modeling** > **Manage Roles** > Create role **`EuropeManager`**:
```dax
DataCoSupplyChainDataset[Order Region] IN {"Western Europe", "Northern Europe", "Southern Europe"}
```
Test via **View as Roles** > `EuropeManager`.
