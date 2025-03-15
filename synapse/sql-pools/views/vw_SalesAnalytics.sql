-- =====================================================
-- Azure Synapse Analytics Data Platform (ASADP)
-- Sales Analytics Views
-- Production-Ready Business Intelligence Views
-- =====================================================

-- =====================================================
-- 1. Sales Performance Summary View
-- =====================================================
IF OBJECT_ID('[dw].[vw_sales_performance_summary]', 'V') IS NOT NULL
    DROP VIEW [dw].[vw_sales_performance_summary];
GO

CREATE VIEW [dw].[vw_sales_performance_summary]
AS
SELECT 
    -- Time dimensions
    d.date,
    d.year,
    d.quarter,
    d.month,
    d.month_name,
    d.day_name,
    d.is_weekend,
    
    -- Customer dimensions
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    c.customer_type,
    
    -- Product dimensions
    p.product_id,
    p.product_name,
    p.product_category,
    p.product_subcategory,
    p.product_brand,
    
    -- Geography dimensions
    g.region_name,
    g.country_name,
    g.state_name,
    g.city_name,
    
    -- Channel dimensions
    ch.channel_name,
    ch.channel_type,
    ch.channel_category,
    ch.is_online,
    
    -- Employee dimensions
    e.employee_name,
    e.job_title,
    e.department,
    
    -- Sales metrics
    s.transaction_id,
    s.order_number,
    s.quantity,
    s.unit_price,
    s.unit_cost,
    s.discount_percent,
    s.discount_amount,
    s.gross_amount,
    s.net_amount,
    s.tax_amount,
    s.total_amount,
    s.profit_amount,
    s.profit_margin,
    s.commission_amount,
    s.shipping_cost,
    s.payment_method,
    s.currency_code,
    
    -- Calculated metrics
    CASE 
        WHEN s.gross_amount > 0 THEN (s.discount_amount / s.gross_amount) * 100
        ELSE 0 
    END AS effective_discount_rate,
    
    CASE 
        WHEN s.unit_cost > 0 THEN ((s.unit_price - s.unit_cost) / s.unit_cost) * 100
        ELSE 0 
    END AS markup_percentage,
    
    s.net_amount / NULLIF(s.quantity, 0) AS net_price_per_unit,
    s.profit_amount / NULLIF(s.quantity, 0) AS profit_per_unit,
    
    -- Flags
    CASE WHEN s.discount_amount > 0 THEN 1 ELSE 0 END AS has_discount_flag,
    CASE WHEN s.profit_margin < 20 THEN 1 ELSE 0 END AS low_margin_flag,
    CASE WHEN s.net_amount > 1000 THEN 1 ELSE 0 END AS high_value_flag,
    CASE WHEN d.is_weekend = 1 THEN 1 ELSE 0 END AS weekend_sale_flag,
    
    -- Audit fields
    s.transaction_timestamp,
    s.created_date,
    s.source_system

FROM [dw].[fact_sales] s
INNER JOIN [dw].[dim_date] d ON s.date_key = d.date_key
INNER JOIN [dw].[dim_customer] c ON s.customer_key = c.customer_key
INNER JOIN [dw].[dim_product] p ON s.product_key = p.product_key
INNER JOIN [dw].[dim_geography] g ON s.geography_key = g.geography_key
INNER JOIN [dw].[dim_sales_channel] ch ON s.channel_key = ch.channel_key
LEFT JOIN [dw].[dim_employee] e ON s.employee_key = e.employee_key;
GO

-- =====================================================
-- 2. Daily Sales Aggregation View
-- =====================================================
IF OBJECT_ID('[dw].[vw_daily_sales_aggregation]', 'V') IS NOT NULL
    DROP VIEW [dw].[vw_daily_sales_aggregation];
GO

