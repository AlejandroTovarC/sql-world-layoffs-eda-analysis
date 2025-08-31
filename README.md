# World Layoffs Strategic Intelligence Analysis

## Project Background

As a strategic consultant specializing in workforce risk assessment, this project analyzes 35 months of global layoff data (2020-2023) to provide comprehensive market intelligence for executive decision-making. The analysis transforms raw layoff events into actionable strategic guidance across temporal, industry, geographic, and investment dimensions.

In an era of unprecedented workforce volatility, organizations need data-driven intelligence to navigate market timing, industry selection, geographic expansion, and partnership decisions. This analysis provides executives with the strategic framework to optimize positioning during periods of economic uncertainty.

Insights and recommendations are provided on the following key strategic areas:

- **Market Recovery Timeline**: Seasonal patterns and crisis phase identification for strategic timing
- **Industry Resilience Rankings**: Sector risk assessment and workforce stability analysis
- **Geographic Risk Assessment**: Location intelligence for market entry and operational decisions
- **Company Stage Intelligence**: Investment risk patterns and funding efficiency analysis
- **Strategic Recommendations**: Executive action plan synthesizing cross-dimensional insights

The SQL scripts for comprehensive layoff intelligence analysis can be found in the `/scripts/` directory.

## Project Acknowledgment

