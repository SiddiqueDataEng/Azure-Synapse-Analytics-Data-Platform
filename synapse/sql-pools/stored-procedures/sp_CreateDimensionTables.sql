-- =====================================================
-- Azure Synapse Analytics Data Platform (ASADP)
-- Stored Procedure: Create Dimension Tables
-- Production-Ready Data Warehouse Schema
-- =====================================================

CREATE PROCEDURE [dw].[sp_CreateDimensionTables]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @ProcedureName NVARCHAR(128) = 'sp_CreateDimensionTables';
    DECLARE @StepName NVARCHAR(128);
    DECLARE @RowCount BIGINT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        -- Log procedure start
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = 'START',
            @Status = 'INFO',
            @Message = 'Starting dimension table creation process';
        
        -- =====================================================
        -- 1. DIM_DATE - Date Dimension
        -- =====================================================
        SET @StepName = 'CREATE_DIM_DATE';
        
        IF OBJECT_ID('[dw].[dim_date]', 'U') IS NOT NULL
            DROP TABLE [dw].[dim_date];
        
        CREATE TABLE [dw].[dim_date]
        (
            [date_key] INT NOT NULL,
            [date] DATE NOT NULL,
            [year] INT NOT NULL,
            [quarter] INT NOT NULL,
            [month] INT NOT NULL,
            [month_name] NVARCHAR(20) NOT NULL,
            [day] INT NOT NULL,
            [day_of_week] INT NOT NULL,
            [day_name] NVARCHAR(20) NOT NULL,
            [day_of_year] INT NOT NULL,
            [week_of_year] INT NOT NULL,
            [is_weekend] BIT NOT NULL,
            [is_holiday] BIT NOT NULL DEFAULT 0,
            [fiscal_year] INT NOT NULL,
            [fiscal_quarter] INT NOT NULL,
            [fiscal_month] INT NOT NULL,
            [season] NVARCHAR(20) NOT NULL,
            [created_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [updated_date] DATETIME2 NOT NULL DEFAULT GETDATE()
        )
        WITH
        (
            DISTRIBUTION = REPLICATE,
            CLUSTERED COLUMNSTORE INDEX
        );
        
        -- Populate date dimension (5 years: 2022-2027)
        DECLARE @StartDate DATE = '2022-01-01';
        DECLARE @EndDate DATE = '2027-12-31';
        DECLARE @CurrentDate DATE = @StartDate;
        
        WHILE @CurrentDate <= @EndDate
        BEGIN
            INSERT INTO [dw].[dim_date]
            (
                [date_key], [date], [year], [quarter], [month], [month_name],
                [day], [day_of_week], [day_name], [day_of_year], [week_of_year],
                [is_weekend], [fiscal_year], [fiscal_quarter], [fiscal_month], [season]
            )
            VALUES
            (
                CAST(FORMAT(@CurrentDate, 'yyyyMMdd') AS INT),
                @CurrentDate,
                YEAR(@CurrentDate),
                DATEPART(QUARTER, @CurrentDate),
                MONTH(@CurrentDate),
                DATENAME(MONTH, @CurrentDate),
                DAY(@CurrentDate),
                DATEPART(WEEKDAY, @CurrentDate),
                DATENAME(WEEKDAY, @CurrentDate),
                DATEPART(DAYOFYEAR, @CurrentDate),
                DATEPART(WEEK, @CurrentDate),
                CASE WHEN DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) THEN 1 ELSE 0 END,
                CASE WHEN MONTH(@CurrentDate) >= 7 THEN YEAR(@CurrentDate) + 1 ELSE YEAR(@CurrentDate) END,
                CASE WHEN MONTH(@CurrentDate) >= 7 THEN DATEPART(QUARTER, @CurrentDate) - 2 
                     WHEN MONTH(@CurrentDate) >= 4 THEN DATEPART(QUARTER, @CurrentDate) + 2
                     ELSE DATEPART(QUARTER, @CurrentDate) + 2 END,
                CASE WHEN MONTH(@CurrentDate) >= 7 THEN MONTH(@CurrentDate) - 6 ELSE MONTH(@CurrentDate) + 6 END,
                CASE 
                    WHEN MONTH(@CurrentDate) IN (12, 1, 2) THEN 'Winter'
                    WHEN MONTH(@CurrentDate) IN (3, 4, 5) THEN 'Spring'
                    WHEN MONTH(@CurrentDate) IN (6, 7, 8) THEN 'Summer'
                    ELSE 'Fall'
                END
            );
            
            SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
        END;
        
        SET @RowCount = @@ROWCOUNT;
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Date dimension created successfully',
            @RowCount = @RowCount;
        
        -- =====================================================
        -- 2. DIM_CUSTOMER - Customer Dimension
        -- =====================================================
        SET @StepName = 'CREATE_DIM_CUSTOMER';
        
        IF OBJECT_ID('[dw].[dim_customer]', 'U') IS NOT NULL
            DROP TABLE [dw].[dim_customer];
        
        CREATE TABLE [dw].[dim_customer]
        (
            [customer_key] BIGINT IDENTITY(1,1) NOT NULL,
            [customer_id] NVARCHAR(50) NOT NULL,
            [customer_name] NVARCHAR(255) NULL,
            [customer_email] NVARCHAR(255) NULL,
            [customer_phone] NVARCHAR(50) NULL,
            [customer_address] NVARCHAR(500) NULL,
            [customer_city] NVARCHAR(100) NULL,
            [customer_state] NVARCHAR(100) NULL,
            [customer_country] NVARCHAR(100) NULL,
            [customer_postal_code] NVARCHAR(20) NULL,
            [customer_segment] NVARCHAR(50) NULL,
            [customer_type] NVARCHAR(50) NULL,
            [registration_date] DATE NULL,
            [last_purchase_date] DATE NULL,
            [total_purchases] INT NULL DEFAULT 0,
            [total_spent] DECIMAL(18,2) NULL DEFAULT 0.00,
            [avg_order_value] DECIMAL(18,2) NULL DEFAULT 0.00,
            [is_active] BIT NOT NULL DEFAULT 1,
            [created_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [updated_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [source_system] NVARCHAR(100) NOT NULL DEFAULT 'ASADP'
        )
        WITH
        (
            DISTRIBUTION = HASH([customer_id]),
            CLUSTERED COLUMNSTORE INDEX
        );
        
        -- Insert sample customer data
        INSERT INTO [dw].[dim_customer] 
        ([customer_id], [customer_name], [customer_email], [customer_segment], [customer_type])
        VALUES 
        ('CUST_000001', 'John Smith', 'john.smith@email.com', 'Premium', 'Individual'),
        ('CUST_000002', 'Jane Doe', 'jane.doe@email.com', 'Standard', 'Individual'),
        ('CUST_000003', 'Acme Corp', 'orders@acme.com', 'Enterprise', 'Business'),
        ('CUST_000004', 'Tech Solutions Inc', 'purchasing@techsol.com', 'Premium', 'Business'),
        ('CUST_000005', 'Mary Johnson', 'mary.j@email.com', 'Standard', 'Individual');
        
        SET @RowCount = @@ROWCOUNT;
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Customer dimension created successfully',
            @RowCount = @RowCount;
        
        -- =====================================================
        -- 3. DIM_PRODUCT - Product Dimension
        -- =====================================================
        SET @StepName = 'CREATE_DIM_PRODUCT';
        
        IF OBJECT_ID('[dw].[dim_product]', 'U') IS NOT NULL
            DROP TABLE [dw].[dim_product];
        
        CREATE TABLE [dw].[dim_product]
        (
            [product_key] BIGINT IDENTITY(1,1) NOT NULL,
            [product_id] NVARCHAR(50) NOT NULL,
            [product_name] NVARCHAR(255) NOT NULL,
            [product_description] NVARCHAR(1000) NULL,
            [product_category] NVARCHAR(100) NOT NULL,
            [product_subcategory] NVARCHAR(100) NULL,
            [product_brand] NVARCHAR(100) NULL,
            [product_model] NVARCHAR(100) NULL,
            [product_color] NVARCHAR(50) NULL,
            [product_size] NVARCHAR(50) NULL,
            [product_weight] DECIMAL(10,2) NULL,
            [unit_cost] DECIMAL(18,2) NULL,
            [unit_price] DECIMAL(18,2) NULL,
            [profit_margin] DECIMAL(5,2) NULL,
            [supplier_id] NVARCHAR(50) NULL,
            [supplier_name] NVARCHAR(255) NULL,
            [is_active] BIT NOT NULL DEFAULT 1,
            [launch_date] DATE NULL,
            [discontinue_date] DATE NULL,
            [created_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [updated_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [source_system] NVARCHAR(100) NOT NULL DEFAULT 'ASADP'
        )
        WITH
        (
            DISTRIBUTION = HASH([product_id]),
            CLUSTERED COLUMNSTORE INDEX
        );
        
        -- Insert sample product data
        INSERT INTO [dw].[dim_product] 
        ([product_id], [product_name], [product_category], [product_subcategory], [product_brand], [unit_cost], [unit_price], [profit_margin])
        VALUES 
        ('PROD_0001', 'Wireless Bluetooth Headphones', 'Electronics', 'Audio', 'TechBrand', 45.00, 89.99, 50.00),
        ('PROD_0002', 'Smart Fitness Watch', 'Electronics', 'Wearables', 'FitTech', 120.00, 249.99, 52.00),
        ('PROD_0003', 'Organic Cotton T-Shirt', 'Clothing', 'Apparel', 'EcoWear', 8.50, 24.99, 66.00),
        ('PROD_0004', 'Stainless Steel Water Bottle', 'Home', 'Kitchen', 'HydroLife', 12.00, 29.99, 60.00),
        ('PROD_0005', 'Yoga Mat Premium', 'Sports', 'Fitness', 'ZenFit', 15.00, 39.99, 62.50),
        ('PROD_0006', 'LED Desk Lamp', 'Home', 'Office', 'BrightLight', 25.00, 59.99, 58.33),
        ('PROD_0007', 'Wireless Mouse', 'Electronics', 'Computer', 'TechBrand', 18.00, 34.99, 48.57),
        ('PROD_0008', 'Coffee Maker Deluxe', 'Home', 'Kitchen', 'BrewMaster', 85.00, 179.99, 52.78),
        ('PROD_0009', 'Running Shoes', 'Sports', 'Footwear', 'RunFast', 55.00, 119.99, 54.17),
        ('PROD_0010', 'Smartphone Case', 'Electronics', 'Accessories', 'ProtectPlus', 5.00, 19.99, 75.00);
        
        SET @RowCount = @@ROWCOUNT;
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Product dimension created successfully',
            @RowCount = @RowCount;
        
        -- =====================================================
        -- 4. DIM_GEOGRAPHY - Geography Dimension
        -- =====================================================
        SET @StepName = 'CREATE_DIM_GEOGRAPHY';
        
        IF OBJECT_ID('[dw].[dim_geography]', 'U') IS NOT NULL
            DROP TABLE [dw].[dim_geography];
        
        CREATE TABLE [dw].[dim_geography]
        (
            [geography_key] BIGINT IDENTITY(1,1) NOT NULL,
            [region_code] NVARCHAR(10) NOT NULL,
            [region_name] NVARCHAR(100) NOT NULL,
            [country_code] NVARCHAR(10) NULL,
            [country_name] NVARCHAR(100) NULL,
            [state_code] NVARCHAR(10) NULL,
            [state_name] NVARCHAR(100) NULL,
            [city_name] NVARCHAR(100) NULL,
            [postal_code] NVARCHAR(20) NULL,
            [latitude] DECIMAL(10,8) NULL,
            [longitude] DECIMAL(11,8) NULL,
            [time_zone] NVARCHAR(50) NULL,
            [currency_code] NVARCHAR(10) NULL,
            [is_active] BIT NOT NULL DEFAULT 1,
            [created_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [updated_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [source_system] NVARCHAR(100) NOT NULL DEFAULT 'ASADP'
        )
        WITH
        (
            DISTRIBUTION = REPLICATE,
            CLUSTERED COLUMNSTORE INDEX
        );
        
        -- Insert sample geography data
        INSERT INTO [dw].[dim_geography] 
        ([region_code], [region_name], [country_code], [country_name], [state_code], [state_name], [city_name], [currency_code])
        VALUES 
        ('NA-EAST', 'North America East', 'US', 'United States', 'NY', 'New York', 'New York City', 'USD'),
        ('NA-WEST', 'North America West', 'US', 'United States', 'CA', 'California', 'Los Angeles', 'USD'),
        ('NA-CENTRAL', 'North America Central', 'US', 'United States', 'TX', 'Texas', 'Dallas', 'USD'),
        ('EU-WEST', 'Europe West', 'GB', 'United Kingdom', 'ENG', 'England', 'London', 'GBP'),
        ('EU-CENTRAL', 'Europe Central', 'DE', 'Germany', 'BY', 'Bavaria', 'Munich', 'EUR'),
        ('APAC-EAST', 'Asia Pacific East', 'JP', 'Japan', 'TK', 'Tokyo', 'Tokyo', 'JPY'),
        ('APAC-SOUTH', 'Asia Pacific South', 'AU', 'Australia', 'NSW', 'New South Wales', 'Sydney', 'AUD');
        
        SET @RowCount = @@ROWCOUNT;
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Geography dimension created successfully',
            @RowCount = @RowCount;
        
        -- =====================================================
        -- 5. DIM_SALES_CHANNEL - Sales Channel Dimension
        -- =====================================================
        SET @StepName = 'CREATE_DIM_SALES_CHANNEL';
        
        IF OBJECT_ID('[dw].[dim_sales_channel]', 'U') IS NOT NULL
            DROP TABLE [dw].[dim_sales_channel];
        
        CREATE TABLE [dw].[dim_sales_channel]
        (
            [channel_key] BIGINT IDENTITY(1,1) NOT NULL,
            [channel_code] NVARCHAR(20) NOT NULL,
            [channel_name] NVARCHAR(100) NOT NULL,
            [channel_type] NVARCHAR(50) NOT NULL,
            [channel_category] NVARCHAR(50) NOT NULL,
            [is_online] BIT NOT NULL,
            [commission_rate] DECIMAL(5,2) NULL DEFAULT 0.00,
            [is_active] BIT NOT NULL DEFAULT 1,
            [created_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [updated_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [source_system] NVARCHAR(100) NOT NULL DEFAULT 'ASADP'
        )
        WITH
        (
            DISTRIBUTION = REPLICATE,
            CLUSTERED COLUMNSTORE INDEX
        );
        
        -- Insert sample sales channel data
        INSERT INTO [dw].[dim_sales_channel] 
        ([channel_code], [channel_name], [channel_type], [channel_category], [is_online], [commission_rate])
        VALUES 
        ('WEB', 'Website', 'Direct', 'Online', 1, 0.00),
        ('MOBILE', 'Mobile App', 'Direct', 'Online', 1, 0.00),
        ('STORE', 'Retail Store', 'Direct', 'Physical', 0, 0.00),
        ('PHONE', 'Phone Sales', 'Direct', 'Remote', 0, 0.00),
        ('AMAZON', 'Amazon Marketplace', 'Marketplace', 'Online', 1, 15.00),
        ('EBAY', 'eBay Store', 'Marketplace', 'Online', 1, 12.50),
        ('PARTNER', 'Partner Reseller', 'Indirect', 'Physical', 0, 20.00),
        ('SOCIAL', 'Social Media', 'Direct', 'Online', 1, 0.00);
        
        SET @RowCount = @@ROWCOUNT;
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Sales channel dimension created successfully',
            @RowCount = @RowCount;
        
        -- =====================================================
        -- 6. DIM_EMPLOYEE - Employee Dimension
        -- =====================================================
        SET @StepName = 'CREATE_DIM_EMPLOYEE';
        
        IF OBJECT_ID('[dw].[dim_employee]', 'U') IS NOT NULL
            DROP TABLE [dw].[dim_employee];
        
        CREATE TABLE [dw].[dim_employee]
        (
            [employee_key] BIGINT IDENTITY(1,1) NOT NULL,
            [employee_id] NVARCHAR(50) NOT NULL,
            [employee_name] NVARCHAR(255) NOT NULL,
            [employee_email] NVARCHAR(255) NULL,
            [job_title] NVARCHAR(100) NULL,
            [department] NVARCHAR(100) NULL,
            [manager_id] NVARCHAR(50) NULL,
            [manager_name] NVARCHAR(255) NULL,
            [hire_date] DATE NULL,
            [termination_date] DATE NULL,
            [salary_band] NVARCHAR(20) NULL,
            [commission_rate] DECIMAL(5,2) NULL DEFAULT 0.00,
            [region_code] NVARCHAR(10) NULL,
            [is_active] BIT NOT NULL DEFAULT 1,
            [created_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [updated_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [source_system] NVARCHAR(100) NOT NULL DEFAULT 'ASADP'
        )
        WITH
        (
            DISTRIBUTION = REPLICATE,
            CLUSTERED COLUMNSTORE INDEX
        );
        
        -- Insert sample employee data
        INSERT INTO [dw].[dim_employee] 
        ([employee_id], [employee_name], [employee_email], [job_title], [department], [hire_date], [salary_band], [commission_rate], [region_code])
        VALUES 
        ('EMP_001', 'Alice Johnson', 'alice.johnson@company.com', 'Sales Manager', 'Sales', '2020-01-15', 'Senior', 5.00, 'NA-EAST'),
        ('EMP_002', 'Bob Smith', 'bob.smith@company.com', 'Sales Representative', 'Sales', '2021-03-10', 'Mid', 3.00, 'NA-EAST'),
        ('EMP_003', 'Carol Davis', 'carol.davis@company.com', 'Sales Representative', 'Sales', '2021-06-20', 'Mid', 3.00, 'NA-WEST'),
        ('EMP_004', 'David Wilson', 'david.wilson@company.com', 'Regional Manager', 'Sales', '2019-08-05', 'Senior', 7.50, 'EU-WEST'),
        ('EMP_005', 'Eva Brown', 'eva.brown@company.com', 'Sales Representative', 'Sales', '2022-01-12', 'Junior', 2.50, 'APAC-EAST');
        
        SET @RowCount = @@ROWCOUNT;
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Employee dimension created successfully',
            @RowCount = @RowCount;
        
        -- =====================================================
        -- Create Primary Keys and Indexes
        -- =====================================================
        SET @StepName = 'CREATE_INDEXES';
        
        -- Date dimension
        ALTER TABLE [dw].[dim_date] ADD CONSTRAINT PK_dim_date PRIMARY KEY NONCLUSTERED ([date_key]) NOT ENFORCED;
        CREATE NONCLUSTERED INDEX IX_dim_date_date ON [dw].[dim_date] ([date]);
        CREATE NONCLUSTERED INDEX IX_dim_date_year_month ON [dw].[dim_date] ([year], [month]);
        
        -- Customer dimension
        ALTER TABLE [dw].[dim_customer] ADD CONSTRAINT PK_dim_customer PRIMARY KEY NONCLUSTERED ([customer_key]) NOT ENFORCED;
        CREATE NONCLUSTERED INDEX IX_dim_customer_id ON [dw].[dim_customer] ([customer_id]);
        CREATE NONCLUSTERED INDEX IX_dim_customer_segment ON [dw].[dim_customer] ([customer_segment]);
        
        -- Product dimension
        ALTER TABLE [dw].[dim_product] ADD CONSTRAINT PK_dim_product PRIMARY KEY NONCLUSTERED ([product_key]) NOT ENFORCED;
        CREATE NONCLUSTERED INDEX IX_dim_product_id ON [dw].[dim_product] ([product_id]);
        CREATE NONCLUSTERED INDEX IX_dim_product_category ON [dw].[dim_product] ([product_category]);
        
        -- Geography dimension
        ALTER TABLE [dw].[dim_geography] ADD CONSTRAINT PK_dim_geography PRIMARY KEY NONCLUSTERED ([geography_key]) NOT ENFORCED;
        CREATE NONCLUSTERED INDEX IX_dim_geography_region ON [dw].[dim_geography] ([region_code]);
        
        -- Sales channel dimension
        ALTER TABLE [dw].[dim_sales_channel] ADD CONSTRAINT PK_dim_sales_channel PRIMARY KEY NONCLUSTERED ([channel_key]) NOT ENFORCED;
        CREATE NONCLUSTERED INDEX IX_dim_sales_channel_code ON [dw].[dim_sales_channel] ([channel_code]);
        
        -- Employee dimension
        ALTER TABLE [dw].[dim_employee] ADD CONSTRAINT PK_dim_employee PRIMARY KEY NONCLUSTERED ([employee_key]) NOT ENFORCED;
        CREATE NONCLUSTERED INDEX IX_dim_employee_id ON [dw].[dim_employee] ([employee_id]);
        
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Indexes and constraints created successfully';
        
        -- Log procedure completion
        DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, GETDATE());
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = 'COMPLETE',
            @Status = 'SUCCESS',
            @Message = 'All dimension tables created successfully',
            @Duration = @Duration;
        
        PRINT 'Dimension tables created successfully!';
        PRINT 'Tables created:';
        PRINT '  - dw.dim_date (Date dimension with 5 years of data)';
        PRINT '  - dw.dim_customer (Customer dimension)';
        PRINT '  - dw.dim_product (Product dimension)';
        PRINT '  - dw.dim_geography (Geography dimension)';
        PRINT '  - dw.dim_sales_channel (Sales channel dimension)';
        PRINT '  - dw.dim_employee (Employee dimension)';
        
    END TRY
    BEGIN CATCH
        SET @ErrorMessage = ERROR_MESSAGE();
        
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'ERROR',
            @Message = @ErrorMessage;
        
        PRINT 'Error occurred: ' + @ErrorMessage;
        THROW;
    END CATCH
END;
GO

-- Grant permissions
GRANT EXECUTE ON [dw].[sp_CreateDimensionTables] TO [db_executor];
GO

PRINT 'Stored procedure [dw].[sp_CreateDimensionTables] created successfully!';