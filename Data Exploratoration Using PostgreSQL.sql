-- To query Tables Using Select 

-- Viewing tables CovidDeaths and Covid Vaccinnation from data ranging from 24th Feb 2020 to 28th Feb 2020
-- Data obtained from https://ourworldindata.org/covid-deaths 

SELECT * FROM "Portfolio".public."CovidDeaths"
ORDER BY  3,4
SELECT * FROM "Portfolio"."public"."CovidVaccinations"
ORDER BY 3,4

-- To change column data types 

-- for table covid deaths
ALTER TABLE "CovidDeaths"
ALTER COLUMN date TYPE date USING (date::date);
ALTER TABLE "CovidDeaths"
ALTER COLUMN population TYPE FLOAT USING (population::FLOAT);
ALTER TABLE "CovidDeaths"
ALTER COLUMN total_cases TYPE FLOAT USING (total_cases::FLOAT);
ALTER TABLE "CovidDeaths"
ALTER COLUMN total_deaths TYPE FLOAT USING (total_deaths::FLOAT);
ALTER TABLE "CovidDeaths"
ALTER COLUMN new_deaths TYPE FLOAT USING (new_deaths::FLOAT);
ALTER TABLE "CovidDeaths"
ALTER COLUMN new_cases TYPE FLOAT USING (new_cases::FLOAT);

 
-- for table CovidVaccinations
ALTER TABLE "CovidVaccinations"
ALTER COLUMN date TYPE date USING (date::date);
ALTER TABLE "CovidVaccinations"
ALTER COLUMN new_vaccinations TYPE FLOAT USING (new_vaccinations::FLOAT);


-- Looking at Total Cases Vs Total Deaths for all countries per day

SELECT "location", "date" , total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM "Portfolio".public."CovidDeaths"
ORDER BY 1,2

-- Looking at Total Cases Vs Total Deaths per day for India

SELECT "location", "date" , total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM "Portfolio".public."CovidDeaths"
WHERE "location" = 'India'


-- Looking at Total Cases Vs Total Deaths for all countries
-- Shows the likelihood of death if you contract covid.

SELECT "location", "date" , total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM "Portfolio".public."CovidDeaths"
WHERE "location" LIKE 'India'
ORDER BY 1,2
-- to verify data  http://surl.li/blyeg
 


-- Looking at Total Cases vs Population
-- Shows what percentage of the population got covid


SELECT "location", "date" , total_cases, population , (total_cases/population)*100 AS positivecasepercentage
FROM "Portfolio".public."CovidDeaths"
WHERE "location" LIKE 'India' AND continent IS NOT NULL
ORDER BY 1,2


-- Looking at Countries with Highest Infection Rate compared to Population

SELECT "location", population, MAX(total_cases) AS HighestInfectionCount , MAX((total_cases/population))*100 AS MaxPercentPopulationInfected 
FROM "Portfolio".public."CovidDeaths"
WHERE continent IS NOT NULL
GROUP BY "location", population 
ORDER BY MaxPercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population 

SELECT "location", MAX(total_deaths) AS TotalDeathCount 
FROM "Portfolio".public."CovidDeaths"
WHERE continent IS NOT NULL AND  total_deaths IS NOT NULL 
GROUP BY "location"
ORDER BY TotalDeathCount DESC

-- Death count by continent

SELECT "location", MAX(total_deaths) AS TotalDeathCount 
FROM "Portfolio".public."CovidDeaths"
WHERE continent IS  NULL AND  total_deaths IS NOT NULL  AND  "location" NOT IN ('World','International','High income','Upper middle income','Low income','Lower middle income')
GROUP BY "location"
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

-- Daily global deaths and cases report
SELECT date, SUM(new_cases) AS global_cases, SUM(new_deaths) AS global_deaths, ( SUM(new_deaths)/SUM(new_cases))*100 AS death_percentage
FROM "Portfolio".public."CovidDeaths"
WHERE continent IS NOT NULL 
GROUP BY date
ORDER BY 1

-- Total gloabl deaths and cases
SELECT  SUM(new_cases) AS global_cases, SUM(new_deaths) AS global_deaths, ( SUM(new_deaths)/SUM(new_cases))*100 AS death_percentage
FROM "Portfolio".public."CovidDeaths"
WHERE continent IS NOT NULL 

-- Looking at Total population vs Vaccinations

-- using joins on both tables
 

SELECT dea."location",dea."continent",dea.date,dea.population,vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS "RollingPeopleVaccinated"
FROM "Portfolio".public."CovidDeaths" dea 
JOIN "Portfolio".public."CovidVaccinations" vac
    ON dea.location=vac.location
    AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3


--Using CTE to find percentage vaccinated.

-- Here total rolling people vaccinated gives the cummulative sum of new vaccinations
-- the total of which gives total vaccinations done in india.
-- to find the percentage fully vaccinated , I have taken the assumption of dividing the total vaccinations by 2 to denote a double dose.
--using cte i have used the alias of rollingeoplevaccinated to find the percentage vaccinated which comes out to be 61% . the  accurate figure is 56.3 % given in this link  : https://rb.gy/mi3dmt



WITH PopvsVac ("location",continent,date,population,new_vaccinations ,"RollingPeopleVaccinated")
AS 
(
SELECT dea."location",dea."continent",dea.date,dea.population,vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS "RollingPeopleVaccinated"
FROM "Portfolio".public."CovidDeaths" dea 
JOIN "Portfolio".public."CovidVaccinations" vac
    ON dea.location=vac.location
    AND dea.date=vac.date
WHERE dea.continent IS NOT NULL
)
SELECT * , (("RollingPeopleVaccinated"/2)/population)*100 AS percentage_vaccinated
FROM PopvsVac
ORDER BY 1,2,3

-- Creating views to store data 
CREATE VIEW  peoplevaccinated AS
SELECT dea."location",dea."continent",dea.date,dea.population,vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS "RollingPeopleVaccinated"
FROM "Portfolio".public."CovidDeaths" dea 
JOIN "Portfolio".public."CovidVaccinations" vac
    ON dea.location=vac.location
    AND dea.date=vac.date
WHERE dea.continent IS NOT NULL


-- Using view to simplify the query for percentage of vaccinated to find the percentage vaccinated for india.


WITH PopvsVac ("location",continent,date,population,new_vaccinations ,"RollingPeopleVaccinated")
AS 
(
SELECT * FROM  peoplevaccinated 
)
SELECT * , (("RollingPeopleVaccinated"/2)/population)*100 AS percentage_vaccinated
FROM PopvsVac
WHERE "location" = 'India'
ORDER BY 1,2,3


