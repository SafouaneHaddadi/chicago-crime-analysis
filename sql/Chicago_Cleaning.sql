

/* STEP 1 — DATA CLEANING
   ==============================================
   Three tables: Schools, Socioeconomic, Crimes
   ============================================ */

/* ----------------------------------------------------------------------------
   SCHOOL TABLE
   ---------------------------------------------------------------------------- */

-- Always keep raw data safe
SELECT * INTO SchoolStaging FROM ChicagoPublicSchools;

-- Quick look at what we have
SELECT * FROM SchoolStaging;

-- Rename columns (get rid of spaces)
EXEC sp_rename 'SchoolStaging.[School ID]', 'school_id', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Name of School]', 'school_name', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Elementary, Middle, or High School]', 'school_type', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Safety Score]', 'safety_score', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Family Involvement Score]', 'family_involvement_score', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Environment Score]', 'environment_score', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Instruction Score]', 'instruction_score', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Leaders Score]', 'leaders_score', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Teachers Score]', 'teachers_score', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Parent Engagement Score]', 'parent_engagement_score', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Parent Environment Score]', 'parent_environment_score', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Average Student Attendance]', 'avg_student_attendance', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Rate of Misconducts (per 100 students)]', 'misconduct_rate', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Graduation Rate %]', 'graduation_rate', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[College Enrollment Rate %]', 'college_enrollment_rate', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Community Area Number]', 'community_area', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Latitude]', 'latitude', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Longitude]', 'longitude', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Average Teacher Attendance]', 'avg_teacher_attendance', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Individualized Education Program Compliance Rate ]', 'iep_compliance_rate', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[ISAT Exceeding Math %]', 'isat_math_pct', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[ISAT Exceeding Reading % ]', 'isat_reading_pct', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Community Area Name]', 'community_name', 'COLUMN';
EXEC sp_rename 'SchoolStaging.[Police District]', 'police_district', 'COLUMN';

-- Drop columns we don't need. Keep only what matters for analysis
ALTER TABLE SchoolStaging DROP COLUMN
    [Street Address], [City], [State], [ZIP Code], [Phone Number], [Link],
    [Network Manager], [Collaborative Name], [Track Schedule],
    [Safety Icon], [Family Involvement Icon], [Environment Icon],
    [Instruction Icon], [Leaders Icon], [Teachers Icon],
    [Parent Engagement Icon], [Parent Environment Icon],
    [CPS Performance Policy Status], [CPS Performance Policy Level],
    [Adequate Yearly Progress Made?], [Healthy Schools Certified?],
    [Pk-2 Literacy %], [Pk-2 Math %],
    [Gr3-5 Grade Level Math %], [Gr3-5 Grade Level Read %],
    [Gr3-5 Keep Pace Read %], [Gr3-5 Keep Pace Math %],
    [Gr6-8 Grade Level Math %], [Gr6-8 Grade Level Read %],
    [Gr6-8 Keep Pace Math%], [Gr6-8 Keep Pace Read %],
    [Gr-8 Explore Math %], [Gr-8 Explore Read %],
    [ISAT Value Add Math], [ISAT Value Add Read],
    [ISAT Value Add Color Math], [ISAT Value Add Color Read],
    [Students Taking  Algebra %], [Students Passing  Algebra %],
    [9th Grade EXPLORE (2009)], [9th Grade EXPLORE (2010)],
    [10th Grade PLAN (2009)], [10th Grade PLAN (2010)],
    [Net Change EXPLORE and PLAN], [11th Grade Average ACT (2011)],
    [Net Change PLAN and ACT], [College Eligibility %],
    [College Enrollment (number of students)], [General Services Route],
    [Freshman on Track Rate %], [RCDTS Code],
    [X_COORDINATE], [Y_COORDINATE], [Location],
    [community_name],      -- we keep community_area for joins
    [police_district]; 


------------------------------------------

-- Check for missing values
SELECT 
    COUNT(*) as total_rows,
    SUM(CASE WHEN safety_score IS NULL THEN 1 ELSE 0 END) as missing_safety,
    SUM(CASE WHEN safety_score = '' THEN 1 ELSE 0 END) as blank_safety
FROM SchoolStaging;

SELECT * FROM SchoolStaging
SELECT school_name, school_type from SchoolStaging where family_involvement_score = 'NDA'

SELECT 
    COUNT(*) as total_rows,
    SUM(CASE WHEN safety_score IS NULL THEN 1 ELSE 0 END) as missing_safety,
    SUM(CASE WHEN family_involvement_score IS NULL THEN 1 ELSE 0 END) as missing_family
FROM SchoolStaging;

SELECT COUNT(*) as total_schools FROM SchoolStaging;

-- Check data types
EXEC sp_help 'SchoolStaging';

-- See what values we have
SELECT DISTINCT safety_score FROM SchoolStaging ORDER BY safety_score;
SELECT DISTINCT(instruction_score) FROM SchoolStaging
SELECT DISTINCT(leaders_score) FROM SchoolStaging

-- Write full school type (no abbreviations)
UPDATE SchoolStaging
SET school_type = CASE
    WHEN school_type = 'ES' THEN 'Elementary school'
    WHEN school_type = 'HS' THEN 'High school'
    WHEN school_type = 'MS' THEN 'Middle school'
    ELSE school_type 
END;

 -- Cleaning Score Columns (Safety Score, Instruction Score, etc.)

-- Looking at some score columns, we found our table has 'NDA' text values
SELECT 
    'family_involvement_score' as column_name,
    COUNT(*) as nda_count
FROM SchoolStaging WHERE family_involvement_score = 'NDA'

UNION ALL
SELECT 'leaders_score', COUNT(*) FROM SchoolStaging WHERE leaders_score = 'NDA'
UNION ALL
SELECT 'teachers_score', COUNT(*) FROM SchoolStaging WHERE teachers_score = 'NDA'
UNION ALL
SELECT 'parent_engagement_score', COUNT(*) FROM SchoolStaging WHERE parent_engagement_score = 'NDA'
UNION ALL
SELECT 'parent_environment_score', COUNT(*) FROM SchoolStaging WHERE parent_environment_score = 'NDA'
UNION ALL
SELECT 'graduation_rate', COUNT(*) FROM SchoolStaging WHERE graduation_rate = 'NDA'
UNION ALL
SELECT 'college_enrollment_rate', COUNT(*) FROM SchoolStaging WHERE college_enrollment_rate = 'NDA';

-- Check one column to understand the problem
SELECT TOP 10 
    school_name,
    family_involvement_score,
    SQL_VARIANT_PROPERTY(family_involvement_score, 'BaseType') as data_type
FROM SchoolStaging
WHERE family_involvement_score = 'NDA';
-- All columns with 'NDA' are nvarchar

-- Replace 'NDA' with NULL
UPDATE SchoolStaging SET family_involvement_score = NULL WHERE family_involvement_score = 'NDA';
UPDATE SchoolStaging SET leaders_score = NULL WHERE leaders_score = 'NDA';
UPDATE SchoolStaging SET teachers_score = NULL WHERE teachers_score = 'NDA';
UPDATE SchoolStaging SET parent_engagement_score = NULL WHERE parent_engagement_score = 'NDA';
UPDATE SchoolStaging SET parent_environment_score = NULL WHERE parent_environment_score = 'NDA';
UPDATE SchoolStaging SET graduation_rate = NULL WHERE graduation_rate = 'NDA';
UPDATE SchoolStaging SET college_enrollment_rate = NULL WHERE college_enrollment_rate = 'NDA';

-- Now we have proper NULLs, we can convert to the right data types
ALTER TABLE SchoolStaging ALTER COLUMN family_involvement_score FLOAT;
ALTER TABLE SchoolStaging ALTER COLUMN leaders_score FLOAT;
ALTER TABLE SchoolStaging ALTER COLUMN teachers_score FLOAT;
ALTER TABLE SchoolStaging ALTER COLUMN parent_engagement_score FLOAT;
ALTER TABLE SchoolStaging ALTER COLUMN parent_environment_score FLOAT;
ALTER TABLE SchoolStaging ALTER COLUMN graduation_rate FLOAT;
ALTER TABLE SchoolStaging ALTER COLUMN college_enrollment_rate FLOAT;

-- Verify
EXEC sp_help 'SchoolStaging';

-- Count NULLs per column 
-- Dynamic SQL to generate the query automatically
DECLARE @TableName NVARCHAR(128) = 'SchoolStaging'; 
DECLARE @SQL NVARCHAR(MAX) = '';

SELECT @SQL = @SQL + '
SELECT ''' + name + ''' AS ColumnName, COUNT(*) AS NullCount FROM ' + @TableName + ' WHERE [' + name + '] IS NULL UNION ALL'
FROM sys.columns
WHERE object_id = OBJECT_ID(@TableName);

SET @SQL = LEFT(@SQL, LEN(@SQL) - 10);
EXEC(@SQL);

-- Handle the ONE avg_student_attendance NULL
SELECT school_name, school_type FROM SchoolStaging WHERE avg_student_attendance IS NULL;

-- Only one school missing, we can fill with average
UPDATE SchoolStaging
SET avg_student_attendance = (SELECT AVG(avg_student_attendance) FROM SchoolStaging)
WHERE avg_student_attendance IS NULL;

-- For the rest, we leave as is

-- Check for duplicates using window functions
/* Reminder: what should be unique?
   - school_id (definitely unique)
   - school_name + community_area (same name in different areas?)
   - latitude + longitude (same building?)
*/

WITH duplicate_rows AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY school_id ORDER BY school_name) as rn_by_id,
        ROW_NUMBER() OVER (PARTITION BY school_name, community_area ORDER BY school_id) as rn_by_name,
        ROW_NUMBER() OVER (PARTITION BY latitude, longitude ORDER BY school_name) as rn_by_location
    FROM SchoolStaging
)
SELECT 
    school_id,
    school_name,
    school_type,
    community_area,
    latitude,
    longitude
FROM duplicate_rows
WHERE rn_by_id > 1 OR rn_by_name > 1 OR rn_by_location > 1
ORDER BY rn_by_id DESC, rn_by_name DESC, rn_by_location DESC;

-- The only 'duplicates' are schools sharing the same location
-- This is normal in Chicago, schools often share a campus

-- Fix that one weird decimal
UPDATE SchoolStaging 
SET avg_student_attendance = ROUND(avg_student_attendance, 1)
WHERE school_id = 610504;

---------------------------------------------------------------------------------------------------
/* ----------------------------------------------------------------------------
   SOCIOECONOMIC TABLE
   ---------------------------------------------------------------------------- */

SELECT * INTO SocioStaging FROM ChicagoSocioeconomic;

-- Rename columns (snake_case)
EXEC sp_rename 'SocioStaging.[Community Area Number]', 'community_area', 'COLUMN';
EXEC sp_rename 'SocioStaging.[COMMUNITY AREA NAME]', 'community_area_name', 'COLUMN';
EXEC sp_rename 'SocioStaging.[PERCENT OF HOUSING CROWDED]', 'pct_housing_crowded', 'COLUMN';
EXEC sp_rename 'SocioStaging.[PERCENT HOUSEHOLDS BELOW POVERTY]', 'pct_households_below_poverty', 'COLUMN';
EXEC sp_rename 'SocioStaging.[PERCENT AGED 16+ UNEMPLOYED]', 'pct_aged_16_plus_unemployed', 'COLUMN';
EXEC sp_rename 'SocioStaging.[PERCENT AGED 25+ WITHOUT HIGH SCHOOL DIPLOMA]', 'pct_aged_25_plus_without_hs_diploma', 'COLUMN';
EXEC sp_rename 'SocioStaging.[PERCENT AGED UNDER 18 OR OVER 64]', 'pct_aged_under18_over64', 'COLUMN';
EXEC sp_rename 'SocioStaging.[PER CAPITA INCOME ]', 'per_capita_income', 'COLUMN';
EXEC sp_rename 'SocioStaging.[HARDSHIP INDEX]', 'hardship_index', 'COLUMN';

-- Check data types
EXEC sp_help 'SocioStaging';

-- Check for duplicates. Each community should appear once.
SELECT 
    community_area_number,
    community_area_name,
    COUNT(*) as count
FROM SocioStaging
GROUP BY community_area_number, community_area_name
HAVING COUNT(*) > 1;

SELECT * FROM SocioStaging
-- Last row is a summary for the whole city
-- We only want community-level data, so delete it
DELETE FROM SocioStaging
WHERE community_area_number IS NULL AND community_area_name = 'CHICAGO';

-- Make sure no NULLs left
SELECT 
    COUNT(*) as total_rows,
    SUM(CASE WHEN community_area_number IS NULL THEN 1 ELSE 0 END) as null_area_number,
    SUM(CASE WHEN community_area_name IS NULL THEN 1 ELSE 0 END) as null_area_name,
    SUM(CASE WHEN pct_housing_crowded IS NULL THEN 1 ELSE 0 END) as null_housing,
    SUM(CASE WHEN pct_households_below_poverty IS NULL THEN 1 ELSE 0 END) as null_poverty,
    SUM(CASE WHEN pct_aged_16_plus_unemployed IS NULL THEN 1 ELSE 0 END) as null_unemployed,
    SUM(CASE WHEN pct_aged_25_plus_without_hs_diploma IS NULL THEN 1 ELSE 0 END) as null_no_hs,
    SUM(CASE WHEN pct_aged_under18_over64 IS NULL THEN 1 ELSE 0 END) as null_dependents,
    SUM(CASE WHEN per_capita_income IS NULL THEN 1 ELSE 0 END) as null_income,
    SUM(CASE WHEN hardship_index IS NULL THEN 1 ELSE 0 END) as null_hardship
FROM SocioStaging;

-- Check percentages are between 0 and 100
SELECT 'Housing Crowded' as metric,
       MIN(pct_housing_crowded) as min_val,
       MAX(pct_housing_crowded) as max_val,
       AVG(pct_housing_crowded) as avg_val
FROM SocioStaging WHERE pct_housing_crowded IS NOT NULL

UNION ALL
SELECT 'Below Poverty',
       MIN(pct_households_below_poverty),
       MAX(pct_households_below_poverty),
       AVG(pct_households_below_poverty)
FROM SocioStaging WHERE pct_households_below_poverty IS NOT NULL

UNION ALL
SELECT 'Unemployed',
       MIN(pct_aged_16_plus_unemployed),
       MAX(pct_aged_16_plus_unemployed),
       AVG(pct_aged_16_plus_unemployed)
FROM SocioStaging WHERE pct_aged_16_plus_unemployed IS NOT NULL;

-- Verify community areas match with Schools table
SELECT sc.community_area
FROM SocioStaging soc
LEFT JOIN SchoolStaging sc ON sc.community_area = soc.community_area
WHERE soc.community_area IS NULL

