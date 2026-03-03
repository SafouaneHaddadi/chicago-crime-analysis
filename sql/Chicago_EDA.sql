
/*
	EXPLORATORY DATA ANALYSIS

	What we're trying to prove : Are crime rates driven by socioeconomic hardship and school performance ?

*/

---------------------------------------------------------------------------

-- QUERY 1: TREND ANALYSIS - Crime Patterns Over Time

/* Business Question:
   	 How have crime patterns evolved? Which crimes are increasing and need attention? 
*/
--------------------------------------------------------------------------------

-- Check what years we have in our crime data
SELECT 
    YEAR(crime_date) as year,
    COUNT(*) as total_crimes
FROM vw_Crimes_Clean
GROUP BY YEAR(crime_date)
ORDER BY year
-- since 2026 is not complete we're not going to show for our queries
-- instead, we're gonna focus on 2016-2025. This will captures a complete story of how crime evolved through a major societal shift (pre-pandemic, pandemic, post-pandemic)


CREATE OR ALTER VIEW vw_CrimeTrends AS
 -- Step 1: Count crimes per year and type
 WITH yearly_crimes AS (
 SELECT
	YEAR(crime_date) as crime_year,
	crime_type,
	COUNT(*) as crimes_count
 FROM vw_Crimes_Clean
 WHERE YEAR(crime_date) BETWEEN 2016 AND 2025
 GROUP BY crime_type, YEAR(crime_date)
 --ORDER BY crime_type,  YEAR(crime_date)
 ),
 yearly_with_previous AS(
-- Step 2: For each crime type, get current year and previous year
SELECT
	crime_year,
	crime_type, 
	crimes_count,
	LAG(crimes_count) OVER(PARTITION BY crime_type ORDER BY crime_year) as prev_year_count
FROM yearly_crimes
), 
yearly_changes AS(
-- Step 3: Calculate year-over-year changes
SELECT 
	crime_year,
	crime_type,
	crimes_count,
	prev_year_count,
	crimes_count - prev_year_count as absolute_change, -- did crimes go up or down?
	CASE
		WHEN prev_year_count > 0
		THEN CONCAT(ROUND(100.0 * (CAST(crimes_count AS FLOAT) - prev_year_count) / prev_year_count, 2), '%')
		ELSE NULL
	END as percent_change
FROM yearly_with_previous
WHERE prev_year_count IS NOT NULL  -- Exclude first year (no previous to compare)
), 
yearly_summary AS(
-- Step 4: Final output - show trends using pivot
SELECT
	crime_type,
	MAX(CASE WHEN crime_year = 2016 THEN crimes_count END) as crimes_2016,
    MAX(CASE WHEN crime_year = 2017 THEN crimes_count END) as crimes_2017,
    MAX(CASE WHEN crime_year = 2018 THEN crimes_count END) as crimes_2018,
    MAX(CASE WHEN crime_year = 2019 THEN crimes_count END) as crimes_2019,
    MAX(CASE WHEN crime_year = 2020 THEN crimes_count END) as crimes_2020,
    MAX(CASE WHEN crime_year = 2021 THEN crimes_count END) as crimes_2021,
    MAX(CASE WHEN crime_year = 2022 THEN crimes_count END) as crimes_2022,
    MAX(CASE WHEN crime_year = 2023 THEN crimes_count END) as crimes_2023,
    MAX(CASE WHEN crime_year = 2024 THEN crimes_count END) as crimes_2024,
    MAX(CASE WHEN crime_year = 2025 THEN crimes_count END) as crimes_2025,

	-- Total change over the 10-year period
	MAX(CASE WHEN crime_year = 2025 THEN crimes_count END)  -  
	MAX(CASE WHEN crime_year = 2016 THEN crimes_count END) as total_change_10yr, 

	-- Percentage change over 10 years
	ROUND(
	  100.0 * (
        MAX(CASE WHEN crime_year = 2025 THEN crimes_count END) - 
        MAX(CASE WHEN crime_year = 2016 THEN crimes_count END)
    ) / NULLIF(CAST(MAX(CASE WHEN crime_year = 2016 THEN crimes_count END) AS FLOAT), 0), 2) 
	as pct_change_10yr

FROM yearly_crimes
GROUP BY crime_type
HAVING MAX(CASE WHEN crime_year = 2016 THEN crimes_count END) IS NOT NULL
   AND MAX(CASE WHEN crime_year = 2025 THEN crimes_count END) IS NOT NULL
), 
categorized_trends AS (
-- We can also categorize our change percentage (optionnal)
    SELECT
        crime_type,
        crimes_2016,
        crimes_2017,
        crimes_2018,
        crimes_2019,
        crimes_2020,
        crimes_2021,
        crimes_2022,
        crimes_2023,
        crimes_2024,
        crimes_2025,
        total_change_10yr,
        pct_change_10yr,
        CASE
            WHEN pct_change_10yr > 50 THEN 'High Growth'
            WHEN pct_change_10yr > 0 THEN 'Moderate Growth'
            WHEN pct_change_10yr = 0 THEN 'Stable'
            ELSE 'Decline'
        END AS growth_category
    FROM yearly_summary
)
SELECT *
FROM categorized_trends
ORDER BY pct_change_10yr DESC, growth_category, crime_type

