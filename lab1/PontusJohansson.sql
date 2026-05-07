/* Lab 1 - MoonMission
av Pontus Johansson
AIMM25G */
-- SELECT * FROM MoonMissions;
/* Insure that the database is correct */
USE everyloop

/*SuccessfulMissions table setup */
-- IF TABLE EXISTS DROP IT!
DROP TABLE IF EXISTS SuccessfulMissions
-- G 
SELECT
	Spacecraft, 
	[Launch date], 
	[Carrier rocket], 
	Operator, 
	[Mission type]
INTO SuccessfulMissions
FROM MoonMissions
WHERE Outcome = 'Successful';

GO

UPDATE SuccessfulMissions
SET Operator = TRIM(Operator)

GO
-- VG

UPDATE SuccessfulMissions
SET Spacecraft = TRIM(LEFT(Spacecraft, CHARINDEX('(', SpaceCraft) - 1))
WHERE CHARINDEX('(', Spacecraft) > 0;

GO

SELECT Operator, 
	[Mission type],
	COUNT(*) AS [Mission Count]
FROM SuccessfulMissions
GROUP BY Operator, 
	[Mission type]
HAVING COUNT(*) > 1
ORDER BY Operator, 
	[Mission type]

GO
/*New Users table setup */
-- G
-- IF TABLE EXISTS DROP IT!
DROP TABLE IF EXISTS NewUsers;
SELECT * FROM Users;
SELECT
	ID, 
	UserName,
	[Password],
	CONCAT(FirstName, ' ', LastName) AS [Name], 
	CASE
        WHEN SUBSTRING(RIGHT(ID, 2), 1, 1) % 2 = 0 then 'Female'
        ELSE 'Male'
    END AS 'Gender', 
	Email, 
	Phone
INTO NewUsers
FROM Users;

GO
/* Check for duplicates */
SELECT 
    UserName,
    COUNT(UserName) as Duplicates
FROM NewUsers
GROUP BY UserName
HAVING COUNT(UserName) > 1;

/* Find columns for dublicates */

SELECT *
FROM NewUsers
WHERE UserName IN (
	SELECT UserName
	FROM NewUsers
	GROUP BY UserName
	HAVING COUNT(UserName) > 1
)
ORDER BY UserName;

/* Assign new unique IDs to the duplicates with Common Table Expression (CTE),
	So the duplicates get unique usernames with 1,2,3,... 
	Since I didn't include FirstName & LastName in NewUsers I took it from the Users table */

WITH CTE AS (
    SELECT 
        ID,
        UserName,
        NewUName =
            LOWER(
                LEFT(TRANSLATE(FirstName, 'åäöÅÄÖ', 'aaoAAO'), 3) +
                LEFT(TRANSLATE(LastName, 'åäöÅÄÖ', 'aaoAAO'), 3)
            ),
        RowNum = ROW_NUMBER() OVER (
            PARTITION BY 
                LOWER(
                    LEFT(TRANSLATE(FirstName, 'åäöÅÄÖ', 'aaoAAO'), 3) +
                    LEFT(TRANSLATE(LastName, 'åäöÅÄÖ', 'aaoAAO'), 3)
                )
            ORDER BY ID
        )
    FROM Users
)
UPDATE N
SET UserName =
    CASE 
        WHEN C.RowNum = 1 THEN C.NewUName
        ELSE LEFT(C.NewUName, 5) + CAST(C.RowNum - 1 AS NVARCHAR(1))
    END
FROM NewUsers N
JOIN CTE C ON N.ID = C.ID;

GO

DELETE 
FROM NewUsers
WHERE CAST(SUBSTRING(ID, 1, 1) AS INT) < 7 AND Gender = 'Female';

GO 

INSERT INTO NewUsers(
	ID,
	UserName,
	[Password], 
	[Name],
	Gender, 
	Email, 
	Phone
)
VALUES (
	'681029-7943', 
	'piajul', 
	'gor14gy4fxg7f54ots0z8rcu37uk8ohg', 
	'Pia Julkunen',
	'Female', 
	'pia.julkunen@gmail.com',
	'0765-341050'
);

GO
-- VG

SELECT Gender, 
	AVG(
		FLOOR(
			(DATEDIFF(day, CONVERT(date, LEFT(ID, 6)), GETDATE()))/ 365)
		) AS [Average age]
	
FROM NewUsers
GROUP BY Gender;

/* Company(Joins) */
GO
-- G

SELECT prod.Id, 
	prod.ProductName,
	supp.CompanyName, 
	categ.CategoryName
FROM company.products prod
	JOIN company.suppliers supp ON prod.SupplierId = supp.Id
	JOIN company.categories categ ON prod.CategoryId = categ.Id;
GO

SELECT
	r.Id, 
	r.RegionDescription, 
	COUNT(empte.EmployeeId) as NumberOfEmployees
FROM company.regions r
	JOIN company.territories te ON r.Id = te.RegionId
	JOIN company.employee_territory empte ON te.Id = empte.TerritoryId
GROUP BY
	r.Id,
	r.RegionDescription;

-- VG

SELECT emp1.Id,
	CONCAT(emp1.TitleOfCourtesy, ' ', emp1.FirstName, ' ', emp1.LastName) AS [Name], 
	CASE
		WHEN emp2.Id IS NULL
		THEN 'Nobody!'
		ELSE CONCAT(emp2.TitleOfCourtesy, ' ', emp2.FirstName, ' ', emp2.LastName)
	END AS [Reports To]

FROM company.employees emp1
	LEFT OUTER JOIN company.employees emp2 ON emp2.Id = emp1.ReportsTo