SELECT soc.community_area
FROM SocioStaging soc
LEFT JOIN SchoolStaging sc ON soc.community_area = sc.community_area
WHERE sc.community_area IS NULL AND soc.community_area IS NOT NULL
ORDER BY soc.community_area;

-------------------------------------------------------------------------------------------------
/* ----------------------------------------------------------------------------
   CRIME TABLE - the big one (2M+ rows)
   ---------------------------------------------------------------------------- */

/* Why CSV + BULK INSERT instead of Excel wizard?
   - Excel driver fails on large files (>1M rows): type mismatches, 0 rows imported
   - BULK INSERT is faster, more reliable, gives full control
*/

CREATE TABLE dbo.ChicagoCrimes (
    ID                  BIGINT          NOT NULL PRIMARY KEY,
    CaseNumber          VARCHAR(20)     NOT NULL,
    [Date]              DATETIME2(3)    NULL,
    Block               VARCHAR(50)     NULL,
    IUCR                VARCHAR(10)     NULL,
    PrimaryType         VARCHAR(50)     NULL,
    Description         VARCHAR(150)    NULL,
    LocationDescription VARCHAR(100)    NULL,
    Arrest              VARCHAR(10)     NULL,   
    Domestic            VARCHAR(10)     NULL,   
    Beat                VARCHAR(10)     NULL,
    District            VARCHAR(10)     NULL,
    Ward                SMALLINT        NULL,
    CommunityArea       SMALLINT        NULL,
    FBICode             VARCHAR(5)      NULL,
    XCoordinate         INT             NULL,
    YCoordinate         INT             NULL,
    Year                SMALLINT        NULL,
    UpdatedOn           DATETIME2(3)    NULL,
    Latitude            FLOAT           NULL,
    Longitude           FLOAT           NULL,
    Location            VARCHAR(100)    NULL
);

-- Bulk import (optimized for large CSV)
BULK INSERT dbo.ChicagoCrimes
FROM 'E:\ChicagoData\Crimes_-_2001_to_Present_20260222.csv' 
WITH (
    FORMAT              = 'CSV',
    FIRSTROW            = 2,                        
    FIELDTERMINATOR     = ',',                      
    ROWTERMINATOR       = '0x0a',                     
    TABLOCK,                                        
    CODEPAGE            = '65001',                 
    ERRORFILE           = 'E:\SQLData\Erreurs_Bulk_New.log',
    BATCHSIZE           = 100000                   
);

-- Quick verification
SELECT COUNT(*) AS TotalRows FROM dbo.ChicagoCrimes;  -- Should be ~2.5 million

SELECT TOP 20 * FROM dbo.ChicagoCrimes ORDER BY crime_date DESC;

---------------------------------

-- Let's start cleaning

-- Drop columns we don't need
ALTER TABLE ChicagoCrimes
DROP COLUMN 
    UpdatedOn,          
    XCoordinate, YCoordinate, Location,  -- redundant with lat/long
    Beat, District, Ward,                 -- too granular
    IUCR, FBICode, Block,                  -- internal codes
    Year;                                   -- we have date

-- Rename remaining columns to snake_case
EXEC sp_rename 'ChicagoCrimes.ID',                  'id',                  'COLUMN';
EXEC sp_rename 'ChicagoCrimes.CaseNumber',          'case_number',         'COLUMN';
EXEC sp_rename 'ChicagoCrimes.Date',                'date',                'COLUMN';
EXEC sp_rename 'ChicagoCrimes.PrimaryType',         'primary_type',        'COLUMN';
EXEC sp_rename 'ChicagoCrimes.Description',         'description',         'COLUMN';
EXEC sp_rename 'ChicagoCrimes.LocationDescription', 'location_description','COLUMN';
EXEC sp_rename 'ChicagoCrimes.Arrest',              'arrest',              'COLUMN';
EXEC sp_rename 'ChicagoCrimes.Domestic',            'domestic',            'COLUMN';
EXEC sp_rename 'ChicagoCrimes.CommunityArea',       'community_area',      'COLUMN';
EXEC sp_rename 'ChicagoCrimes.Date',                'crime_date',          'COLUMN';
EXEC sp_rename 'ChicagoCrimes.primary_type',        'crime_type',          'COLUMN';
EXEC sp_rename 'ChicagoCrimes.Latitude',            'latitude',            'COLUMN';
EXEC sp_rename 'ChicagoCrimes.Longitude',           'longitude',           'COLUMN';

-- Fix date format
ALTER TABLE ChicagoCrimes
ALTER COLUMN crime_date date NULL;

-- Check data types
EXEC sp_help 'ChicagoCrimes';

