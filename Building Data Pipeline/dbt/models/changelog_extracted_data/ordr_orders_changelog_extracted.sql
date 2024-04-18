SELECT
    NULLIF(JSON_EXTRACT_SCALAR(data, '$._id'),'') AS order_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.user'),'') AS user_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.business'),'') AS business_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.contact.id'),'') AS contact_id
    ,JSON_EXTRACT_SCALAR(data, '$._id') AS inventory_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.type'),'') AS transaction_type
    ,DATE_TRUNC(DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.createdAt")AS TIMESTAMP), 'Asia/Karachi'), second) AS created_at
    ,DATE_TRUNC(DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.updatedAt")AS TIMESTAMP), 'Asia/Karachi'), second) AS updated_at
    ,SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.__v") AS INT64) AS __v
FROM {{ref('orders_mongo_changelog_raw')}}