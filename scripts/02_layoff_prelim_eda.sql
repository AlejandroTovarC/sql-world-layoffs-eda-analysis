/*
=============================================================
  Exploratory Data Analysis — world_layoffs.layoffs_staging2
=============================================================
Script Purpose:
- Begin general EDA to find trends to further explore in later scripts.

*/

SELECT *
FROM layoffs_staging2;

-- Looking at which companies had a 100% layoffs
SELECT company, MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 3 DESC;

-- Looking at companies that went under
SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off  =1
ORDER BY funds_raised_millions DESC;

-- Looking at company
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

-- Looking at data date range
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging2;

-- Looking at industry
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY 2 DESC;

-- Looking at country
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY 2 DESC;

-- Looking at layoffs by year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY YEAR(`date`)
ORDER BY 2 DESC;

-- Looking at stage
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 1 DESC;

-- Looking at percentage laid off
SELECT stage, ROUND(AVG(percentage_laid_off),2)
FROM layoffs_staging2
GROUP BY stage
ORDER BY 2 DESC;

-- Looking at progression of total laid off
-- Using rolling sum based on month
SELECT substring(`date`, 1,7) AS `month`, sum(total_laid_off)
FROM layoffs_staging2
WHERE substring(`date`, 1,7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC;

WITH rolling_total AS 
(
SELECT substring(`date`, 1,7) AS `month`, sum(total_laid_off) AS total_off
FROM layoffs_staging2
WHERE substring(`date`, 1,7) IS NOT NULL
GROUP BY `month`
ORDER BY 1 ASC
)
SELECT `month`, total_off
, sum(total_off) OVER(ORDER BY `month`) AS rolling_total
FROM rolling_total;

-- Looking at company laid off by year
SELECT company, SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 DESC;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

-- ranking max layoffs by year
WITH company_year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), sum(total_laid_off)
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
), company_year_rank AS
(
SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_laid_off DESC) AS ranking
FROM company_year
WHERE years is not null
)
SELECT * 
FROM company_year_rank
WHERE ranking <= 5
;


SELECT
  company,
  COUNT(*) AS company_count
FROM layoffs_staging2
GROUP BY company
ORDER BY company_count DESC
LIMIT 15;

SELECT MIN(`date`), MAX(`date`), TIMESTAMPDIFF(month, min(`date`), max(`date`))
FROM layoffs_staging2

