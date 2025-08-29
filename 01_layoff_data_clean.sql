/*
=============================================================
  Data Cleaning & Data Quality — world_layoffs.layoffs
=============================================================
Script Purpose:
  Prepare a clean, typed working table for analysis by:
    1) Copying source data into staging tables.
    2) Identifying and removing duplicate rows.
    3) Standardizing string fields and normalizing values.
    4) Converting the date column to DATE type.
    5) Removing records with no layoff signals (NULL total AND NULL percentage).

Assumptions:
  - Source table: world_layoffs.layoffs (raw import; TEXT columns by design).
  - Duplicates = identical values across all business fields.
  - Country names use US/International formatting seen in the import (period fix).

Inputs / Outputs
  IN:  world_layoffs.layoffs (raw)
  OUT: world_layoffs.layoffs_staging2 (cleaned; DATE typed; duplicates removed)

*/

-- =======================================
-- 	1. CREATE STAGING TABLE AND TRANSFER DATA
-- =======================================

-- Create staging table to duplicate table and data.
CREATE TABLE layoffs_staging
LIKE layoffs;

-- Checking if metadata transferred properly.
SELECT * FROM layoffs_staging;

-- Copy data from layoffs -> layoffs_staging.
INSERT layoffs_staging
SELECT *
FROM layoffs;

SELECT 'Staging copy complete' AS status, COUNT(*) AS rows_in_staging FROM layoffs_staging;
-- -------------------

-- Identify duplicates
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, industry, total_laid_off, percentage_laid_off, `date`) AS row_num
FROM layoffs_staging;

-- Creating CTE 
WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT * 
FROM duplicate_cte
WHERE row_num >1;

-- Double-checking that the duplicates exist
select * 
from layoffs_staging
where company= 'Casper';

-- ===================================================
-- 	CREATE NEW STAGING TABLE AND DELETE DUPLICATE DATA
-- ===================================================

-- Cannot delete duplicates from CTE.
-- Creating new table to then delete the column.
-- Adding column to new table 'row_num'.

CREATE TABLE `layoffs_staging2` (
  `company` 				TEXT,
  `location` 				TEXT,
  `industry` 				TEXT,
  `total_laid_off` 			INT DEFAULT NULL,
  `percentage_laid_off` 	TEXT,
  `date` 					TEXT,
  `stage` 					TEXT,
  `country` 				TEXT,
  `funds_raised_millions` 	INT DEFAULT NULL,
  `row_num` 				INT 				-- new column
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Inserting data into new table
INSERT INTO	 layoffs_staging2
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Verifying data was copied
select * from layoffs_staging2;


-- Deleting duplicate data --
--   We assign row_num = 1 to the first occurrence and >1 to duplicates.
-- (TO APPLY: remove leading '--' on the next line).
-- DELETE -- commented to prevent unwanted deletion
FROM layoffs_staging2
WHERE row_num >1;

-- Verifying duplicates are empty
SELECT *
FROM layoffs_staging2
WHERE row_num >1;

-- =====================================
-- 	3. STANDARDIZING DATA
-- =====================================

-- Removing blank spaces on left- and right- hand side.
SELECT company, TRIM(company)
FROM layoffs_staging2;

-- Normalize company names (trim whitespace).
UPDATE layoffs_staging2
SET company= TRIM(company);
-- -------------------------------------

-- Looking at Industry -- 
SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

-- Crypto seems to be the only one with disimilar formatting
-- Updating Crypto
SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

-- Normalize industry values: collapse 'Crypto1234' -> 'Crypto'
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
-- -------------------------------------

-- Looking at Country --
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

-- Updating country to remove period.
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Normalize country formatting: remove trailing period in 'United States.'
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States';
-- -------------------------------------

-- Updating `date` column from TEXT -> DATE data type.
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging2;

-- Convert 'date' from TEXT (m/d/Y) to DATE
UPDATE layoffs_staging2
SET `date`= STR_TO_DATE(`date`, '%m/%d/%Y');

-- Checking date format is correct
SELECT `date`
FROM layoffs_staging2;

-- Change metadata to 'date' format
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
-- -------------------------------------

-- Looking at current modifications
select * 
FROM layoffs_staging2;

-- =====================================
-- 4. Dealing with NULL and blank values 
-- ===================================== 
SELECT * 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * 
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';

-- Airbnb has a blank industry label
SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';

-- Joining to then update the cell
SELECT t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry= '')
AND t2.industry IS NOT NULL;

-- Changing values to NULL instead of leaving it blank
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

-- =====================================
-- 5. Removing  columns and rows.
-- ===================================== 
-- Removing columns with NULL total laid off and percentage laid off.
-- Keep only rows where at least one of (total_laid_off, percentage_laid_off) is present.
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Drop row_num as it will not be used in future cleaning or EDA 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- =============================================================
-- End of cleaning: layoffs_staging2 ready for EDA analysis.
-- Next steps: run 02_layoff_eda.sql script
-- =============================================================
