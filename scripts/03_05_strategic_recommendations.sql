/*
=============================================================
Strategic Recommendations Synthesis
=============================================================
Script: 03_05_strategic_recommendations.sql
Purpose: Synthesize all analyses into actionable strategic guidance
Context: Strategic consultant delivering comprehensive layoff intelligence
         for executive decision-making across multiple business dimensions

Key Business Deliverables:
- Executive summary of cross-dimensional risk patterns
- Prioritized action recommendations by business function
- Risk mitigation strategies based on layoff intelligence
- Portfolio optimization guidance for strategic planning

Analysis Period: 35-month market cycle (2020-2023)

=============================================================
*/

USE world_layoffs;

-- =======================================
-- 5. STRATEGIC RECOMMENDATIONS SYNTHESIS
-- =======================================

-- 5a. Executive Dashboard - Key Risk Indicators
-- Highest Risk Industry-Geography Combinations
WITH country_industry_impact AS (
    SELECT 
        country,
        industry,
        COUNT(DISTINCT company) AS companies_affected,
        SUM(total_laid_off) AS total_impact,
        ROUND(AVG(total_laid_off), 0) AS avg_event_severity
    FROM layoffs_staging2
    WHERE industry IS NOT NULL 
      AND country IS NOT NULL 
      AND total_laid_off IS NOT NULL
    GROUP BY country, industry
),
ranked_combinations AS (
    SELECT 
        country,
        industry,
        companies_affected,
        total_impact,
        avg_event_severity,
        ROW_NUMBER() OVER (PARTITION BY country ORDER BY total_impact DESC) AS country_rank
    FROM country_industry_impact
    WHERE total_impact >= 1000  -- Minimum threshold for meaningful data
)
SELECT 
    'HIGH RISK COMBINATIONS - TOP 2 PER COUNTRY' AS risk_category,
    CONCAT(industry, ' in ', country) AS risk_combination,
    companies_affected,
    total_impact,
    avg_event_severity
FROM ranked_combinations
WHERE country_rank <= 2  -- Top 2 combinations per country
ORDER BY country, total_impact DESC;

-- Critical Seasonal Risk Windows
WITH monthly_risk_analysis AS (
    SELECT 
        MONTH(`date`) AS month_num,
        MONTHNAME(`date`) AS risk_month,
        COUNT(DISTINCT company) AS companies_at_risk,
        SUM(total_laid_off) AS seasonal_impact,
        ROUND(AVG(total_laid_off), 0) AS avg_seasonal_severity
    FROM layoffs_staging2
    WHERE `date` IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY MONTH(`date`), MONTHNAME(`date`)
)
SELECT 
    'CRITICAL SEASONAL WINDOWS' AS risk_category,
    risk_month,
    companies_at_risk,
    seasonal_impact,
    avg_seasonal_severity,
    CASE 
        WHEN month_num IN (1, 11, 12) THEN 'AVOID MAJOR INITIATIVES'
        WHEN month_num IN (3, 4, 9, 10) THEN 'EXERCISE CAUTION'
        ELSE 'MODERATE RISK PERIOD'
    END AS executive_guidance
FROM monthly_risk_analysis
ORDER BY seasonal_impact DESC
LIMIT 5;

-- ----------------------------------------------------------------------
-- 5b. Strategic Recommendations by Business Function
-- Targeted guidance for different organizational stakeholders

-- Human Resources & Workforce Planning Recommendations
WITH monthly_hiring_analysis AS (
    SELECT 
        MONTHNAME(`date`) AS month_name,
        SUM(total_laid_off) AS monthly_layoffs
    FROM layoffs_staging2
    WHERE `date` IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY MONTH(`date`), MONTHNAME(`date`)
    ORDER BY SUM(total_laid_off) ASC
    LIMIT 3
)
SELECT 
    'HUMAN RESOURCES RECOMMENDATIONS' AS function_area,
    'Optimal Hiring Months' AS recommendation_type,
    CONCAT(month_name, ' - ', monthly_layoffs, ' total layoffs') AS specific_action,
    'Schedule major hiring during lowest layoff activity months' AS business_rationale
FROM monthly_hiring_analysis;

-- Investment & Partnership Strategy Recommendations  
SELECT 
    'INVESTMENT STRATEGY RECOMMENDATIONS' AS function_area,
    'Company Stage Risk Assessment' AS recommendation_type,
    CASE 
        WHEN stage IN ('Post-IPO', 'Seed') THEN CONCAT('HIGH CAUTION: ', stage, ' companies show poor funding efficiency')
        WHEN stage LIKE 'Series D%' OR stage LIKE 'Series E%' THEN CONCAT('PREFERRED: ', stage, ' companies show efficient capital utilization')
        ELSE CONCAT('MODERATE RISK: ', stage, ' requires individual assessment')
    END AS specific_action,
    'Based on layoffs-per-million-funded efficiency analysis' AS business_rationale
FROM (
    SELECT DISTINCT stage 
    FROM layoffs_staging2 
    WHERE stage IS NOT NULL 
    AND stage IN ('Post-IPO', 'Seed', 'Series D', 'Series E', 'Series F', 'Series A', 'Series B', 'Series C')
) stages;

-- Geographic Expansion Strategy Recommendations
SELECT 
    'GEOGRAPHIC STRATEGY RECOMMENDATIONS' AS function_area,
    'Market Entry Risk Assessment' AS recommendation_type,
    CASE
        WHEN total_layoffs >= 100000 THEN CONCAT('AVOID: ', country, ' shows extreme workforce volatility')
        WHEN total_layoffs <= 5000 AND companies_affected >= 10 THEN CONCAT('OPPORTUNITY: ', country, ' shows stable workforce patterns')
        ELSE CONCAT('MODERATE: ', country, ' requires enhanced due diligence')
    END AS specific_action,
    CONCAT('Based on ', total_layoffs, ' total layoffs across ', companies_affected, ' companies') AS business_rationale
FROM (
    SELECT 
        country,
        SUM(total_laid_off) AS total_layoffs,
        COUNT(DISTINCT company) AS companies_affected
    FROM layoffs_staging2
    WHERE country IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY country
    HAVING COUNT(DISTINCT company) >= 5
) country_analysis
ORDER BY total_layoffs DESC;


-- ----------------------------------------------------------------------
-- 5c. Portfolio Optimization Guidance
-- Strategic portfolio balancing based on risk analysis

-- Industry Diversification Recommendations
WITH industry_risk_profile AS (
    SELECT 
        industry,
        SUM(total_laid_off) AS total_impact,
        COUNT(DISTINCT company) AS market_depth,
        ROUND(AVG(total_laid_off), 0) AS avg_volatility,
        CASE
            WHEN SUM(total_laid_off) >= 40000 THEN 'High Risk'
            WHEN SUM(total_laid_off) >= 20000 THEN 'Moderate Risk'  
            ELSE 'Lower Risk'
        END AS risk_classification
    FROM layoffs_staging2
    WHERE industry IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY industry
)
SELECT 
    'INDUSTRY PORTFOLIO BALANCE' AS optimization_area,
    risk_classification,
    COUNT(*) AS industries_in_category,
    CONCAT('Limit exposure to ', ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM industry_risk_profile), 0), '% of portfolio') AS allocation_guidance
FROM industry_risk_profile
GROUP BY risk_classification
ORDER BY 
    CASE risk_classification
        WHEN 'High Risk' THEN 1
        WHEN 'Moderate Risk' THEN 2
        WHEN 'Lower Risk' THEN 3
    END;
    
