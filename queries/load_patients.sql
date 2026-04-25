USE HealthcareLab;

DECLARE @RunID INT;
DECLARE @RowsUpdated INT = 0;
DECLARE @RowsInserted INT = 0;

INSERT INTO Pipeline_Run_Audit (PipelineName, StartTime, Status)
VALUES ('Patient Pipeline', GETDATE(), 'RUNNING');

SET @RunID = SCOPE_IDENTITY();

BEGIN TRY

DECLARE @LastLoadDate DATETIME;

SELECT @LastLoadDate = ISNULL(MAX(LastProcessedDate), '1900-01-01')
FROM Load_Log;

--------------------------------------------------
-- STEP 0: LOG INVALID RECORDS
--------------------------------------------------

-- Invalid DOB
INSERT INTO Patient_Error_Log (PatientID, ErrorType, ErrorDescription)
SELECT PatientID, 'INVALID_DOB', 'DOB is in the future'
FROM Staging_Patients
WHERE DOB > GETDATE();

-- Invalid Gender
INSERT INTO Patient_Error_Log (PatientID, ErrorType, ErrorDescription)
SELECT PatientID, 'INVALID_GENDER', 'Invalid gender value'
FROM Staging_Patients
WHERE Gender NOT IN ('Male', 'Female', 'Other');

--------------------------------------------------
-- STEP 1: EXPIRE OLD RECORDS (SCD TYPE 2)
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
    WHERE DOB <= GETDATE()
      AND Gender IN ('Male', 'Female', 'Other')
      AND PatientID IS NOT NULL
      AND LoadDate > @LastLoadDate
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
SET @RowsUpdated = @@ROWCOUNT;
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
    WHERE DOB <= GETDATE()
      AND Gender IN ('Male', 'Female', 'Other')
      AND PatientID IS NOT NULL
      AND LoadDate > @LastLoadDate
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
SET @RowsInserted = @@ROWCOUNT;
--------------------------------------------------
-- STEP 3: LOG PIPELINE RUN
--------------------------------------------------

INSERT INTO Load_Log (RecordsInserted, LastProcessedDate)
VALUES (0, GETDATE());

UPDATE Pipeline_Run_Audit
SET 
    EndTime = GETDATE(),
    Status = 'SUCCESS',
    RecordsProcessed = @RowsUpdated + @RowsInserted
WHERE RunID = @RunID;

END TRY
BEGIN CATCH

    UPDATE Pipeline_Run_Audit
    SET 
        EndTime = GETDATE(),
        Status = 'FAILED',
        ErrorMessage = ERROR_MESSAGE()
    WHERE RunID = @RunID;

END CATCH;