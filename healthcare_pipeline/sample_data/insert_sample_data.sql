INSERT INTO Staging_Patients VALUES
(101, 'John Doe', '1990-05-10', 'Male', GETDATE());

INSERT INTO Staging_Visits VALUES
(1, 101, '2024-01-10', 'Flu', GETDATE());