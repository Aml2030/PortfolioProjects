--We have downloaded this data from : 
--https://ourworldindata.org/explorers/covid?tab=chart&time=2020-01-29..2021-04-30&country=FRA~USA~DEU~IND~CAN~GBR&Metric=Excess+mortality+%28estimates%29&Interval=Cumulative&Relative+to+population=true
--We have selected specific columns for our analysis. 
--We have then separated the data into two Excel workbooks: CovidDeaths and CovidVaccinations.
--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types.
--These queries demonstrate various SQL techniques (JOINs, CTEs, Window Functions, Aggregate Functions)
--while providing valuable insights into the COVID-19 pandemic.
--in the db when continent is null the location will be a continent.
 
-----------------------------------------------------
--These queries demonstrate various SQL techniques including:

--Basic aggregations (SUM, MAX, AVG)
--Window functions (OVER clause)
--Common Table Expressions (WITH clause)
--Joins
--Date manipulation (DATE_TRUNC)
--Conditional logic (CASE statement)

 select * 
 from PortfolioProject..CovidDeaths

  select * 
 from PortfolioProject..CovidVaccinations

-- 1. Max Total cases for each country 
select location , max(total_cases) as MaxTotalCases
from PortfolioProject..CovidDeaths
where continent is not null
group by location 
order by MaxTotalCases desc ; 

-- 2. Top 10 Countries with the highest death count
SELECT  top 10 location, MAX(total_deaths) as MAXTotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY MAXTotalDeaths Desc;

-- 3. Daily new cases in a specific country (e.g., Egypt)
SELECT date, new_cases, location
FROM PortfolioProject..CovidDeaths
WHERE location = 'Egypt' 
ORDER BY date;

-- 4. Global COVID-19 Cases, Deaths, and Death Percentage
SELECT 
    SUM(new_cases) as total_cases, 
    --SUM(convert (int , new_deaths)) as total_deaths,
	SUM(CAST (new_deaths AS INT) ) as total_deaths,
    CASE 
        WHEN SUM(new_cases) > 0 THEN (SUM(convert (int , new_deaths)) * 100.0 / SUM(new_cases))
        ELSE NULL
    END as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL;


-- 5. 7-day moving SUM of new cases for each country**
	--"When the query reaches the 8th day, it subtracts the value from the 1st day and adds the value from the 8th day.
	--On the 9th day, it subtracts the 2nd day and adds the 9th day.
	--This pattern continues for each subsequent day, always maintaining a rolling 7-day sum.
	--it sums the new cases for 7 days moving"
SELECT 
    date,
    location,
    new_cases,
    SUM(new_cases) OVER (PARTITION BY location 
                          ORDER BY   date
                          ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
						  )as cases_7day_moving
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location;


-- 6. Sum of Cases for Distinct 7-day Periods
WITH period_data AS (
    SELECT 
		date,
        location,
        SUM(new_cases) AS daily_cases,
        DATEDIFF(day, MIN(date) OVER (PARTITION BY location), date) / 7 AS period_number
        FROM PortfolioProject.dbo.CovidDeaths
    WHERE continent IS NOT NULL AND new_cases IS NOT NULL
    GROUP BY date , location
)
SELECT 
    location,
    MIN(date) AS period_start_date,
    MAX(date) AS period_end_date,
    SUM(daily_cases) AS cases_7day_sum
FROM period_data
GROUP BY location, period_number
ORDER BY location, period_start_date;


-- 7. Countries with highest infection rate compared to population
SELECT 
    location, 
    population, 
    MAX(total_cases) as highest_infection_count,
    MAX((total_cases)/population*100 )as percent_population_infected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL AND total_cases IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC;



-- 8. Monthly new cases and deaths by continent
SELECT 
	DATETRUNC(MONTH, date) as month,
    continent,
    SUM(new_cases) as monthly_new_cases,
    SUM(CONVERT(INT, new_deaths )) as monthly_new_deaths
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL AND new_cases IS NOT NULL AND new_deaths IS NOT NULL
GROUP BY continent, DATETRUNC(MONTH, date)
ORDER BY continent, month;

-- 9. Monthly new cases and deaths by a certain location ,and Death Percentage
SELECT 
	DATETRUNC(MONTH, date) as month,
    Location,
    SUM(new_cases) as monthly_new_cases,
    SUM(CONVERT(INT, new_deaths )) as monthly_new_deaths,
	(SUM(new_cases))/ (SUM(CONVERT(INT, new_deaths )) *100) as DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE Location ='EGypt' and new_cases IS NOT NULL AND new_deaths IS NOT NULL
GROUP BY Location, DATETRUNC(MONTH, date)
ORDER BY Location, month;


-- 10. COVID-19 Death Percentage in Egypt
Select
	Location  ,
	MAX(total_deaths) AS TotalDeaths , 
	MAX(total_cases) AS TotalCases,
	(MAX(total_deaths)/MAX(total_cases))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%Egypt'
GROUP BY location  