-- Count NULLs
SELECT 
    COUNT(*) AS Total,
    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS Null_id,
    SUM(CASE WHEN case_number IS NULL THEN 1 ELSE 0 END) AS Null_case_number,
    SUM(CASE WHEN crime_date IS NULL THEN 1 ELSE 0 END) AS Null_date,
    SUM(CASE WHEN crime_type IS NULL THEN 1 ELSE 0 END) AS Null_crime_type,
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) Null_description,
    SUM(CASE WHEN location_description IS NULL THEN 1 ELSE 0 END) Null_location_description,
    SUM(CASE WHEN arrest IS NULL THEN 1 ELSE 0 END) AS Null_arrest,
    SUM(CASE WHEN domestic IS NULL THEN 1 ELSE 0 END) AS Null_domestic,
    SUM(CASE WHEN community_area IS NULL THEN 1 ELSE 0 END) AS Null_community_area,
    SUM(CASE WHEN latitude IS NULL THEN 1 ELSE 0 END) AS Null_latitude,
    SUM(CASE WHEN longitude IS NULL THEN 1 ELSE 0 END) AS Null_longitude
FROM ChicagoCrimes;

/* Interesting finding: NULL location_description is mostly for DECEPTIVE PRACTICE
   Makes sense - fraud, online scams, phone calls don't have a physical location */
SELECT 
    crime_type,
    COUNT(*) AS nb,
    SUM(CASE WHEN location_description IS NULL THEN 1 ELSE 0 END) AS Null_location_desc,
    CAST(ROUND(100.0 * SUM(CASE WHEN location_description IS NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS DECIMAL(5,2)) AS pct_no_location
FROM ChicagoCrimes
GROUP BY crime_type
HAVING SUM(CASE WHEN location_description IS NULL THEN 1 ELSE 0 END) > 0
ORDER BY Null_location_desc DESC;

-- 6.94% is significant, so we create a category
UPDATE ChicagoCrimes
SET location_description = 'NO PHYSICAL LOCATION (ONLINE/PHONE)'
WHERE crime_type = 'DECEPTIVE PRACTICE' AND location_description IS NULL;
-- Why? Because these crimes happen virtually

-- For other crime types, NULL rates are below 0.2%, we leave them as NULL

SELECT TOP 10
    crime_type,
    COUNT(*) AS nb,
    SUM(CASE WHEN community_area IS NULL THEN 1 ELSE 0 END) AS Nulls,
    AVG(CASE WHEN community_area IS NULL THEN 1.0 ELSE 0 END) * 100 AS PercentNull
FROM ChicagoCrimes
GROUP BY crime_type
ORDER BY Nulls DESC;

/* For NULL community_area, we can use lat/long to find the neighborhood
   If we have coordinates, we can figure out which community it belongs to */

SELECT * FROM SocioStaging
SELECT * FROM SchoolStaging

SELECT TOP 20 community_area FROM ChicagoCrimes WHERE community_area IS NOT NULL

-- Exact matches?
SELECT TOP 70
    school.latitude as School_latitude,
    school.longitude as school_longitude,
    crime.latitude as crime_latitude,
    crime.longitude as crime_longitude,
    school.community_area as school_community,
    crime.community_area as crime_community
FROM SchoolStaging school
LEFT JOIN ChicagoCrimes crime ON school.latitude = crime.latitude AND school.longitude = crime.longitude
WHERE crime.community_area IS NULL 
    AND school.community_area IS NOT NULL 
    AND crime.latitude IS NOT NULL 
    AND crime.longitude IS NOT NULL
-- Nothing. Crimes don't happen at exact school coordinates

-- Try proximity instead
WITH ranked_distance AS (
    SELECT 
        c.id,
        c.latitude,
        c.longitude,
        s.community_area,
        ABS(c.latitude - s.latitude) + ABS(c.longitude - s.longitude) AS distance,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY ABS(c.latitude - s.latitude) + ABS(c.longitude - s.longitude)) AS rn
    FROM ChicagoCrimes c
    CROSS JOIN SchoolStaging s
    WHERE c.community_area IS NULL
        AND c.latitude IS NOT NULL
        AND c.longitude IS NOT NULL
        AND s.latitude IS NOT NULL
        AND s.longitude IS NOT NULL
),
distance_quality AS (
    SELECT 
        id,
        latitude,
        longitude,
        community_area AS proposed_community_area,
        distance,
        CASE
            WHEN distance < 0.01 THEN 'Very Close'
            WHEN distance < 0.05 THEN 'Close'
            WHEN distance < 0.1 THEN 'Nearby'
            WHEN distance < 0.5 THEN 'Could be right'
            ELSE 'Too far'
        END AS quality
    FROM ranked_distance
    WHERE rn = 1
)
SELECT * FROM distance_quality WHERE id = '11462723' 

/* Here we have 0.00766 - difference in coordinates between crime and school
   Let's convert to real distance:
   In Chicago, 1 degree latitude ≈ 69 miles
   In Chicago, 1 degree longitude ≈ 53 miles */
SELECT 
    0.00766002200000315 as coord_difference,
    0.00766002200000315 * 69 as miles_latitude, 
    0.00766002200000315 * 53 as miles_longitude, 
    (0.00766002200000315 * 69 + 0.00766002200000315 * 53) / 2 as approx_miles;
-- About 0.47 miles (half a mile) from the school. Good enough!

-- Update all crimes with closest school's community
WITH ranked_distance AS (
    SELECT
        c.id,
        c.latitude,
        c.longitude,
        s.community_area,
        ABS(c.latitude - s.latitude) + ABS(c.longitude - s.longitude) AS distance,
        ROW_NUMBER() OVER (PARTITION BY c.id ORDER BY ABS(c.latitude - s.latitude) + ABS(c.longitude - s.longitude)) AS rn
    FROM ChicagoCrimes c
    CROSS JOIN SchoolStaging s
    WHERE c.community_area IS NULL
        AND c.latitude IS NOT NULL
        AND c.longitude IS NOT NULL
        AND s.latitude IS NOT NULL
        AND s.longitude IS NOT NULL
),
closest_matches AS (
    SELECT id, community_area AS proposed_community_area, distance
    FROM ranked_distance
    WHERE rn = 1
)
UPDATE c
SET c.community_area = cm.proposed_community_area
FROM ChicagoCrimes c
INNER JOIN closest_matches cm ON c.id = cm.id
WHERE c.community_area IS NULL;

-- Still 2 crimes left with no coordinates - delete them
DELETE FROM ChicagoCrimes
WHERE community_area IS NULL AND latitude IS NULL AND longitude IS NULL;

SELECT COUNT(*) AS remaining FROM ChicagoCrimes WHERE community_area IS NULL AND latitude IS NULL AND longitude IS NULL;

-- Now populate NULL latitude/longitude using community area
SELECT TOP 50
    crime.community_area,
    crime.latitude,
    crime.longitude,
    school.community_area as school_area,
    school.latitude as school_latitude,
    school.longitude as school_longitude
FROM ChicagoCrimes crime
LEFT JOIN SchoolStaging school ON school.community_area = crime.community_area
WHERE crime.community_area IS NOT NULL
    AND crime.latitude IS NULL 
    AND crime.longitude IS NULL
    AND school.community_area = 25
-- One community, many schools. Let's use average to get a "middle" point

-- Step 1: Create temp table with average coordinates per community
SELECT 
    community_area,
    AVG(latitude) AS avg_latitude,
    AVG(longitude) AS avg_longitude,
    COUNT(*) as school_count
INTO #SchoolAvgLocation
FROM SchoolStaging
WHERE latitude IS NOT NULL AND longitude IS NOT NULL AND community_area IS NOT NULL
GROUP BY community_area;

-- Step 2: Update crimes with missing coordinates
UPDATE crime
SET 
    crime.latitude = avg.avg_latitude,
    crime.longitude = avg.avg_longitude
FROM ChicagoCrimes crime
INNER JOIN #SchoolAvgLocation avg ON crime.community_area = avg.community_area
WHERE crime.latitude IS NULL AND crime.longitude IS NULL;

DROP TABLE #SchoolAvgLocation;

SELECT COUNT(*) AS remain FROM ChicagoCrimes WHERE latitude IS NULL OR longitude IS NULL;

-- ----------------------------------------------------------------------------
-- Duplicate detection
-- ----------------------------------------------------------------------------
/* What makes a crime unique?
   - case_number should be unique
   - combination of date + location + type
*/

-- Check how many case_numbers appear multiple times
SELECT case_number, COUNT(*) as nb_times
FROM ChicagoCrimes
GROUP BY case_number
HAVING COUNT(*) > 1
ORDER BY nb_times DESC;

-- More specific with ROW_NUMBER
WITH ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY case_number ORDER BY crime_date DESC, id DESC) AS rn_case_only,
        ROW_NUMBER() OVER (PARTITION BY case_number, crime_date ORDER BY id DESC) AS rn_case_date
    FROM ChicagoCrimes
)
SELECT *
FROM ranked
WHERE rn_case_only > 1 OR rn_case_date > 1
ORDER BY case_number, crime_date DESC, rn_case_only, rn_case_date;