CREATE VIEW [dw].[vw_daily_sales_aggregation]
AS
SELECT 
    -- Time dimensions
    d.date,
    d.year,
    d.quarter,
    d.month,
    d.month_name,
    d.day_name,
    d.is_weekend,
    d.is_holiday,
    
    -- Geography dimensions
    g.region_name,
    g.country_name,
    
    -- Channel dimensions
    ch.channel_name,
    ch.channel_type,
    ch.is_online,
    
    -- Aggregated metrics
    COUNT(DISTINCT s.transaction_id) AS total_transactions,
    COUNT(DISTINCT s.customer_key) AS unique_customers,
    COUNT(DISTINCT s.product_key) AS unique_products,
    COUNT(DISTINCT s.order_number) AS total_orders,
    
    SUM(s.quantity) AS total_quantity,
    SUM(s.gross_amount) AS total_gross_amount,
    SUM(s.discount_amount) AS total_discount_amount,
    SUM(s.net_amount) AS total_net_amount,
    SUM(s.tax_amount) AS total_tax_amount,
    SUM(s.total_amount) AS total_revenue,
    SUM(s.profit_amount) AS total_profit,
    SUM(s.commission_amount) AS total_commission,
    SUM(s.shipping_cost) AS total_shipping_cost,
    
    -- Average metrics
    AVG(s.net_amount) AS avg_transaction_value,
    AVG(s.quantity) AS avg_quantity_per_transaction,
    AVG(s.profit_margin) AS avg_profit_margin,
    AVG(s.discount_percent) AS avg_discount_percent,
    
    -- Min/Max metrics
    MIN(s.net_amount) AS min_transaction_value,
    MAX(s.net_amount) AS max_transaction_value,
    MIN(s.profit_margin) AS min_profit_margin,
    MAX(s.profit_margin) AS max_profit_margin,
    
    -- Calculated KPIs
    CASE 
        WHEN SUM(s.gross_amount) > 0 
        THEN (SUM(s.discount_amount) / SUM(s.gross_amount)) * 100
        ELSE 0 
    END AS overall_discount_rate,
    
    CASE 
        WHEN SUM(s.net_amount) > 0 
        THEN (SUM(s.profit_amount) / SUM(s.net_amount)) * 100
        ELSE 0 
    END AS overall_profit_margin,
    
    SUM(s.net_amount) / NULLIF(COUNT(DISTINCT s.customer_key), 0) AS revenue_per_customer,
    SUM(s.net_amount) / NULLIF(COUNT(DISTINCT s.transaction_id), 0) AS revenue_per_transaction,
    
    -- Flags and indicators
    SUM(CASE WHEN s.discount_amount > 0 THEN 1 ELSE 0 END) AS transactions_with_discount,
    SUM(CASE WHEN s.profit_margin < 20 THEN 1 ELSE 0 END) AS low_margin_transactions,
    SUM(CASE WHEN s.net_amount > 1000 THEN 1 ELSE 0 END) AS high_value_transactions

FROM [dw].[fact_sales] s
INNER JOIN [dw].[dim_date] d ON s.date_key = d.date_key
INNER JOIN [dw].[dim_geography] g ON s.geography_key = g.geography_key
INNER JOIN [dw].[dim_sales_channel] ch ON s.channel_key = ch.channel_key

GROUP BY 
    d.date, d.year, d.quarter, d.month, d.month_name, d.day_name, 
    d.is_weekend, d.is_holiday,
    g.region_name, g.country_name,
    ch.channel_name, ch.channel_type, ch.is_online;
GO

-- =====================================================
-- 3. Product Performance Analysis View
-- =====================================================
IF OBJECT_ID('[dw].[vw_product_performance_analysis]', 'V') IS NOT NULL
    DROP VIEW [dw].[vw_product_performance_analysis];
GO

CREATE VIEW [dw].[vw_product_performance_analysis]
AS
SELECT 
    -- Product dimensions
    p.product_id,
    p.product_name,
    p.product_category,
    p.product_subcategory,
    p.product_brand,
    p.unit_cost AS standard_cost,
    p.unit_price AS list_price,
    p.profit_margin AS standard_margin,
    
    -- Time dimensions
    d.year,
    d.quarter,
    d.month,
    
    -- Performance metrics
    COUNT(DISTINCT s.transaction_id) AS total_transactions,
    COUNT(DISTINCT s.customer_key) AS unique_customers,
    COUNT(DISTINCT s.order_number) AS total_orders,
    
    SUM(s.quantity) AS total_quantity_sold,
    SUM(s.net_amount) AS total_revenue,
    SUM(s.profit_amount) AS total_profit,
    SUM(s.discount_amount) AS total_discounts_given,
    
    -- Average metrics
    AVG(s.unit_price) AS avg_selling_price,
    AVG(s.discount_percent) AS avg_discount_percent,
    AVG(s.profit_margin) AS avg_profit_margin,
    AVG(s.quantity) AS avg_quantity_per_transaction,
    
    -- Calculated KPIs
    SUM(s.net_amount) / NULLIF(SUM(s.quantity), 0) AS revenue_per_unit,
    SUM(s.profit_amount) / NULLIF(SUM(s.quantity), 0) AS profit_per_unit,
    
    CASE 
        WHEN SUM(s.gross_amount) > 0 
        THEN (SUM(s.discount_amount) / SUM(s.gross_amount)) * 100
        ELSE 0 
    END AS discount_rate,
    
    -- Ranking metrics (using window functions)
    RANK() OVER (PARTITION BY d.year, d.quarter ORDER BY SUM(s.net_amount) DESC) AS revenue_rank,
    RANK() OVER (PARTITION BY d.year, d.quarter ORDER BY SUM(s.quantity) DESC) AS volume_rank,
    RANK() OVER (PARTITION BY d.year, d.quarter ORDER BY AVG(s.profit_margin) DESC) AS margin_rank,
    
    -- Performance indicators
    CASE 
        WHEN SUM(s.net_amount) > AVG(SUM(s.net_amount)) OVER (PARTITION BY d.year, d.quarter) 
        THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS revenue_performance,
    
    CASE 
        WHEN AVG(s.profit_margin) > AVG(AVG(s.profit_margin)) OVER (PARTITION BY d.year, d.quarter) 
        THEN 'High Margin' 
        ELSE 'Low Margin' 
    END AS margin_performance

