use PortfiolioCovidProject

/*Basic queries*/

select *
from CovidDeaths
where continent is not null
order by 3,4

select location, date, total_cases, new_cases,
		total_deaths, population
from CovidDeaths
order by 1,2


/*Showing death percentage out of all covid cases
  for a specific country*/

select location, date, total_cases,	total_deaths,
(total_deaths/total_cases)*100 as death_percentage
from CovidDeaths
where location like '%states%'
order by 1,2

/*Showing total infection percentage out of population for a specific
  country*/

select location, date,	population, total_cases,
(total_cases/population)*100 as death_percentage
from CovidDeaths
where location like '%states%'
order by 1,2

/* Showing countries with the highest infection rate
  compared to population*/
  
select location, population, max(total_cases) as highestinfectioncount,
max((total_cases/population))*100 as percentinfected
from CovidDeaths
group by location, population
order by percentinfected desc

/* Showing countries with highest death rate*/

select location, max(cast(total_deaths as int)) as deathcount
from CovidDeaths
where continent is not null
group by location, population
order by deathcount desc

/* Showing continents with highest death rate*/

select location, max(cast(total_deaths as int)) as deathcount
from CovidDeaths
where continent is null
group by location
order by deathcount desc


/* Showing vaccinated percentage out of population by country using 
  a temp table*/
create table #percentvaccinated
(continent nvarchar(255), 
 location nvarchar(255), 
 date datetime, 
 population numeric, 
 new_vaccinations numeric, 
 rollingvaccinatedsum numeric)
insert into #percentvaccinated
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
		sum(cast(CV.new_vaccinations as int)) over 
		(partition by CV.location order by CD.location, CD.date) as rollingvaccinatedsum
from CovidDeaths CD
join CovidVaccinations CV
on CD.location = CV.location
and CD.date = CV.date
where CD.continent is not null

select *, (rollingvaccinatedsum/population*100) as percentage from #percentvaccinated


/* Showing vaccinated percentage out of population by country using cte*/
with percentvaccinated (continent, location, date, population, new_vaccinations, rollingvaccinatedsum)
as (select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
			sum(cast(CV.new_vaccinations as int)) over 
			(partition by CV.location order by CD.location, CD.date) as rollingvaccinatedsum
	from CovidDeaths CD
	join CovidVaccinations CV
	on CD.location = CV.location
	and CD.date = CV.date
	where CD.continent is not null)
select *, (rollingvaccinatedsum/population*100) as percentage from percentvaccinated


/*creating a view to store data in for later visualization*/
create view percentvaccinated as
select CD.continent, CD.location, CD.date, CD.population, CV.new_vaccinations,
		sum(cast(CV.new_vaccinations as int)) over 
		(partition by CV.location order by CD.location, CD.date) as rollingvaccinatedsum
from CovidDeaths CD
join CovidVaccinations CV
on CD.location = CV.location
and CD.date = CV.date
where CD.continent is not null

select * from percentvaccinated


/*Queries for Tableau visualisation*/
--1
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null 
order by 1,2

--2
Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

--3
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

--4
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc
