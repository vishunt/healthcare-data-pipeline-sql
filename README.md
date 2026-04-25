# Healthcare Data Pipeline (SQL Server)

This project simulates a healthcare data migration and processing system inspired by Epic-style EHR workflows.

# Healthcare Data Pipeline (SQL Server)

## 📌 Overview

This project implements a production-style healthcare data pipeline using SQL Server.
It processes patient and visit data from staging tables into core tables using incremental loading, validation, and historical tracking.

The pipeline is designed to simulate real-world data engineering systems with audit logging, error handling, and referential integrity.

---

## 🧱 Architecture

```
Source → Staging Tables → Validation → Core Tables
                           ↓
                       Error Logs
                           ↓
                       Audit Tables
```

---

## ⚙️ Features

* Incremental data loading using `LoadDate`
* Slowly Changing Dimension (SCD Type 2) implementation
* Data validation and error logging
* Referential integrity enforcement (Patients → Visits)
* Audit framework with pipeline run tracking
* Idempotent pipeline execution (safe to rerun)
* Accurate row tracking using `OUTPUT` clause

---

## 🗂️ Project Structure

```
healthcare-data-pipeline/
│
├── schema/
│   └── create_tables.sql
│
├── pipelines/
│   ├── run_patient_pipeline.sql
│   └── run_visits_pipeline.sql
│
├── audit/
│   └── audit_tables.sql
│
├── validation/
│   └── error_tables.sql
│
├── sample_data/
│   └── insert_sample_data.sql
│
└── README.md
```

---

## 🔄 Pipeline Flow

### 1. Load Data

* Raw data is inserted into staging tables

### 2. Validation

* Invalid records (e.g., invalid patient references) are logged

### 3. SCD Type 2 Processing

* Existing records are expired (`IsActive = 0`)
* New versions are inserted (`IsActive = 1`)

### 4. Dependency Enforcement

* Visits are only processed if the corresponding patient exists

### 5. Audit Tracking

* Each pipeline run logs:

  * Start time
  * End time
  * Status (SUCCESS / FAILED)
  * Records processed

---

## 🧪 How to Run

1. Run schema:

   ```sql
   create_tables.sql
   ```

2. Create audit and validation tables:

   ```sql
   audit_tables.sql
   error_tables.sql
   ```

3. Insert sample data:

   ```sql
   insert_sample_data.sql
   ```

4. Run pipelines:

   ```sql
   EXEC Run_Patient_Pipeline;
   EXEC Run_Visits_Pipeline;
   ```

5. Check results:

   ```sql
   SELECT * FROM Patients;
   SELECT * FROM Visits;
   SELECT * FROM Pipeline_Run_Audit;
   ```

---

## 🧠 Key Learning

Initially, row tracking was implemented using `@@ROWCOUNT`, which produced incorrect results in complex queries.
This was resolved by using the `OUTPUT` clause to accurately capture affected rows during INSERT and UPDATE operations.

---

## 🚀 Summary

This project demonstrates:

* End-to-end pipeline design
* SQL-based data engineering concepts
* Production-style error handling and auditing
* Multi-table dependency management

---
