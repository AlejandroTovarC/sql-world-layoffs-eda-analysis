/*
=============================================================
Geographic Risk Assessment — Location Intelligence Analysis
=============================================================
Script: 03_03_geographic_risk_assessment.sql
Purpose: Identify stable vs volatile markets for strategic location decisions

Key Business Questions Answered:
- Which countries/regions offer the most stable business environments?
- What geographic markets show highest workforce volatility?
- Where should companies establish operations to minimize layoff risk?
- How do regional patterns inform global expansion strategy?
=============================================================
*/

-- =======================================
-- 3. GEOGRAPHIC RISK ASSESSMENT ANALYSIS
-- =======================================

-- 3a. Country Impact Overview
-- Shows total damage and market penetration by country
SELECT 
    country,
    COUNT(DISTINCT company) AS companies_affected,
    COUNT(*) AS layoff_events,
    SUM(total_laid_off) AS total_layoffs,
    ROUND(AVG(total_laid_off), 0) AS avg_layoffs_per_event,
    ROUND(SUM(total_laid_off) / COUNT(DISTINCT company), 0) AS avg_impact_per_company
FROM layoffs_staging2
WHERE country IS NOT NULL AND total_laid_off IS NOT NULL
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;

-- 3b. Geographic Stability Scoring
-- Creates risk framework for location decision-making
WITH country_metrics AS (
    SELECT 
        country,
        COUNT(DISTINCT company) AS companies_affected,
        COUNT(*) AS layoff_events,
        SUM(total_laid_off) AS total_layoffs,
        ROUND(AVG(total_laid_off), 0) AS avg_event_size,
        MAX(total_laid_off) AS worst_single_event,
        COUNT(DISTINCT DATE_FORMAT(`date`, '%Y-%m')) AS active_months
    FROM layoffs_staging2
    WHERE country IS NOT NULL AND total_laid_off IS NOT NULL AND `date` IS NOT NULL
    GROUP BY country
),
stability_classification AS (
    SELECT 
        country,
        companies_affected,
        layoff_events,
        total_layoffs,
        avg_event_size,
        worst_single_event,
        active_months,
        CASE 
            WHEN total_layoffs >= 200000 THEN 'High Risk Market'
            WHEN total_layoffs >= 50000 THEN 'Moderate-High Risk'
            WHEN total_layoffs >= 20000 THEN 'Moderate Risk'
            WHEN total_layoffs >= 5000 THEN 'Lower-Moderate Risk'
            ELSE 'Low Risk Market'
        END AS market_risk_level,
        CASE
            WHEN avg_event_size >= 1000 THEN 'High Volatility'
            WHEN avg_event_size >= 500 THEN 'Moderate Volatility'
            ELSE 'Low Volatility'
        END AS market_volatility,
        CASE
            WHEN active_months >= 30 THEN 'Persistent Instability'
            WHEN active_months >= 20 THEN 'Extended Instability' 
            WHEN active_months >= 10 THEN 'Moderate Instability'
            ELSE 'Brief Instability'
        END AS duration_pattern
    FROM country_metrics
)
SELECT 
    country,
    market_risk_level,
    market_volatility,
    duration_pattern,
    total_layoffs AS total_impact,
    companies_affected,
    layoff_events,
    active_months,
    avg_event_size AS avg_event_size,
    worst_single_event AS worst_single_event
FROM stability_classification
WHERE total_layoffs >= 1000  -- Focus on countries with meaningful data
ORDER BY total_layoffs DESC;

