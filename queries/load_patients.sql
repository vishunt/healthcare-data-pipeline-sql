USE HealthcareLab;
GO

DECLARE @InsertedCount INT;

INSERT INTO Patients (Name, DOB, Gender)
SELECT DISTINCT
    Name,
    DOB,
    Gender
FROM Staging_Patients
WHERE DOB IS NOT NULL;

SET @InsertedCount = @@ROWCOUNT;

INSERT INTO Load_Log (RecordsInserted)
VALUES (@InsertedCount);