CREATE TABLE Patients (
    PatientID INT,
    Name VARCHAR(100),
    DOB DATE,
    Gender VARCHAR(10),
    EffectiveDate DATETIME,
    EndDate DATETIME,
    IsActive BIT
);

CREATE TABLE Visits (
    VisitID INT,
    PatientID INT,
    VisitDate DATE,
    Diagnosis VARCHAR(100),
    EffectiveDate DATETIME,
    EndDate DATETIME,
    IsActive BIT
);

CREATE TABLE Staging_Patients (
    PatientID INT,
    Name VARCHAR(100),
    DOB DATE,
    Gender VARCHAR(10),
    LoadDate DATETIME
);

CREATE TABLE Staging_Visits (
    VisitID INT,
    PatientID INT,
    VisitDate DATE,
    Diagnosis VARCHAR(100),
    LoadDate DATETIME
);