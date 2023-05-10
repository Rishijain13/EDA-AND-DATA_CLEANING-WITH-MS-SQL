------------------------------------------------EDA ------------------------

--- check the both tables and data

select * 
from CovidDeaths
order by 3 , 4  --- this is for order by 3 and 4 column

select * 
from CovidVaccinations
order by 3 , 4

---  select the data we are going to use
 
 select location, date, total_cases, new_cases, total_deaths, population
 from CovidDeaths
 order by 1,2

 --- looking total cases vs total death as total_death_percetage over total cases happens for india

 select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as total_death_percentage
 from CovidDeaths
 where location like '%india%'
 order by 1,2


 --- looking the total cases vs population
 --- show the % of population got covid
 select location, date, total_cases, population, (total_cases/population)*100 as total_population_got_covid_percentage
 from CovidDeaths
 where location like '%india%'
 order by 1,2

 --- looking at countries highest infection rate compared with population

 select location,  population,max(total_cases) as highest_infection, max((total_cases/population))*100 as population_infection_percentage
 from CovidDeaths
 group by location, population
 order by population_infection_percentage desc




 --- lookimg countries highest death count per population
 --- changing the data type of total_deaths by cast int
 --- remove continent
 select location,max(cast (total_deaths as int)) as total_deaths
 from CovidDeaths
 where continent is not null
 group by location
 order by total_deaths desc

  --- LETS BREAK  THINGS DOWN BY CONTINENT  

 select location,max(cast (total_deaths as int)) as total_deaths
 from CovidDeaths
 where continent is  null
 group by location
 order by total_deaths desc


 --- Global number
 select sum(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as deaths_percentage
 from CovidDeaths
 ---where location like '%india%'
 where continent is  not null
 ---group by date 
 order by 1,2


 ---- join the vaccination and covid table

 select *
 from CovidDeaths dea
 join CovidVaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
 order by 1,2

 --- looking total population and vs vaccinations
 --- using window function for running total
 select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
 sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_vaccinating_count
 from CovidDeaths dea
 join CovidVaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
 where dea.continent is not null
 order by 2, 3


 --- using CTE on rolling_vaccinating_count
 -- no of column in CTE and no of column in select are diff it will givean error
 with popvsvac (continent,location,date,population,new_vaccinations,rolling_vaccinating_count)
 as
 (
 select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
 sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_vaccinating_count
 from CovidDeaths dea
 join CovidVaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
 where dea.continent is not null
 ---order by 2, 3
 )
 select *, (rolling_vaccinating_count/population)*100 as total_percentage_vaccinated
 from popvsvac



 --- TEMP TABLE
 drop table if exists #perpopulationvaccinated
 create table #perpopulationvaccinated
 (
 continent nvarchar(255),
 location nvarchar(255),
 date datetime,
 population numeric,
 new_vaccinations numeric,
 rolling_vaccinating_count numeric
 )

 insert into #perpopulationvaccinated

 select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
 sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_vaccinating_count
 from CovidDeaths dea
 join CovidVaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
 ---where dea.continent is not null
 ---order by 2, 3
 
 select *, (rolling_vaccinating_count/population)*100 as total_percentage_vaccinated
 from #perpopulationvaccinated


 ---- creating view to store data

 create view perpopulationvaccinated as
 select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
 sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_vaccinating_count
 from CovidDeaths dea
 join CovidVaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
 where dea.continent is not null
 ---order by 2, 3

 select *
 from perpopulationvaccinated 



 ----------------------------------------DATA CLEANING -------------------------------

 Select *
From NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


Select saleDateConverted, CONVERT(Date,SaleDate)
From NashvilleHousing


Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

Select *
From NashvilleHousing
--Where PropertyAddress is null
order by ParcelID



Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousing a
JOIN NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null




--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


Select PropertyAddress
From NashvilleHousing
--Where PropertyAddress is null
--order by ParcelID

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address

From NashvilleHousing


ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )


ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))




Select *
From NashvilleHousing





Select OwnerAddress
From NashvilleHousing


Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From NashvilleHousing



ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



Select *
From NashvilleHousing




--------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousing
Group by SoldAsVacant
order by 2




Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From NashvilleHousing


Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END






-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From NashvilleHousing
--order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress



Select *
From NashvilleHousing




---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns



Select *
From NashvilleHousing


ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate




