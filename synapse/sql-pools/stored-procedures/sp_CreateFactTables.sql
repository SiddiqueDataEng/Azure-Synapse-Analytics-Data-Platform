-- =====================================================
-- Azure Synapse Analytics Data Platform (ASADP)
-- Stored Procedure: Create Fact Tables
-- Production-Ready Data Warehouse Schema
-- =====================================================

CREATE PROCEDURE [dw].[sp_CreateFactTables]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @ProcedureName NVARCHAR(128) = 'sp_CreateFactTables';
    DECLARE @StepName NVARCHAR(128);
    DECLARE @RowCount BIGINT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        -- Log procedure start
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = 'START',
            @Status = 'INFO',
            @Message = 'Starting fact table creation process';
        
        -- =====================================================
        -- 1. FACT_SALES - Sales Fact Table
        -- =====================================================
        SET @StepName = 'CREATE_FACT_SALES';
        
        IF OBJECT_ID('[dw].[fact_sales]', 'U') IS NOT NULL
            DROP TABLE [dw].[fact_sales];
        
        CREATE TABLE [dw].[fact_sales]
        (
            [sales_key] BIGINT IDENTITY(1,1) NOT NULL,
            [transaction_id] NVARCHAR(50) NOT NULL,
            [date_key] INT NOT NULL,
            [customer_key] BIGINT NOT NULL,
            [product_key] BIGINT NOT NULL,
            [geography_key] BIGINT NOT NULL,
            [channel_key] BIGINT NOT NULL,
            [employee_key] BIGINT NULL,
            [order_number] NVARCHAR(50) NULL,
            [line_number] INT NULL,
            [quantity] INT NOT NULL,
            [unit_price] DECIMAL(18,2) NOT NULL,
            [unit_cost] DECIMAL(18,2) NULL,
            [discount_amount] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
            [discount_percent] DECIMAL(5,2) NOT NULL DEFAULT 0.00,
            [gross_amount] DECIMAL(18,2) NOT NULL,
            [net_amount] DECIMAL(18,2) NOT NULL,
            [tax_amount] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
            [total_amount] DECIMAL(18,2) NOT NULL,
            [profit_amount] DECIMAL(18,2) NULL,
            [profit_margin] DECIMAL(5,2) NULL,
            [commission_amount] DECIMAL(18,2) NULL DEFAULT 0.00,
            [shipping_cost] DECIMAL(18,2) NULL DEFAULT 0.00,
            [payment_method] NVARCHAR(50) NULL,
            [currency_code] NVARCHAR(10) NOT NULL DEFAULT 'USD',
            [exchange_rate] DECIMAL(10,6) NOT NULL DEFAULT 1.000000,
            [transaction_timestamp] DATETIME2 NOT NULL,
            [created_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [updated_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [source_system] NVARCHAR(100) NOT NULL DEFAULT 'ASADP',
            [batch_id] NVARCHAR(50) NULL,
            [data_quality_score] DECIMAL(3,2) NOT NULL DEFAULT 1.00
        )
        WITH
        (
            DISTRIBUTION = HASH([customer_key]),
            CLUSTERED COLUMNSTORE INDEX,
            PARTITION ([date_key] RANGE RIGHT FOR VALUES (
                20220101, 20220201, 20220301, 20220401, 20220501, 20220601,
                20220701, 20220801, 20220901, 20221001, 20221101, 20221201,
                20230101, 20230201, 20230301, 20230401, 20230501, 20230601,
                20230701, 20230801, 20230901, 20231001, 20231101, 20231201,
                20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
                20240701, 20240801, 20240901, 20241001, 20241101, 20241201,
                20250101, 20250201, 20250301, 20250401, 20250501, 20250601,
                20250701, 20250801, 20250901, 20251001, 20251101, 20251201
            ))
        );
        
        -- Insert sample sales data
        INSERT INTO [dw].[fact_sales] 
        (
            [transaction_id], [date_key], [customer_key], [product_key], [geography_key], 
            [channel_key], [employee_key], [order_number], [line_number], [quantity], 
            [unit_price], [unit_cost], [discount_percent], [discount_amount], 
            [gross_amount], [net_amount], [tax_amount], [total_amount], 
            [profit_amount], [profit_margin], [payment_method], [transaction_timestamp]
        )
        VALUES 
        ('TXN_00000001', 20240115, 1, 1, 1, 1, 1, 'ORD_001', 1, 2, 89.99, 45.00, 10.00, 17.998, 179.98, 161.982, 12.95, 174.932, 71.982, 44.44, 'Credit Card', '2024-01-15 10:30:00'),
        ('TXN_00000002', 20240115, 2, 2, 2, 2, 2, 'ORD_002', 1, 1, 249.99, 120.00, 0.00, 0.00, 249.99, 249.99, 20.00, 269.99, 129.99, 52.00, 'Debit Card', '2024-01-15 14:45:00'),
        ('TXN_00000003', 20240116, 3, 3, 3, 3, 3, 'ORD_003', 1, 5, 24.99, 8.50, 15.00, 18.74, 124.95, 106.21, 8.50, 114.71, 48.71, 45.86, 'PayPal', '2024-01-16 09:15:00'),
        ('TXN_00000004', 20240116, 4, 4, 4, 4, 4, 'ORD_004', 1, 3, 29.99, 12.00, 5.00, 4.50, 89.97, 85.47, 6.84, 92.31, 49.47, 57.88, 'Credit Card', '2024-01-16 16:20:00'),
        ('TXN_00000005', 20240117, 5, 5, 5, 5, 5, 'ORD_005', 1, 2, 39.99, 15.00, 20.00, 15.996, 79.98, 63.984, 5.12, 69.104, 33.984, 53.11, 'Cash', '2024-01-17 11:00:00'),
        ('TXN_00000006', 20240117, 1, 6, 1, 1, 1, 'ORD_006', 1, 1, 59.99, 25.00, 0.00, 0.00, 59.99, 59.99, 4.80, 64.79, 34.99, 58.33, 'Credit Card', '2024-01-17 13:30:00'),
        ('TXN_00000007', 20240118, 2, 7, 2, 6, 2, 'ORD_007', 1, 2, 34.99, 18.00, 10.00, 6.998, 69.98, 62.982, 5.04, 68.022, 26.982, 42.84, 'Amazon Pay', '2024-01-18 08:45:00'),
        ('TXN_00000008', 20240118, 3, 8, 3, 7, 3, 'ORD_008', 1, 1, 179.99, 85.00, 25.00, 44.998, 179.99, 134.992, 10.80, 145.792, 49.992, 37.04, 'Partner Credit', '2024-01-18 15:10:00'),
        ('TXN_00000009', 20240119, 4, 9, 4, 2, 4, 'ORD_009', 1, 1, 119.99, 55.00, 0.00, 0.00, 119.99, 119.99, 9.60, 129.59, 64.99, 54.17, 'Debit Card', '2024-01-19 12:25:00'),
        ('TXN_00000010', 20240119, 5, 10, 5, 8, 5, 'ORD_010', 1, 3, 19.99, 5.00, 5.00, 2.999, 59.97, 56.971, 4.56, 61.531, 41.971, 73.67, 'Social Pay', '2024-01-19 17:40:00');
        
        SET @RowCount = @@ROWCOUNT;
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Sales fact table created successfully',
            @RowCount = @RowCount;
        
        -- =====================================================
        -- 2. FACT_INVENTORY - Inventory Fact Table
        -- =====================================================
        SET @StepName = 'CREATE_FACT_INVENTORY';
        
        IF OBJECT_ID('[dw].[fact_inventory]', 'U') IS NOT NULL
            DROP TABLE [dw].[fact_inventory];
        
        CREATE TABLE [dw].[fact_inventory]
        (
            [inventory_key] BIGINT IDENTITY(1,1) NOT NULL,
            [date_key] INT NOT NULL,
            [product_key] BIGINT NOT NULL,
            [geography_key] BIGINT NOT NULL,
            [warehouse_id] NVARCHAR(50) NOT NULL,
            [warehouse_name] NVARCHAR(255) NULL,
            [beginning_inventory] INT NOT NULL DEFAULT 0,
            [receipts] INT NOT NULL DEFAULT 0,
            [sales] INT NOT NULL DEFAULT 0,
            [adjustments] INT NOT NULL DEFAULT 0,
            [ending_inventory] INT NOT NULL DEFAULT 0,
            [safety_stock] INT NOT NULL DEFAULT 0,
            [reorder_point] INT NOT NULL DEFAULT 0,
            [max_stock] INT NOT NULL DEFAULT 0,
            [unit_cost] DECIMAL(18,2) NOT NULL,
            [inventory_value] DECIMAL(18,2) NOT NULL,
            [days_on_hand] INT NULL,
            [turnover_rate] DECIMAL(10,2) NULL,
            [stockout_flag] BIT NOT NULL DEFAULT 0,
            [overstock_flag] BIT NOT NULL DEFAULT 0,
            [created_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [updated_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [source_system] NVARCHAR(100) NOT NULL DEFAULT 'ASADP',
            [batch_id] NVARCHAR(50) NULL
        )
        WITH
        (
            DISTRIBUTION = HASH([product_key]),
            CLUSTERED COLUMNSTORE INDEX,
            PARTITION ([date_key] RANGE RIGHT FOR VALUES (
                20220101, 20220201, 20220301, 20220401, 20220501, 20220601,
                20220701, 20220801, 20220901, 20221001, 20221101, 20221201,
                20230101, 20230201, 20230301, 20230401, 20230501, 20230601,
                20230701, 20230801, 20230901, 20231001, 20231101, 20231201,
                20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
                20240701, 20240801, 20240901, 20241001, 20241101, 20241201
            ))
        );
        
        -- Insert sample inventory data
        INSERT INTO [dw].[fact_inventory] 
        (
            [date_key], [product_key], [geography_key], [warehouse_id], [warehouse_name],
            [beginning_inventory], [receipts], [sales], [adjustments], [ending_inventory],
            [safety_stock], [reorder_point], [max_stock], [unit_cost], [inventory_value]
        )
        VALUES 
        (20240115, 1, 1, 'WH_001', 'East Coast Warehouse', 100, 50, 10, 0, 140, 25, 50, 200, 45.00, 6300.00),
        (20240115, 2, 1, 'WH_001', 'East Coast Warehouse', 75, 25, 5, 0, 95, 15, 30, 150, 120.00, 11400.00),
        (20240115, 3, 2, 'WH_002', 'West Coast Warehouse', 200, 100, 25, -5, 270, 50, 75, 400, 8.50, 2295.00),
        (20240115, 4, 2, 'WH_002', 'West Coast Warehouse', 150, 75, 15, 0, 210, 30, 50, 300, 12.00, 2520.00),
        (20240115, 5, 3, 'WH_003', 'Central Warehouse', 80, 40, 8, 2, 114, 20, 35, 180, 15.00, 1710.00),
        (20240116, 1, 1, 'WH_001', 'East Coast Warehouse', 140, 0, 8, 0, 132, 25, 50, 200, 45.00, 5940.00),
        (20240116, 2, 1, 'WH_001', 'East Coast Warehouse', 95, 0, 3, 0, 92, 15, 30, 150, 120.00, 11040.00),
        (20240116, 3, 2, 'WH_002', 'West Coast Warehouse', 270, 0, 20, 0, 250, 50, 75, 400, 8.50, 2125.00),
        (20240116, 4, 2, 'WH_002', 'West Coast Warehouse', 210, 0, 12, 0, 198, 30, 50, 300, 12.00, 2376.00),
        (20240116, 5, 3, 'WH_003', 'Central Warehouse', 114, 0, 6, 0, 108, 20, 35, 180, 15.00, 1620.00);
        
        SET @RowCount = @@ROWCOUNT;
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Inventory fact table created successfully',
            @RowCount = @RowCount;
        
        -- =====================================================
        -- 3. FACT_CUSTOMER_ACTIVITY - Customer Activity Fact Table
        -- =====================================================
        SET @StepName = 'CREATE_FACT_CUSTOMER_ACTIVITY';
        
        IF OBJECT_ID('[dw].[fact_customer_activity]', 'U') IS NOT NULL
            DROP TABLE [dw].[fact_customer_activity];
        
        CREATE TABLE [dw].[fact_customer_activity]
        (
            [activity_key] BIGINT IDENTITY(1,1) NOT NULL,
            [date_key] INT NOT NULL,
            [customer_key] BIGINT NOT NULL,
            [geography_key] BIGINT NOT NULL,
            [channel_key] BIGINT NOT NULL,
            [activity_type] NVARCHAR(50) NOT NULL,
            [activity_category] NVARCHAR(50) NOT NULL,
            [session_id] NVARCHAR(100) NULL,
            [page_views] INT NOT NULL DEFAULT 0,
            [session_duration_minutes] INT NOT NULL DEFAULT 0,
            [bounce_flag] BIT NOT NULL DEFAULT 0,
            [conversion_flag] BIT NOT NULL DEFAULT 0,
            [email_opens] INT NOT NULL DEFAULT 0,
            [email_clicks] INT NOT NULL DEFAULT 0,
            [support_tickets] INT NOT NULL DEFAULT 0,
            [satisfaction_score] DECIMAL(3,2) NULL,
            [nps_score] INT NULL,
            [activity_timestamp] DATETIME2 NOT NULL,
            [created_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [updated_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [source_system] NVARCHAR(100) NOT NULL DEFAULT 'ASADP',
            [batch_id] NVARCHAR(50) NULL
        )
        WITH
        (
            DISTRIBUTION = HASH([customer_key]),
            CLUSTERED COLUMNSTORE INDEX,
            PARTITION ([date_key] RANGE RIGHT FOR VALUES (
                20220101, 20220201, 20220301, 20220401, 20220501, 20220601,
                20220701, 20220801, 20220901, 20221001, 20221101, 20221201,
                20230101, 20230201, 20230301, 20230401, 20230501, 20230601,
                20230701, 20230801, 20230901, 20231001, 20231101, 20231201,
                20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
                20240701, 20240801, 20240901, 20241001, 20241101, 20241201
            ))
        );
        
        -- Insert sample customer activity data
        INSERT INTO [dw].[fact_customer_activity] 
        (
            [date_key], [customer_key], [geography_key], [channel_key], [activity_type], 
            [activity_category], [session_id], [page_views], [session_duration_minutes], 
            [bounce_flag], [conversion_flag], [email_opens], [email_clicks], 
            [satisfaction_score], [nps_score], [activity_timestamp]
        )
        VALUES 
        (20240115, 1, 1, 1, 'Website Visit', 'Browsing', 'SES_001', 12, 25, 0, 1, 0, 0, 4.5, 9, '2024-01-15 10:00:00'),
        (20240115, 2, 2, 2, 'App Usage', 'Shopping', 'SES_002', 8, 18, 0, 1, 0, 0, 4.2, 8, '2024-01-15 14:30:00'),
        (20240115, 3, 3, 3, 'Email Campaign', 'Marketing', NULL, 0, 0, 0, 0, 1, 1, NULL, NULL, '2024-01-15 09:00:00'),
        (20240116, 1, 1, 1, 'Support Contact', 'Service', NULL, 0, 0, 0, 0, 0, 0, 3.8, 7, '2024-01-16 11:30:00'),
        (20240116, 4, 4, 4, 'Website Visit', 'Research', 'SES_003', 15, 35, 0, 1, 0, 0, 4.7, 9, '2024-01-16 16:00:00'),
        (20240117, 5, 5, 5, 'Store Visit', 'Purchase', NULL, 0, 45, 0, 1, 0, 0, 4.3, 8, '2024-01-17 10:45:00'),
        (20240117, 2, 2, 6, 'Marketplace View', 'Browsing', 'SES_004', 6, 12, 1, 0, 0, 0, NULL, NULL, '2024-01-17 20:15:00'),
        (20240118, 3, 3, 7, 'Partner Referral', 'Acquisition', NULL, 0, 0, 0, 1, 0, 0, 4.1, 8, '2024-01-18 15:00:00'),
        (20240118, 1, 1, 8, 'Social Media', 'Engagement', NULL, 3, 8, 0, 0, 0, 0, NULL, NULL, '2024-01-18 19:30:00'),
        (20240119, 4, 4, 2, 'App Usage', 'Shopping', 'SES_005', 10, 22, 0, 1, 0, 0, 4.6, 9, '2024-01-19 12:00:00');
        
        SET @RowCount = @@ROWCOUNT;
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Customer activity fact table created successfully',
            @RowCount = @RowCount;
        
        -- =====================================================
        -- 4. FACT_FINANCIAL - Financial Performance Fact Table
        -- =====================================================
        SET @StepName = 'CREATE_FACT_FINANCIAL';
        
        IF OBJECT_ID('[dw].[fact_financial]', 'U') IS NOT NULL
            DROP TABLE [dw].[fact_financial];
        
        CREATE TABLE [dw].[fact_financial]
        (
            [financial_key] BIGINT IDENTITY(1,1) NOT NULL,
            [date_key] INT NOT NULL,
            [geography_key] BIGINT NOT NULL,
            [channel_key] BIGINT NOT NULL,
            [account_code] NVARCHAR(20) NOT NULL,
            [account_name] NVARCHAR(255) NOT NULL,
            [account_type] NVARCHAR(50) NOT NULL,
            [account_category] NVARCHAR(50) NOT NULL,
            [budget_amount] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
            [actual_amount] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
            [variance_amount] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
            [variance_percent] DECIMAL(5,2) NOT NULL DEFAULT 0.00,
            [ytd_budget] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
            [ytd_actual] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
            [ytd_variance] DECIMAL(18,2) NOT NULL DEFAULT 0.00,
            [currency_code] NVARCHAR(10) NOT NULL DEFAULT 'USD',
            [exchange_rate] DECIMAL(10,6) NOT NULL DEFAULT 1.000000,
            [created_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [updated_date] DATETIME2 NOT NULL DEFAULT GETDATE(),
            [source_system] NVARCHAR(100) NOT NULL DEFAULT 'ASADP',
            [batch_id] NVARCHAR(50) NULL
        )
        WITH
        (
            DISTRIBUTION = HASH([geography_key]),
            CLUSTERED COLUMNSTORE INDEX,
            PARTITION ([date_key] RANGE RIGHT FOR VALUES (
                20220101, 20220201, 20220301, 20220401, 20220501, 20220601,
                20220701, 20220801, 20220901, 20221001, 20221101, 20221201,
                20230101, 20230201, 20230301, 20230401, 20230501, 20230601,
                20230701, 20230801, 20230901, 20231001, 20231101, 20231201,
                20240101, 20240201, 20240301, 20240401, 20240501, 20240601,
                20240701, 20240801, 20240901, 20241001, 20241101, 20241201
            ))
        );
        
        -- Insert sample financial data
        INSERT INTO [dw].[fact_financial] 
        (
            [date_key], [geography_key], [channel_key], [account_code], [account_name], 
            [account_type], [account_category], [budget_amount], [actual_amount], 
            [variance_amount], [variance_percent], [ytd_budget], [ytd_actual], [ytd_variance]
        )
        VALUES 
        (20240115, 1, 1, 'REV001', 'Product Sales Revenue', 'Revenue', 'Sales', 50000.00, 52500.00, 2500.00, 5.00, 50000.00, 52500.00, 2500.00),
        (20240115, 1, 1, 'EXP001', 'Cost of Goods Sold', 'Expense', 'COGS', 25000.00, 24800.00, -200.00, -0.80, 25000.00, 24800.00, -200.00),
        (20240115, 1, 1, 'EXP002', 'Marketing Expenses', 'Expense', 'Marketing', 8000.00, 8500.00, 500.00, 6.25, 8000.00, 8500.00, 500.00),
        (20240115, 2, 2, 'REV001', 'Product Sales Revenue', 'Revenue', 'Sales', 45000.00, 43200.00, -1800.00, -4.00, 45000.00, 43200.00, -1800.00),
        (20240115, 2, 2, 'EXP001', 'Cost of Goods Sold', 'Expense', 'COGS', 22500.00, 21600.00, -900.00, -4.00, 22500.00, 21600.00, -900.00),
        (20240116, 1, 1, 'REV001', 'Product Sales Revenue', 'Revenue', 'Sales', 50000.00, 48900.00, -1100.00, -2.20, 100000.00, 101400.00, 1400.00),
        (20240116, 1, 1, 'EXP001', 'Cost of Goods Sold', 'Expense', 'COGS', 25000.00, 24450.00, -550.00, -2.20, 50000.00, 49250.00, -750.00),
        (20240116, 2, 2, 'REV001', 'Product Sales Revenue', 'Revenue', 'Sales', 45000.00, 46800.00, 1800.00, 4.00, 90000.00, 90000.00, 0.00),
        (20240116, 2, 2, 'EXP001', 'Cost of Goods Sold', 'Expense', 'COGS', 22500.00, 23400.00, 900.00, 4.00, 45000.00, 45000.00, 0.00),
        (20240117, 1, 1, 'REV002', 'Service Revenue', 'Revenue', 'Services', 15000.00, 16200.00, 1200.00, 8.00, 15000.00, 16200.00, 1200.00);
        
        SET @RowCount = @@ROWCOUNT;
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Financial fact table created successfully',
            @RowCount = @RowCount;
        
        -- =====================================================
        -- Create Primary Keys and Indexes
        -- =====================================================
        SET @StepName = 'CREATE_INDEXES';
        
        -- Sales fact table
        ALTER TABLE [dw].[fact_sales] ADD CONSTRAINT PK_fact_sales PRIMARY KEY NONCLUSTERED ([sales_key]) NOT ENFORCED;
        CREATE NONCLUSTERED INDEX IX_fact_sales_date ON [dw].[fact_sales] ([date_key]);
        CREATE NONCLUSTERED INDEX IX_fact_sales_customer ON [dw].[fact_sales] ([customer_key]);
        CREATE NONCLUSTERED INDEX IX_fact_sales_product ON [dw].[fact_sales] ([product_key]);
        CREATE NONCLUSTERED INDEX IX_fact_sales_transaction ON [dw].[fact_sales] ([transaction_id]);
        
        -- Inventory fact table
        ALTER TABLE [dw].[fact_inventory] ADD CONSTRAINT PK_fact_inventory PRIMARY KEY NONCLUSTERED ([inventory_key]) NOT ENFORCED;
        CREATE NONCLUSTERED INDEX IX_fact_inventory_date ON [dw].[fact_inventory] ([date_key]);
        CREATE NONCLUSTERED INDEX IX_fact_inventory_product ON [dw].[fact_inventory] ([product_key]);
        CREATE NONCLUSTERED INDEX IX_fact_inventory_warehouse ON [dw].[fact_inventory] ([warehouse_id]);
        
        -- Customer activity fact table
        ALTER TABLE [dw].[fact_customer_activity] ADD CONSTRAINT PK_fact_customer_activity PRIMARY KEY NONCLUSTERED ([activity_key]) NOT ENFORCED;
        CREATE NONCLUSTERED INDEX IX_fact_customer_activity_date ON [dw].[fact_customer_activity] ([date_key]);
        CREATE NONCLUSTERED INDEX IX_fact_customer_activity_customer ON [dw].[fact_customer_activity] ([customer_key]);
        CREATE NONCLUSTERED INDEX IX_fact_customer_activity_type ON [dw].[fact_customer_activity] ([activity_type]);
        
        -- Financial fact table
        ALTER TABLE [dw].[fact_financial] ADD CONSTRAINT PK_fact_financial PRIMARY KEY NONCLUSTERED ([financial_key]) NOT ENFORCED;
        CREATE NONCLUSTERED INDEX IX_fact_financial_date ON [dw].[fact_financial] ([date_key]);
        CREATE NONCLUSTERED INDEX IX_fact_financial_account ON [dw].[fact_financial] ([account_code]);
        CREATE NONCLUSTERED INDEX IX_fact_financial_geography ON [dw].[fact_financial] ([geography_key]);
        
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Indexes and constraints created successfully';
        
        -- =====================================================
        -- Create Views for Business Users
        -- =====================================================
        SET @StepName = 'CREATE_VIEWS';
        
        -- Sales summary view
        IF OBJECT_ID('[dw].[vw_sales_summary]', 'V') IS NOT NULL
            DROP VIEW [dw].[vw_sales_summary];
        
        EXEC('
        CREATE VIEW [dw].[vw_sales_summary]
        AS
        SELECT 
            d.date,
            d.year,
            d.month,
            d.quarter,
            c.customer_name,
            c.customer_segment,
            p.product_name,
            p.product_category,
            g.region_name,
            ch.channel_name,
            e.employee_name,
            s.quantity,
            s.unit_price,
            s.discount_amount,
            s.net_amount,
            s.profit_amount,
            s.profit_margin
        FROM [dw].[fact_sales] s
        INNER JOIN [dw].[dim_date] d ON s.date_key = d.date_key
        INNER JOIN [dw].[dim_customer] c ON s.customer_key = c.customer_key
        INNER JOIN [dw].[dim_product] p ON s.product_key = p.product_key
        INNER JOIN [dw].[dim_geography] g ON s.geography_key = g.geography_key
        INNER JOIN [dw].[dim_sales_channel] ch ON s.channel_key = ch.channel_key
        LEFT JOIN [dw].[dim_employee] e ON s.employee_key = e.employee_key
        ');
        
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = @StepName,
            @Status = 'SUCCESS',
            @Message = 'Business views created successfully';
        
        -- Log procedure completion
        DECLARE @Duration INT = DATEDIFF(SECOND, @StartTime, GETDATE());
        EXEC [audit].[sp_LogExecution] 
            @ProcedureName = @ProcedureName,
            @StepName = 'COMPLETE',
            @Status = 'SUCCESS',
            @Message = 'All fact tables created successfully',
            @Duration = @Duration;
        
        PRINT 'Fact tables created successfully!';
        PRINT 'Tables created:';
        PRINT '  - dw.fact_sales (Sales transactions with sample data)';
        PRINT '  - dw.fact_inventory (Inventory levels and movements)';
        PRINT '  - dw.fact_customer_activity (Customer engagement metrics)';
        PRINT '  - dw.fact_financial (Financial performance data)';
        PRINT '  - dw.vw_sales_summary (Business user view)';
        
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
GRANT EXECUTE ON [dw].[sp_CreateFactTables] TO [db_executor];
GO

PRINT 'Stored procedure [dw].[sp_CreateFactTables] created successfully!';