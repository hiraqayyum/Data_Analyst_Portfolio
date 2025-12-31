SELECT *
from Portfolio_Project..Covid_Vaccinations$
ORDER BY 3,4

SELECT * 
FROM Portfolio_Project..Covid_Deaths$
ORDER BY 3,4


SELECT location, date, total_cases,new_cases, total_deaths, population
FROM Covid_Deaths$
order by 1,2

-- LOOKING AT TOTAL CASES VS. TOTAL DEATHS
-- LIKELIHOOD OF DYING IF YOU GET COVID IN YOUR COUNTRY 
SELECT 
     location, 
     date, 
     total_cases, 
     total_deaths, 
     CASE
        WHEN total_cases= 0 OR total_cases IS NULL THEN NULL
        ELSE CONCAT(
        ROUND((total_deaths/NULLIF(total_cases,0))*100, 2), '%')
        END as Death_Percentage
FROM Covid_Deaths$
WHERE location LIKE 'Pakistan'
ORDER BY 1,2

-- LOOKING AT TOTAL CASES VS POPULATION
-- SHOWS WHAT %AGE OF POPULATION IS AFFECTED BY COVID IN WHICH COUNTRY
SELECT location, date, total_cases, population, 
CASE
    WHEN total_cases=0 THEN '0%'
    WHEN total_cases IS NULL OR population IS NULL THEN NULL
    ELSE
    CONCAT(ROUND((total_cases/population)*100.0,2), '%') 
    END AS InfectedPercentage
FROM Covid_Deaths$
--WHERE location LIKE 'A%a'
Order by 1,2

-- WHICH COUNTRIES HAVE THE HIGHEST INFECTION RATE
SELECT DISTINCT location, total_cases, population, 
CASE
    WHEN total_cases=0 THEN '0%'
    WHEN total_cases IS NULL OR population IS NULL THEN NULL
    ELSE
    CONCAT(ROUND((total_cases/population)*100.0,2), '%') 
    END AS InfectedPercentage
FROM Covid_Deaths$
WHERE (
total_cases/population)*100.0=(
SELECT MAX((total_cases/population)*100.0)
FROM Covid_Deaths$
)


SELECT location, MAX(total_cases) as MaxCases, 
MAX(
CONCAT(
ROUND(
(
(total_cases/population)*100),2)
,'%')
) as MaxInfectedPopulation
FROM Covid_Deaths$
GROUP BY location
ORDER BY MaxInfectedPopulation DESC


SELECT location, MAX(total_cases) as MaxCases, 
MAX(
ROUND(
(total_cases/population)*100, 2)
) as MaxInfectedPopulation
FROM Covid_Deaths$
GROUP BY location
ORDER BY MaxInfectedPopulation DESC

SELECT TOP 1 
       location, 
       population, 
       CONCAT(InfectedPopulation,'%') as InfPop
       FROM 
           (SELECT location, population, MAX(ROUND((total_cases/population)*100,2)
           ) as InfectedPopulation
           FROM Covid_Deaths$
           GROUP BY location, population
           ) t
Order by InfectedPopulation DESC


SELECT location, MAX(total_cases), population, MAX(total_cases/population)*100 as InfectedPopulation
FROM Covid_Deaths$
GROUP BY location, population
ORDER BY InfectedPopulation DESC

-- SHOWING COUNTRIES WITH THE HIGHEST DEATH COUNT
SELECT location, MAX(CAST(total_deaths AS INT)) as TotalDeaths, population
FROM Covid_Deaths$
WHERE continent is NOT NULL
GROUP BY location, population
Order by TotalDeaths DESC


-- LET'S BREAK DOWN THINGS BY CONTINENT
SELECT continent, MAX(CAST(total_deaths AS INT)) as TotalDeaths
FROM Covid_Deaths$
WHERE continent is NOT NULL
GROUP BY continent
Order by TotalDeaths DESC

