{{
    config(
        materialized='incremental'
    )
}}

WITH CDC AS(
SELECT
    document_id
    ,operation
    ,timestamp
    ,data
    ,date
    ,COALESCE(
        DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.updatedAt") AS TIMESTAMP), 'Asia/Karachi') 
        ,DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.createdAt") AS TIMESTAMP), 'Asia/Karachi')
        ) AS updatedAt -- using this column as markup column to load incremental data
FROM {{ source('mongodb_staging_data','customers_mongo_raw_data')}}
)
SELECT * FROM CDC
 {% if is_incremental() %}
WHERE updatedAt > (SELECT COALESCE(MAX(updatedAt),'1900-01-01') FROM {{ this }})
 {% endif %}