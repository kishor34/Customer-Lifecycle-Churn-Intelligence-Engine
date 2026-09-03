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