-- 3c. Layoff Activity Concentration Analysis
-- Shows workforce crisis penetration patterns by country
WITH country_activity_indicators AS (
    SELECT 
        country,
        COUNT(DISTINCT company) AS companies_with_layoffs,
        COUNT(DISTINCT industry) AS affected_sectors,
        SUM(total_laid_off) AS total_impact,
        ROUND(AVG(total_laid_off), 0) AS avg_layoff_size,
        COUNT(*) AS total_layoff_events,
        MIN(`date`) AS first_layoff_date,
        MAX(`date`) AS last_layoff_date
    FROM layoffs_staging2
    WHERE country IS NOT NULL 
      AND total_laid_off IS NOT NULL 
      AND industry IS NOT NULL
      AND `date` IS NOT NULL
    GROUP BY country
),
activity_classification AS (
    SELECT 
        country,
        companies_with_layoffs,
        affected_sectors,
        total_impact,
        avg_layoff_size,
        total_layoff_events,
        first_layoff_date,
        last_layoff_date,
        CASE
            WHEN companies_with_layoffs >= 50 AND affected_sectors >= 10 THEN 'High Activity Market'
            WHEN companies_with_layoffs >= 20 AND affected_sectors >= 7 THEN 'Moderate Activity Market'
            WHEN companies_with_layoffs >= 10 AND affected_sectors >= 5 THEN 'Limited Activity Market'
            ELSE 'Minimal Activity Market'
        END AS layoff_activity_level,
        ROUND(total_impact / companies_with_layoffs, 0) AS avg_impact_per_company
    FROM country_activity_indicators
)
SELECT 
    country,
    layoff_activity_level,
    companies_with_layoffs,
    affected_sectors AS sectors_with_layoffs,
    FORMAT(total_impact, 0) AS total_layoffs,
    total_layoff_events,
    FORMAT(avg_layoff_size, 0) AS avg_event_size,
    FORMAT(avg_impact_per_company, 0) AS avg_impact_per_company,
    first_layoff_date,
    last_layoff_date
FROM activity_classification
WHERE total_impact >= 5000  -- Focus on substantial activity
ORDER BY 
    CASE layoff_activity_level
        WHEN 'High Activity Market' THEN 1
        WHEN 'Moderate Activity Market' THEN 2
        WHEN 'Limited Activity Market' THEN 3
        WHEN 'Minimal Activity Market' THEN 4
    END,
    total_impact DESC;


-- 3d. Strategic Location Recommendations
-- Geographic guidance for expansion and risk management

-- Highest Risk Markets (Avoid or Exercise Extreme Caution)
SELECT 
    'HIGH RISK - CAUTION REQUIRED' AS recommendation_type,
    country,
    SUM(total_laid_off) AS total_impact,
    COUNT(DISTINCT company) AS companies_affected,
    ROUND(AVG(total_laid_off), 0) AS avg_event_severity
FROM layoffs_staging2
WHERE country IS NOT NULL AND total_laid_off IS NOT NULL
GROUP BY country
ORDER BY SUM(total_laid_off) DESC
LIMIT 3;

-- Stable Markets for Expansion (Lower Risk Options)
WITH high_risk_countries AS (
    SELECT country
    FROM layoffs_staging2
    WHERE country IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY country
    ORDER BY SUM(total_laid_off) DESC
    LIMIT 3
),
market_analysis AS (
    SELECT 
        country,
        SUM(total_laid_off) AS total_impact,
        COUNT(DISTINCT company) AS companies_affected,
        ROUND(AVG(total_laid_off), 0) AS avg_event_size,
        COUNT(*) AS total_events
    FROM layoffs_staging2
    WHERE country IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY country
    HAVING SUM(total_laid_off) >= 2000  -- Meaningful market presence
)
SELECT 
    'STABLE MARKETS - EXPANSION OPPORTUNITIES' AS recommendation_type,
    ma.country,
    ma.total_impact AS total_impact,
    ma.companies_affected,
    ma.total_events,
    FORMAT(ma.avg_event_size, 0) AS avg_event_size
FROM market_analysis ma
LEFT JOIN high_risk_countries hrc ON ma.country = hrc.country
WHERE hrc.country IS NULL  -- Exclude highest risk countries
ORDER BY ma.avg_event_size ASC, ma.total_impact ASC
LIMIT 5;



-- ===========================================
-- Next Analysis: Industry Resilience Ranking
-- Next steps: Run /03_04_company_stage_insights.sql
-- ===========================================