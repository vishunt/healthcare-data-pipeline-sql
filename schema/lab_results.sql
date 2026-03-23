CREATE TABLE LabResults
(
    LabID INT IDENTITY(1,1) PRIMARY KEY,
    PatientID INT,
    TestName VARCHAR(100),
    ResultValue VARCHAR(50),
    ResultDate DATETIME
);