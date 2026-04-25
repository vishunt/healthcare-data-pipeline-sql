CREATE TABLE Pipeline_Run_Audit (
    RunID INT IDENTITY(1,1),
    PipelineName VARCHAR(100),
    StartTime DATETIME,
    EndTime DATETIME,
    Status VARCHAR(20),
    RecordsProcessed INT,
    ErrorMessage VARCHAR(MAX)
);

CREATE TABLE Load_Log (
    RecordsInserted INT,
    LastProcessedDate DATETIME
);