-- MS SQL Server
-- T-SQL

SELECT *
FROM NashvilleHousing


------------------------------------------------------------------------------------------------------------------------------
-- CLEANING SaleDate COLUMN TO REMOVE THE TIME PART GIVING NO USEFUL INFORMATION
-- FOLLOWING APPROACH USUALLY DOES NOT WORK BCZ SQL IMPLICITLY CONVERTS SaleDate BACK TO DATETIME

UPDATE NashvilleHousing
SET SaleDate= CONVERT(DATE, SaleDate)

SELECT SaleDate, CONVERT(DATE, SaleDate)
FROM NashvilleHousing

-- THERE ARE TWO OTHER WAYS:
ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate DATE;

ALTER TABLE NashvilleHousing
ADD SaleDateConverted DATE;

UPDATE NashvilleHousing 
SET SaleDateConverted= CONVERT(DATE, SaleDate)




------------------------------------------------------------------------------------------------------------------------------
-- POPULATING PROPERTY ADDRESS

SELECT *
FROM NashvilleHousing
ORDER BY ParcelID

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress
FROM NashvilleHousing A
JOIN NashvilleHousing B
     ON A.ParcelID= B.ParcelID
     AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL

UPDATE A
SET 
PropertyAddress = ISNULL(A.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousing A
JOIN NashvilleHousing B
     ON A.ParcelID= B.ParcelID
     AND A.[UniqueID ] <> B.[UniqueID ]
WHERE A.PropertyAddress IS NULL




------------------------------------------------------------------------------------------------------------------------------
-- BREAKING OUT ADDRESS INTO SUB-COLUMNS

SELECT PropertyAddress
FROM NashvilleHousing

SELECT 
SUBSTRING(PropertyAddress, 1,CHARINDEX(',',PropertyAddress)-1) AS StreetAddress
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS Town
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertyAddressStreet NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertyAddressStreet= SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertyAddressCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertyAddressCity= SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

SELECT * 
FROM NashvilleHousing





------------------------------------------------------------------------------------------------------------------------------
-- SPLITTING OWNER ADDRESS INTO SUB-COLUMNS USING A SIMPLER APPROACH

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3),
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerAddressStreet NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerAddressStreet= PARSENAME(REPLACE(OwnerAddress,',','.'),3)

ALTER TABLE NashvilleHousing
ADD OwnerAddressCity NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerAddressCity= PARSENAME(REPLACE(OwnerAddress,',','.'),2)


ALTER TABLE NashvilleHousing
ADD OwnerAddressState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerAddressState= PARSENAME(REPLACE(OwnerAddress,',','.'),1)





------------------------------------------------------------------------------------------------------------------------------
-- DATA STANDARDIZATION: CONVERTING 'Y' AND 'N' IN SoldAsVacant COLUMN INTO 'YES' AND 'NO'

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
       WHEN SoldAsVacant = 'N' THEN 'No'
       ELSE SoldAsVacant
       END




------------------------------------------------------------------------------------------------------------------------------
--  REMOVE DUPLICATES

WITH NoDuplicatesCTE
AS
(
SELECT *,
       ROW_NUMBER() OVER(
       PARTITION BY ParcelID,
                    PropertyAddress,
                    SaleDate,
                    SalePrice,
                    LegalReference
                    ORDER BY UniqueID
       ) row_num
FROM NashvilleHousing
)
DELETE
FROM NoDuplicatesCTE
WHERE row_num > 1
--ORDER BY PropertyAddress




------------------------------------------------------------------------------------------------------------------------------
-- FEATURE SELECTION: REMOVING UNUSED COLUMNS

SELECT * 
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict

