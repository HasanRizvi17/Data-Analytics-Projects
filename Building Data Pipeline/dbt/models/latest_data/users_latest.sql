SELECT *
FROM {{ref("users_changelog_extracted")}}
QUALIFY ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY updated_at DESC, created_at DESC) = 1