SELECT
  template_name,
  SUM(count_clicked_new) AS count_clicked,
  SUM(count_sent) AS count_sent,
  ROUND(SAFE_DIVIDE(SUM(count_clicked_new), SUM(count_sent)), 3) AS click_rate,
  COUNT(DISTINCT customer_id) AS unique_customers
FROM `reporting_layer.campaign_data_cleaned`
WHERE template_language = 'en'
GROUP BY template_name
HAVING unique_customers >= 10
ORDER BY click_rate DESC
LIMIT 10

