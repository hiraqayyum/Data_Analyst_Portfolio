-- HEALTHCARE DIAGNOSIS
-- DIAGNOSIS BY GENDER

SELECT patient_sex, 
       COUNT(*)
FROM patient_visits_analysis
GROUP BY patient_sex;

SELECT patient_sex,
       COUNT(*) AS TotalVisits,
       CONCAT(
       COUNT(*) * 100/SUM(COUNT(*)) OVER()
       , '%') AS VisitPercent
FROM patient_visits_analysis
GROUP BY patient_sex;

-- RESULT: FEMALE PATIENTS HAVE A MODERATELY DOMINANT PATIENT BASE INCLUDING 58% VISITS
--         WHILE THE MALE PATIENTS CONSTITUTE 41% VISITS.





-- MOST FREQUENT CPT-CODES
SELECT cpt_code, 
       COUNT(*) AS FREQUENCY
FROM patient_visits_analysis
GROUP BY cpt_code
ORDER BY FREQUENCY DESC;

-- RESULT: 99213 AND 99214 ARE THE MOST FREQUENT CPT_CODE HAVING AN OCCURENCE OF 7 & 6 RESPECTIVELY.





SELECT *
FROM patient_visits_analysis;
ALTER TABLE patient_visits_analysis
ALTER COLUMN date_of_birth DATE;
ALTER TABLE patient_visits_analysis
ALTER COLUMN visit_date DATE;






-- CALCULATING PATIENT AGE BY DATE OF BIRTH

ALTER FUNCTION CALCULATE_AGE(@DOB DATE, @VISITDATE DATE)
RETURNS VARCHAR(50)
AS
BEGIN
    DECLARE @YEARS INT;
    DECLARE @MONTHS INT;
    DECLARE @DAYS INT;
    DECLARE @TEMPDATE DATE;

    SET @YEARS= DATEDIFF(YEAR, @DOB, @VISITDATE)
    IF (DATEADD(YEAR, @YEARS, @DOB) > @VISITDATE)
    SET @YEARS= @YEARS-1

    SET @TEMPDATE= DATEADD(YEAR, @YEARS, @DOB)

--    SET @MONTHS= DATEDIFF(MONTH, @TEMPDATE, @VISITDATE)
--    IF (DATEADD(MONTH, @MONTHS, @TEMPDATE)> @VISITDATE)
--    SET @MONTHS= @MONTHS-1

--    SET @TEMPDATE= DATEADD(MONTH, @MONTHS, @TEMPDATE)

--    SET @DAYS= DATEDIFF(DAY,@TEMPDATE, @VISITDATE)

    RETURN 
    CAST(@YEARS AS VARCHAR)

END
  
SELECT dbo.CALCULATE_AGE('2001-02-14', '2025-04-12') as Age;

ALTER TABLE patient_visits_analysis
ADD CalculatedAge AS dbo.CALCULATE_AGE(date_of_birth, visit_date);

SELECT * 
FROM patient_visits_analysis;

ALTER TABLE patient_visits_analysis
DROP COLUMN CalculatedAge;






-- GROUPING PATIENTS INTO SIMPLE AGE BANDS

CREATE FUNCTION AGE_BAND(@DOB DATE, @VISITDATE DATE)
RETURNS VARCHAR(50)
AS
BEGIN
     DECLARE @AGE INT;
     DECLARE @AGE_GROUP VARCHAR(50);

     SET @AGE= DATEDIFF(YEAR, @DOB, @VISITDATE)

     IF (DATEADD(YEAR, @AGE, @DOB) > @VISITDATE)
        SET @AGE= @AGE-1;

     SET @AGE_GROUP=
         CASE
         WHEN @AGE>0 AND @AGE<18 THEN '1-18'
         WHEN @AGE>=18 AND @AGE<40 THEN '18-39'
         WHEN @AGE>=40 AND @AGE<65 THEN '40-64'
         WHEN @AGE>=65 THEN '65+'
         ELSE 'Invalid input'
         END;

     RETURN @AGE_GROUP;
END;

SELECT dbo.AGE_BAND('2001-12-14', '2025-04-12');

SELECT * 
FROM patient_visits_analysis;

ALTER TABLE patient_visits_analysis
ADD age_group AS dbo.AGE_BAND(date_of_birth, visit_date)






-- CREATING A COUNT FOR EACH AGE RANGE

SELECT age_group, 
       COUNT(*) AS Visits
FROM patient_visits_analysis
GROUP BY age_group
ORDER BY Visits;


SELECT * 
FROM patient_visits_analysis
WHERE age_group= '1-18';

-- RESULT: OUR MOST FREQUENT PATIENT VISITS LIE IN THE AGE GROUP 40-64.





-- HOW MANY TIMES EACH ICD_CODE APPEARS

SELECT icd_code, COUNT(*) AS FREQUENCY
FROM patient_visits_analysis
GROUP BY icd_code
ORDER BY FREQUENCY DESC;





-- LOOKING TOP 10 DIAGNOSIS OVERALL. BREAKING THEM DOWN BY AGE AND GENDER

SELECT TOP 10 
       icd_code,
       COUNT(*) AS Diagnosis_Count
FROM patient_visits_analysis
GROUP BY icd_code
ORDER BY Diagnosis_Count DESC;
-- By Gender
SELECT TOP 10 
       icd_code,
       patient_sex,
       COUNT(*) AS Diagnosis_Count