/* We found:
   - Partition by case_number only: 316 duplicates
   - Partition by case_number + date: 266 duplicates
   That means 50 rows have same case but different dates
*/

/* How to read results:
   rn_case_only > 1 and rn_case_date = 1 -> same case, different dates (probably real updates)
   rn_case_date > 1 -> same case, same date (real duplicates)
*/

-- Example: homicide case
SELECT * FROM ChicagoCrimes WHERE case_number = 'HZ216949'
-- 2016-04-07: initial report
-- 2016-04-09: update (autopsy, suspect)

-- Delete only true duplicates (same case, same date)
WITH to_delete AS (
    SELECT id,
        ROW_NUMBER() OVER (PARTITION BY case_number, crime_date ORDER BY id DESC) AS rn
    FROM ChicagoCrimes
)
DELETE FROM ChicagoCrimes
WHERE id IN (SELECT id FROM to_delete WHERE rn > 1);
-- This keeps different dates, different locations, different arrest status

-- ----------------------------------------------------------------------------
-- Clean location_description column
-- ----------------------------------------------------------------------------

-- First, see distribution
SELECT 
    DISTINCT(location_description),
    COUNT(*) as frequency,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(), 2) as percentage
FROM ChicagoCrimes
GROUP BY location_description
ORDER BY frequency DESC;

