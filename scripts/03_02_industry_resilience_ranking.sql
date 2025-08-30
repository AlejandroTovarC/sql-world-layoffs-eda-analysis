/*
=============================================================
Industry Resilience Ranking — Layoff Impact Analysis
=============================================================
Script: 03_02_industry_resilience_ranking.sql
Purpose: 
	- Identify which industries weathered the crisis best/worst
	- Which industries show the strongest workforce stability?
	- What sectors recovered fastest from peak layoff periods?
	- Where should companies focus expansion or avoid risk?
	- How do industry layoff patterns inform investment strategy?

=============================================================
*/

-- 2a. Industry Impact Overview
-- Shows total damage and company count by sector
SELECT 
    industry,
    COUNT(DISTINCT company) AS companies_affected,
    SUM(total_laid_off) AS total_layoffs,
    ROUND(AVG(total_laid_off), 0) AS avg_layoffs_per_event,
    ROUND(SUM(total_laid_off) / COUNT(DISTINCT company), 0) AS avg_layoffs_per_company
FROM layoffs_staging2
WHERE industry IS NOT NULL AND total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY SUM(total_laid_off) DESC;
-- ------------------------------------------


-- 2b. Industry Resilience Scoring
-- Creates risk categories for strategic decision-making
WITH industry_metrics AS (
    SELECT 
        industry,
        COUNT(DISTINCT company) AS companies_affected,
        SUM(total_laid_off) AS total_layoffs,
        COUNT(*) AS layoff_events,
        ROUND(AVG(total_laid_off), 0) AS avg_layoffs_per_event,
        MAX(total_laid_off) AS largest_single_layoff
    FROM layoffs_staging2
    WHERE industry IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY industry
),
risk_classification AS (
    SELECT 
        industry,
        companies_affected,
        total_layoffs,
        layoff_events,
        avg_layoffs_per_event,
        largest_single_layoff,
        CASE 
            WHEN total_layoffs >= 100000 THEN 'High Risk'
            WHEN total_layoffs >= 50000 THEN 'Moderate-High Risk'
            WHEN total_layoffs >= 20000 THEN 'Moderate Risk'
            WHEN total_layoffs >= 10000 THEN 'Low-Moderate Risk'
            ELSE 'Low Risk'
        END AS risk_category,
        CASE
            WHEN avg_layoffs_per_event >= 1000 THEN 'High Severity'
            WHEN avg_layoffs_per_event >= 500 THEN 'Moderate Severity'
            ELSE 'Low Severity'  
        END AS event_severity
    FROM industry_metrics
)
SELECT 
    industry,
    risk_category,
    event_severity,
    total_layoffs AS total_impact,
    companies_affected,
    layoff_events,
    avg_layoffs_per_event AS avg_event_size,
    largest_single_layoff AS worst_single_event
FROM risk_classification
ORDER BY total_layoffs DESC;
-- ------------------------------------------


-- 2c. Industry Duration Pattern Analysis  
-- Shows which sectors had sustained vs brief layoff periods
WITH monthly_industry_impact AS (
    SELECT 
        industry,
        DATE_FORMAT(`date`, '%Y-%m') AS month_year,
        SUM(total_laid_off) AS monthly_layoffs
    FROM layoffs_staging2
    WHERE industry IS NOT NULL 
      AND total_laid_off IS NOT NULL
      AND `date` IS NOT NULL
    GROUP BY industry, DATE_FORMAT(`date`, '%Y-%m')
),
industry_duration_analysis AS (
    SELECT 
        industry,
        COUNT(*) AS active_months,
        MIN(month_year) AS first_layoff_period,
        MAX(month_year) AS last_layoff_period,
        MAX(monthly_layoffs) AS peak_month_impact,
        ROUND(AVG(monthly_layoffs), 0) AS avg_monthly_impact,
        SUM(monthly_layoffs) AS total_industry_impact
    FROM monthly_industry_impact
    GROUP BY industry
),
duration_classification AS (
    SELECT 
        industry,
        active_months,
        first_layoff_period,
        last_layoff_period,
        peak_month_impact,
        avg_monthly_impact,
        total_industry_impact,
        CASE 
            WHEN active_months >= 20 THEN 'Prolonged Crisis (20+ months)'
            WHEN active_months >= 15 THEN 'Extended Impact (15-19 months)'
            WHEN active_months >= 10 THEN 'Moderate Duration (10-14 months)'
            ELSE 'Brief Impact (Under 10 months)'
        END AS duration_category,
        CASE
            WHEN peak_month_impact >= 10000 THEN 'High Peak Severity'
            WHEN peak_month_impact >= 5000 THEN 'Moderate Peak Severity'
            ELSE 'Low Peak Severity'
        END AS peak_severity
    FROM industry_duration_analysis
),
top_industries AS (
    SELECT industry 
    FROM industry_duration_analysis 
    ORDER BY total_industry_impact DESC 
    LIMIT 10
)
SELECT 
    dc.industry,
    dc.duration_category,
    dc.peak_severity,
    dc.active_months,
    dc.first_layoff_period,
    dc.last_layoff_period,
    FORMAT(dc.peak_month_impact, 0) AS peak_month_layoffs,
    FORMAT(dc.avg_monthly_impact, 0) AS avg_monthly_impact,
    FORMAT(dc.total_industry_impact, 0) AS total_impact
FROM duration_classification dc
INNER JOIN top_industries ti ON dc.industry = ti.industry
ORDER BY dc.active_months DESC, dc.peak_month_impact DESC;
-- ------------------------------------------


-- 2d. Strategic Industry Recommendations


-- Top 5 Industries to Avoid (Highest Risk)
SELECT 
    'HIGH RISK - AVOID EXPANSION' AS recommendation_type,
    industry,
    SUM(total_laid_off) AS total_impact,
    COUNT(DISTINCT company) AS companies_affected
FROM layoffs_staging2
WHERE industry IS NOT NULL AND total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY SUM(total_laid_off) DESC
LIMIT 5;

-- Top 5 Industries with Resilience (Lower Risk) 
WITH high_risk_industries AS (
    SELECT industry
    FROM layoffs_staging2
    WHERE industry IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY industry 
    ORDER BY SUM(total_laid_off) DESC 
    LIMIT 5
),
remaining_industries AS (
    SELECT 
        industry,
        SUM(total_laid_off) AS total_impact,
        COUNT(DISTINCT company) AS companies_affected,
        ROUND(AVG(total_laid_off), 0) AS avg_event_size
    FROM layoffs_staging2
    WHERE industry IS NOT NULL 
      AND total_laid_off IS NOT NULL
    GROUP BY industry
    HAVING SUM(total_laid_off) >= 5000  -- Focus on industries with meaningful data
)
SELECT 
    'LOWER RISK - EXPANSION OPPORTUNITIES' AS recommendation_type,
    ri.industry,
    ri.total_impact AS total_impact,
    ri.companies_affected,
    ri.avg_event_size AS avg_event_size
FROM remaining_industries ri
LEFT JOIN high_risk_industries hri ON ri.industry = hri.industry
WHERE hri.industry IS NULL  -- Exclude high-risk industries
ORDER BY ri.avg_event_size ASC
LIMIT 5;


-- ===========================================
-- Next Analysis: Industry Resilience Ranking
-- Next steps: Run /03_03_industry_resilience_ranking.sql
-- ===========================================