FROM [dw].[fact_sales] s
INNER JOIN [dw].[dim_product] p ON s.product_key = p.product_key
INNER JOIN [dw].[dim_date] d ON s.date_key = d.date_key

GROUP BY 
    p.product_id, p.product_name, p.product_category, p.product_subcategory, 
    p.product_brand, p.unit_cost, p.unit_price, p.profit_margin,
    d.year, d.quarter, d.month;
GO

-- =====================================================
-- 4. Customer Segmentation Analysis View
-- =====================================================
IF OBJECT_ID('[dw].[vw_customer_segmentation_analysis]', 'V') IS NOT NULL
    DROP VIEW [dw].[vw_customer_segmentation_analysis];
GO

CREATE VIEW [dw].[vw_customer_segmentation_analysis]
AS
SELECT 
    -- Customer dimensions
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    c.customer_type,
    c.registration_date,
    
    -- Geography
    g.region_name,
    g.country_name,
    
    -- Time period
    d.year,
    
    -- Customer metrics
    COUNT(DISTINCT s.transaction_id) AS total_transactions,
    COUNT(DISTINCT s.order_number) AS total_orders,
    COUNT(DISTINCT s.product_key) AS unique_products_purchased,
    COUNT(DISTINCT p.product_category) AS unique_categories_purchased,
    COUNT(DISTINCT s.channel_key) AS channels_used,
    
    SUM(s.quantity) AS total_quantity_purchased,
    SUM(s.net_amount) AS total_spent,
    SUM(s.profit_amount) AS total_profit_generated,
    
    -- Average metrics
    AVG(s.net_amount) AS avg_transaction_value,
    AVG(s.quantity) AS avg_quantity_per_transaction,
    AVG(s.profit_margin) AS avg_profit_margin,
    
    -- Temporal metrics
    MIN(d.date) AS first_purchase_date,
    MAX(d.date) AS last_purchase_date,
    DATEDIFF(DAY, MIN(d.date), MAX(d.date)) AS customer_lifespan_days,
    
    -- RFM Analysis components
    DATEDIFF(DAY, MAX(d.date), GETDATE()) AS recency_days,
    COUNT(DISTINCT s.transaction_id) AS frequency,
    SUM(s.net_amount) AS monetary_value,
    
    -- Customer value indicators
    CASE 
        WHEN SUM(s.net_amount) > 5000 THEN 'High Value'
        WHEN SUM(s.net_amount) > 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS value_segment,
    
    CASE 
        WHEN COUNT(DISTINCT s.transaction_id) > 10 THEN 'Frequent'
        WHEN COUNT(DISTINCT s.transaction_id) > 3 THEN 'Regular'
        ELSE 'Occasional'
    END AS frequency_segment,
    
    CASE 
        WHEN DATEDIFF(DAY, MAX(d.date), GETDATE()) <= 30 THEN 'Recent'
        WHEN DATEDIFF(DAY, MAX(d.date), GETDATE()) <= 90 THEN 'Moderate'
        ELSE 'Dormant'
    END AS recency_segment,
    
    -- Channel preference
    (SELECT TOP 1 ch.channel_name 
     FROM [dw].[fact_sales] s2 
     INNER JOIN [dw].[dim_sales_channel] ch ON s2.channel_key = ch.channel_key
     WHERE s2.customer_key = c.customer_key 
     GROUP BY ch.channel_name 
     ORDER BY COUNT(*) DESC) AS preferred_channel,
    
    -- Product preference
    (SELECT TOP 1 p2.product_category 
     FROM [dw].[fact_sales] s3 
     INNER JOIN [dw].[dim_product] p2 ON s3.product_key = p2.product_key
     WHERE s3.customer_key = c.customer_key 
     GROUP BY p2.product_category 
     ORDER BY SUM(s3.net_amount) DESC) AS preferred_category

FROM [dw].[fact_sales] s
INNER JOIN [dw].[dim_customer] c ON s.customer_key = c.customer_key
INNER JOIN [dw].[dim_date] d ON s.date_key = d.date_key
INNER JOIN [dw].[dim_geography] g ON s.geography_key = g.geography_key
INNER JOIN [dw].[dim_product] p ON s.product_key = p.product_key

