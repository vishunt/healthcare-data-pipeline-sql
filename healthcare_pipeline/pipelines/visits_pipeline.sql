ALTER PROCEDURE Run_Visits_Pipeline
AS
BEGIN

    --------------------------------------------------
    -- STEP 1: START RUN
    --------------------------------------------------
    DECLARE @RunID INT;

    INSERT INTO Pipeline_Run_Audit (PipelineName, StartTime, Status)
    VALUES ('Visits Pipeline', GETDATE(), 'RUNNING');

    SET @RunID = SCOPE_IDENTITY();

    BEGIN TRY

        --------------------------------------------------
        -- TEMP TABLES
        --------------------------------------------------
        CREATE TABLE #UpdatedRows (VisitID INT);
        CREATE TABLE #InsertedRows (VisitID INT);

        --------------------------------------------------
        -- STEP 2: SCD UPDATE
        --------------------------------------------------
        WITH RankedVisits AS
        (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY VisitID ORDER BY LoadDate DESC) AS rn
            FROM Staging_Visits
        )

        UPDATE v
        SET 
            EndDate = GETDATE(),
            IsActive = 0
        OUTPUT inserted.VisitID INTO #UpdatedRows
        FROM Visits v
        JOIN RankedVisits r
            ON v.VisitID = r.VisitID
        WHERE v.IsActive = 1
        AND r.rn = 1
        AND (
            v.VisitDate <> r.VisitDate OR
            v.Diagnosis <> r.Diagnosis
        );

        --------------------------------------------------
        -- STEP 3: LOG INVALID DATA
        --------------------------------------------------
        INSERT INTO Visit_Error_Log (VisitID, PatientID, ErrorType, ErrorDescription)
        SELECT
            s.VisitID,
            s.PatientID,
            'INVALID_PATIENT',
            'Patient does not exist or is not active'
        FROM Staging_Visits s
        WHERE NOT EXISTS (
            SELECT 1
            FROM Patients p
            WHERE p.PatientID = s.PatientID
              AND p.IsActive = 1
        )
        AND NOT EXISTS (
            SELECT 1
            FROM Visit_Error_Log e
            WHERE e.VisitID = s.VisitID
              AND e.PatientID = s.PatientID
        );

        --------------------------------------------------
        -- STEP 4: INSERT VALID DATA
        --------------------------------------------------
        WITH RankedVisits AS
        (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY VisitID ORDER BY LoadDate DESC) AS rn
            FROM Staging_Visits
        )

        INSERT INTO Visits (VisitID, PatientID, VisitDate, Diagnosis, EffectiveDate, EndDate, IsActive)
        OUTPUT inserted.VisitID INTO #InsertedRows
        SELECT
            r.VisitID,
            r.PatientID,
            r.VisitDate,
            r.Diagnosis,
            GETDATE(),
            NULL,
            1
        FROM RankedVisits r
        WHERE r.rn = 1
        AND NOT EXISTS (
            SELECT 1
            FROM Visits v
            WHERE v.VisitID = r.VisitID
              AND v.IsActive = 1
        )
        AND EXISTS (
            SELECT 1
            FROM Patients p
            WHERE p.PatientID = r.PatientID
              AND p.IsActive = 1
        );

        --------------------------------------------------
        -- STEP 5: SUCCESS AUDIT
        --------------------------------------------------
        DECLARE @RowsUpdated INT;
        DECLARE @RowsInserted INT;

        SELECT @RowsUpdated = COUNT(*) FROM #UpdatedRows;
        SELECT @RowsInserted = COUNT(*) FROM #InsertedRows;

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

    END CATCH

END;