-- Trim spaces and uppercase
UPDATE ChicagoCrimes
SET location_description = TRIM(UPPER(location_description))
WHERE location_description IS NOT NULL;

-- Merge similar terms into one name 
UPDATE ChicagoCrimes
SET location_description = TRIM(UPPER(
    CASE
        WHEN location_description LIKE 'RESIDEN%' AND location_description NOT LIKE '%COLLEGE%' THEN 'RESIDENCE'
        WHEN location_description IN ('HOUSE') THEN 'HOUSE'
        WHEN location_description LIKE '%APART%%' THEN 'APARTMENT'
        WHEN location_description LIKE '%COLLEGE%' THEN 'COLLEGE / UNIVERSITY'
        WHEN location_description LIKE '%HOSPITAL%' OR location_description LIKE '%MEDICAL%' THEN 'MEDICAL - CARE FACILITY'
        WHEN location_description LIKE '%NURS%' THEN 'MEDICAL - NURSING HOME'
        WHEN location_description IN ('ALLEY', 'BOWLING ALLEY') THEN 'ALLEY'
        WHEN location_description IN ('MOVIE HOUSE / THEATER', 'MOVIE HOUSE/THEATER') THEN 'THEATER / CINEMA'
        WHEN location_description = 'WAREHOUSE' THEN 'WAREHOUSE'
        WHEN location_description IN ('PARKING LOT / GARAGE (NON RESIDENTIAL)', 'PARKING LOT/GARAGE(NON.RESID.)', 'PARKING LOT') THEN 'COMMERCIAL PARKING'
        WHEN location_description = 'GARAGE' THEN 'GARAGE'
        WHEN location_description = 'GARAGE/AUTO REPAIR' THEN 'AUTO REPAIR SHOP'
        WHEN location_description LIKE '%CHA PARKING%' THEN 'CHA PARKING'
        WHEN location_description IN ('CTA GARAGE / OTHER PROPERTY', 'CTA PARKING LOT / GARAGE / OTHER PROPERTY') THEN 'CTA PARKING'
        WHEN location_description = 'AIRPORT PARKING LOT' THEN 'AIRPORT PARKING'
        WHEN location_description LIKE '%GOVERNMENT%' OR location_description LIKE '%FEDERAL%' OR location_description LIKE '%FACILITY%' THEN 'GOVERNMENT FACILITY'
        WHEN location_description IN ('CHA APARTMENT', 'CHA ELEVATOR', 'CHA HALLWAY', 'CHA HALLWAY / STAIRWELL / ELEVATOR', 'CHA HALLWAY/STAIRWELL/ELEVATOR', 'CHA LOBBY', 'CHA STAIRWELL') THEN 'CHA - INDOOR'
        WHEN location_description IN ('CHA GROUNDS', 'CHA PLAY LOT') THEN 'CHA - OUTDOOR'
        WHEN location_description LIKE '%HOTEL%' THEN 'HOTEL'
        WHEN location_description LIKE '%PUBLIC%%' THEN 'PUBLIC SCHOOL'
        WHEN location_description LIKE '%PRIVATE%%' THEN 'PRIVATE SCHOOL'
        WHEN location_description = 'CEMETARY' THEN 'CEMETERY'
        WHEN location_description IN ('CTA "L" PLATFORM', 'CTA PLATFORM', 'CTA "L" TRAIN', 'CTA TRAIN', 'CTA STATION', 'CTA SUBWAY STATION', 'CTA TRACKS - RIGHT OF WAY') THEN 'CTA Rail (The "L")'
        WHEN location_description IN ('CTA BUS', 'CTA BUS STOP') THEN 'CTA Bus'
        WHEN location_description IN ('CTA GARAGE / OTHER PROPERTY', 'CTA PARKING LOT / GARAGE / OTHER PROPERTY', 'CTA PROPERTY') THEN 'CTA Property'
        WHEN location_description = 'COMMERCIAL / BUSINESS OFFICE' THEN 'COMMERCIAL - OFFICE'
        WHEN location_description IN ('GAS STATION', 'GAS STATION DRIVE/PROP.') THEN 'COMMERCIAL - GAS STATION'
        WHEN location_description IN ('CONVENIENCE STORE', 'SMALL RETAIL STORE', 'RETAIL STORE', 'PAWN SHOP') THEN 'COMMERCIAL - CONVENIENCE STORE'
        WHEN location_description = 'GROCERY FOOD STORE' THEN 'COMMERCIAL - GROCERY STORE'
        WHEN location_description IN ('TAVERN/LIQUOR STORE', 'LIQUOR STORE', 'TAVERN / LIQUOR STORE') THEN 'COMMERCIAL - LIQUOR STORE'
        WHEN location_description IN ('APPLIANCE STORE', 'DRUG STORE', 'CLEANING STORE', 'DEPARTMENT STORE') THEN 'COMMERCIAL - RETAIL (OTHER)'
        WHEN location_description = 'VEHICLE NON-COMMERCIAL' THEN 'VEHICLE - PERSONAL'
        WHEN location_description IN ('VEHICLE - COMMERCIAL', 'VEHICLE-COMMERCIAL') THEN 'VEHICLE - COMMERCIAL (GENERIC)'
        WHEN location_description = 'OTHER COMMERCIAL TRANSPORTATION' THEN 'COMMERCIAL - TAXI/RIDE SHARE'
        WHEN location_description IN ('VEHICLE - COMMERCIAL: ENTERTAINMENT / PARTY BUS', 'VEHICLE - COMMERCIAL: TROLLEY BUS', 'VEHICLE-COMMERCIAL - ENTERTAINMENT/PARTY BUS', 'VEHICLE-COMMERCIAL - TROLLEY BUS') THEN 'COMMERCIAL - ENTERTAINMENT VEHICLE'
        WHEN location_description LIKE '%SECURE AREA%' AND location_description NOT LIKE '%NON-SECURE AREA%' THEN 'AIRPORT - SECURE AREA'
        WHEN location_description LIKE '%NON-SECURE AREA%' THEN 'AIRPORT - PUBLIC AREA'
        WHEN location_description IN ('AIRPORT TRANSPORTATION SYSTEM (ATS)', 'AIRPORT VENDING ESTABLISHMENT') THEN 'AIRPORT - TRANSIT'
        ELSE location_description
    END
))
WHERE location_description IS NOT NULL;
GO

