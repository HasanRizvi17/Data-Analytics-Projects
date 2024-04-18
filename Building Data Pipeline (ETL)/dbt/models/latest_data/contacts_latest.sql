SELECT *
FROM {{ref("contacts_changelog_extracted")}} AS a
WHERE NOT EXISTS (SELECT 1 FROM {{ref("internal_test_users")}} WHERE business_id = a.business_id)
QUALIFY ROW_NUMBER() OVER(PARTITION BY contact_id ORDER BY updated_at DESC,created_at DESC) = 1