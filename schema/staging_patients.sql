USE HealthcareLab;
GO

CREATE TABLE Staging_Patients
(
    PatientID INT,
    Name VARCHAR(100),
    DOB DATE,
    Gender VARCHAR(10),
    LoadDate DATETIME DEFAULT GETDATE()
);