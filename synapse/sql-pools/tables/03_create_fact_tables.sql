-- =====================================================
-- Azure Synapse Analytics Data Platform (ASADP)
-- Fact Tables Creation Script
-- =====================================================

-- Create fact tables for the data warehouse
-- Using appropriate distribution and indexing strategies

-- =====================================================
-- Sales Fact Table
-- =====================================================
CREATE TABLE curated.FactSales (
    SalesKey BIGINT IDENTITY(1,1) NOT NULL,
    SalesOrderID VARCHAR(50) NOT NULL,
    SalesOrderLineID VARCHAR(50) NOT NULL,
    DateKey INT NOT NULL,
    TimeKey INT NOT NULL,
    CustomerKey BIGINT NOT NULL,
    ProductKey BIGINT NOT NULL,
    EmployeeKey BIGINT NOT NULL,
    GeographyKey BIGINT NOT NULL,
    SalesChannelKey BIGINT NOT NULL,
    CampaignKey BIGINT,
    CurrencyKey BIGINT NOT NULL,
    
    -- Measures
    Quantity DECIMAL(18,2) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL,
    SalesAmount DECIMAL(18,2) NOT NULL,
    CostAmount DECIMAL(18,2) NOT NULL,
    GrossProfit DECIMAL(18,2) NOT NULL,
    DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    TaxAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    NetSalesAmount DECIMAL(18,2) NOT NULL,
    
    -- Additional Metrics
    ProfitMargin DECIMAL(5,4) NOT NULL,
    CommissionAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    
    -- Audit Fields
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    BatchID VARCHAR(100)
)
WITH (
    DISTRIBUTION = HASH(CustomerKey),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (DateKey RANGE RIGHT FOR VALUES (
        20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
        20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
        20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
        20250701, 20250801, 20250901, 20251001, 20251101, 20251201
    ))
);

-- =====================================================
-- Inventory Fact Table
-- =====================================================
CREATE TABLE curated.FactInventory (
    InventoryKey BIGINT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    ProductKey BIGINT NOT NULL,
    GeographyKey BIGINT NOT NULL,
    SupplierKey BIGINT,
    
    -- Measures
    BeginningInventory DECIMAL(18,2) NOT NULL DEFAULT 0,
    EndingInventory DECIMAL(18,2) NOT NULL DEFAULT 0,
    ReceivedQuantity DECIMAL(18,2) NOT NULL DEFAULT 0,
    SoldQuantity DECIMAL(18,2) NOT NULL DEFAULT 0,
    AdjustmentQuantity DECIMAL(18,2) NOT NULL DEFAULT 0,
    DamagedQuantity DECIMAL(18,2) NOT NULL DEFAULT 0,
    
    -- Costs
    UnitCost DECIMAL(18,2) NOT NULL,
    TotalCost DECIMAL(18,2) NOT NULL,
    
    -- Metrics
    DaysOnHand INT,
    TurnoverRate DECIMAL(10,4),
    
    -- Audit Fields
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    BatchID VARCHAR(100)
)
WITH (
    DISTRIBUTION = HASH(ProductKey),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (DateKey RANGE RIGHT FOR VALUES (
        20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
        20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
        20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
        20250701, 20250801, 20250901, 20251001, 20251101, 20251201
    ))
);

-- =====================================================
-- Customer Behavior Fact Table
-- =====================================================
CREATE TABLE curated.FactCustomerBehavior (
    BehaviorKey BIGINT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    TimeKey INT NOT NULL,
    CustomerKey BIGINT NOT NULL,
    ProductKey BIGINT,
    GeographyKey BIGINT NOT NULL,
    SalesChannelKey BIGINT NOT NULL,
    
    -- Event Information
    EventType VARCHAR(100) NOT NULL, -- PageView, ProductView, AddToCart, Purchase, etc.
    SessionID VARCHAR(100),
    DeviceType VARCHAR(50),
    Browser VARCHAR(50),
    OperatingSystem VARCHAR(50),
    
    -- Measures
    Duration INT, -- in seconds
    PageViews INT DEFAULT 0,
    ClickCount INT DEFAULT 0,
    ConversionFlag BIT DEFAULT 0,
    
    -- Audit Fields
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    BatchID VARCHAR(100)
)
WITH (
    DISTRIBUTION = HASH(CustomerKey),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (DateKey RANGE RIGHT FOR VALUES (
        20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
        20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
        20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
        20250701, 20250801, 20250901, 20251001, 20251101, 20251201
    ))
);

-- =====================================================
-- Marketing Campaign Performance Fact Table
-- =====================================================
CREATE TABLE curated.FactCampaignPerformance (
    CampaignPerformanceKey BIGINT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    CampaignKey BIGINT NOT NULL,
    SalesChannelKey BIGINT NOT NULL,
    GeographyKey BIGINT NOT NULL,
    
    -- Measures
    Impressions BIGINT NOT NULL DEFAULT 0,
    Clicks BIGINT NOT NULL DEFAULT 0,
    Conversions BIGINT NOT NULL DEFAULT 0,
    Leads BIGINT NOT NULL DEFAULT 0,
    Cost DECIMAL(18,2) NOT NULL DEFAULT 0,
    Revenue DECIMAL(18,2) NOT NULL DEFAULT 0,
    
    -- Calculated Metrics
    ClickThroughRate DECIMAL(5,4) NOT NULL DEFAULT 0,
    ConversionRate DECIMAL(5,4) NOT NULL DEFAULT 0,
    CostPerClick DECIMAL(18,2) NOT NULL DEFAULT 0,
    CostPerConversion DECIMAL(18,2) NOT NULL DEFAULT 0,
    ReturnOnAdSpend DECIMAL(10,4) NOT NULL DEFAULT 0,
    
    -- Audit Fields
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    BatchID VARCHAR(100)
)
WITH (
    DISTRIBUTION = HASH(CampaignKey),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (DateKey RANGE RIGHT FOR VALUES (
        20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
        20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
        20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
        20250701, 20250801, 20250901, 20251001, 20251101, 20251201
    ))
);