This project was inspired by and builds upon the foundational work from [Alex The Analyst's](https://www.youtube.com/@AlexTheAnalyst) YouTube tutorial on [layoffs data analysis](https://www.youtube.com/watch?v=QYd-RtK58VQ). The initial exploratory data analysis and data cleaning procedures were adapted from their educational content. The strategic business framework, advanced analytical techniques, and comprehensive cross-dimensional analysis represent significant extensions and original contributions to transform the tutorial foundation into a complete strategic intelligence system.
## Data Structure & Initial Checks

The layoffs database consists of a single comprehensive table with 2,361 records after data cleaning, containing layoff events across 35 months of market activity. The cleaned dataset structure is as follows:

**layoffs_staging2 (Final Analysis Table):**

- **company**: Organization name (TEXT)
- **location**: City/region location (TEXT)
- **industry**: Business sector classification (TEXT)
- **total_laid_off**: Number of employees affected (INT)
- **percentage_laid_off**: Percentage of workforce reduced (TEXT)
- **date**: Event date (DATE - converted from TEXT)
- **stage**: Company maturity level (TEXT)
- **country**: Geographic location (TEXT)
- **funds_raised_millions**: Total funding raised (INT)


![Final Table](/images/table-structure.png)

The dataset spans from March 2020 to March 2023, covering the full economic cycle from pandemic onset through recovery phases. Data quality assessment revealed 100% completeness for core analytical fields after cleaning procedures removed duplicates and standardized formatting.

## Executive Summary

**Overview of Strategic Findings**

The analysis reveals distinct seasonal, industry, and geographic risk patterns that enable data-driven strategic positioning. January emerges as the highest-risk month for layoffs (92,000+ events), while Consumer and Technology sectors show the greatest workforce volatility. The United States dominates layoff activity with 260,000+ total impacts, though geographic diversification opportunities exist in stable markets. Post-IPO and Seed-stage companies demonstrate poor funding efficiency, with layoffs-per-million-funded ratios significantly exceeding later-stage companies. These patterns provide actionable intelligence for workforce planning, market entry timing, and investment risk assessment.

## Strategic Insights Deep Dive

**Market Recovery Timeline Intelligence:**

- **Seasonal Risk Patterns**: January shows 92,037 layoffs (highest monthly total), establishing clear budget cycle risk windows. November and December also present elevated risk periods, while mid-quarter months show more stability for strategic initiatives.
- **Crisis Phase Classification**: Market phases span from Crisis (100K+ monthly layoffs) through Recovery periods, with 35-month analysis revealing distinct volatility patterns that inform long-term planning cycles.
- **Strategic Timing Framework**: Three-month rolling averages smooth market volatility to reveal true directional trends, enabling executives to time major initiatives during stable periods rather than reactive phases.

**Industry Resilience Assessment:**

- **High-Risk Sectors**: Consumer (45,182 total layoffs) and Retail (43,613) industries show sustained workforce volatility across multiple years, indicating structural market challenges requiring enhanced risk management.
- **Duration Patterns**: Retail demonstrates the longest layoff activity period (22 months), while Sales sector shows briefer but intense impact windows (12 months), revealing different strategic approaches to workforce management.
- **Efficiency Indicators**: Industries with controlled average layoff sizes suggest more measured workforce adjustments versus panic-driven mass reductions, providing partnership and investment guidance.

**Geographic Risk Distribution:**

- **Market Concentration**: United States accounts for 260,000+ layoffs with persistent instability patterns, while international markets show varied risk profiles suitable for diversification strategies.
- **Activity Concentration Analysis**: High-activity markets demonstrate broad sector impact (10+ industries affected), while limited-activity markets suggest either stability or data coverage limitations requiring individual assessment.
- **Expansion Intelligence**: Geographic risk classification enables market entry prioritization, balancing growth opportunities against workforce stability requirements.

**Investment & Partnership Risk Patterns:**

- **Funding Efficiency Analysis**: Post-IPO companies show 57.35 layoffs per million funded (worst efficiency), while Series D-J companies demonstrate superior capital utilization with ratios under 1.0.
- **Stage Risk Assessment**: Seed-stage companies present 18.23 layoffs per million funded, indicating early-stage over-hiring patterns that create downstream workforce corrections.
- **Portfolio Optimization**: Company stage diversification across efficiency profiles reduces exposure to systematic over-investment patterns while maintaining growth potential.

## Strategic Recommendations

Based on comprehensive layoff intelligence analysis, leadership should consider implementing the following strategic initiatives:

- **Seasonal Risk Management**: Restructure major workforce expansion and strategic initiatives to avoid January-November-December budget cycle periods when layoff activity peaks. **Establish 3-month cash reserves during Q4 planning to accommodate Q1 volatility patterns.**
- **Industry Portfolio Diversification**: Limit exposure to Consumer and Technology sectors to no more than 25% of strategic partnerships or investment portfolios. **Target resilient sectors with controlled layoff patterns for stable growth opportunities.**
- **Geographic Expansion Strategy**: Balance US market exposure with international diversification across countries showing different risk profiles. **Establish operations in 3+ stable markets to reduce geographic concentration risk.**
- **Investment Due Diligence Enhancement**: Implement funding efficiency ratio analysis (layoffs-per-million-funded) as standard metric for partnership and investment decisions. **Prioritize Series D-F stage companies while exercising extreme caution with Post-IPO and Seed-stage organizations.**
- **Counter-Cyclical Talent Acquisition**: Schedule major hiring initiatives during lowest layoff activity months (June, July, August) to reduce talent competition and optimize recruitment costs. **Avoid hiring during high-layoff periods when market conditions create talent acquisition challenges.**

## Assumptions and Caveats

Throughout the analysis, several assumptions were made to manage data quality challenges:

- **Geographic Bias**: Dataset heavily weighted toward US companies (60%+ of records), potentially under-representing international layoff patterns. International risk assessments should be supplemented with regional data sources.
- **Industry Classification**: Some companies appear under generic categories ("Other", "Consumer") which may mask specific sub-sector patterns. Industry recommendations should be validated against detailed sector analysis where possible.
- **Funding Data Completeness**: Approximately 30% of records lack funding information, potentially skewing funding efficiency analysis toward well-documented companies. Private company funding patterns may be under-represented.
- **Temporal Boundaries**: Analysis period ends March 2023, limiting forward-looking predictive capability. Seasonal patterns assume historical trends will continue absent major economic disruption.
- **Layoff vs Business Health**: High layoff activity may indicate either business distress or aggressive growth corrections. Context-specific assessment required to distinguish between scenarios for strategic decision-making.

## Data Quality Assessment

Comprehensive data quality validation was performed across all analytical dimensions:

- **Validation Approach**: Multi-stage cleaning process addressing duplicates, standardization, data type conversion, and business rule validation
- **Overall Assessment**: Dataset achieved 100% completeness for core analytical fields after cleaning procedures, with minimal data quality issues affecting analysis conclusions
- **Identified Issues**: 1 duplicate record (0.04% of dataset) and trailing period formatting in country names - both resolved during cleaning process with no impact on strategic findings
- **Data Handling**: All quality issues documented and addressed during staging table development, ensuring analytical integrity throughout the strategic intelligence framework
