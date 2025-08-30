/*
=============================================================
Company Stage & Funding Insights — Investment Risk Analysis
=============================================================
Script: 03_04_company_stage_insights.sql
Purpose: Identify which industries weathered the crisis best/worst

Key Business Questions Answered:
- Which industries show the strongest workforce stability?
- What sectors recovered fastest from peak layoff periods?
- Where should companies focus expansion or avoid risk?
- How do industry layoff patterns inform investment strategy?

=============================================================
*/

USE world_layoffs;

-- =======================================
-- 4. COMPANY STAGE & FUNDING INSIGHTS ANALYSIS
-- =======================================

-- 4a. Company Stage Impact Analysis
-- Shows layoff patterns across different company maturity levels
SELECT 
    stage,
    COUNT(DISTINCT company) AS companies_affected,
    COUNT(*) AS layoff_events,
    SUM(total_laid_off) AS total_layoffs,
    ROUND(AVG(total_laid_off), 0) AS avg_layoffs_per_event,
    ROUND(SUM(total_laid_off) / COUNT(DISTINCT company), 0) AS avg_layoffs_per_company,
    MAX(total_laid_off) AS largest_single_layoff
FROM layoffs_staging2
WHERE stage IS NOT NULL AND total_laid_off IS NOT NULL
GROUP BY stage
ORDER BY SUM(total_laid_off) DESC;

-- 4b. Funding Level Risk Assessment
-- Analyzes relationship between funding raised and layoff severity
WITH funding_brackets AS (
    SELECT 
        company,
        stage,
        funds_raised_millions,
        total_laid_off,
        CASE 
            WHEN funds_raised_millions IS NULL THEN 'Unknown Funding'
            WHEN funds_raised_millions >= 1000 THEN 'Mega Funded (1B+)'
            WHEN funds_raised_millions >= 500 THEN 'Highly Funded (500M-1B)'
            WHEN funds_raised_millions >= 100 THEN 'Well Funded (100M-500M)'
            WHEN funds_raised_millions >= 50 THEN 'Moderately Funded (50M-100M)'
            WHEN funds_raised_millions >= 10 THEN 'Early Funded (10M-50M)'
            ELSE 'Minimal Funding (<10M)'
        END AS funding_category
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL
),
funding_impact_analysis AS (
    SELECT 
        funding_category,
        COUNT(DISTINCT company) AS companies_in_category,
        COUNT(*) AS total_layoff_events,
        SUM(total_laid_off) AS total_layoffs,
        ROUND(AVG(total_laid_off), 0) AS avg_layoffs_per_event,
        MAX(total_laid_off) AS worst_single_event,
        ROUND(AVG(funds_raised_millions), 0) AS avg_funding_in_category
    FROM funding_brackets
    GROUP BY funding_category
)
SELECT 
    funding_category,
    companies_in_category,
    total_layoff_events,
    total_layoffs,
    avg_layoffs_per_event AS avg_event_severity,
    worst_single_event,
    avg_funding_in_category AS avg_funding_millions
FROM funding_impact_analysis
ORDER BY 
    CASE funding_category
        WHEN 'Mega Funded (1B+)' THEN 1
        WHEN 'Highly Funded (500M-1B)' THEN 2
        WHEN 'Well Funded (100M-500M)' THEN 3
        WHEN 'Moderately Funded (50M-100M)' THEN 4
        WHEN 'Early Funded (10M-50M)' THEN 5
        WHEN 'Minimal Funding (<10M)' THEN 6
        WHEN 'Unknown Funding' THEN 7
    END;