-- =====================================================
-- Financial Performance Fact Table
-- =====================================================
CREATE TABLE curated.FactFinancialPerformance (
    FinancialKey BIGINT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    GeographyKey BIGINT NOT NULL,
    CurrencyKey BIGINT NOT NULL,
    
    -- Account Information
    AccountType VARCHAR(100) NOT NULL, -- Revenue, Expense, Asset, Liability, Equity
    AccountCategory VARCHAR(100) NOT NULL,
    AccountSubCategory VARCHAR(100),
    
    -- Measures
    ActualAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    BudgetAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    ForecastAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    PriorYearAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    
    -- Calculated Fields
    BudgetVariance DECIMAL(18,2) NOT NULL DEFAULT 0,
    BudgetVariancePercent DECIMAL(5,4) NOT NULL DEFAULT 0,
    YearOverYearGrowth DECIMAL(5,4) NOT NULL DEFAULT 0,
    
    -- Audit Fields
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    BatchID VARCHAR(100)
)
WITH (
    DISTRIBUTION = HASH(GeographyKey),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (DateKey RANGE RIGHT FOR VALUES (
        20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
        20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
        20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
        20250701, 20250801, 20250901, 20251001, 20251101, 20251201
    ))
);

-- =====================================================
-- Quality Metrics Fact Table
-- =====================================================
CREATE TABLE curated.FactQualityMetrics (
    QualityKey BIGINT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    ProductKey BIGINT NOT NULL,
    SupplierKey BIGINT,
    GeographyKey BIGINT NOT NULL,
    
    -- Quality Measures
    DefectCount INT NOT NULL DEFAULT 0,
    TotalUnits INT NOT NULL DEFAULT 0,
    DefectRate DECIMAL(5,4) NOT NULL DEFAULT 0,
    CustomerComplaints INT NOT NULL DEFAULT 0,
    Returns INT NOT NULL DEFAULT 0,
    ReturnRate DECIMAL(5,4) NOT NULL DEFAULT 0,
    
    -- Cost Impact
    QualityCost DECIMAL(18,2) NOT NULL DEFAULT 0,
    ReworkCost DECIMAL(18,2) NOT NULL DEFAULT 0,
    WarrantyCost DECIMAL(18,2) NOT NULL DEFAULT 0,
    
    -- Audit Fields
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    BatchID VARCHAR(100)
)
WITH (
    DISTRIBUTION = HASH(ProductKey),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (DateKey RANGE RIGHT FOR VALUES (
        20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
        20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
        20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
        20250701, 20250801, 20250901, 20251001, 20251101, 20251201
    ))
);

-- =====================================================
-- Employee Performance Fact Table
-- =====================================================
CREATE TABLE curated.FactEmployeePerformance (
    EmployeePerformanceKey BIGINT IDENTITY(1,1) NOT NULL,
    DateKey INT NOT NULL,
    EmployeeKey BIGINT NOT NULL,
    GeographyKey BIGINT NOT NULL,
    
    -- Performance Measures
    SalesTarget DECIMAL(18,2) NOT NULL DEFAULT 0,
    SalesActual DECIMAL(18,2) NOT NULL DEFAULT 0,
    SalesAchievementPercent DECIMAL(5,4) NOT NULL DEFAULT 0,
    CustomerSatisfactionScore DECIMAL(3,2) NOT NULL DEFAULT 0,
    ProductivityScore DECIMAL(5,2) NOT NULL DEFAULT 0,
    
    -- Activity Measures
    CallsMade INT NOT NULL DEFAULT 0,
    MeetingsHeld INT NOT NULL DEFAULT 0,
    DealsWon INT NOT NULL DEFAULT 0,
    DealsLost INT NOT NULL DEFAULT 0,
    WinRate DECIMAL(5,4) NOT NULL DEFAULT 0,
    
    -- Compensation
    BaseSalary DECIMAL(18,2) NOT NULL DEFAULT 0,
    Commission DECIMAL(18,2) NOT NULL DEFAULT 0,
    Bonus DECIMAL(18,2) NOT NULL DEFAULT 0,
    TotalCompensation DECIMAL(18,2) NOT NULL DEFAULT 0,
    
    -- Audit Fields
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown',
    BatchID VARCHAR(100)
)
WITH (
    DISTRIBUTION = HASH(EmployeeKey),
    CLUSTERED COLUMNSTORE INDEX,
    PARTITION (DateKey RANGE RIGHT FOR VALUES (
        20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
        20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
        20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
        20250701, 20250801, 20250901, 20251001, 20251101, 20251201
    ))
);

PRINT 'Fact tables created successfully!'
GO