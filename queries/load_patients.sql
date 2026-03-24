USE HealthcareLab;
GO

DECLARE @InsertedCount INT;

WITH RankedPatients AS
(
    SELECT
        PatientID,
        Name,
        DOB,
        Gender,
        LoadDate,
        ROW_NUMBER() OVER (
            PARTITION BY PatientID
            ORDER BY LoadDate DESC
        ) AS rn
    FROM Staging_Patients
    WHERE DOB IS NOT NULL
)

INSERT INTO Patients (Name, DOB, Gender)
SELECT
    r.Name,
    r.DOB,
    r.Gender
FROM RankedPatients r
WHERE r.rn = 1
AND NOT EXISTS (
    SELECT 1
    FROM Patients p
    WHERE p.Name = r.Name
      AND p.DOB = r.DOB
);

SET @InsertedCount = @@ROWCOUNT;

INSERT INTO Load_Log (RecordsInserted)
VALUES (@InsertedCount);