WITH 

customer_metrics AS (
  SELECT 
    customer_id,
    customer_industry,
    month_new AS month,
    SUM(count_clicked_new) AS count_clicked,
    SUM(count_sent) AS count_sent,
    SAFE_DIVIDE(SUM(count_clicked_new), SUM(count_sent)) AS click_rate,
    COUNT(DISTINCT template_name) AS templates_used
  FROM `reporting_layer.campaign_data_cleaned`
  WHERE count_sent != 0 OR count_clicked != 0 -- 143 rows filtered out
  GROUP BY customer_id, month, customer_industry
)

SELECT 
  month,
  customer_industry,
  SUM(count_clicked) AS count_clicked,
  SUM(count_sent) AS count_sent,
  COUNT(customer_id) AS active_customers,
  ROUND(SUM(count_clicked) / SUM(count_sent), 3) AS click_rate,
  ROUND(SUM(CASE WHEN click_rate <= 0.2 THEN 1 ELSE 0 END) / COUNT(customer_id), 3) AS perc_customers_with_good_awareness,
  ROUND(APPROX_QUANTILES(click_rate, 10)[OFFSET(5)], 3) AS avg_click_rate_per_customer,
  ROUND(APPROX_QUANTILES(templates_used, 10)[OFFSET(5)], 3) AS avg_templates_used_per_customer

FROM customer_metrics
GROUP BY month, customer_industry
ORDER BY month DESC, customer_industry

