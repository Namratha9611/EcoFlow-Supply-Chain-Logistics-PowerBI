/* ============================================================================
   POWER QUERY (M) TRANSFORMATION CODE
   Project: EcoFlow — Supply Chain & Logistics Intelligence Dashboard
   ============================================================================
   Create each Query separately in Power Query Editor (Home > Advanced Editor)
   ============================================================================ */

// ============================================================================
// QUERY 1: DataCoSupplyChainDataset
// Target Name: DataCoSupplyChainDataset
// ============================================================================

let
    // 1. Load Raw CSV File
    Source = Csv.Document(
        File.Contents("c:\Data Analyst course certificate\Power BI\EcoFlow_Supply_Chain_Analytics\Dataset\DataCoSupplyChainDataset.csv"),
        [Delimiter=",", Columns=53, Encoding=1252, QuoteStyle=QuoteStyle.Csv]
    ),
    
    // 2. Promote Headers
    PromotedHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    
    // 3. Transform Data Types for all 53 Columns
    TypedTable = Table.TransformColumnTypes(PromotedHeaders, {
        {"Type", type text},
        {"Days for shipping (real)", Int64.Type},
        {"Days for shipment (scheduled)", Int64.Type},
        {"Benefit per order", Currency.Type},
        {"Sales per customer", Currency.Type},
        {"Delivery Status", type text},
        {"Late_delivery_risk", Int64.Type},
        {"Category Id", Int64.Type},
        {"Category Name", type text},
        {"Customer City", type text},
        {"Customer Country", type text},
        {"Customer Email", type text},
        {"Customer Fname", type text},
        {"Customer Id", Int64.Type},
        {"Customer Lname", type text},
        {"Customer Segment", type text},
        {"Customer State", type text},
        {"Customer Street", type text},
        {"Customer Zipcode", type text},
        {"Department Id", Int64.Type},
        {"Department Name", type text},
        {"Latitude", type number},
        {"Longitude", type number},
        {"Market", type text},
        {"Order City", type text},
        {"Order Country", type text},
        {"Order Customer Id", Int64.Type},
        {"order date (DateOrders)", type datetime},
        {"Order Id", Int64.Type},
        {"Order Item Cardprod Id", Int64.Type},
        {"Order Item Discount", Currency.Type},
        {"Order Item Discount Rate", type number},
        {"Order Item Id", Int64.Type},
        {"Order Item Product Price", Currency.Type},
        {"Order Item Profit Ratio", type number},
        {"Order Item Quantity", Int64.Type},
        {"Sales", Currency.Type},
        {"Order Item Total", Currency.Type},
        {"Order Profit Per Order", Currency.Type},
        {"Order Region", type text},
        {"Order State", type text},
        {"Order Status", type text},
        {"Order Zipcode", type text},
        {"Product Card Id", Int64.Type},
        {"Product Category Id", Int64.Type},
        {"Product Description", type text},
        {"Product Image", type text},
        {"Product Name", type text},
        {"Product Price", Currency.Type},
        {"Product Status", Int64.Type},
        {"shipping date (DateOrders)", type datetime},
        {"Shipping Mode", type text}
    }),

    // 4. Feature Engineering: Shipping Delay (Days)
    AddShippingDelay = Table.AddColumn(
        TypedTable, 
        "Shipping Delay (Days)", 
        each [#"Days for shipping (real)"] - [#"Days for shipment (scheduled)"], 
        Int64.Type
    ),

    // 5. Feature Engineering: Delivery Binary Flags
    AddIsLate = Table.AddColumn(
        AddShippingDelay, 
        "Is Late Delivery", 
        each if [Delivery Status] = "Late delivery" then 1 else 0, 
        Int64.Type
    ),
    
    AddIsOnTime = Table.AddColumn(
        AddIsLate, 
        "Is On Time Delivery", 
        each if [Delivery Status] = "Shipping on time" or [Delivery Status] = "Advance shipping" then 1 else 0, 
        Int64.Type
    ),

    // 6. Feature Engineering: Lead Time Category
    AddLeadTimeCat = Table.AddColumn(
        AddIsOnTime, 
        "Lead Time Category", 
        each if [#"Shipping Delay (Days)"] <= 0 then "On-Time / Early"
             else if [#"Shipping Delay (Days)"] <= 2 then "Minor Delay (1-2 Days)"
             else "Major Delay (>2 Days)", 
        type text
    ),

    // 7. Feature Engineering: Customer Full Name
    AddFullName = Table.AddColumn(
        AddLeadTimeCat, 
        "Customer Full Name", 
        each Text.Combine({Text.Trim([Customer Fname]), Text.Trim([Customer Lname])}, " "), 
        type text
    )
in
    AddFullName


// ============================================================================
// QUERY 2: Dim_Date (Power Query Calendar Table)
// Target Name: Dim_Date
// ============================================================================

/*
let
    StartDate = #date(2015, 1, 1),
    EndDate = #date(2018, 12, 31),
    DayCount = Duration.Days(EndDate - StartDate) + 1,
    SourceDates = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),
    TableFromList = Table.FromList(SourceDates, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    ChangedType = Table.TransformColumnTypes(TableFromList, {{"Date", type date}}),
    AddYear = Table.AddColumn(ChangedType, "Year", each Date.Year([Date]), Int64.Type),
    AddMonthNo = Table.AddColumn(AddYear, "Month Number", each Date.Month([Date]), Int64.Type),
    AddMonthName = Table.AddColumn(AddMonthNo, "Month Name", each Date.MonthName([Date]), type text),
    AddYearMonth = Table.AddColumn(AddMonthName, "Year-Month", each Text.From([Year]) & "-" & Text.PadStart(Text.From([Month Number]), 2, "0"), type text),
    AddQuarter = Table.AddColumn(AddYearMonth, "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    AddDayOfWeek = Table.AddColumn(AddQuarter, "Day of Week", each Date.DayOfWeekName([Date]), type text),
    AddIsWeekend = Table.AddColumn(AddDayOfWeek, "Is Weekend", each if Date.DayOfWeek([Date]) >= 5 then "Yes" else "No", type text)
in
    AddIsWeekend
*/
