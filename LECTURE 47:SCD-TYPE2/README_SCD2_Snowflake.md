# 🧠 Snowflake SCD Type-2 Automation — Employee Dimension Pipeline

## 📘 Overview

This project implements a **fully automated, production-grade Slowly Changing Dimension Type-2 (SCD2)** process in **Snowflake** using a **JavaScript Stored Procedure**.

It tracks all historical changes in **employee attributes** (Name, Email, Phone, Address, Company, Experience) and maintains both **current and historical records** in the curated layer.

Designed for **real-time ingestion** from S3 → Snowpipe → Snowflake, with complete **data lineage**, **audit logging**, and **email alerts** on job failures.

---

## ⚙️ Architecture Flow

```mermaid
flowchart TD
    A[S3 CSV Files] --> B[Snowpipe / External Stage]
    B --> C[STAGING.RAW_EMPLOYEE]
    C --> D[SP_PROCESS_EMPLOYEE_DIM()]
    D --> E[CURATED.EMPLOYEE_DIM (SCD2 Table)]
    D --> F[AUDIT.PIPELINE_JOB_LOG]
    D --> G[AUDIT.ERROR_LOG]
    D --> H[EMAIL_INT → Email Notification]
```

---

## 🧩 Key Features

- 🧱 **Implements SCD Type-2 Logic**
  - Tracks historical changes across all business attributes.
  - Automatically expires and inserts records when changes are detected.

- 🧮 **Change Detection Using Hash**
  - Uses `MD5()` of normalized attributes to detect *any* data change.
  - Case-insensitive and whitespace-tolerant comparisons.

- 🧰 **Auto Schema Healing**
  - Adds missing audit and lineage columns dynamically:
    - `SOURCE_FILE`, `INGESTED_AT` in STAGING
    - `SRC_HASH`, `BATCH_ID` in CURATED

- 🔁 **Deterministic Deduplication**
  - Retains only the most recent record per EID:
    ```sql
    ROW_NUMBER() OVER (PARTITION BY EID ORDER BY INGESTED_AT DESC, SOURCE_FILE DESC)
    ```

- 🧾 **Audit & Monitoring**
  - Inserts detailed logs into:
    - `AUDIT.PIPELINE_JOB_LOG`
    - `AUDIT.ERROR_LOG`
  - Captures job metadata: start time, duration, inserted/expired row counts.

- 📧 **Automated Email Notification**
  - Sends best-effort email alerts via Snowflake `EMAIL_INT` notification integration.
  - Recipient list is managed via `AUDIT.EMAIL_RECIPIENTS`.

- 💪 **Fully Idempotent**
  - Safe to re-run; ignores duplicates and re-ingestions of same batch.

---

## 🧱 Table Structures

### 🗂️ Staging Table
```sql
CREATE OR REPLACE TABLE STAGING.RAW_EMPLOYEE (
  EID STRING,
  EName STRING,
  Email STRING,
  PhoneNo STRING,
  Address STRING,
  CompanyName STRING,
  Exp STRING,
  SOURCE_FILE STRING,
  INGESTED_AT TIMESTAMP_NTZ
);
```

### 🗃️ Curated Table (SCD2)
```sql
CREATE OR REPLACE TABLE CURATED.EMPLOYEE_DIM (
  EID STRING,
  EName STRING,
  Email STRING,
  PhoneNo STRING,
  Address STRING,
  CompanyName STRING,
  Exp STRING,
  Start_Date DATE DEFAULT CURRENT_DATE,
  End_Date DATE,
  Is_Current BOOLEAN DEFAULT TRUE,
  SRC_HASH STRING,
  BATCH_ID STRING
);
```

### 🧾 Audit Tables
```sql
CREATE OR REPLACE TABLE AUDIT.PIPELINE_JOB_LOG (
  JOB_ID STRING,
  JOB_NAME STRING,
  FILE_NAME STRING,
  STATUS STRING,
  DETAILS STRING,
  RUN_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE AUDIT.ERROR_LOG (
  FILE_NAME STRING,
  ERROR_DETAILS STRING,
  CREATED_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE AUDIT.EMAIL_RECIPIENTS (
  RECIPIENT_NAME STRING,
  RECIPIENT_EMAIL STRING
);
```

---

## 🧠 Stored Procedure: `SP_PROCESS_EMPLOYEE_DIM`

### 🔍 Core Responsibilities
- Validates and enriches staging schema.
- Deduplicates data (latest record per employee).
- Detects data changes using **SRC_HASH**.
- Performs **SCD2 merge**:
  - **Expire** old records (`Is_Current = FALSE, End_Date = CURRENT_DATE()`).
  - **Insert** new current record (`Is_Current = TRUE, Start_Date = CURRENT_DATE()`).
- Updates **audit logs** with metrics (inserted, expired, duplicates, duration).
- Triggers **email alerts** on failure.

### 🧮 Change Detection Logic
```sql
MD5(
  LOWER(TRIM(EName)) || '||' ||
  LOWER(TRIM(Email)) || '||' ||
  LOWER(TRIM(PhoneNo)) || '||' ||
  LOWER(TRIM(Address)) || '||' ||
  LOWER(TRIM(CompanyName)) || '||' ||
  LOWER(TRIM(Exp))
) AS SRC_HASH
```

---

## 🧠 Key Business Benefits

- 🔄 Maintains complete employee history for analytics & compliance.  
- 🕓 Enables point-in-time queries (“what was the employee data on any given date?”).  
- 🔍 Ensures auditability & traceability with job logs and hashes.  
- ⚙️ Fully automated; ideal for daily ingestion via Snowpipe or Airflow.  
- 🧾 Supports enterprise-grade **Data Governance & Data Lineage**.  

---

## 👨‍💻 Author
**AnalyticsWithAnand**  
🎓 *Snowflake Super Data Hero 2025 | Senior Data Engineer @ Tiger Analytics*  
📺 [YouTube: AnalyticsWithAnand](https://www.youtube.com/@analyticswithanand)  
💼 *“Let the Data Do the Talking...”*