FROM patient_visits_analysis
GROUP BY icd_code,patient_sex
ORDER BY Diagnosis_Count DESC;
--By Age
SELECT TOP 10 
       icd_code,
       CalculatedAge,
       COUNT(*) AS Diagnosis_Count
FROM patient_visits_analysis
GROUP BY icd_code,CalculatedAge
ORDER BY Diagnosis_Count DESC;





-- COUNTING TOTAL VISTIS and AVERAGE NUMBER OF VISITS PER PATIENT

SELECT patient_id, 
       COUNT(*) AS Visits_per_patient
FROM patient_visits_analysis
GROUP BY patient_id;
-- RESULT: TOTAL PATIENTS ANALYZED: 42, 18 PATIENTS HAD 9 VISITS, TWO PATIENTS HAD 8 VISITS AND THE REST, ONLY 1.

WITH AvgVisitsCte 
AS
( 
 SELECT patient_id, COUNT(*) AS VISITS
 FROM patient_visits_analysis
 GROUP BY patient_id
)
SELECT CONCAT(
       ROUND
       (AVG(CAST(VISITS AS FLOAT))
       ,2)
       ,'%') AS Average_Of_Visits  
FROM AvgVisitsCte;
-- RESULT: AVERGAE NUMBER OF VISITS PER PATIENT EQUALS 4.76%.





-- Visit Frequency Distribution Across Patients

WITH VisitsPerPatient
AS
(
  SELECT patient_id, 
         COUNT(*) AS Visits
  FROM patient_visits_analysis
  GROUP BY patient_id
),
VisitDistribution 
AS
(
  SELECT Visits, 
         COUNT(*) AS Number_Of_Patients
  FROM VisitsPerPatient
  GROUP BY Visits
)
SELECT Number_Of_Patients,
       Visits,
       CONCAT(
       ROUND(
       100.0 * CAST(Number_Of_Patients AS FLOAT)/SUM(CAST(Number_Of_Patients AS FLOAT)) OVER()
       , 2)
       , '%') AS Percentage_of_Patients
FROM VisitDistribution
ORDER BY Visits DESC;
       




--How many diagnoses were recorded for each patient.

SELECT patient_id, COUNT(icd_code) AS Total_Diagnosis
FROM patient_visits_analysis
GROUP BY patient_id, icd_code
ORDER BY Total_Diagnosis DESC;






-- STORING MOST FREQUENT QUERIES AS //VIEWS//
------------------------------------------------------------------------------------------------------------------------
CREATE VIEW Ranking_CPT_Codes 
AS
SELECT 
    cpt_code, 
    COUNT(*) AS FREQUENCY
FROM patient_visits_analysis
GROUP BY cpt_code;

------------------------------------------------------------------------------------------------------------------------
CREATE VIEW Diagnosis_By_Gender 
AS
SELECT patient_sex,
       COUNT(*) AS TotalVisits,
       CONCAT(
       COUNT(*) * 100/SUM(COUNT(*)) OVER()
       , '%') AS VisitPercent
FROM patient_visits_analysis
GROUP BY patient_sex;

------------------------------------------------------------------------------------------------------------------------
CREATE VIEW AgeGroup_Visit_FrequencyAnalysis
AS 
SELECT age_group, 
       COUNT(*) AS Visits
FROM patient_visits_analysis
GROUP BY age_group;

------------------------------------------------------------------------------------------------------------------------
CREATE VIEW Top_Diagnosis_ICDcodes
AS 
SELECT icd_code, 
       COUNT(*) AS FREQUENCY
FROM patient_visits_analysis
GROUP BY icd_code;

------------------------------------------------------------------------------------------------------------------------
CREATE VIEW Average_Visits
AS
WITH AvgVisitsCte 
AS
( 
 SELECT patient_id, COUNT(*) AS VISITS
 FROM patient_visits_analysis
 GROUP BY patient_id
)
SELECT CONCAT(
       ROUND
       (AVG(CAST(VISITS AS FLOAT))
       ,2)
       ,'%') AS Average_Of_Visits  
FROM AvgVisitsCte;

------------------------------------------------------------------------------------------------------------------------
CREATE VIEW Diagnosis_Recorded_Per_Patient
AS
SELECT patient_id, COUNT(icd_code) AS Total_Diagnosis
FROM patient_visits_analysis
GROUP BY patient_id, icd_code;

------------------------------------------------------------------------------------------------------------------------
CREATE VIEW Diagnosis_By_Age
AS
SELECT icd_code,
       CalculatedAge,
       COUNT(*) AS Diagnosis_Count
FROM patient_visits_analysis
GROUP BY icd_code,CalculatedAge;

------------------------------------------------------------------------------------------------------------------------

-- ENCAPSULATED AND USABLE SQL VIEWS FOR QUICK ANALYSIS

SELECT *
FROM Ranking_CPT_Codes
ORDER BY FREQUENCY DESC;

SELECT *
FROM Diagnosis_By_Gender;

SELECT *
FROM AgeGroup_Visit_FrequencyAnalysis
ORDER BY Visits;

SELECT *
FROM Top_Diagnosis_ICDcodes
ORDER BY FREQUENCY DESC;

SELECT *
FROM Average_Visits;

SELECT *
FROM Diagnosis_Recorded_Per_Patient
ORDER BY Total_Diagnosis DESC;

SELECT *
FROM Visit_Frequency_Across_Patients
ORDER BY Visits DESC;

SELECT TOP 10 *
FROM Diagnosis_By_Age
ORDER BY Diagnosis_Count DESC;