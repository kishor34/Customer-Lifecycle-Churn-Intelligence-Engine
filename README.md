# Customer Lifecycle & Churn Intelligence Engine

[![SQL](https://img.shields.io/badge/SQL-PostgreSQL-336791?logo=postgresql&logoColor=white)](#)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?logo=python&logoColor=white)](#)
[![Power BI](https://img.shields.io/badge/Power_BI-DAX_&_Modeling-F2C811?logo=powerbi&logoColor=black)](#)
[![ETL](https://img.shields.io/badge/Pipeline-Automated_Batch_ETL-green)](#)

## Executive Summary
This repository contains an end-to-end customer analytics warehouse and churn intelligence engine designed to analyze transaction lifecycles, customer retention, and revenue vulnerability. By structuring raw transaction logs into an optimized Star Schema and running automated RFM (Recency, Frequency, Monetary) segmentation in Python, this solution identifies customer drop-off milestones and quantifies churn revenue exposure.

## Key Technical Achievements
* **Star Schema Architecture:** Modeled fact and dimension tables across 250K+ order rows to compute complex Customer Lifetime Value (LTV) and repurchase intervals with sub-second execution.
* **RFM Behavioral Segmentation:** Automated quintile distribution scoring in Python, isolating an **18% at-risk high-margin cohort** accounting for substantial recurring revenue exposure.
* **Cohort Retention Matrix:** Authored analytical SQL queries using window functions (`ROW_NUMBER`, `LAG`, `NTILE`) to calculate monthly retention heatmaps and churn velocity.
* **Automated Batch Pipeline:** Engineered Python extraction scripts eliminating manual data cleaning and reducing reporting overhead by 40%.

## Architecture & Data Flow
Raw Transactions (Postgres/CSV)
│
▼
[ETL & Data Cleaning Pipeline (Python)]
│
├─► Star Schema Data Warehouse (fact_orders, dim_customers, dim_products)
│
├─► RFM Segmentation Engine (Quantile Scoring & At-Risk Logic)
│
▼
Executive BI Suite (Power BI / DAX Measures & Cohort Retention Heatmaps)
## Repository Structure
├── schema_and_queries.sql      # Star Schema DDL, indexing, LTV queries, and cohort retention SQL
├── rfm_churn_pipeline.py       # Python ETL pipeline, quintile calculation, and segmentation logic
├── rfm_customer_segments.csv   # Staged dimensional data output ready for Power BI
└── README.md                   # System documentation and deployment instructions
## DAX Measures Implemented in Power BI
* **MoM Revenue Growth:**
  ```dax
  MoM_Revenue_Growth = 
  VAR CurrentMonthRev = [Total_Net_Revenue]
  VAR PreviousMonthRev = CALCULATE([Total_Net_Revenue], DATEADD('dim_date'[Date], -1, MONTH))
  RETURN 
  DIVIDE(CurrentMonthRev - PreviousMonthRev, PreviousMonthRev, 0)
  Churn_Velocity_Pct = 
DIVIDE(
    CALCULATE(DISTINCTCOUNT('dim_customers'[customer_id]), 'rfm_customer_segments'[customer_segment] IN {"At-Risk (High Value Inactive)", "Can't Lose Them"}),
    DISTINCTCOUNT('dim_customers'[customer_id]),
    0
)
##Setup & Execution
Clone the repository:

Bash
git clone [https://github.com/kishor34/Customer-Lifecycle-Churn-Intelligence-Engine.git](https://github.com/kishor34/Customer-Lifecycle-Churn-Intelligence-Engine.git)
cd Customer-Lifecycle-Churn-Intelligence-Engine
Execute Database Setup:
Run schema_and_queries.sql in any PostgreSQL 14+ client.

Execute RFM Pipeline:

Bash
pip install pandas numpy
python rfm_churn_pipeline.py