-- SELECT * FROM vw_CrimeTrends ORDER BY pct_change_10yr DESC

/* the pivot allows us to see the narrative arc of crime over 10 years
  without the pivot, this story is hidden in 300 rows of data. With the pivot, it's OBVIOUS 
 */

--------------------------------------------------------------------------
-- QUERY 2: CORRELATION - Socioeconomic Factors vs Crime

/* Business Question:
   	 What socioeconomic factors most strongly correlate with crime? Which neighborhoods need help? 
*/
--------------------------------------------------------------------------------

CREATE OR ALTER VIEW vw_Neighborhood_Crime_Socio_Rank AS
-- Step 1: let's get crime counts per community
WITH crime_by_community AS (
    SELECT 
        community_area,
        COUNT(*) as total_crimes
    FROM vw_Crimes_Clean
    WHERE community_area IS NOT NULL
    GROUP BY community_area
),
community_comparison AS (
-- Step 2: Now join with socioeconomic data
-- We want to see which communities are the worst. So we'll rank them
  SELECT 
        c.community_area,
        c.total_crimes,
        s.community_area_name,
        s.pct_households_below_poverty,
        s.pct_aged_16_plus_unemployed,
        s.per_capita_income,
        s.hardship_index,
		CASE
			WHEN s.hardship_index BETWEEN 1 AND 33 THEN 'Well-off'
			WHEN s.hardship_index BETWEEN 34 AND 66 THEN 'Middle-class'
			WHEN s.hardship_index BETWEEN 67 AND 100 THEN 'Struggling'
		END as score_breakdown,
		RANK() OVER (ORDER BY c.total_crimes DESC) as crime_rank,
		RANK() OVER (ORDER BY s.pct_households_below_poverty DESC) as poverty_rank,
		RANK() OVER (ORDER BY s.pct_aged_16_plus_unemployed DESC) as unemployment_rank,
		RANK() OVER (ORDER BY s.hardship_index DESC) as hardship_rank, -- reminder : the higher the number, the more the people are struggling
		RANK() OVER (ORDER BY s.per_capita_income) as income_rank
	FROM crime_by_community c
    JOIN vw_SocioEconomic_Clean s ON c.community_area = s.community_area
)
-- Step 3: Final output - show the comparison
SELECT 
	community_area,
    community_area_name,
    total_crimes,
	pct_households_below_poverty as poverty_rate,
	pct_aged_16_plus_unemployed as unemployment_rate,
	per_capita_income,
	hardship_index,
	crime_rank,
	poverty_rank,
	unemployment_rank,
	hardship_rank,
	income_rank,

	 -- If crime_rank and poverty_rank are close, they're related
    ABS(crime_rank - poverty_rank) as crime_poverty_gap,

	 CASE 
        WHEN crime_rank <= 10 AND poverty_rank <= 10 THEN 'CRITICAL - High Crime + High Poverty'
        WHEN crime_rank <= 10 AND hardship_rank <= 10 THEN 'CRITICAL - High Crime + High Hardship'
        WHEN crime_rank <= 20 AND poverty_rank <= 20 THEN 'HIGH PRIORITY'
        WHEN crime_rank <= 10 THEN 'High Crime Only'
        WHEN poverty_rank <= 10 THEN 'High Poverty Only'
        ELSE 'Moderate/Low'
    END as priority_level

