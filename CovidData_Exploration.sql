/*
Project Name: "Covid-19 Insights: Analyzing Cases, Deaths, and Vaccinations Worldwide"

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Exploring the Data CovidDeaths
SELECT *
FROM Covid_Data_Exploration_Project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4;

-- Selecting essential data to start with
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Covid_Data_Exploration_Project..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Analyzing the likelihood of death if contracting Covid-19 in a specific country
SELECT Location, date, total_cases, total_deaths,
(total_deaths / total_cases) * 100 AS DeathPercentage
FROM Covid_Data_Exploration_Project..CovidDeaths
WHERE Location LIKE '%india'
ORDER BY 1, 2;

-- Examining the percentage of the population infected with Covid-19 over time
SELECT Location, date, total_cases, population,
(total_cases / population) * 100 AS PercentPopulationInfected
FROM Covid_Data_Exploration_Project..CovidDeaths
ORDER BY 1, 2;

-- Identifying countries with the highest infection rate compared to their population
SELECT Location, Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM Covid_Data_Exploration_Project..CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Determining countries with the highest death count per population
SELECT Location,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM Covid_Data_Exploration_Project..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Breaking down death count by continent
SELECT continent,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM Covid_Data_Exploration_Project..CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Analyzing global Covid-19 numbers
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM Covid_Data_Exploration_Project..CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1, 2;

-- Exploring the Data CovidVaccinations
SELECT * 
FROM Covid_Data_Exploration_Project..CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4;

-- Calculating the percentage of the population that received at least one Covid vaccine
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) 
OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Covid_Data_Exploration_Project..CovidDeaths dea
JOIN Covid_Data_Exploration_Project..CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2, 3;

-- Using CTE to perform calculation on Partition By in the previous query
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
  , SUM(CONVERT(INT, vac.new_vaccinations)) 
    OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Covid_Data_Exploration_Project..CovidDeaths dea
JOIN Covid_Data_Exploration_Project..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;

-- Using Temp Table to perform calculation on Partition By in the previous query
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
  Continent NVARCHAR(255),
  Location NVARCHAR(255),
  Date DATETIME,
  Population NUMERIC,
  New_vaccinations NUMERIC,
  RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) 
OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Covid_Data_Exploration_Project..CovidDeaths dea
JOIN Covid_Data_Exploration_Project..CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated;

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(INT, vac.new_vaccinations)) 
OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Covid_Data_Exploration_Project..CovidDeaths dea
JOIN Covid_Data_Exploration_Project..CovidVaccinations vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

