/*
Data Exploration Using COVID19 Data

Skills Employed: Joins, CTE's, Temporary Tables, Windows Functions, Aggregate Functions, View Creation, Creating Cases, Data Type Conversion, Try and Catch, NULL Handling
*/
USE [CovidData]


SELECT Location, date, total_cases,  new_cases, total_deaths, population
From COV19Deaths
ORDER BY 1,2 
----COUNTRY-WISE ANALYSIS
----Total Cases VS Total Deaths
SELECT Location, date, total_cases, total_deaths, (CAST(total_deaths AS FLOAT)/ total_cases) * 100 as deathPercentage
From COV19Deaths
WHERE Location = 'India'
ORDER BY 1,2 

----Total Cases VS Population
SELECT Location, date, total_cases, population,  (CAST(total_cases AS FLOAT) / CAST(population AS FLOAT)) * 100 AS deathPercentage
From COV19Deaths
--WHERE Location = 'India'
ORDER BY 1,2 

---Countries with highest cases compared to other countries
SELECT Location,MAX(total_cases) as highestCasesCount,population,(MAX(total_cases) / CAST(population AS FLOAT)) * 100 AS percentageOfPopulationAffected
FROM COV19Deaths
GROUP BY Location, population
ORDER BY  percentageOfPopulationAffected DESC

---Countries with highest death count per population
SELECT Location,MAX(CAST(total_deaths AS Int)) as totalDeathCount
FROM COV19Deaths
Where continent is not null
GROUP BY Location
ORDER BY  totalDeathCount DESC

---Continent-Wise Death Count
SELECT Continent,MAX(CAST(total_deaths AS Int)) as totalDeathCount
FROM COV19Deaths
Where continent is not null
GROUP BY Continent
ORDER BY  totalDeathCount DESC
    
----GLOBAL NUMBERS
--Cases around the world- Global Numbers
SELECT
    date,
    SUM(new_cases) AS total_new_cases,
    SUM(new_deaths) AS total_new_deaths,
---Here, CASE has been used to remove the division by zero error
    CASE
        WHEN SUM(new_cases) = 0 THEN NULi
        ELSE (SUM(new_deaths) * 100 / SUM(new_cases)) 
    END AS deathPercentage
FROM COV19Deaths
WHERE Continent is not null
GROUP BY date
ORDER BY 1,2 

---Total Population VS Vaccination
SELECT DEA.continent, DEA.Location, DEA.date, DEA.population, VAC.new_vaccinations, SUM(CONVERT(float,VAC.new_vaccinations)) OVER(Partition by DEA.Location ORDER BY DEA.Location, DEA.date) AS rollingCountOfVaccinatedPeople
FROM COV19Deaths AS DEA
JOIN COVVaccinations as VAC
ON DEA.Location= VAC.Location
WHERE DEA.continent is not null
and DEA.date =VAC.date
ORDER BY 2,3

---Using CTE to perform calcualtion on partition by
WITH popVsVac (Continent, Location, Date, Population, new_vaccinatios, rollingCountOfVaccinatedPeople)
AS
(
SELECT DEA.continent, DEA.Location, DEA.date, DEA.population, VAC.new_vaccinations, SUM(CONVERT(float,VAC.new_vaccinations)) OVER(Partition by DEA.Location ORDER BY DEA.Location, DEA.date) AS rollingCountOfVaccinatedPeople
FROM COV19Deaths AS DEA
JOIN COVVaccinations as VAC
ON DEA.Location= VAC.Location
WHERE DEA.continent is not null
and DEA.date =VAC.date
--ORDER BY 2,3
)
SELECT *, (rollingCountOfVaccinatedPeople/ Population)* 100 AS RollingPercentage
FROM popVsVac


---Using Temporary Table to perform calcualtion on partition by
DROP TABLE IF exists #percentPopulationVaccinated
CREATE TABLE #percentPopulationVaccinated
(Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, new_vaccinations numeric, rollingCountOfVaccinatedPeople numeric)
INSERT INTO #percentPopulationVaccinated
SELECT DEA.continent, DEA.Location, DEA.date, DEA.population, VAC.new_vaccinations, SUM(CONVERT(float,VAC.new_vaccinations)) OVER(Partition by DEA.Location ORDER BY DEA.Location, DEA.date) AS rollingCountOfVaccinatedPeople
FROM COV19Deaths AS DEA
JOIN COVVaccinations as VAC
ON DEA.Location= VAC.Location
WHERE DEA.continent is not null
and DEA.date =VAC.date
--ORDER BY 2,3

SELECT *, (rollingCountOfVaccinatedPeople/ Population)* 100 AS RollingPercentage
FROM #percentPopulationVaccinated

----Creating view to store data for later

CREATE VIEW PercentPopulationVaccinated
AS
SELECT DEA.continent, DEA.Location, DEA.date, DEA.population, VAC.new_vaccinations, SUM(CONVERT(float,VAC.new_vaccinations)) OVER(Partition by DEA.Location ORDER BY DEA.Location, DEA.date) AS rollingCountOfVaccinatedPeople
FROM COV19Deaths AS DEA
JOIN COVVaccinations as VAC
ON DEA.Location= VAC.Location
WHERE DEA.continent is not null
and DEA.date =VAC.date
--ORDER BY 2,3

SELECT * 
    FROM PercentPopulationVaccinated

--Using Try and Catch to make sure the NULLS are replaced by zero

BEGIN TRY
Select Location, Population,
ISNULL(MAX(total_cases), 0) as HighestInfectionCount,  
ISNULL(MAX(CAST(total_cases/population))*100, 0) as PercentPopulationInfected
From COV19Deaths
--Where location like 'India'
Group by Location, population
order by PercentPopulationInfected desc
END TRY
BEGIN CATCH
    -- Handle the error
    PRINT 'An error occurred: ' + ERROR_MESSAGE();
END CATCH;

