# Environment Reproduction Guide

This directory contains the pipeline and analytical queries required to reproduce the B2B Ecosystem Revenue Leakage Audit.

## 1. Environment Specifications
*   **Database Engine:** MySQL Server (Version 8.0+)
*   **Interface Tooling:** MySQL Workbench / Command Line Interface
*   **SQL Dialect:** Standard MySQL

## 2. Ingestion Prerequisites
Before executing the initialization scripts, ensure that the raw source CSV datasets are deposited into your server's secure outbound upload directory. 

To locate your server's designated secure file directory, execute the following command in your SQL editor:
```sql
SHOW VARIABLES LIKE "secure_file_priv";
```

Move all source relational files into the file path returned by that query.

## 3. Order of Execution
To avoid relational foreign key mapping errors and schema definition breaks, execute the codebase sequentially according to this sequence mapping:

1.  **[scripts/01_data_ingestion.sql](01_data_ingestion.sql)**  
    *Purpose:* Builds the baseline database schema structure and streams raw CSV strings into normalized tables.
2.  **[scripts/02_data_sanitization.sql](02_data_sanitization.sql)**  
    *Purpose:* Runs primary key constraint validations, identifies chronologically impossible timestamps, and patches missing localization strings.
3.  **[scripts/03_funnel_and_latency.sql](03_funnel_and_latency.sql)**  
    *Purpose:* Calculates marketing qualified lead attribution channels and computes vertical implementation lags.
4.  **[scripts/04_churn_and_recovery.sql](04_churn_and_recovery.sql)**  
    *Purpose:* Uses window partition functions to isolate the 15-day momentum loop and executes financial revenue recovery models.
