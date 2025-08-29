/*
=============================================================
	Create Database and Load Data
=============================================================
Script Purpose:
    - This script creates a new database named 'world_layoffs' after checking if it already exists. 
		If the database exists, it is dropped and recreated. 
    - Additionally, the script creates table 'layoffs' 
    - Lastly the scripts loads data into 'layoffs' table. 
	
WARNING:
    Running this script will drop the entire 'world_layoffs' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.
*/ 

-- Recreate DB.
DROP DATABASE IF EXISTS world_layoffs;
CREATE DATABASE world_layoffs;
USE world_layoffs;
SELECT '--- Database created and in use ---' AS status;

-- Create table schema. 
DROP TABLE IF EXISTS layoffs;
CREATE TABLE layoffs (
	company 				TEXT,
  location 					TEXT,
  industry 					TEXT,
  total_laid_off 			INT DEFAULT NULL,
  percentage_laid_off 		TEXT,
  `date` 					TEXT,
  stage 					TEXT,
  country 					TEXT,
  funds_raised_millions 	INT DEFAULT NULL
);
SELECT '--- Table created: layoffs ---' AS status;

-- Load data from CSV.
START TRANSACTION;

LOAD DATA LOCAL INFILE 'C:\Users\aleja\Downloads\1. Data Analysis\Data Analysis Bootcamp\MySQL - World Layoffs Analysis - Data Cleaning and EDA\datasets\layoffs.csv'
INTO TABLE layoffs
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(@company, @location, @industry, @total_laid_off, @percentage_laid_off, @date, @stage, @country, @funds_raised_millions)
SET
  company               = NULLIF(@company, ''),
  location              = NULLIF(@location, ''),
  industry              = NULLIF(@industry, ''),
  total_laid_off        = NULLIF(@total_laid_off, ''),
  percentage_laid_off   = CASE
                          WHEN @percentage_laid_off IN ('', 'NULL') THEN NULL
                          ELSE @percentage_laid_off
                        END,
`date`                = CASE
                          WHEN @date IN ('', 'NULL') THEN NULL
                          ELSE @date
                        END,
  stage                 = NULLIF(@stage, ''),
  country               = NULLIF(@country, ''),
  funds_raised_millions = NULLIF(@funds_raised_millions, '');
  
COMMIT;

SELECT '--- Data loading completed ---' AS status;

-- =============================================================
-- End of script: Data loaded into world_layoffs.layoffs
-- Next steps: Run 01_data_clean.sql script
-- =============================================================
SELECT CONCAT('Script completed at ', DATE_FORMAT(NOW(), '%Y-%m-%d %H:%i:%s'),
              ' | Rows in layoffs: ', COUNT(*)) AS status
FROM layoffs;