-- Group very rare locations (<100 occurrences)
WITH rare_locations AS (
    SELECT location_description
    FROM ChicagoCrimes
    GROUP BY location_description
    HAVING COUNT(*) < 100
)
UPDATE ChicagoCrimes
SET location_description = 'OTHER (RARE)'
WHERE location_description IN (SELECT location_description FROM rare_locations);

-- Merge all OTHER variations into one
UPDATE ChicagoCrimes
SET location_description = 'OTHER'
WHERE location_description IN ('OTHER', 'OTHER (SPECIFY)', 'OTHER (RARE)');

-- Merge duplicate categories
UPDATE ChicagoCrimes
SET location_description = 
    CASE
        WHEN location_description IN ('VACANT LOT / LAND', 'VACANT LOT/LAND') THEN 'VACANT LOT'
        WHEN location_description IN ('SPORTS ARENA/STADIUM', 'SPORTS ARENA / STADIUM') THEN 'SPORTS ARENA / STADIUM'
        WHEN location_description IN ('HIGHWAY / EXPRESSWAY', 'HIGHWAY/EXPRESSWAY') THEN 'HIGHWAY / EXPRESSWAY'
        WHEN location_description IN ('CHURCH / SYNAGOGUE / PLACE OF WORSHIP', 'CHURCH/SYNAGOGUE/PLACE OF WORSHIP') THEN 'CHURCH / SYNAGOGUE / PLACE OF WORSHIP'
        WHEN location_description IN ('LAKEFRONT / WATERFRONT / RIVERBANK', 'LAKEFRONT/WATERFRONT/RIVERBANK') THEN 'LAKEFRONT / WATERFRONT / RIVERBANK'
        WHEN location_description IN ('BOAT / WATERCRAFT', 'BOAT/WATERCRAFT') THEN 'BOAT / WATERCRAFT'
        WHEN location_description IN ('OTHER RAILROAD PROPERTY / TRAIN DEPOT', 'OTHER RAILROAD PROP / TRAIN DEPOT') THEN 'RAILROAD / TRAIN DEPOT'
        WHEN location_description IN ('FACTORY / MANUFACTURING BUILDING', 'FACTORY/MANUFACTURING BUILDING') THEN 'FACTORY / MANUFACTURING'
        WHEN location_description IN ('VEHICLE - OTHER RIDE SHARE SERVICE (LYFT, UBER, ETC.)', 'VEHICLE - OTHER RIDE SHARE SERVICE (E.G., UBER, LYFT)', 'VEHICLE - OTHER RIDE SERVICE') THEN 'VEHICLE - RIDE SHARE'
        ELSE location_description
    END;

-- Change NULL to 'UNKNOWN'
UPDATE ChicagoCrimes
SET location_description = 'UNKNOWN'
WHERE location_description IS NULL;

-- Fix a few duplicates in crime_type
UPDATE ChicagoCrimes
SET crime_type = CASE 
    WHEN crime_type IN ('CRIM SEXUAL ASSAULT', 'CRIMINAL SEXUAL ASSAULT') 
      THEN 'CRIMINAL SEXUAL ASSAULT'
    ELSE crime_type 
END

--------------------------------------------------------------------------------

-- Data cleaning is done. Final step: create views for analysis

CREATE OR ALTER VIEW vw_Schools_Clean AS
SELECT * FROM SchoolStaging;

CREATE OR ALTER VIEW vw_SocioEconomic_Clean AS
SELECT * FROM SocioStaging;

CREATE OR ALTER VIEW vw_Crimes_Clean AS
SELECT * FROM ChicagoCrimes;

/* Why views?
   - They don't duplicate data
   - Always show the latest cleaned version
   - We can share them without exposing raw tables
*/
SELECT TOP 20
	*
FROM vw_Crimes_Clean
