## Skills Used
- ***dbt (data build tool)***: to set up data transformations and build data models
- ***Apache Airflow***: to schedule/orchestrate the data pipeline and transformational processes 
- ***Google BigQuery***: to host the Data Warehouse

## Overview
This project covers the "T" part of ETL. Its objective was to set up data transformational processes using modern data stack tools which would then build  data models through a sequence of layers in a data pipeline for efficient data consumption by the end-users of data (primarily analysts). 

## Description
The data pipeline we aimed to build includes the following components:
- ***Storing Changelogs of Source Data***: Changelogs for each record is stored in the tables in this layer using dbt's *incremental models*.
- ***Extracting Fields and Values from JSON***: The source data from the database hosted on MongoDB comes in form of JSON documents in key-value pairs. We extract in various structured and semi-nstructured forms and store in proper tables more suitable for downstream consumption and analysis.
- ***Extracting Latest Records from Changelogs Data***: Most of the times we need latest rows for each record, so we extract the latest rows for each record in each table using Window Functions (BigQuery SQL)
- ***Facts***: Layer for building fact tables, which are collections of information that typically refers to an action, event, or result of a business process. In terms of a real business, some facts may look like transactions, payments, or emails sent.
- ***Dimensions***: Layer for building dimension tables, which are collections of data that describe who or what took action or was affected by the action. They add context to the stored events in fact tables. In terms of a business, some dimensions may look like users, accounts, customers, and invoices.
- ***Reporting Layer***: Layer for building any relevant data products for business and operational use that require more complex logic and calculations. These should ideally be built using the tables in the Dimensions and Facts Layers.
### Snapshot of the Data Pipeline (and data layers)
![image](https://github.com/HasanRizvi17/Hasan-Data-Analytics-Projects/assets/66498297/ab2a861c-3442-4638-a1d2-77966b4b9597)

## Not Covered in this Project
- Extraction and Loading / Ingestion