--11. Countries with Highest COVID-19 Infection Rate Compared to Population
Select
	Location, 
	Population, 
	MAX(total_cases) as HighestInfectionCount,  
    Max((total_cases/population))*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc



-- 12. Total COVID-19 cases evolution over time for each continent on each date.
SELECT date, continent, SUM(total_cases) as total_cases
FROM PortfolioProject..CovidDeaths
where continent is not null and total_cases is not null
GROUP BY date, continent 
ORDER BY date, continent;

 
--13. COVID-19 Vaccination Progress by Location 
Select 
	date,
	location, 
	new_vaccinations,
    SUM(CONVERT(int,new_vaccinations)) OVER (Partition by Location 
											 Order by Date
											) as RollingPeopleVaccinated
From  PortfolioProject..CovidVaccinations 
where  new_vaccinations  > 0
		AND  location  NOT IN ('World','Africa', 'Asia', 'Europe','European Union', 'North America', 'Oceania', 'South America')



--14.  Join" COVID-19 Vaccination Progress by Location and PercentageOfRollingPeopleVaccinatedToPopulation
--the progression of vaccinations over time for each location,
--including both the cumulative number of vaccinations and the percentage of the population vaccinated. 

SELECT
    dea.date,  
    dea.continent, 
    dea.location, 
    vac.new_vaccinations,
	SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by vac.Location 
											 Order by dea.Date
											) as RollingPeopleVaccinated,
  
    dea.population,
    (SUM(CONVERT(int, vac.new_vaccinations)) OVER ( PARTITION BY vac.Location
													ORDER BY dea.Date
												  ) / dea.population) * 100 AS PercentageOfRollingPeopleVaccinatedToPopulation

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE vac.new_vaccinations > 0
    AND dea.location NOT IN ('World', 'Africa', 'Asia', 'Europe', 'European Union', 'North America', 'Oceania', 'South America')
 

-- The next query achieves the same result as the previous one, but using a CTE (Common Table Expression).

With PopvsVac (Date, Continent, Location,  New_Vaccinations, RollingPeopleVaccinated , Popullation)
as
(
Select
	dea.date,  
	dea.continent, 
	dea.location, 
	vac.new_vaccinations,
    SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by vac.Location
												 Order by  dea.Date
												 ) as RollingPeopleVaccinated,
	dea.population

From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date
where  new_vaccinations  > 0
		AND   DEA.location NOT IN ('World','Africa', 'Asia', 'Europe','European Union', 'North America', 'Oceania', 'South America')

)
Select *, (RollingPeopleVaccinated/Popullation)*100 as PercentageOfRollingPeopleVaccinatedToPopulation
From PopvsVac
 

--15. Total Female and Male smokers for each country
 
select location ,
   ISNULL(MAX(female_smokers), 'there is no') AS female_smokers,
   ISNULL(MAX(male_smokers), 'there is no') AS male_smokers
  from PortfolioProject..CovidVaccinations 
  GROUP BY location
  order by location 

 

 --16.  The locations that both male and female are smoking " where both female_smokers and male_smokers have non-null values".
 select 
		location ,
		MAX(female_smokers) AS max_female_smokers,
        MAX(male_smokers) AS max_male_smokers
  from PortfolioProject..CovidVaccinations 
  WHERE female_smokers IS NOT NULL and male_smokers IS NOT NULL
  GROUP BY location
order by location 

--How many are these locations ? 
 SELECT COUNT(*) AS number_of_locations
FROM (
  select location 
  from PortfolioProject..CovidVaccinations 
  WHERE female_smokers IS NOT NULL and male_smokers IS NOT NULL
  GROUP BY location
) AS subquery

 --17. The locations that both male and female are not smoking .
select location 
  from PortfolioProject..CovidVaccinations 
  WHERE female_smokers IS  NULL and male_smokers IS  NULL
  GROUP BY location
order by location 

--How many are these locations ? 
 SELECT COUNT(*) AS number_of_locations
FROM (
   select location 
  from PortfolioProject..CovidVaccinations 
  WHERE female_smokers IS  NULL and male_smokers IS  NULL
  GROUP BY location
) AS subquery




--18. The locations with the maximum number of female and male smokers

WITH SmokingData (Location ,max_female_smokers ,  max_male_smokers) AS (
    SELECT 
        location,
        MAX(female_smokers) ,
        MAX(male_smokers)
    FROM PortfolioProject..CovidVaccinations
	WHERE female_smokers IS NOT NULL AND male_smokers IS NOT NULL
    GROUP BY location
)
----JUST TO SEE THE TEMP TBL
--SELECT *
--FROM SmokingData 
--order by location 

SELECT 
    'Female' AS Gender,
    location AS Location,
    max_female_smokers AS max_smokers
FROM SmokingData
WHERE max_female_smokers = (SELECT MAX(max_female_smokers) FROM SmokingData)

UNION ALL

SELECT 
    'Male' AS Gender,
    location AS Location,
    max_male_smokers AS max_smokers
FROM SmokingData
WHERE max_male_smokers = (SELECT MAX(max_male_smokers) FROM SmokingData)

ORDER BY max_smokers DESC;
 