-- GLOBAL NUMBERS PER DAY
SELECT 
     date,
     SUM(new_cases) as Total_Cases, 
     SUM(new_deaths) as Total_Deaths,
     ROUND(
     (SUM(new_deaths)/NULLIF(SUM(new_cases), 0))*100 
     , 2) as DeathPercenatage
     FROM Covid_Deaths$
     WHERE continent IS NOT NULL
     GROUP BY date
     ORDER BY 1,2

-- TOTAL POPULATION VS VACCINATIONS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as bigint)) OVER 
(PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM Covid_Deaths$ dea
JOIN Covid_Vaccinations$ vac
ON dea.date= vac.date
AND dea.location= vac.location
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- PERCENTAGE OF PEOPLE VACCINATED
--First using {CTE}

WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM Covid_Deaths$ dea
JOIN Covid_Vaccinations$ vac
ON dea.location= vac.location
AND dea.date= vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PopVaccinated
FROM PopVsVac
ORDER BY 2,3

--Now using a {Temp Table}

CREATE TABLE #PeopleVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255), 
Date Datetime, 
Population numeric, 
New_Vaccinations numeric, 
RollingPeopleVaccinated numeric
)

INSERT INTO #PeopleVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM Covid_Deaths$ dea
JOIN Covid_Vaccinations$ vac
ON dea.location= vac.location
AND dea.date= vac.date


SELECT *, (RollingPeopleVaccinated/Population)*100 as PopVaccinated
FROM #PeopleVaccinated
WHERE Continent IS NOT NULL

-- CREATING VIEWS FOR EFFICIENT LOOKUPS

CREATE VIEW vw_RollingPeopleVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) 
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM Covid_Deaths$ dea
JOIN Covid_Vaccinations$ vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;


CREATE VIEW vw_PercentPeopleVaccinated AS
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
FROM Covid_Deaths$ dea
JOIN Covid_Vaccinations$ vac
ON dea.location= vac.location
AND dea.date= vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PopVaccinated
FROM PopVsVac


CREATE VIEW vw_GlobalNumbers As
SELECT 
     date,
     SUM(new_cases) as Total_Cases, 
     SUM(new_deaths) as Total_Deaths,
     ROUND(
     (SUM(new_deaths)/NULLIF(SUM(new_cases), 0))*100 
     , 2) as DeathPercenatage
     FROM Covid_Deaths$
     WHERE continent IS NOT NULL
     GROUP BY date


CREATE VIEW vw_DeathsPerCountry As
SELECT location, MAX(CAST(total_deaths AS INT)) as TotalDeaths, population
FROM Covid_Deaths$
WHERE continent is NOT NULL
GROUP BY location, population


CREATE VIEW vw_CountryWithMaxDeaths As
SELECT DISTINCT location, total_cases, population, 
CASE
    WHEN total_cases=0 THEN '0%'
    WHEN total_cases IS NULL OR population IS NULL THEN NULL
    ELSE
    CONCAT(ROUND((total_cases/population)*100.0,2), '%') 
    END AS InfectedPercentage
FROM Covid_Deaths$
WHERE (
total_cases/population)*100.0=(
SELECT MAX((total_cases/population)*100.0)
FROM Covid_Deaths$
)


CREATE VIEW vw_RollingDeathPercentage AS
SELECT 
     location, 
     date, 
     total_cases, 
     total_deaths, 
     CASE
        WHEN total_cases= 0 OR total_cases IS NULL THEN NULL
        ELSE CONCAT(
        ROUND((total_deaths/NULLIF(total_cases,0))*100, 2), '%')
        END as Death_Percentage
FROM Covid_Deaths$

-- OVERALL STATS /OBSERVATIONS 

SELECT * 
FROM vw_RollingPeopleVaccinated

SELECT * 
FROM vw_PercentPeopleVaccinated

SELECT * 
FROM vw_GlobalNumbers

SELECT * 
FROM vw_DeathsPerCountry
ORDER BY TotalDeaths DESC

SELECT *
FROM vw_CountryWithMaxDeaths

SELECT *
FROM vw_RollingDeathPercentage
WHERE location LIKE 'Pakistan'
