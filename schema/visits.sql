CREATE TABLE Visits
(
    VisitID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT,
    VisitDate DATETIME,
    VisitType VARCHAR(50),
    Status VARCHAR(20)
);