FROM community_comparison
ORDER BY 
    CASE 
        WHEN crime_rank <= 10 AND poverty_rank <= 10 THEN 1
        WHEN crime_rank <= 10 AND hardship_rank <= 10 THEN 2
        WHEN crime_rank <= 20 AND poverty_rank <= 20 THEN 3
        WHEN crime_rank <= 10 THEN 4
        WHEN poverty_rank <= 10 THEN 5
        ELSE 6
    END,
    crime_rank

--------------------------------------------------------------------------------
-- QUERY 3: SEGMENTATION - Community Risk Categories

/* Business Question:
   	 Can we categorize communities by risk profile to target different interventions ? 
*/
--------------------------------------------------------------------------------

CREATE OR ALTER VIEW vw_CommunityRisk AS
-- Step 1: First, let's get all our data in one place
 WITH community_data AS (
 SELECT 
        c.community_area,
        s.community_area_name,
        COUNT(c.id) as total_crimes,
        s.pct_households_below_poverty,
        s.pct_aged_16_plus_unemployed,
        s.pct_aged_25_plus_without_hs_diploma,
        s.per_capita_income,
        s.hardship_index
  
    FROM vw_Crimes_Clean c
    JOIN vw_SocioEconomic_Clean s ON c.community_area = s.community_area
    GROUP BY 
        c.community_area,
        s.community_area_name,
        s.pct_households_below_poverty,
        s.pct_aged_16_plus_unemployed,
        s.pct_aged_25_plus_without_hs_diploma,
        s.per_capita_income,
        s.hardship_index
), 
averages AS( 
-- Step 2: Calculate averages for each factor
SELECT
        ROUND(AVG(total_crimes),2) as avg_crimes,
        ROUND(AVG(pct_households_below_poverty),2) as avg_poverty,
        ROUND(AVG(pct_aged_16_plus_unemployed),2) as avg_unemployment,
        ROUND(AVG(pct_aged_25_plus_without_hs_diploma),2) as avg_no_hs,
        ROUND(AVG(per_capita_income),2) as avg_income,
        ROUND(AVG(hardship_index),2) as avg_hardship,

		 -- Standard deviations (how much things vary)
		STDEV(total_crimes) as stdev_crimes,
        STDEV(pct_households_below_poverty) as stdev_poverty,
        STDEV(pct_aged_16_plus_unemployed) as stdev_unemployment,
        STDEV(pct_aged_25_plus_without_hs_diploma) as stdev_no_hs,
        STDEV(per_capita_income) as stdev_income,
        STDEV(hardship_index) as stdev_hardship

	FROM community_data
),
z_scores AS(
-- Step 3: Calculate z-scores for each community
-- A z-score shows how unusual a neighborhood is compared to others
    SELECT
        cd.community_area,
        cd.community_area_name,
        cd.total_crimes,
        cd.pct_households_below_poverty,
        cd.pct_aged_16_plus_unemployed,
        cd.pct_aged_25_plus_without_hs_diploma,
        cd.per_capita_income,
        cd.hardship_index,
        
        (cd.total_crimes - a.avg_crimes) / a.stdev_crimes as crime_z,
        (cd.pct_households_below_poverty - a.avg_poverty) / a.stdev_poverty as poverty_z,
        (cd.pct_aged_16_plus_unemployed - a.avg_unemployment) / a.stdev_unemployment as unemployment_z,
        (cd.pct_aged_25_plus_without_hs_diploma - a.avg_no_hs) / a.stdev_no_hs as no_hs_z,
        -1 * (cd.per_capita_income - a.avg_income) / a.stdev_income as income_z, -- for income, higher is better, so we multiply by -1 to flip it
        (cd.hardship_index - a.avg_hardship) / a.stdev_hardship as hardship_z
        
    FROM community_data cd
    CROSS JOIN averages a -- to make the avg values available for every neighborhood row
),
-- Step 4: Create a composite risk score to rank neighborhoods by overall risk
risk_score AS (
    SELECT
        *,
        (crime_z + poverty_z + unemployment_z + no_hs_z + income_z + hardship_z) / 6.0 as composite_risk
    FROM z_scores
),
-- Step 5: Categorize based on composite risk
categories AS (
    SELECT
        community_area,
        community_area_name,
        total_crimes,
        ROUND(pct_households_below_poverty, 1) as poverty_rate,
        ROUND(pct_aged_16_plus_unemployed, 1) as unemployment_rate,
        per_capita_income,
        hardship_index,
        
        ROUND(crime_z, 2) as crime_z_score,
        ROUND(poverty_z, 2) as poverty_z_score,
		ROUND(unemployment_z, 2) as unemployment_z_score,
        ROUND(composite_risk, 2) as risk_score,
        
        CASE
            WHEN composite_risk > 1.5 THEN 'CRITICAL RISK'
            WHEN composite_risk > 0.8 THEN 'HIGH RISK'
            WHEN composite_risk > 0.3 THEN 'MODERATE RISK'
            WHEN composite_risk > -0.3 THEN 'AVERAGE RISK'
            WHEN composite_risk > -0.8 THEN 'LOW RISK'
            ELSE 'VERY LOW RISK'
        END as risk_category,
        
		-- if we only show the composite score, decision-makers see two neighborhoods with the same risk score but miss which community needs what (police help ? economic help ?)
        CASE
        WHEN crime_z > 1 AND poverty_z > 1 AND unemployment_z > 1 
            THEN 'Triple threat : Crime + Poverty + Unemployment'
        
        WHEN crime_z > 1 AND poverty_z > 1 
            THEN 'Crime + Poverty hotspot'
        WHEN crime_z > 1 AND unemployment_z > 1 
            THEN 'Crime + Unemployment hotspot'
        WHEN poverty_z > 1 AND unemployment_z > 1 
            THEN 'Poverty + Unemployment hotspot'
        
        WHEN crime_z > 1 THEN 'Crime Hotspot Only'
        WHEN poverty_z > 1 THEN 'High Poverty Only'
        WHEN unemployment_z > 1 THEN 'High Unemployment Only'
        
        ELSE 'Mixed'
    END as community_profile
        
    FROM risk_score
)

