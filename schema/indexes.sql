USE HealthcareLab;
GO

-- Index for incremental load filtering
CREATE NONCLUSTERED INDEX IX_Staging_LoadDate
ON Staging_Patients (LoadDate);

-- Improved index for filtering + partitioning
CREATE NONCLUSTERED INDEX IX_Staging_LoadDate_PatientID
ON Staging_Patients (LoadDate, PatientID);

-- Index for fast lookup in NOT EXISTS
CREATE NONCLUSTERED INDEX IX_Patients_Name_DOB
ON Patients (Name, DOB);

-- Improves incremental filtering (LoadDate)
-- Improves dedup partitioning (PatientID)
-- Improves NOT EXISTS lookup (Name, DOB)