GROUP BY 
    c.customer_id, c.customer_name, c.customer_segment, c.customer_type, 
    c.registration_date, c.customer_key,
    g.region_name, g.country_name,
    d.year;
GO

-- =====================================================
-- 5. Sales Trend Analysis View
-- =====================================================
IF OBJECT_ID('[dw].[vw_sales_trend_analysis]', 'V') IS NOT NULL
    DROP VIEW [dw].[vw_sales_trend_analysis];
GO

CREATE VIEW [dw].[vw_sales_trend_analysis]
AS
SELECT 
    -- Time dimensions
    d.date,
    d.year,
    d.quarter,
    d.month,
    d.month_name,
    d.week_of_year,
    d.day_of_week,
    d.day_name,
    d.is_weekend,
    
    -- Current period metrics
    SUM(s.net_amount) AS current_revenue,
    COUNT(DISTINCT s.transaction_id) AS current_transactions,
    COUNT(DISTINCT s.customer_key) AS current_customers,
    AVG(s.net_amount) AS current_avg_transaction_value,
    
    -- Previous period comparisons (same day previous week)
    LAG(SUM(s.net_amount), 7) OVER (ORDER BY d.date) AS prev_week_revenue,
    LAG(COUNT(DISTINCT s.transaction_id), 7) OVER (ORDER BY d.date) AS prev_week_transactions,
    
    -- Previous period comparisons (same day previous month)
    LAG(SUM(s.net_amount), 30) OVER (ORDER BY d.date) AS prev_month_revenue,
    LAG(COUNT(DISTINCT s.transaction_id), 30) OVER (ORDER BY d.date) AS prev_month_transactions,
    
    -- Moving averages
    AVG(SUM(s.net_amount)) OVER (ORDER BY d.date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS revenue_7day_ma,
    AVG(SUM(s.net_amount)) OVER (ORDER BY d.date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW) AS revenue_30day_ma,
    
    -- Growth calculations
    CASE 
        WHEN LAG(SUM(s.net_amount), 7) OVER (ORDER BY d.date) > 0 
        THEN ((SUM(s.net_amount) - LAG(SUM(s.net_amount), 7) OVER (ORDER BY d.date)) / 
              LAG(SUM(s.net_amount), 7) OVER (ORDER BY d.date)) * 100
        ELSE 0 
    END AS wow_revenue_growth_percent,
    
    CASE 
        WHEN LAG(SUM(s.net_amount), 30) OVER (ORDER BY d.date) > 0 
        THEN ((SUM(s.net_amount) - LAG(SUM(s.net_amount), 30) OVER (ORDER BY d.date)) / 
              LAG(SUM(s.net_amount), 30) OVER (ORDER BY d.date)) * 100
        ELSE 0 
    END AS mom_revenue_growth_percent,
    
    -- Cumulative metrics
    SUM(SUM(s.net_amount)) OVER (PARTITION BY d.year ORDER BY d.date) AS ytd_revenue,
    SUM(COUNT(DISTINCT s.transaction_id)) OVER (PARTITION BY d.year ORDER BY d.date) AS ytd_transactions,
    
    -- Ranking
    RANK() OVER (PARTITION BY d.year ORDER BY SUM(s.net_amount) DESC) AS daily_revenue_rank,
    DENSE_RANK() OVER (PARTITION BY d.year, d.month ORDER BY SUM(s.net_amount) DESC) AS monthly_daily_rank

FROM [dw].[fact_sales] s
INNER JOIN [dw].[dim_date] d ON s.date_key = d.date_key

GROUP BY 
    d.date, d.year, d.quarter, d.month, d.month_name, 
    d.week_of_year, d.day_of_week, d.day_name, d.is_weekend;
GO

-- =====================================================
-- Grant permissions to views
-- =====================================================
GRANT SELECT ON [dw].[vw_sales_performance_summary] TO [db_datareader];
GRANT SELECT ON [dw].[vw_daily_sales_aggregation] TO [db_datareader];
GRANT SELECT ON [dw].[vw_product_performance_analysis] TO [db_datareader];
GRANT SELECT ON [dw].[vw_customer_segmentation_analysis] TO [db_datareader];
GRANT SELECT ON [dw].[vw_sales_trend_analysis] TO [db_datareader];
GO

PRINT 'Sales Analytics Views created successfully!';
PRINT 'Views created:';
PRINT '  - dw.vw_sales_performance_summary (Detailed sales performance)';
PRINT '  - dw.vw_daily_sales_aggregation (Daily aggregated metrics)';
PRINT '  - dw.vw_product_performance_analysis (Product performance KPIs)';
PRINT '  - dw.vw_customer_segmentation_analysis (Customer analytics and RFM)';
PRINT '  - dw.vw_sales_trend_analysis (Trend analysis with growth metrics)';
GO