/* Risk Category: How bad is it overall?
Community Profile: Which specific problems are causing the high score? */

-- Step 6: Final output 
SELECT 
    community_area,
    community_area_name,
    total_crimes,
    poverty_rate,
    unemployment_rate,
    per_capita_income,
    hardship_index,
    crime_z_score,
    poverty_z_score,
	unemployment_z_score
    risk_score,
    risk_category,
    community_profile
FROM categories
ORDER BY risk_score DESC;

-- SELECT * FROM vw_CommunityRisk WHERE risk_category = 'HIGH RISK';

-------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--    QUERY 4: PERFORMANCE - School Safety in High-Crime Areas

/* Business Question:
   	 How do schools perform in high-crime vs low-crime areas ? Are kids learning in safe environments ?
    
    This is important because if kids are trying to learn in dangerous neighborhoods, it might affect their education
*/
--------------------------------------------------------------------------------

CREATE OR ALTER VIEW vw_School_Safety_Comparison AS
-- STEP 1: Count crimes per community and rank them
WITH crime_ranks AS (
    SELECT 
        community_area,
        COUNT(*) AS total_crimes,
        RANK() OVER (ORDER BY COUNT(*) DESC) AS crime_rank
    FROM vw_Crimes_Clean
    WHERE community_area IS NOT NULL
    GROUP BY community_area
),
-- STEP 2: Get the 15 communities with the MOST crime
high_crime AS (
    SELECT community_area 
    FROM crime_ranks 
    WHERE crime_rank <= 15
),
-- STEP 3: Get the 15 communities with the LEAST crime 
low_crime AS (
    SELECT community_area 
    FROM crime_ranks 
    WHERE crime_rank >= (SELECT MAX(crime_rank) - 14 FROM crime_ranks) -- top 15 lowest crime
)
-- STEP 4: Combine high and low into two groups and calculate averages
SELECT 
    area_type,
    COUNT(DISTINCT s.school_id) AS number_of_schools,
    ROUND(AVG(s.safety_score), 1) AS avg_safety_score,
    ROUND(AVG(s.isat_math_pct), 1) AS avg_math_pct,
    ROUND(AVG(s.isat_reading_pct), 1) AS avg_reading_pct,
    ROUND(AVG(s.avg_student_attendance), 1) AS avg_attendance,
    ROUND(AVG(s.misconduct_rate), 1) AS avg_misconduct_rate, 
    ROUND(AVG(e.pct_households_below_poverty), 1) AS avg_poverty_pct -- adding the avg_poverty helps avoid the trap of saying 'crime causes bad schools' without considering the poverty and economic environment

