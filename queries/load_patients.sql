USE HealthcareLab;

DECLARE @LastLoadDate DATETIME;

SELECT @LastLoadDate = ISNULL(MAX(LastProcessedDate), '1900-01-01')
FROM Load_Log;

--------------------------------------------------
-- STEP 1: EXPIRE OLD RECORDS
--------------------------------------------------
WITH RankedPatients AS
(
    SELECT
        PatientID,
        Name,
        DOB,
        Gender,
        ROW_NUMBER() OVER (
            PARTITION BY PatientID
            ORDER BY LoadDate DESC
        ) AS rn
    FROM Staging_Patients
)

UPDATE p
SET 
    EndDate = GETDATE(),
    IsActive = 0
FROM Patients p
JOIN RankedPatients r
    ON p.PatientID = r.PatientID
WHERE p.IsActive = 1
AND r.rn = 1
AND (
    p.Name <> r.Name OR
    p.DOB <> r.DOB OR
    p.Gender <> r.Gender
);

--------------------------------------------------
-- STEP 2: INSERT NEW VERSION
--------------------------------------------------
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
)

INSERT INTO Patients (PatientID, Name, DOB, Gender, EffectiveDate, EndDate, IsActive)
SELECT
    r.PatientID,
    r.Name,
    r.DOB,
    r.Gender,
    GETDATE(),
    NULL,
    1
FROM RankedPatients r
WHERE r.rn = 1
AND NOT EXISTS (
    SELECT 1
    FROM Patients p
    WHERE p.PatientID = r.PatientID
      AND p.IsActive = 1
);
--------------------------------------------------
-- STEP 3: LOG
--------------------------------------------------
INSERT INTO Load_Log (RecordsInserted, LastProcessedDate)
VALUES (0, GETDATE());
