SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY location,date

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--WHERE continent is not null
--ORDER BY location,date


-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY location, date


-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
and continent is not null
ORDER BY location, date


-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID
SELECT location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
ORDER BY location, date


-- Looking at Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected desc


-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing Continents with Highest Death Count per Population
SELECT continent, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc


-- (The data is accurate with this, but it may disrupt the drilldown effect for visualization in PowerBI/Tablueau)
-- Showing Continents with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths as bigint)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc



-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, (SUM(cast(new_deaths as bigint))/SUM(new_cases))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY date, total_cases

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, (SUM(cast(new_deaths as bigint))/SUM(new_cases))*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location like '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY total_cases, total_deaths



-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(int, vac.new_vaccinations)) 
		OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY dea.location, dea.date


-- USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(int, vac.new_vaccinations)) 
		OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY dea.location, dea.date
)
SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentPopulationVaccinated
FROM PopvsVac



-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(int, vac.new_vaccinations)) 
		OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY dea.location, dea.date

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentPopulationVaccinated
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

USE PortfolioProject
GO
CREATE View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(CONVERT(int, vac.new_vaccinations)) 
		OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY dea.location, dea.date

SELECT *, (RollingPeopleVaccinated/Population)*100 as PercentPopulationVaccinated
FROM PercentPopulationVaccinated