SELECT
    JSON_EXTRACT_SCALAR(data, '$._id') AS user_id
    ,JSON_EXTRACT_SCALAR(data, '$.fullName') AS full_name
    ,JSON_EXTRACT_SCALAR(data, '$.phone.countryCode') AS country_code
    ,JSON_EXTRACT_SCALAR(data, '$.phone.number') AS mobile_number
    ,DATE_TRUNC(DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.createdAt") AS TIMESTAMP), 'Asia/Karachi'), second) AS created_at
    ,DATE_TRUNC(DATETIME(SAFE_CAST(JSON_EXTRACT_SCALAR(data,"$.updatedAt") AS TIMESTAMP), 'Asia/Karachi'), second) AS updated_at
FROM {{ref('users_mongo_changelog_raw')}}