FROM (
	 -- Stack the two groups together
    SELECT 'High Crime Areas (Top 15)' AS area_type, community_area FROM high_crime
    UNION ALL
    SELECT 'Low Crime Areas (Bottom 15)', community_area FROM low_crime
) areas
JOIN vw_Schools_Clean s ON areas.community_area = s.community_area
JOIN vw_SocioEconomic_Clean e ON areas.community_area = e.community_area
GROUP BY area_type
ORDER BY area_type DESC;  

-- SELECT * FROM vw_School_Safety_Comparison ORDER BY area_type DESC; 

--------------------------------------------------------------------------------
--    QUERY 5: PART-TO-WHOLE - Crime Composition in Vulnerable Areas

/* Business Question:
   	 Which crimes disproportionately affect poor neighborhoods? Is crime evenly distributed or concentrated ?
    
    We want to know : Do poor neighborhoods suffer from the same types of crime as rich ones, or do they face a different mix ?
*/
--------------------------------------------------------------------------------


CREATE OR ALTER VIEW vw_CrimeConcentration AS
-- STEP 1: Mark each community as 'Poor' or 'Non-Poor'
WITH community_poverty AS(
SELECT
	community_area,
	community_area_name,
	pct_households_below_poverty,
	CASE 
	WHEN NTILE(4) OVER(ORDER BY pct_households_below_poverty DESC) = 1 THEN 'Poor'
	ELSE 'Non-Poor'
	END as poverty_status
FROM vw_SocioEconomic_Clean
),
crimes_with_status AS(
-- STEP 2: Attach poverty status to every crime
SELECT
	crime_type,
	poverty_status
FROM vw_Crimes_Clean c
JOIN community_poverty p ON c.community_area = p.community_area
),
-- STEP 3: Calculate all counts using window functions
crime_analysis AS (
SELECT
	DISTINCT
	crime_type,
	COUNT(CASE WHEN poverty_status = 'Poor' THEN 1 END) OVER(PARTITION BY crime_type) as poor_count,
	COUNT(CASE WHEN poverty_status = 'Non-Poor' THEN 1 END) OVER(PARTITION BY crime_type) as non_poor_count,
	COUNT(*) OVER(PARTITION BY crime_type) as total_count,
	SUM(CASE WHEN poverty_status = 'Poor' THEN 1 ELSE 0 END) OVER() as total_poor_crimes, --  Total crimes in ALL poor areas
	COUNT(*) OVER() as total_crimes_all

FROM crimes_with_status
),
-- STEP 4: Final calculations (percentages + concentration ratio)
final_metrics AS(
SELECT DISTINCT	
	crime_type,
	poor_count,
	non_poor_count,
	total_count,
	-- % of this crime in poor areas
	CONCAT(ROUND(100.0 * CAST(poor_count AS FLOAT) / CAST(total_count AS FLOAT), 1), '%') as pct_in_poor_areas,
	 -- % of ALL crimes in poor areas
	CONCAT(ROUND(100.0 * CAST(total_poor_crimes AS FLOAT) / CAST(total_crimes_all AS FLOAT), 1), '%') as pct_all_crimes_in_poor,

	-- This ratio is the key number that answers which crimes disproportionately affect poor neighborhoods
	ROUND((100.0 * CAST(poor_count AS FLOAT) / CAST(total_count AS FLOAT)) / 
	(100.0 * CAST(total_poor_crimes AS FLOAT) / CAST(total_crimes_all AS FLOAT)), 2) as concentration_ratio

FROM crime_analysis
WHERE total_count > 100  -- Only look at crimes with enough data
)

-- Final output with CASE based on concentration_ratio
SELECT
    crime_type,
    poor_count,
    non_poor_count,
    total_count,
    pct_in_poor_areas,
    pct_all_crimes_in_poor,
    concentration_ratio,
        CASE
        WHEN concentration_ratio > 1.5 THEN 'Highly Concentrated in Poor Areas'
        WHEN concentration_ratio > 1.2 THEN 'Moderately Concentrated'
        WHEN concentration_ratio > 0.8 THEN 'Evenly Distributed'
		ELSE 'More Common in Non-Poor Areas'
    END AS distribution_pattern
    
FROM final_metrics
WHERE total_count > 100  -- Ignore rare crime 
ORDER BY concentration_ratio DESC;

/*
--> This query looks at what kinds of crimes happen in poor vs non-poor neighborhoods. 
	We want to see if some crimes (like homicide) affect poor areas much more than others  */


