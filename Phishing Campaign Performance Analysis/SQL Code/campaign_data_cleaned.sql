WITH

cleaned AS (
  SELECT
    DATE(PARSE_DATE("%Y-%m", CONCAT(CAST(year AS STRING), '-', LPAD(CAST(month AS STRING), 2, '0')))) AS month_new,
    CASE WHEN count_clicked > count_sent THEN count_sent ELSE count_clicked END AS count_clicked_new,
    c.*,
    CASE WHEN i.industry IS NULL THEN 'Other' ELSE i.industry END AS customer_industry
  FROM `reporting_layer.campaign_data` AS c
  LEFT JOIN `reporting_layer.industry_customer_map` AS i ON i.customer_id = c.customer_id
)

SELECT *
FROM cleaned