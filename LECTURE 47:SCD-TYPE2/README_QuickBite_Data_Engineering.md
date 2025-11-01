# 🍴 QuickBite — End-to-End Food Delivery Data Engineering Project

## 📘 Overview

**QuickBite** is a fully functional **data engineering and analytics pipeline** inspired by **Swiggy/Zomato**, designed to simulate a real-world food delivery business scenario.  

It covers every layer of a **modern data stack** — from data ingestion using **AWS S3 and Snowpipe**, to data transformation using **Snowflake Stored Procedures and Tasks**, and finally **business KPIs** generation for analytics dashboards.  

---

## ⚙️ Architecture Flow

```mermaid
flowchart TD
    A[CSV Files in AWS S3] --> B[Snowflake External Stage]
    B --> C[Snowpipe for Auto Ingestion]
    C --> D[STG (Raw Tables)]
    D --> E[SP_PROCESS_RAW_ORDERS (Stored Procedure)]
    E --> F[CURATED Tables (Star Schema)]
    F --> G[Snowflake TASK (Cron-based)]
    F --> H[Power BI / Tableau Dashboards]
```

---

## 🧱 Project Layers

### 1️⃣ Data Source — AWS S3 (Raw Zone)
All source CSVs are stored in S3 with the following folder structure:

```
s3://quickbite-data-bucket/
│
├── raw_customers/
│    └── customers_batch1.csv
├── raw_orders/
│    └── orders_batch1.csv
├── raw_order_items/
│    └── order_items_batch1.csv
├── raw_restaurants/
│    └── restaurants_batch1.csv
├── raw_menu_items/
│    └── menu_items_batch1.csv
├── raw_drivers/
│    └── drivers_batch1.csv
└── raw_coupons/
     └── coupons_batch1.csv
```

---

### 2️⃣ Data Ingestion — Snowpipe (Staging Layer)

Each folder is connected to Snowflake via an **External Stage** + **Storage Integration**.

Example:
```sql
CREATE STORAGE INTEGRATION QUICKBITE_S3_INT
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = S3
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::123456789012:role/snowflake-s3-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://quickbite-data-bucket/');

CREATE OR REPLACE STAGE RAW.STAGE_CUSTOMERS
  URL='s3://quickbite-data-bucket/raw_customers/'
  STORAGE_INTEGRATION=QUICKBITE_S3_INT
  FILE_FORMAT=(TYPE=CSV FIELD_OPTIONALLY_ENCLOSED_BY='"' SKIP_HEADER=1);
```

Snowpipe Example:
```sql
CREATE OR REPLACE PIPE RAW.PIPE_CUSTOMERS
AUTO_INGEST = TRUE
AS
COPY INTO STG.RAW_CUSTOMERS (customer_id, name, phone, email, city, signup_date, __source_file, __ingested_at)
FROM (
  SELECT t.$1, t.$2, t.$3, t.$4, t.$5, TRY_TO_DATE(t.$6), METADATA$FILENAME, CURRENT_TIMESTAMP()
  FROM @RAW.STAGE_CUSTOMERS (FILE_FORMAT => 'RAW.CSV_FORMAT') t
)
ON_ERROR='CONTINUE';
```

✅ **Auto-ingests new CSVs from S3** as soon as they are uploaded.

---

### 3️⃣ Data Transformation — Staging to Curated (ETL Logic)

The transformation is driven by a powerful **Snowflake Stored Procedure**:  
`SP_PROCESS_RAW_ORDERS()`  

This SP performs:  
- Merging of staging → curated tables (`MERGE` statements).  
- Key resolution for `customer_key`, `restaurant_key`, `driver_key`, etc.  
- Foreign key mapping via `LEFT JOIN`s.  
- Incremental loading and deduplication.  
- Logging of audit entries to `AUDIT.PIPELINE_JOB_LOG`.  

Key Steps:
1. **Merge Customers**
2. **Merge Restaurants**
3. **Merge Menu Items**
4. **Merge Drivers**
5. **Merge Coupons**
6. **Populate Orders (fact table)**  
7. **Populate Order Items (fact child table)**

---

### 4️⃣ Data Model — Star Schema

**Fact Tables**
- `orders`
- `order_items`

**Dimension Tables**
- `customers`
- `restaurants`
- `menu_items`
- `drivers`
- `coupons`