--------------------------------------------------------------------------------
--      QUERY 6: REPORTING - Executive Dashboard View

/* Business Question:
   	What's the one-page summary for decision-makers? What are the key metrics they need to know ?
*/
--------------------------------------------------------------------------------

/* Since query 6 needs to reuse the final results from our previous queries, we have to create VIEWS, bc our current CTEs only exist while the query runs
 Once these views are created, Query 6 becomes much simpler because we can just SELECT from these views  */

CREATE OR ALTER VIEW vw_ExecutiveDashboard AS
WITH overall_stats AS (
    -- 1. Overall city stats 
    SELECT
        COUNT(CASE WHEN YEAR(crime_date) BETWEEN 2016 AND 2025 THEN 1 END) as total_crimes_10yr,
		COUNT(CASE WHEN YEAR(crime_date) = 2025 THEN 1 END) AS crimes_in_2025,
		-- 5-year trend: compare 2016-2020 vs 2021-2025
		CAST(
		ROUND(
			100.0 * (
				(SELECT COUNT(*) FROM vw_Crimes_Clean WHERE YEAR(crime_date) BETWEEN 2021 AND 2025) -
				(SELECT COUNT(*) FROM vw_Crimes_Clean WHERE YEAR(crime_date) BETWEEN 2016 AND 2020)
			) / NULLIF((SELECT COUNT(*) FROM vw_Crimes_Clean WHERE YEAR(crime_date) BETWEEN 2016 AND 2020), 0),
			1
			) AS DECIMAL(10,1)
		) AS crime_change_5yr,
        COUNT(DISTINCT CASE WHEN YEAR(crime_date) BETWEEN 2021 AND 2025 THEN community_area END) as communities_affected,
        (SELECT COUNT(*) FROM vw_Schools_Clean) as total_schools,
        (SELECT ROUND(AVG(safety_score), 1) FROM vw_Schools_Clean) AS city_avg_safety,
        (SELECT ROUND(AVG(isat_math_pct), 1) FROM vw_Schools_Clean) AS city_avg_math,
        (SELECT ROUND(AVG(pct_households_below_poverty), 1) FROM vw_SocioEconomic_Clean) AS city_avg_poverty
    FROM vw_Crimes_Clean
),

risk_summary AS (
    -- 2. Risk summary
    SELECT 
        COUNT(CASE WHEN risk_category = 'CRITICAL RISK' THEN 1 END) AS critical_communities,
        COUNT(CASE WHEN risk_category = 'HIGH RISK' THEN 1 END) AS high_risk_communities,
        COUNT(*) AS total_communities
    FROM vw_CommunityRisk
),

top_critical AS (
    -- 3. Top 5 critical/vulnerable communities
    SELECT TOP 5
        community_area_name,
        risk_category,
        poverty_rate,
        total_crimes,
        risk_score
    FROM vw_CommunityRisk
    WHERE risk_category IN ('CRITICAL RISK', 'HIGH RISK')
),

crime_trends AS (
    -- 4. Crime trends summary 
	SELECT 
		(SELECT STRING_AGG(crime_type + ' (+' + CAST(pct_change_10yr AS VARCHAR(10)) + '%)', ', ') 
		FROM ( 
			SELECT TOP 3 crime_type, pct_change_10yr
			FROM vw_CrimeTrends 
			WHERE pct_change_10yr > 0 
			ORDER BY pct_change_10yr DESC
			) as inc
		) as top_increasing,
		
		(SELECT STRING_AGG(crime_type + ' (' + CAST(pct_change_10yr AS VARCHAR(10)) + '%)', ', ') 
		FROM ( 
			SELECT TOP 3 crime_type, pct_change_10yr
			FROM vw_CrimeTrends 
			WHERE pct_change_10yr < 0 
			ORDER BY pct_change_10yr
			) as dec
		) as top_decreasing
),

crime_concentration AS (
    SELECT
        (SELECT STRING_AGG(crime_type + ' (' + CAST(concentration_ratio AS VARCHAR(10)) + 'x)', ', ')
         FROM (
             SELECT TOP 3 crime_type, concentration_ratio
             FROM vw_CrimeConcentration
             WHERE concentration_ratio > 1
             ORDER BY concentration_ratio DESC
         ) AS conc
        ) AS most_concentrated,
        
        (SELECT STRING_AGG(crime_type + ' (' + CAST(concentration_ratio AS VARCHAR(10)) + 'x)', ', ')
         FROM (
             SELECT TOP 3 crime_type, concentration_ratio
             FROM vw_CrimeConcentration
             WHERE concentration_ratio < 1
             ORDER BY concentration_ratio ASC
         ) AS least
        ) AS least_concentrated
),