-- 4c. Stage-Funding Cross Analysis
-- Shows risk patterns across company stage and funding combinations
WITH stage_funding_matrix AS (
    SELECT 
        stage,
        CASE 
            WHEN funds_raised_millions IS NULL THEN 'Unknown'
            WHEN funds_raised_millions >= 100 THEN 'High Funding (100M+)'
            WHEN funds_raised_millions >= 25 THEN 'Moderate Funding (25M-100M)'
            WHEN funds_raised_millions >= 5 THEN 'Low Funding (5M-25M)'
            ELSE 'Minimal Funding (<5M)'
        END AS funding_tier,
        COUNT(DISTINCT company) AS companies,
        SUM(total_laid_off) AS total_layoffs,
        ROUND(AVG(total_laid_off), 0) AS avg_layoffs_per_event,
        COUNT(*) AS layoff_events
    FROM layoffs_staging2
    WHERE stage IS NOT NULL AND total_laid_off IS NOT NULL
    GROUP BY stage, funding_tier
),
risk_scoring AS (
    SELECT 
        stage,
        funding_tier,
        companies,
        total_layoffs,
        avg_layoffs_per_event,
        layoff_events,
        CASE
            WHEN avg_layoffs_per_event >= 1000 THEN 'High Risk'
            WHEN avg_layoffs_per_event >= 500 THEN 'Moderate-High Risk'
            WHEN avg_layoffs_per_event >= 250 THEN 'Moderate Risk'
            ELSE 'Lower Risk'
        END AS risk_assessment
    FROM stage_funding_matrix
)
SELECT 
    stage,
    funding_tier,
    risk_assessment,
    companies,
    layoff_events,
    total_layoffs,
    avg_layoffs_per_event AS avg_event_severity
FROM risk_scoring
WHERE companies >= 2  -- Focus on patterns with multiple companies
ORDER BY stage, 
    CASE funding_tier
        WHEN 'High Funding (100M+)' THEN 1
        WHEN 'Moderate Funding (25M-100M)' THEN 2
        WHEN 'Low Funding (5M-25M)' THEN 3
        WHEN 'Minimal Funding (<5M)' THEN 4
        WHEN 'Unknown' THEN 5
    END;

-- 4d. Over-funding vs Under-funding Risk Indicators
-- Identifies potential over-investment patterns in layoff data
WITH funding_efficiency_analysis AS (
    SELECT 
        company,
        stage,
        funds_raised_millions,
        SUM(total_laid_off) AS total_layoffs_per_company,
        COUNT(*) AS layoff_events_per_company,
        -- Calculate layoff-to-funding ratio as risk indicator
        CASE 
            WHEN funds_raised_millions > 0 
            THEN ROUND(SUM(total_laid_off) / funds_raised_millions, 2)
            ELSE NULL
        END AS layoffs_per_million_funded
    FROM layoffs_staging2
    WHERE total_laid_off IS NOT NULL 
      AND funds_raised_millions IS NOT NULL
      AND funds_raised_millions > 0
    GROUP BY company, stage, funds_raised_millions
),
risk_indicators AS (
    SELECT 
        stage,
        COUNT(*) AS companies_analyzed,
        ROUND(AVG(funds_raised_millions), 0) AS avg_funding,
        ROUND(AVG(total_layoffs_per_company), 0) AS avg_layoffs_per_company,
        ROUND(AVG(layoffs_per_million_funded), 2) AS avg_layoffs_per_million_funded,
        MAX(total_layoffs_per_company) AS worst_company_layoffs,
        MAX(layoffs_per_million_funded) AS worst_efficiency_ratio
    FROM funding_efficiency_analysis
    GROUP BY stage
)
SELECT 
    stage,
    companies_analyzed,
    FORMAT(avg_funding, 0) AS avg_funding_millions,
    FORMAT(avg_layoffs_per_company, 0) AS avg_layoffs_per_company,
    avg_layoffs_per_million_funded AS layoffs_per_million_ratio,
    worst_company_layoffs,
    worst_efficiency_ratio,
    CASE
        WHEN avg_layoffs_per_million_funded >= 10 THEN 'High Funding Risk'
        WHEN avg_layoffs_per_million_funded >= 5 THEN 'Moderate Funding Risk'
        WHEN avg_layoffs_per_million_funded >= 1 THEN 'Low Funding Risk'
        ELSE 'Efficient Funding'
    END AS funding_efficiency_assessment
FROM risk_indicators
WHERE companies_analyzed >= 3  -- Focus on stages with meaningful sample size
ORDER BY avg_layoffs_per_million_funded DESC;
