USE HealthcareLab;
GO

INSERT INTO Staging_Patients (PatientID, Name, DOB, Gender)
VALUES
(101, 'John Doe', '1990-05-10', 'Male'),
(102, 'Jane Smith', '1985-08-22', 'Female'),
(103, 'Invalid DOB', NULL, 'Male'),
(104, 'Duplicate Test', '1992-01-01', 'Male'),
(104, 'Duplicate Test', '1992-01-01', 'Male');