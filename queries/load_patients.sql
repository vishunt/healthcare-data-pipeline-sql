USE HealthcareLab;

DECLARE @InsertedCount INT;
DECLARE @LastLoadDate DATETIME;

-- Get last processed time
SELECT @LastLoadDate = ISNULL(MAX(LastProcessedDate), '1900-01-01')
FROM Load_Log;

-- 🔥 STEP 1: UPDATE existing records (based on PatientID)
UPDATE p
SET 
    p.Name = s.Name,
    p.DOB = s.DOB,
    p.Gender = s.Gender
FROM Patients p
JOIN Staging_Patients s
    ON p.PatientID = s.PatientID
WHERE s.LoadDate > DATEADD(DAY, -2, @LastLoadDate);

-- 🔥 STEP 2: INSERT only NEW PatientIDs
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
      AND LoadDate > DATEADD(DAY, -2, @LastLoadDate)
)

INSERT INTO Patients (PatientID, Name, DOB, Gender)
SELECT
    r.PatientID,
    r.Name,
    r.DOB,
    r.Gender
FROM RankedPatients r
WHERE r.rn = 1
AND NOT EXISTS (
    SELECT 1
    FROM Patients p
    WHERE p.PatientID = r.PatientID
);

SET @InsertedCount = @@ROWCOUNT;

-- 🔥 STEP 3: LOG
INSERT INTO Load_Log (RecordsInserted, LastProcessedDate)
VALUES (@InsertedCount, GETDATE());