school_gap AS (
    SELECT
        MAX(CASE WHEN area_type LIKE 'High%' THEN avg_safety_score END) AS safety_high,
        MAX(CASE WHEN area_type LIKE 'Low%' THEN avg_safety_score END) AS safety_low,
        MAX(CASE WHEN area_type LIKE 'High%' THEN avg_math_pct END) AS math_high,
        MAX(CASE WHEN area_type LIKE 'Low%' THEN avg_math_pct END) AS math_low,
        MAX(CASE WHEN area_type LIKE 'High%' THEN avg_attendance END) AS attendance_high,
        MAX(CASE WHEN area_type LIKE 'Low%' THEN avg_attendance END) AS attendance_low
    FROM vw_School_Safety_Comparison
)

-- Final single-row dashboard output
/* This is a one-page dashboard for a decision-maker. They don't have time to read 50 pages. They need ONE ROW that tells them everything. */

SELECT 
	'CHICAGO CRIME & SCHOOLS DASHBOARD' as Report_title,
	FORMAT(GETDATE(), 'MMMM d, yyyy' ) as Report_date,

	-- Section 1: City Overview
	os.total_crimes_10yr AS Total_Crimes_2016_2025,
	os.crimes_in_2025 AS Crimes_In_2025,
    CONCAT(os.crime_change_5yr, '%') AS Crime_Change_5yr,
    os.communities_affected AS Communities_Affected_Recent,
	os.total_schools AS Total_Schools,
	os.city_avg_safety AS City_Avg_Safety_Score,
	os.city_avg_math AS City_Avg_Math_Score,
	os.city_avg_poverty AS City_Avg_Poverty_Rate,

	-- Section 2: Risk Overview
	rs.critical_communities AS Critical_Risk_Communities,
	rs.high_risk_communities AS High_Risk_Communities,

	-- Section 3: Top Vulnerable Areas
	(SELECT STRING_AGG(community_area_name, ', ') FROM top_critical) as Top_5_Vulnerable_Areas,

	-- Section 4: Crime Trends
	ct.top_increasing AS Fastest_Increasing_Crimes,
	ct.top_decreasing AS Biggest_Decreasing_Crimes,

	-- Section 5: Crime Concentration
	cc.most_concentrated AS Crimes_Most_Concentrated_in_Poor_Areas,
	cc.least_concentrated AS Crimes_More_Common_in_Non_Poor_Areas,

	-- Section 6: School Safety Gaps (shows the inequality)
    sg.safety_high AS Safety_High_Crime_Areas,
    sg.safety_low AS Safety_Low_Crime_Areas,
    sg.safety_low - sg.safety_high AS Safety_Gap,
    sg.math_high AS Math_High_Crime_Areas,
    sg.math_low AS Math_Low_Crime_Areas,
    sg.math_low - sg.math_high AS Math_Gap

	-- Key Recommendations (dynamic text for fun)
    /* CONCAT(
        '1. Prioritize the ', rs.critical_communities, ' critical communities, including: ',
        (SELECT STRING_AGG(community_area_name, ', ') FROM top_critical), '.', CHAR(10),
        '2. Focus on rising crimes: ', ct.top_increasing, '.', CHAR(10),
        '3. Target ', 
        (SELECT TOP 1 crime_type FROM vw_CrimeConcentration ORDER BY concentration_ratio DESC),
        ' prevention in poor neighborhoods (',
        (SELECT TOP 1 CAST(concentration_ratio AS VARCHAR(10)) FROM vw_CrimeConcentration ORDER BY concentration_ratio DESC),
        'x more concentrated).', CHAR(10),
        '4. Close school safety gap: ', 
        ROUND(sg.safety_low - sg.safety_high, 1), ' point difference between high- and low-crime areas.'
    ) AS Key_Recommendations */

FROM overall_stats os
-- CROSS JOIN to combine our CTEs into one final row
CROSS JOIN risk_summary rs
CROSS JOIN crime_trends ct
CROSS JOIN crime_concentration cc
CROSS JOIN school_gap sg
