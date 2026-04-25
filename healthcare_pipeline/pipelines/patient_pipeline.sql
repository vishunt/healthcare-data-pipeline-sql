ALTER PROCEDURE Run_Patient_Pipeline
AS
BEGIN

    --------------------------------------------------
    -- STEP 1: START RUN
    --------------------------------------------------
    DECLARE @RunID INT;

    INSERT INTO Pipeline_Run_Audit (PipelineName, StartTime, Status)
    VALUES ('Patient Pipeline', GETDATE(), 'RUNNING');

    SET @RunID = SCOPE_IDENTITY();

    BEGIN TRY

        --------------------------------------------------
        -- VARIABLES
        --------------------------------------------------
        DECLARE @LastLoadDate DATETIME;
        DECLARE @RowsUpdated INT = 0;
        DECLARE @RowsInserted INT = 0;

        SELECT @LastLoadDate = ISNULL(MAX(LastProcessedDate), '1900-01-01')
        FROM Load_Log;

        --------------------------------------------------
        -- TEMP TABLES FOR ROW TRACKING
        --------------------------------------------------
        CREATE TABLE #UpdatedRows (PatientID INT);
        CREATE TABLE #InsertedRows (PatientID INT);

        --------------------------------------------------
        -- STEP 2: VALIDATION
        --------------------------------------------------
        INSERT INTO Patient_Error_Log (PatientID, ErrorType, ErrorDescription)
        SELECT PatientID, 'INVALID_DOB', 'DOB is in the future'
        FROM Staging_Patients
        WHERE DOB > GETDATE();

        INSERT INTO Patient_Error_Log (PatientID, ErrorType, ErrorDescription)
        SELECT PatientID, 'INVALID_GENDER', 'Invalid gender value'
        FROM Staging_Patients
        WHERE Gender NOT IN ('Male', 'Female', 'Other');

        --------------------------------------------------
        -- STEP 3: SCD TYPE 2 - UPDATE
        --------------------------------------------------
        WITH RankedPatients AS
        (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY PatientID ORDER BY LoadDate DESC) AS rn
            FROM Staging_Patients
            WHERE LoadDate > @LastLoadDate
        )

        UPDATE p
        SET 
            EndDate = GETDATE(),
            IsActive = 0
        OUTPUT inserted.PatientID INTO #UpdatedRows
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
        -- STEP 4: SCD TYPE 2 - INSERT
        --------------------------------------------------
        WITH RankedPatients AS
        (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY PatientID ORDER BY LoadDate DESC) AS rn
            FROM Staging_Patients
            WHERE LoadDate > @LastLoadDate
        )

        INSERT INTO Patients (PatientID, Name, DOB, Gender, EffectiveDate, EndDate, IsActive)
        OUTPUT inserted.PatientID INTO #InsertedRows
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
        -- STEP 5: SUCCESS AUDIT
        --------------------------------------------------
        SELECT @RowsUpdated = COUNT(*) FROM #UpdatedRows;
        SELECT @RowsInserted = COUNT(*) FROM #InsertedRows;

        UPDATE Pipeline_Run_Audit
        SET 
            EndTime = GETDATE(),
            Status = 'SUCCESS',
            RecordsProcessed = @RowsUpdated + @RowsInserted
        WHERE RunID = @RunID;

        --------------------------------------------------
        -- STEP 6: LOAD LOG
        --------------------------------------------------
        INSERT INTO Load_Log (RecordsInserted, LastProcessedDate)
        VALUES (@RowsInserted, GETDATE());

    END TRY

    BEGIN CATCH

        UPDATE Pipeline_Run_Audit
        SET 
            EndTime = GETDATE(),
            Status = 'FAILED',
            ErrorMessage = ERROR_MESSAGE()
        WHERE RunID = @RunID;

    END CATCH

END;