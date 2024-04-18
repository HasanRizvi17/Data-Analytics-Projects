SELECT
    NULLIF(JSON_EXTRACT_SCALAR(data, '$._id'),'') AS business_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.user'),'') AS user_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.name'),'') AS business_name
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.address'),'') AS address
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.businessType'),'') AS business_type
    ,JSON_EXTRACT_STRING_ARRAY(data,'$.supplyChainRole') AS supply_chain_role
    ,DATE_TRUNC(DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.createdAt") AS TIMESTAMP), 'Asia/Karachi'), second) AS created_at
    ,DATE_TRUNC(DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.updatedAt") AS TIMESTAMP), 'Asia/Karachi'), second) AS updated_at
FROM {{ref('businesses_mongo_changelog_raw')}}