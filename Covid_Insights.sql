/*For this dataset, population ratio can not be reliable for earlier years because 
the data reports only the current population across all the dates 
without regard for the actual population in that period of time.*/


SELECT * FROM covideaths;
SELECT * FROM covidvaxx;

--Select the data of interest
SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM covideaths
ORDER BY 1,2,3;


--Looking at total cases vs total deaths
SELECT date, total_cases, total_deaths, ROUND(((total_deaths/total_cases)*100),4) death_ratio
FROM covideaths
WHERE location = 'United States'
ORDER BY 1,2;
--Shows what percentage of those who died to those who got infected
/*As of February 27 2023, the death rate among those who get infected was 1.083 in the United States.
This means that anyone who got infected has a 1.083% chance of dying*/


--Looking at total cases vs population
SELECT date, total_cases, population, ((total_cases/population)*100) cases_ratio
FROM covideaths
WHERE location = 'United States'
ORDER BY 1,2,3;
--Shows what percentage of the US population got covid
/*As of February 27 2023, 30.56% of the population had gotten infected with covid*/


--What country has the highest infection rate compared to population
SELECT location, MAX(total_cases) most_cases, population, MAX((total_cases/population)*100) cases_ratio
FROM covideaths
WHERE continent IS NOT NULL
GROUP BY location, population
HAVING MAX(total_cases) is not null
ORDER BY 4 desc;
/*As of February 27 2023, Cyprus had the highest number of cases per population at 72.44%*/


--What country has the highest death count per population
SELECT location, MAX(total_deaths) as mostdeaths
FROM covideaths
WHERE continent IS NOT NULL
GROUP BY location
HAVING MAX(total_deaths) is not null
ORDER BY 2 desc;
/*As of February 27 2023, the country with the most deaths from covid is the United States, at 1,119,560*/


--What continent has the highest death count per population
WITH CTE AS
(
	SELECT continent, location, MAX(total_deaths) maxi
	FROM covideaths
	GROUP BY continent, location
	HAVING MAX(total_deaths) IS NOT NULL
	ORDER BY 1 DESC
)
SELECT continent, SUM(maxi)
FROM CTE
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 2 DESC;
/*As of February 27 2023, the continent with the most deaths from covid is the Europe, at 2,032,603*/


--Global death per number of cases per day
SELECT date, SUM(new_cases) total_cases, SUM(new_deaths) total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 death_ratio
FROM covideaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 4 desc;
/*As of February 27, 2023 -- On January 15, 2023 China reported a a high rate of covid related death cases of almost 60000,
and this caused the data to spike on that very day and gives the impression of that day having the highest
covid related death rate of 31% in the world. The next date with the highest covid related death rate after that was
February 24, 2020 at 28.17%*/


--Global deaths per cases overall
SELECT SUM(new_cases) total_cases, SUM(new_deaths) total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 death_ratio
FROM covideaths
WHERE continent IS NOT NULL;
/*As of February 27 2023, the covid death ratio for the whole world was 1.015% 
with a total number of 673,459,849 cases, and 6,833,022 deaths.*/

--Total new vaccinations per day for each population
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
FROM covideaths dea JOIN covidvaxx vax
ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--Cummulative total for each new day of new vaccinations 
SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
		SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cummulative_new_vaxx
FROM covideaths dea JOIN covidvaxx vax
ON dea.location = vax.location
	AND dea.date = vax.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--Total vaccinations in relation to population for each country
WITH popvax (continent, location, date, population, new_vax, cumm_vax) AS
(
	SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
	SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cummulative_new_vaxx
	FROM covideaths dea JOIN covidvaxx vax
	ON dea.location = vax.location
	AND dea.date = vax.date
	WHERE dea.continent IS NOT NULL
)
SELECT location, population, (maxim/population)*100 as vax_per_pop
FROM (SELECT location, MAX(cumm_vax) maxim, population FROM popvax GROUP BY location, population) as sub 
ORDER BY 3 DESC;
/*As of February 27 2023, Cuba had the highest percentage ratio of vaccinations per total population of 331.5%*/



--create views for each query above
CREATE VIEW VaxPop AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
			SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cummulative_new_vaxx
	FROM covideaths dea JOIN covidvaxx vax
	ON dea.location = vax.location
		AND dea.date = vax.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3;

CREATE VIEW US_death_ratio AS
	SELECT date, total_cases, total_deaths, ROUND(((total_deaths/total_cases)*100),4) death_ratio
	FROM covideaths
	WHERE location = 'United States'
	ORDER BY 1,2;

CREATE VIEW case_ratio_per_country AS
	SELECT date, total_cases, population, ((total_cases/population)*100) cases_ratio
	FROM covideaths
	WHERE location = 'United States'
	ORDER BY 1,2,3;
	
CREATE VIEW highest_total_deaths_per_country AS
	SELECT location, MAX(total_deaths) as mostdeaths
	FROM covideaths
	WHERE continent IS NOT NULL
	GROUP BY location
	HAVING MAX(total_deaths) is not null
	ORDER BY 2 desc;
	
CREATE VIEW continent_level_deaths AS
	WITH CTE AS
	(
		SELECT continent, location, MAX(total_deaths) maxi
		FROM covideaths
		GROUP BY continent, location
		HAVING MAX(total_deaths) IS NOT NULL
		ORDER BY 1 DESC
	)
	SELECT continent, SUM(maxi)
	FROM CTE
	WHERE continent IS NOT NULL
	GROUP BY continent
	ORDER BY 2 DESC;
	
CREATE VIEW top_perc_death_per_day_global AS
	SELECT date, SUM(new_cases) total_cases, SUM(new_deaths) total_deaths, 
	(SUM(new_deaths)/SUM(new_cases))*100 death_ratio
	FROM covideaths
	WHERE continent IS NOT NULL
	GROUP BY date
	ORDER BY 4 desc;
	
CREATE VIEW overall_death_per_case AS
	SELECT SUM(new_cases) total_cases, SUM(new_deaths) total_deaths, 
	(SUM(new_deaths)/SUM(new_cases))*100 death_ratio
	FROM covideaths
	WHERE continent IS NOT NULL;
	
CREATE VIEW total_vax_per_day AS	
	SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations
	FROM covideaths dea JOIN covidvaxx vax
	ON dea.location = vax.location
		AND dea.date = vax.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3;
	
CREATE VIEW cumm_vax_per_day AS
	SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
			SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cummulative_new_vaxx
	FROM covideaths dea JOIN covidvaxx vax
	ON dea.location = vax.location
		AND dea.date = vax.date
	WHERE dea.continent IS NOT NULL
	ORDER BY 2,3;
	
CREATE VIEW country_level_vax_per_pop AS	
	WITH popvax (continent, location, date, population, new_vax, cumm_vax) AS
	(
		SELECT dea.continent, dea.location, dea.date, dea.population, vax.new_vaccinations,
		SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS cummulative_new_vaxx
		FROM covideaths dea JOIN covidvaxx vax
		ON dea.location = vax.location
		AND dea.date = vax.date
		WHERE dea.continent IS NOT NULL
	)
	SELECT location, population, (maxim/population)*100 as vax_per_pop
	FROM (SELECT location, MAX(cumm_vax) maxim, population FROM popvax GROUP BY location, population) as sub 
	ORDER BY 3 DESC;