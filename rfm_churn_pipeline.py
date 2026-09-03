"""
Customer Lifecycle & Churn Intelligence Engine
Module: Automated ETL, RFM Scoring, and Churn Risk Modeling
Author: Kishor Ravi
"""

import pandas as pd
import numpy as np
import datetime as dt

def run_rfm_pipeline(data_path: str, snapshot_date: dt.datetime = None):
    print("[ETL Pipeline] Ingesting raw transactional records...")
    df = pd.read_csv(data_path, parse_dates=['order_timestamp'])
    
    # 1. Data Cleaning & Validation
    initial_rows = len(df)
    df = df.dropna(subset=['customer_id', 'order_id', 'net_revenue'])
    df = df[df['net_revenue'] > 0]
    df = df[df['order_status'] == 'Delivered']
    print(f"[ETL Pipeline] Validated dataset. Dropped {initial_rows - len(df)} corrupt/cancelled records.")
    
    # Reference date for recency calculation
    if not snapshot_date:
        snapshot_date = df['order_timestamp'].max() + dt.timedelta(days=1)
        
    print(f"[RFM Engine] Running calculations against snapshot date: {snapshot_date.strftime('%Y-%m-%d')}")
    
    # 2. Aggregating Recency, Frequency, and Monetary metrics
    rfm = df.groupby('customer_id').agg({
        'order_timestamp': lambda x: (snapshot_date - x.max()).days,
        'order_id': 'nunique',
        'net_revenue': 'sum'
    }).reset_index()
    
    rfm.rename(columns={
        'order_timestamp': 'recency_days',
        'order_id': 'frequency_count',
        'net_revenue': 'monetary_value'
    }, inplace=True)
    
    # 3. Quantile Quintile Scoring (1 to 5)
    # Higher recency days means worse score (inverted ranking)
    rfm['R_score'] = pd.qcut(rfm['recency_days'], q=5, labels=[5, 4, 3, 2, 1]).astype(int)
    rfm['F_score'] = pd.qcut(rfm['frequency_count'].rank(method='first'), q=5, labels=[1, 2, 3, 4, 5]).astype(int)
    rfm['M_score'] = pd.qcut(rfm['monetary_value'], q=5, labels=[1, 2, 3, 4, 5]).astype(int)
    
    # Composite RFM Score
    rfm['RFM_composite'] = (
        rfm['R_score'].astype(str) + 
        rfm['F_score'].astype(str) + 
        rfm['M_score'].astype(str)
    )
    
    # 4. Behavioral Customer Segmentation Logic
    def assign_segment(row):
        r, f, m = row['R_score'], row['F_score'], row['M_score']
        if r >= 4 and f >= 4 and m >= 4:
            return 'Champions / Core Loyal'
        elif r >= 3 and f >= 3:
            return 'Potential Loyalists'
        elif r <= 2 and f >= 3 and m >= 3:
            return 'At-Risk (High Value Inactive)'
        elif r <= 2 and f <= 2 and m >= 4:
            return 'Can\'t Lose Them (High Margin Slipping)'
        elif r >= 4 and f == 1:
            return 'New / Recent Activations'
        elif r <= 2 and f <= 2:
            return 'Hibernating / Churned'
        else:
            return 'Needs Attention'

    rfm['customer_segment'] = rfm.apply(assign_segment, axis=1)
    
    # 5. Pipeline Summary & Churn Quantification
    at_risk_df = rfm[rfm['customer_segment'].isin(['At-Risk (High Value Inactive)', 'Can\'t Lose Them (High Margin Slipping)'])]
    at_risk_pct = (len(at_risk_df) / len(rfm)) * 100
    at_risk_revenue = at_risk_df['monetary_value'].sum()
    total_revenue = rfm['monetary_value'].sum()
    revenue_exposure_pct = (at_risk_revenue / total_revenue) * 100
    
    print("\n" + "="*50)
    print("CUSTOMER RETENTION & CHURN AUDIT")
    print("="*50)
    print(f"Total Unique Customers Audited: {len(rfm):,}")
    print(f"At-Risk Accounts Identified:     {len(at_risk_df):,} ({at_risk_pct:.2f}% of user base)")
    print(f"Capital Exposed to Churn Risk:  ${at_risk_revenue:,.2f} ({revenue_exposure_pct:.2f}% of total revenue)")
    print("="*50)
    
    # Export for Power BI Consumption
    rfm.to_csv("rfm_customer_segments_export.csv", index=False)
    print("[Pipeline Output] Staged 'rfm_customer_segments_export.csv' for Power BI ingestion.")
    return rfm

if __name__ == "__main__":
    # Synthetic generator test to verify pipeline execution
    np.random.seed(42)
    sample_records = 5000
    sample_data = {
        'customer_id': [f"CUST_{np.random.randint(1000, 1800)}" for _ in range(sample_records)],
        'order_id': [f"ORD_{100000 + i}" for i in range(sample_records)],
        'order_timestamp': pd.date_range(start='2024-01-01', end='2025-04-15', periods=sample_records),
        'net_revenue': np.random.exponential(scale=75, size=sample_records).round(2),
        'order_status': np.random.choice(['Delivered', 'Cancelled', 'Returned'], size=sample_records, p=[0.92, 0.05, 0.03])
    }
    sample_df = pd.DataFrame(sample_data)
    sample_df.to_csv("transactions_staging.csv", index=False)
    
    run_rfm_pipeline("transactions_staging.csv")
