--query 1
--uisng ROLLUP()
--The first result would give you the total sum of confirmed cases on a continent and country  level, a second one on the country level, 
--and a third one worldwide. we will combine it in one code using rollup(). It gives higher level summary report.

select coalesce(continent,'GrandTotal'),
coalesce(location,'GrandTotal') ,
sum(cast(new_cases as bigint)) as total_cases_count  
from dbo.covid_deaths
--where location like '%states'
where   continent is not  null 
group by ROLLUP(continent,location)
order by continent ,total_cases_count desc 

--Query 2
--Looking at Total cases vs Total Deaths
--shows lilklihood of dying in my country 
select 
Location,date,total_cases,total_deaths,
round(cast(total_deaths as float)/cast(total_cases as float) * 100,2) as Death_percn
from dbo.covid_deaths
where
  continent is not null 
order by 2 desc 

--query 3
--show what % of population died of covid per country
-- dont take sum but max as its a count of deaths per day 
select 
Location,max(cast(total_deaths as int)) as total_deaths_till_date ,
round((max(cast(total_deaths as float))/cast(population as float)) * 100,2) as Death_per_population
from dbo.covid_deaths
where   continent is not null 
--and location like '%india'
group by Location,population
order by 3 desc

--query4
--reporting the above two queries in one query
select Location,population,max(total_cases) as highest_infection_count ,max(total_cases) as highest_infection_count,
max(round(cast(total_cases as float)/cast(population as float) * 100,2)) as Percent_infected_population,
max(round((cast(total_deaths as float)/cast(population as float)) * 100,2)) as Percent_death_population
from dbo.covid_deaths
--where location like '%states'
where   continent is not null 
group by Location,population
order by 4 desc ,5 desc

--query 5
--Showing the countries with the highest Death count per population

select Location ,
max(cast(total_cases as int)) as highest_infection_count,
max(cast(total_deaths as int)) as highest_death_count 
from dbo.covid_deaths
--where location like '%states'
where   continent is not null 
group by Location
order by highest_infection_count desc, highest_death_count desc 

--Query6
--global numbers
-- adding new cases worldwide per day / RUNNING TOTAL
select 
location ,date,new_cases,
sum(new_cases)over(partition by location order by date) as running_total
from  dbo.covid_deaths
where continent is not null
order by 1,2 ASC 

--Query7
--finding delta cases per day , taking new_cases as the base.

select  date, location, new_cases,
      lag(new_cases)over(partition by location order by date asc) as Case_prev_day,
      new_cases - lag(new_cases)over(partition by location order by date asc) as delta_cases_per_day
from  dbo.covid_deaths
where continent is not null
--and location = 'India'
order by 2,1 asc;

--Query8
--Calculating the daily percent change in new cases
--ex if today we have 10 new confirmed cases and yesterday we had five, our percent change is calculated like this: (10–5)/5 * 100 = 100

with daily_cases_differ as (
select location,date,new_cases, lag(new_cases)over(partition by location order by date asc) as prev_case,
case when  lag(new_cases)over(partition by location order by date asc) > 0  then  
cast(new_cases- lag(new_cases)over(partition by location order by date asc) as float) else 0 end as new_cases_diff,
case when  lag(new_cases)over(partition by location order by date asc) > 0  then  
round(cast(new_cases- lag(new_cases)over(partition by location order by date asc) as float)/ 
cast(lag(new_cases)over(partition by location order by date asc) as float) *100,2)
else 0 end as newcases_diff_percent
from  dbo.covid_deaths
where continent is not null)
select *,
case when newcases_diff_percent > 0 then 'increase'
    when newcases_diff_percent < 0 then 'decrease'
    else 'no change' end as trend
from daily_cases_differ
order by 1 ,2 asc;

--Query9
--worst hit countries by yearly and monthly (top 1 contributor)

select * from (
select location, 
datepart(year,date) as year,
datepart(month,date) as month,
sum(new_cases) as total_cases_per_month,
rank()over(partition by datepart(month,date) order by sum(new_cases) desc) as rnk 
from  dbo.covid_deaths
where continent is not null
group by location,datepart(year,date),datepart(month,date)
)a 
where a.rnk =1
order by year asc,month asc;

--Query10
-- as we are working above on raw data, there will be spikes, so we will be smoothing the data on a weekly basis. 5 days
--smooth new cases and new death 
select
location, date, new_cases,
new_deaths,
avg(new_cases)over(partition by location order by date rows between 2 preceding and 2 following) as smooth_cases,
avg(new_deaths)over(partition by location order by date rows between 2 Preceding and 2 following) as smooth_death
from  dbo.covid_deaths
where continent is not null
order by 1,2 asc

--Query11
-- weekly deaths vs weekly_hosp_admissions vs  weekly_icu_admissions Globally


 select 
 Datepart(year,date) as year, 
 Datepart(month,date) as month, 
 Datepart(week,date) as week, 
 sum(cast(new_deaths as int)) as weekly_deaths,
 round(sum(cast(weekly_hosp_admissions as float)),0) as weekly_hosp_admissions, 
 round(sum(cast(weekly_icu_admissions as float)),0) as weekly_icu_admissions
 from  dbo.covid_deaths
where continent is not null
group by Datepart(year,date), Datepart(month,date),Datepart(week,date)
order by 1 ,2,6 desc,5 desc, 4 desc;


--Query13
with ROllingCountVacc  (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
as 
(select dea.continent, dea.location , dea.date , dea.population, vac.new_vaccinations ,
sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location  order by dea.location, dea.date) as RollingPeopleVaccinated
from covid_deaths dea
join 
covid_vaccination vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not  null 
 and vac.new_vaccinations is not null
)
select 
*, round((RollingPeopleVaccinated)/population * 100,2) as Perc_vaccinated_country
from ROllingCountVacc

--Query13
-- above query taking the max only and will show what is the total people vacinated, it should be same as the last no of rolling count per loca

select * ,  round(cast(b.max_vacccinated_people as float)/cast(b.population as float) * 100,2) as Perc_vaccinated_country
 from 
 ( select a.continent, 
 a.location, a.population,
   max(a.RollingPeopleVaccinated) as max_vacccinated_people
  FROM 
  ( select dea.continent, dea.location , dea.date , dea.population, vac.new_vaccinations , 
  sum(cast(vac.new_vaccinations as bigint)) over(partition by dea.location  order by dea.location, dea.date) as RollingPeopleVaccinated 
  from 
  covid_deaths dea 
  join 
   covid_vaccination vac
    on dea.location = vac.location 
    and dea.date = vac.date
     where dea.continent is not  null 
       and vac.new_vaccinations is not null) as a
    group by a.continent, a.location ,a.population ) as b  
  order by 2 desc



--Query14
-- death percentage worldwide
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths 
, round(sum(cast(new_deaths as float))/sum(cast(new_cases as float))* 100,2) as Percnt_death_worldwide
from  dbo.covid_deaths
where continent is not null


--Query15
--7 day rolling avergae new cases and deaths
select
location, date, new_cases,
new_deaths,
avg(new_cases)over(partition by location order by date rows between 6 preceding and current row) as smooth_cases,
avg(new_deaths)over(partition by location order by date rows between 6 preceding and current row) as smooth_death,
sum(new_cases)over(partition by location order by date) as running_total_cases,
sum(new_deaths)over(partition by location order by date) as running_total_deaths
from  dbo.covid_deaths
where continent is not null
order by 1,2 asc