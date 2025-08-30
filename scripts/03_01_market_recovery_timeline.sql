/*
=============================================================
Strategic Business Analysis — Layoff Market Intelligence
=============================================================
Script Purpose: Economic recovery briefing for strategic workforce planning
	- Identify peak crisis periods to understand market cycles
	- Determine recovery phases for strategic timing decisions  
	- Reveal seasonal patterns for workforce planning
	- Establish baseline for industry/geographic comparisons

Analysis Period: 35-month market cycle analysis
Dataset: world_layoffs.layoffs_staging2 (cleaned)
=============================================================
*/

-- =======================================
-- 1. MARKET RECOVERY TIMELINE ANALYSIS
-- =======================================
-- 1a. Monthly Layoff Progression (Rolling Analysis)

WITH monthly_layoffs AS (
    SELECT 
        DATE_FORMAT(`date`, '%Y-%m') AS month_year,
        YEAR(`date`) AS year,
        MONTH(`date`) AS month,
        COUNT(DISTINCT company) AS companies_affected,
        SUM(total_laid_off) AS monthly_total_layoffs
    FROM layoffs_staging2 
    WHERE `date` IS NOT NULL 
      AND total_laid_off IS NOT NULL
    GROUP BY DATE_FORMAT(`date`, '%Y-%m'), YEAR(`date`), MONTH(`date`)
    ORDER BY month_year
),
rolling_impact AS (
    SELECT 
        month_year,
        year,
        MONTHNAME(STR_TO_DATE(CONCAT(year, '-', month, '-01'), '%Y-%m-%d')) AS month_name,
        companies_affected,
        monthly_total_layoffs,
        SUM(monthly_total_layoffs) OVER (ORDER BY month_year) AS cumulative_layoffs,
        AVG(monthly_total_layoffs) OVER (ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3month_avg
    FROM monthly_layoffs
)
SELECT 
    month_year,
    CONCAT(month_name, ' ', year) AS period_label,
    companies_affected,
    FORMAT(monthly_total_layoffs, 0) AS monthly_layoffs,
    FORMAT(cumulative_layoffs, 0) AS cumulative_total,
    FORMAT(ROUND(rolling_3month_avg, 0), 0) AS three_month_trend
FROM rolling_impact
ORDER BY month_year;
-- -------------------------------

-- 1b. Crisis vs Recovery Phase Analysis

WITH monthly_data AS (
    SELECT 
        DATE_FORMAT(`date`, '%Y-%m') AS month_year,
        SUM(total_laid_off) AS monthly_layoffs,
        COUNT(DISTINCT company) AS companies_affected
    FROM layoffs_staging2 
    WHERE `date` IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY DATE_FORMAT(`date`, '%Y-%m')
),
	phase_analysis AS (
    SELECT 
        month_year,
        monthly_layoffs,
        companies_affected,
        CASE 
            WHEN monthly_layoffs >= 100000 THEN 'Crisis Phase'
            WHEN monthly_layoffs >= 50000 THEN 'High Impact Phase'  
            WHEN monthly_layoffs >= 20000 THEN 'Moderate Impact Phase'
            ELSE 'Low Impact Phase'
        END AS market_phase
    FROM monthly_data
)
SELECT 
    market_phase,
    COUNT(*) AS months_in_phase,
    ROUND(COUNT(*) / (SELECT COUNT(*) FROM phase_analysis) * 100, 1) AS pct_of_timeline,
    AVG(monthly_layoffs) AS avg_monthly_layoffs,
    AVG(companies_affected) AS avg_companies_per_month,
    MIN(monthly_layoffs) AS min_monthly_layoffs,
    MAX(monthly_layoffs) AS max_monthly_layoffs
FROM phase_analysis
GROUP BY market_phase
ORDER BY 
    CASE market_phase
        WHEN 'Crisis Phase' THEN 1
        WHEN 'High Impact Phase' THEN 2  
        WHEN 'Moderate Impact Phase' THEN 3
        WHEN 'Low Impact Phase' THEN 4
    END;

    -- ------------------------------------
    
-- 1c. Seasonal Patterns Analysis
SELECT MAX(`date`) FROM layoffs_staging2;
WITH monthly_summary AS (
    SELECT 
        MONTH(`date`) AS month_num,
        MONTHNAME(`date`) AS month_name,
        COUNT(DISTINCT company) AS companies_affected,
        SUM(total_laid_off) AS monthly_layoffs,
        AVG(total_laid_off) AS avg_layoffs_per_event
    FROM layoffs_staging2
    WHERE `date` IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY MONTH(`date`), MONTHNAME(`date`)
)
SELECT 
    month_num,
    month_name,
    companies_affected,
    monthly_layoffsAS total_layoffs,
    ROUND(avg_layoffs_per_event, 0) AS avg_layoffs_per_event,
    -- Strategic timing guidance
    CASE 
        WHEN month_num IN (1, 11, 12) THEN 'High Risk - Budget Cycles'
        WHEN month_num IN (3, 4, 9, 10) THEN 'Moderate Risk - Quarter Ends'
        ELSE 'Lower Risk - Mid Quarter'
    END AS strategic_risk_level
FROM monthly_summary
ORDER BY monthly_layoffs DESC;
	-- ------------------------------------

-- 1d. Key Timeline Milestones
-- Executive summary of critical dates

-- Analysis period overview
SELECT 
    MIN(`date`) AS analysis_start_date,
    MAX(`date`) AS analysis_end_date,
    ROUND(DATEDIFF(MAX(`date`), MIN(`date`)) / 30.44, 1) AS months_covered -- 30.44 = average days in a month
FROM layoffs_staging2 
WHERE `date` IS NOT NULL;

-- Peak crisis identification
SELECT 
    DATE_FORMAT(`date`, '%Y-%m') AS peak_crisis_month,
    SUM(total_laid_off) AS total_layoffs_that_month
FROM layoffs_staging2 
WHERE `date` IS NOT NULL AND total_laid_off IS NOT NULL
GROUP BY DATE_FORMAT(`date`, '%Y-%m')
ORDER BY SUM(total_laid_off) DESC 
LIMIT 1;

-- Largest single layoff event
SELECT 
    company,
    `date` AS event_date,
    FORMAT(total_laid_off, 0) AS layoffs,
    industry,
    country
FROM layoffs_staging2 
WHERE total_laid_off = (SELECT MAX(total_laid_off) FROM layoffs_staging2)
LIMIT 1;

-- ===========================================
-- Next Analysis: Industry Resilience Ranking
-- Next steps: Run /03_02_industry_resilience_ranking.sql
-- ===========================================


