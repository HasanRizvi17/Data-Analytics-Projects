SELECT
    JSON_EXTRACT_SCALAR(data, '$._id') AS inventory_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.business'),'') AS business_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data,'$.user'),'') AS user_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.name'),'') AS name
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.code'),'') AS code
    ,JSON_EXTRACT_STRING_ARRAY(data,'$.labels') AS lables
    ,DATE_TRUNC(DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.createdAt") AS TIMESTAMP), 'Asia/Karachi'), second) AS created_at
    ,DATE_TRUNC(DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.updatedAt") AS TIMESTAMP), 'Asia/Karachi'), second) AS updated_at
FROM {{ref('inventories_mongo_changelog_raw')}}