-- =====================================================
-- Azure Synapse Analytics Data Platform (ASADP)
-- SQL Pool Schema Creation Script
-- =====================================================

-- Create schemas for data organization
-- Following medallion architecture: Bronze (raw), Silver (processed), Gold (curated)

-- =====================================================
-- Raw Data Schema (Bronze Layer)
-- =====================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'raw')
BEGIN
    EXEC('CREATE SCHEMA raw')
    PRINT 'Created schema: raw'
END
ELSE
BEGIN
    PRINT 'Schema already exists: raw'
END
GO

-- =====================================================
-- Processed Data Schema (Silver Layer)
-- =====================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'processed')
BEGIN
    EXEC('CREATE SCHEMA processed')
    PRINT 'Created schema: processed'
END
ELSE
BEGIN
    PRINT 'Schema already exists: processed'
END
GO

-- =====================================================
-- Curated Data Schema (Gold Layer)
-- =====================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'curated')
BEGIN
    EXEC('CREATE SCHEMA curated')
    PRINT 'Created schema: curated'
END
ELSE
BEGIN
    PRINT 'Schema already exists: curated'
END
GO

-- =====================================================
-- Data Marts Schema
-- =====================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'marts')
BEGIN
    EXEC('CREATE SCHEMA marts')
    PRINT 'Created schema: marts'
END
ELSE
BEGIN
    PRINT 'Schema already exists: marts'
END
GO

-- =====================================================
-- Staging Schema
-- =====================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'staging')
BEGIN
    EXEC('CREATE SCHEMA staging')
    PRINT 'Created schema: staging'
END
ELSE
BEGIN
    PRINT 'Schema already exists: staging'
END
GO

-- =====================================================
-- Metadata Schema
-- =====================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'metadata')
BEGIN
    EXEC('CREATE SCHEMA metadata')
    PRINT 'Created schema: metadata'
END
ELSE
BEGIN
    PRINT 'Schema already exists: metadata'
END
GO

-- =====================================================
-- Audit Schema
-- =====================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'audit')
BEGIN
    EXEC('CREATE SCHEMA audit')
    PRINT 'Created schema: audit'
END
ELSE
BEGIN
    PRINT 'Schema already exists: audit'
END
GO

-- =====================================================
-- Security Schema
-- =====================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'security')
BEGIN
    EXEC('CREATE SCHEMA security')
    PRINT 'Created schema: security'
END
ELSE
BEGIN
    PRINT 'Schema already exists: security'
END
GO

-- =====================================================
-- Utilities Schema
-- =====================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'utils')
BEGIN
    EXEC('CREATE SCHEMA utils')
    PRINT 'Created schema: utils'
END
ELSE
BEGIN
    PRINT 'Schema already exists: utils'
END
GO

-- =====================================================
-- Machine Learning Schema
-- =====================================================
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'ml')
BEGIN
    EXEC('CREATE SCHEMA ml')
    PRINT 'Created schema: ml'
END
ELSE
BEGIN
    PRINT 'Schema already exists: ml'
END
GO

PRINT 'Schema creation completed successfully!'
GO