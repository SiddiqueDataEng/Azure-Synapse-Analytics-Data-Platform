-- =====================================================
-- Azure Synapse Analytics Data Platform (ASADP)
-- Dimension Tables Creation Script
-- =====================================================

-- Create dimension tables for the data warehouse
-- Using Type 2 Slowly Changing Dimensions (SCD) pattern

-- =====================================================
-- Date Dimension Table
-- =====================================================
CREATE TABLE curated.DimDate (
    DateKey INT NOT NULL,
    Date DATE NOT NULL,
    Year INT NOT NULL,
    Quarter INT NOT NULL,
    Month INT NOT NULL,
    MonthName VARCHAR(20) NOT NULL,
    Day INT NOT NULL,
    DayOfWeek INT NOT NULL,
    DayOfWeekName VARCHAR(20) NOT NULL,
    DayOfYear INT NOT NULL,
    WeekOfYear INT NOT NULL,
    IsWeekend BIT NOT NULL,
    IsHoliday BIT NOT NULL DEFAULT 0,
    FiscalYear INT NOT NULL,
    FiscalQuarter INT NOT NULL,
    FiscalMonth INT NOT NULL,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

-- =====================================================
-- Customer Dimension Table (SCD Type 2)
-- =====================================================
CREATE TABLE curated.DimCustomer (
    CustomerKey BIGINT IDENTITY(1,1) NOT NULL,
    CustomerID VARCHAR(50) NOT NULL,
    CustomerName VARCHAR(255) NOT NULL,
    CustomerType VARCHAR(50) NOT NULL,
    Email VARCHAR(255),
    Phone VARCHAR(50),
    Address VARCHAR(500),
    City VARCHAR(100),
    State VARCHAR(100),
    Country VARCHAR(100),
    PostalCode VARCHAR(20),
    Region VARCHAR(100),
    Segment VARCHAR(100),
    Industry VARCHAR(100),
    CompanySize VARCHAR(50),
    AnnualRevenue DECIMAL(18,2),
    CreditRating VARCHAR(10),
    CustomerSince DATE,
    IsActive BIT NOT NULL DEFAULT 1,
    EffectiveDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ExpiryDate DATETIME2 NOT NULL DEFAULT '9999-12-31 23:59:59',
    IsCurrent BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown'
)
WITH (
    DISTRIBUTION = HASH(CustomerID),
    CLUSTERED COLUMNSTORE INDEX
);

-- =====================================================
-- Product Dimension Table (SCD Type 2)
-- =====================================================
CREATE TABLE curated.DimProduct (
    ProductKey BIGINT IDENTITY(1,1) NOT NULL,
    ProductID VARCHAR(50) NOT NULL,
    ProductName VARCHAR(255) NOT NULL,
    ProductDescription VARCHAR(1000),
    Category VARCHAR(100) NOT NULL,
    SubCategory VARCHAR(100),
    Brand VARCHAR(100),
    Manufacturer VARCHAR(100),
    ProductLine VARCHAR(100),
    Color VARCHAR(50),
    Size VARCHAR(50),
    Weight DECIMAL(10,2),
    UnitOfMeasure VARCHAR(20),
    UnitPrice DECIMAL(18,2),
    StandardCost DECIMAL(18,2),
    ListPrice DECIMAL(18,2),
    IsActive BIT NOT NULL DEFAULT 1,
    LaunchDate DATE,
    DiscontinuedDate DATE,
    EffectiveDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ExpiryDate DATETIME2 NOT NULL DEFAULT '9999-12-31 23:59:59',
    IsCurrent BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown'
)
WITH (
    DISTRIBUTION = HASH(ProductID),
    CLUSTERED COLUMNSTORE INDEX
);

-- =====================================================
-- Geography Dimension Table
-- =====================================================
CREATE TABLE curated.DimGeography (
    GeographyKey BIGINT IDENTITY(1,1) NOT NULL,
    GeographyID VARCHAR(50) NOT NULL,
    City VARCHAR(100) NOT NULL,
    StateProvince VARCHAR(100) NOT NULL,
    Country VARCHAR(100) NOT NULL,
    Region VARCHAR(100) NOT NULL,
    Continent VARCHAR(50) NOT NULL,
    PostalCode VARCHAR(20),
    Latitude DECIMAL(10,6),
    Longitude DECIMAL(10,6),
    TimeZone VARCHAR(50),
    CurrencyCode VARCHAR(10),
    LanguageCode VARCHAR(10),
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown'
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

-- =====================================================
-- Sales Channel Dimension Table
-- =====================================================
CREATE TABLE curated.DimSalesChannel (
    SalesChannelKey BIGINT IDENTITY(1,1) NOT NULL,
    SalesChannelID VARCHAR(50) NOT NULL,
    ChannelName VARCHAR(100) NOT NULL,
    ChannelType VARCHAR(50) NOT NULL,
    ChannelDescription VARCHAR(500),
    IsOnline BIT NOT NULL DEFAULT 0,
    CommissionRate DECIMAL(5,4),
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown'
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

-- =====================================================
-- Employee Dimension Table (SCD Type 2)
-- =====================================================
CREATE TABLE curated.DimEmployee (
    EmployeeKey BIGINT IDENTITY(1,1) NOT NULL,
    EmployeeID VARCHAR(50) NOT NULL,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    FullName VARCHAR(255) NOT NULL,
    Email VARCHAR(255),
    Phone VARCHAR(50),
    JobTitle VARCHAR(100),
    Department VARCHAR(100),
    Division VARCHAR(100),
    Manager VARCHAR(255),
    HireDate DATE,
    TerminationDate DATE,
    Salary DECIMAL(18,2),
    CommissionRate DECIMAL(5,4),
    IsActive BIT NOT NULL DEFAULT 1,
    EffectiveDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ExpiryDate DATETIME2 NOT NULL DEFAULT '9999-12-31 23:59:59',
    IsCurrent BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown'
)
WITH (
    DISTRIBUTION = HASH(EmployeeID),
    CLUSTERED COLUMNSTORE INDEX
);

-- =====================================================
-- Campaign Dimension Table
-- =====================================================
CREATE TABLE curated.DimCampaign (
    CampaignKey BIGINT IDENTITY(1,1) NOT NULL,
    CampaignID VARCHAR(50) NOT NULL,
    CampaignName VARCHAR(255) NOT NULL,
    CampaignType VARCHAR(100) NOT NULL,
    CampaignDescription VARCHAR(1000),
    StartDate DATE NOT NULL,
    EndDate DATE,
    Budget DECIMAL(18,2),
    ActualCost DECIMAL(18,2),
    TargetAudience VARCHAR(255),
    Channel VARCHAR(100),
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown'
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

-- =====================================================
-- Supplier Dimension Table (SCD Type 2)
-- =====================================================
CREATE TABLE curated.DimSupplier (
    SupplierKey BIGINT IDENTITY(1,1) NOT NULL,
    SupplierID VARCHAR(50) NOT NULL,
    SupplierName VARCHAR(255) NOT NULL,
    ContactName VARCHAR(255),
    Email VARCHAR(255),
    Phone VARCHAR(50),
    Address VARCHAR(500),
    City VARCHAR(100),
    State VARCHAR(100),
    Country VARCHAR(100),
    PostalCode VARCHAR(20),
    Website VARCHAR(255),
    Industry VARCHAR(100),
    Rating VARCHAR(10),
    PaymentTerms VARCHAR(100),
    IsActive BIT NOT NULL DEFAULT 1,
    EffectiveDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ExpiryDate DATETIME2 NOT NULL DEFAULT '9999-12-31 23:59:59',
    IsCurrent BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    SourceSystem VARCHAR(100) NOT NULL DEFAULT 'Unknown'
)
WITH (
    DISTRIBUTION = HASH(SupplierID),
    CLUSTERED COLUMNSTORE INDEX
);

-- =====================================================
-- Currency Dimension Table
-- =====================================================
CREATE TABLE curated.DimCurrency (
    CurrencyKey BIGINT IDENTITY(1,1) NOT NULL,
    CurrencyCode VARCHAR(10) NOT NULL,
    CurrencyName VARCHAR(100) NOT NULL,
    Symbol VARCHAR(10),
    DecimalPlaces INT NOT NULL DEFAULT 2,
    IsActive BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    ModifiedDate DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

-- =====================================================
-- Time Dimension Table (for intraday analysis)
-- =====================================================
CREATE TABLE curated.DimTime (
    TimeKey INT NOT NULL,
    Time TIME NOT NULL,
    Hour INT NOT NULL,
    Minute INT NOT NULL,
    Second INT NOT NULL,
    HourName VARCHAR(20) NOT NULL,
    DayPeriod VARCHAR(20) NOT NULL, -- Morning, Afternoon, Evening, Night
    BusinessHour BIT NOT NULL DEFAULT 0,
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE()
)
WITH (
    DISTRIBUTION = REPLICATE,
    CLUSTERED COLUMNSTORE INDEX
);

PRINT 'Dimension tables created successfully!'
GO