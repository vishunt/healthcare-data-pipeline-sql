CREATE TABLE Patient_Error_Log (
    PatientID INT,
    ErrorType VARCHAR(100),
    ErrorDescription VARCHAR(255),
    ErrorDate DATETIME DEFAULT GETDATE()
);

CREATE TABLE Visit_Error_Log (
    ErrorID INT IDENTITY(1,1),
    VisitID INT,
    PatientID INT,
    ErrorType VARCHAR(100),
    ErrorDescription VARCHAR(255),
    ErrorDate DATETIME DEFAULT GETDATE()
);