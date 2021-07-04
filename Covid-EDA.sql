SELECT *
FROM Project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

-- Overview of Data Needed
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Project..CovidDeaths
ORDER BY 1,2

-- Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM Project..CovidDeaths
WHERE location = 'Philippines'
ORDER BY 1,2

-- Total Cases vs Population
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PopulationInfectedPercentage
FROM Project..CovidDeaths
WHERE location = 'Philippines'
ORDER BY 1,2

-- Country With the Highest Infection Rate
SELECT location, population, MAX(total_cases) AS HighestInfectionCount , MAX((total_cases/population))*100 AS PopulationInfectedPercentage
FROM Project..CovidDeaths
GROUP BY location, population
ORDER BY PopulationInfectedPercentage DESC


-- Country with Highest Death Count per Population
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeath
FROM Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeath DESC

-- Country with Highest Death Count per Continent
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeath
FROM Project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeath DESC

-- Global Death Count
SET ARITHABORT OFF
SET ANSI_WARNINGS OFF
SELECT SUM(new_cases) NewCases, SUM(CAST(new_deaths AS INT)) NewDeaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS DeathPercetage
FROM Project..CovidDeaths
ORDER BY 1,2

-- Total Populaton vs Vaccinations (Using CTE)
WITH PopulationVSVaccination (continent, location, date, population, new_vaccinations, RollingCountPeopleVaccinated)
AS
(SELECT CDeath.continent, CDeath.location, CDeath.date, CDeath.population, CVac.new_vaccinations
	,SUM(CAST(CVac.new_vaccinations AS INT)) OVER (PARTITION BY CDeath.location ORDER BY CDeath.location, CDeath.date) AS RollingCountPeopleVaccinated
FROM Project..CovidDeaths CDeath
JOIN Project..CovidVaccinations CVac
	ON CDeath.location = CVac.location
	AND CDeath.date = CVac.date
WHERE CDeath.continent IS NOT NULL
)
SELECT *, (RollingCountPeopleVaccinated/population)*100 AS PercentagePopulationVaccinated
FROM PopulationVSVaccination

-- Total Population vs Vaccinations (Using Temp Table)
DROP TABLE IF EXISTS #PopulationvsVaccinations
CREATE TABLE #PopulationvsVaccinations
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
INSERT INTO #PopulationvsVaccinations
SELECT CDeath.continent, CDeath.location, CDeath.date, CDeath.population, CVac.new_vaccinations
	,SUM(CAST(CVac.new_vaccinations AS INT)) OVER (PARTITION BY CDeath.location ORDER BY CDeath.location, CDeath.date) AS RollingPeopleVaccinated
FROM Project..CovidDeaths CDeath
JOIN Project..CovidVaccinations CVac
	ON CDeath.location = CVac.location
	AND CDeath.date = CVac.date
WHERE CDeath.continent IS NOT NULL
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentagePopulationVaccinated
FROM #PopulationvsVaccinations

-- View
CREATE VIEW PopulationvsVaccinations AS    
SELECT CDeath.continent, CDeath.location, CDeath.date, CDeath.population, CVac.new_vaccinations
	,SUM(CAST(CVac.new_vaccinations AS INT)) OVER (PARTITION BY CDeath.location ORDER BY CDeath.location, CDeath.date) AS RollingPeopleVaccinated
FROM Project..CovidDeaths CDeath
JOIN Project..CovidVaccinations CVac
	ON CDeath.location = CVac.location
	AND CDeath.date = CVac.date
WHERE CDeath.continent IS NOT NULL

SELECT * FROM PopulationvsVaccinations