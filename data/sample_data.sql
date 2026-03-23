INSERT INTO Patients (Name, DOB, Gender)
VALUES 
('John Doe', '1990-05-10', 'Male'),
('Jane Smith', '1985-08-22', 'Female');

INSERT INTO Visits (PatientID, VisitDate, VisitType, Status)
VALUES
(1, GETDATE(), 'Outpatient', 'Completed'),
(2, GETDATE(), 'Emergency', 'Pending');

INSERT INTO LabResults (PatientID, TestName, ResultValue, ResultDate)
VALUES
(1, 'Blood Test', 'Normal', GETDATE()),
(2, 'X-Ray', 'Clear', GETDATE());
