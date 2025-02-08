-- Cleaning Data in SQL Queries

SELECT *
FROM Portfolio_Project..NashvilleHousing

---------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format
-- File is already converted and not needed for this project


Select saleDateConverted, CONVERT(Date,SaleDate)
From Portfolio_Project.dbo.NashvilleHousing


Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data

SELECT *
FROM Portfolio_Project..NashvilleHousing
--WHERE PropertyAddress is null
order by ParcelID

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM Portfolio_Project..NashvilleHousing a
JOIN Portfolio_Project..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Portfolio_Project..NashvilleHousing a
JOIN Portfolio_Project..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
WHERE a.PropertyAddress is null


--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress
FROM Portfolio_Project..NashvilleHousing
--WHERE PropertyAddress is null
--order by ParcelID

--Substring and CHARINDEX
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress)-1) as Address,
	SUBSTRING(PropertyAddress,CHARINDEX (',', PropertyAddress)+1, LEN(PropertyAddress)) as Address
FROM Portfolio_Project..NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255)

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX (',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255)

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX (',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT *
FROM Portfolio_Project..NashvilleHousing


SELECT OwnerAddress
FROM Portfolio_Project..NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From Portfolio_Project..NashvilleHousing

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
From Portfolio_Project.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------


--Change 1 to Y and 0 to N
--Change Y and N to Yes and No in "Sold as Vacant" field

Select *
From Portfolio_Project..NashvilleHousing

ALTER TABLE NashvilleHousing
ALTER COLUMN SoldAsVacant Nvarchar(50)

Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 1 THEN 'Yes'
	   When SoldAsVacant = 0 THEN 'No'
	   ELSE SoldAsVacant
	   END


SELECT Distinct(SoldASVacant), Count(SoldAsVacant)
FROM Portfolio_Project..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2




Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From Portfolio_Project..NashvilleHousing


-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference
	ORDER BY UniqueID) row_num

From Portfolio_Project.dbo.NashvilleHousing
--ORDER BY ParcelID
)
Select *
--DELETE
From RowNumCTE
WHERE row_num > 1
Order by PropertyAddress

SELECT *
From Portfolio_Project.dbo.NashvilleHousing

---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns

Select *
From Portfolio_Project.dbo.NashvilleHousing


ALTER TABLE Portfolio_Project.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate


-- REAL WORLD DO NOT ALTER RAW DATA --USE TEMP TABLES