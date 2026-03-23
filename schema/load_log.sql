USE HealthcareLab;
GO

CREATE TABLE Load_Log
(
    LoadID INT IDENTITY(1,1) PRIMARY KEY,
    LoadDate DATETIME DEFAULT GETDATE(),
    RecordsInserted INT
);