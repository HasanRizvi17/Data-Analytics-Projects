SELECT
    JSON_EXTRACT_SCALAR(data, '$._id') AS contact_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.user'),'') AS user_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.business'),'') AS business_id
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.name'),'') AS contact_name
    ,NULLIF(NULLIF(JSON_EXTRACT_SCALAR(data, '$.businessName'),''),'N/A') AS business_name
    ,CONCAT("+",NULLIF(JSON_EXTRACT_SCALAR(data, '$.phone.countryCode'),''),NULLIF(JSON_EXTRACT_SCALAR(data, '$.phone.number'),'')) AS mobile_number
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.email'),'') AS email 
    ,NULLIF(JSON_EXTRACT_SCALAR(data, '$.address'),'') AS address 
    ,JSON_EXTRACT_STRING_ARRAY(data,'$.businessRelationship') AS business_relationship
    ,DATE_TRUNC(DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.createdAt") AS TIMESTAMP), 'Asia/Karachi'), second) AS created_at
    ,DATE_TRUNC(DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.updatedAt") AS TIMESTAMP), 'Asia/Karachi'), second) AS updated_at
FROM {{ref('contacts_mongo_changelog_raw')}}