Example:
```sql
SELECT 
  c.name AS customer_name,
  r.name AS restaurant_name,
  SUM(o.total_amount) AS total_spent
FROM CURATED.orders o
JOIN CURATED.customers c ON o.customer_key = c.customer_key
JOIN CURATED.restaurants r ON o.restaurant_key = r.restaurant_key
GROUP BY c.name, r.name
ORDER BY total_spent DESC;
```

---

### 5️⃣ Logging and Monitoring

Audit tables ensure complete traceability of ETL operations.

```sql
CREATE OR REPLACE TABLE AUDIT.PIPELINE_JOB_LOG (
  JOB_NAME STRING,
  STATUS STRING,
  ROWS_PROCESSED NUMBER,
  ROWS_INSERTED NUMBER,
  ROWS_UPDATED NUMBER,
  ERROR_MESSAGE STRING,
  DETAILS VARIANT,
  RUN_AT TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
```

Stored Procedure logs both success and error states automatically.

---

### 6️⃣ Scheduling with Snowflake TASK

The ETL job runs automatically using a **Snowflake Task** scheduled with a cron expression.

```sql
CREATE OR REPLACE TASK CURATED.TASK_PROCESS_RAW_ORDERS
  WAREHOUSE = COMPUTE_WH
  SCHEDULE = 'USING CRON 0 3 * * * UTC'  -- Daily at 8:30 AM IST
AS
CALL STG.SP_PROCESS_RAW_ORDERS();
```

---

### 7️⃣ Business KPIs and Analytics

Once curated data is ready, key metrics are computed such as:

| KPI | Description |
|------|--------------|
| Total Orders | `COUNT(DISTINCT order_id)` |
| Average Order Value | `AVG(total_amount)` |
| Top Restaurants | `SUM(total_amount)` grouped by restaurant |
| Top Customers | `SUM(total_amount)` grouped by customer |
| Coupon Utilization Rate | `(Orders using coupon / Total Orders) * 100` |
| Driver Efficiency | `AVG(order_delivery_time)` per driver |

---

### 8️⃣ Example Analytical Queries

#### Top 10 Restaurants by Revenue
```sql
SELECT r.name, SUM(o.total_amount) AS total_revenue
FROM CURATED.orders o
JOIN CURATED.restaurants r ON o.restaurant_key = r.restaurant_key
GROUP BY r.name
ORDER BY total_revenue DESC
LIMIT 10;
```

#### Top 10 Customers by Spend
```sql
SELECT c.name, SUM(o.total_amount) AS total_spent
FROM CURATED.orders o
JOIN CURATED.customers c ON o.customer_key = c.customer_key
GROUP BY c.name
ORDER BY total_spent DESC
LIMIT 10;
```

#### Average Delivery Time by City
```sql
SELECT r.city, AVG(o.delivery_time) AS avg_delivery_time
FROM CURATED.orders o
JOIN CURATED.restaurants r ON o.restaurant_key = r.restaurant_key
GROUP BY r.city;
```

---

## 🚀 Technologies Used

| Layer | Technology |
|--------|-------------|
| Cloud Storage | AWS S3 |
| Data Warehouse | Snowflake |
| Ingestion | Snowpipe + Storage Integration |
| Transformation | Stored Procedures + SQL MERGE |
| Orchestration | Snowflake Task (Cron) |
| Monitoring | Audit Tables + Logs |
| Visualization | Power BI / Tableau |

---

## 🧩 Key Business Insights
- Identify **top-performing restaurants and cities**.
- Measure **coupon effectiveness** and **discount ROI**.
- Track **driver delivery efficiency** and SLA breaches.
- Understand **customer purchase frequency** and churn risk.
- Enable **daily executive dashboards** using Snowflake data feeds.

---

## 🧠 Future Enhancements
- Integrate with **Kafka or Fivetran** for real-time ingestion.
- Use **Snowflake Streams + Tasks** for continuous incremental processing.
- Implement **Cortex AI** for demand forecasting (predicting order volumes).
- Add **DBT models** for automated testing and documentation.

---

## 👨‍💻 Author

**AnalyticsWithAnand**  
🎓 *Snowflake Super Data Hero 2025 | Senior Data Engineer @ Tiger Analytics*  
📺 [YouTube: AnalyticsWithAnand](https://www.youtube.com/@analyticswithanand)  
💼 *“Let the Data Do the Talking...”*
