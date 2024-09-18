--"To access the DataCleaning database, download the Excel file titled 'Housing Data.xlsx'."

--1. Data Type Conversion to change date formats.
select SaleDate , CONVERT(date , SaleDate) 
from DataCleaning.dbo.HousingData

alter table DataCleaning.dbo.HousingData
add SaleDateConverted date
 
update  DataCleaning.dbo.HousingData
set SaleDateConverted = CONVERT(date , SaleDate) 


--2. Database Schema Optimization: Removing unused columns
alter table DataCleaning.dbo.HousingData 
drop column SaleDate , TaxDistrict


--3. Data Quality Improvement: Populating missing data, Populate property address data using Self Joins: Joining a table to itself to fill in missing data.
select  a.ParcelID ,a.PropertyAddress ,   b.ParcelID , b.PropertyAddress  , ISNULL(a.PropertyAddress ,  b.PropertyAddress)
from DataCleaning.dbo.HousingData a 
join DataCleaning.dbo.HousingData b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is  null 

update a
set PropertyAddress = ISNULL(a.PropertyAddress ,  b.PropertyAddress)
from DataCleaning.dbo.HousingData a 
join DataCleaning.dbo.HousingData b
on a.ParcelID = b.ParcelID
and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is  null


--4. Data Normalization:  to reduce redundancy.
--   Splitting compound fields (PropertyAddress) into separate columns (Address, Cit, State) using SUBSTRING, CHARINDEX, and PARSENAME.
select PropertyAddress
from DataCleaning.dbo.HousingData

select PropertyAddress ,  SUBSTRING(PropertyAddress,1, CHARINDEX(',' , PropertyAddress )-1)
from DataCleaning.dbo.HousingData

select PropertyAddress ,  SUBSTRING(PropertyAddress,CHARINDEX(',' , PropertyAddress )+1, LEN(PropertyAddress))
from DataCleaning.dbo.HousingData

alter table DataCleaning.dbo.HousingData
add PropertySplitAddress nvarchar(255),
	PropertySplitCity nvarchar(255);
 
update DataCleaning.dbo.HousingData
set PropertySplitAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',' , PropertyAddress )-1) , 
	PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',' , PropertyAddress )+1, LEN(PropertyAddress));

select PropertyAddress, PropertySplitAddress , PropertySplitCity 
from DataCleaning.dbo.HousingData

----------------another solution to split-----------------
select OwnerAddress , PARSENAME(Replace(OwnerAddress, ',' , '.') , 3)
from DataCleaning.dbo.HousingData

alter table DataCleaning.dbo.HousingData
add OwnerSplitAddess nvarchar(255) ,
	OwnerSplitCity nvarchar(255) ,
	OwnerSplitState nvarchar(255)  ;

update DataCleaning.dbo.HousingData
set OwnerSplitAddess = PARSENAME(Replace(OwnerAddress, ',' , '.') , 3) ,
	OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',' , '.') , 2) , 
	OwnerSplitState =  PARSENAME(Replace(OwnerAddress, ',' , '.') , 1)

select *
from DataCleaning.dbo.HousingData

--5. Data Standardization: Converting 'Y'/'N' to 'YES'/'NO' using CASE statements for conditional updates.
update DataCleaning.dbo.HousingData
set SoldAsVacant = case when SoldAsVacant='N' then 'NO'
							when SoldAsVacant='Y' then 'YES'
							ELSE SoldAsVacant
							END

--6. Data Quality Improvement: Removing duplicates "using DELETE in combination with a CTE to remove duplicate rows".
with row_num_cte as 
(
select *, ROW_NUMBER() over ( partition by ParcelID , PropertyAddress , SalePrice, SaleDate, LegalReference order by uniqueID) as row_num
from DataCleaning.dbo.HousingData 
)
delete
from row_num_cte
where row_num > 1 


		
