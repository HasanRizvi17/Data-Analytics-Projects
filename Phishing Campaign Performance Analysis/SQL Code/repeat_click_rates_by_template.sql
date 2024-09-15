WITH 

ranking AS
      (
      SELECT
        *,
        DENSE_RANK() OVER(PARTITION BY template_name ORDER BY month_new) AS nth_month
      FROM `reporting_layer.campaign_data_cleaned`
      WHERE 
        template_language = "en"
        AND count_clicked_new > 1
      ORDER BY customer_id, template_id, month
      ),

repeat_click_rates AS
      (
      SELECT
        template_name,
        COUNT(DISTINCT customer_id) AS unique_customer_clicks,
        COUNT(DISTINCT CASE WHEN nth_month > 3 THEN customer_id ELSE NULL END) AS repeat_unique_customer_clicks,
        ROUND(SAFE_DIVIDE(COUNT(DISTINCT CASE WHEN nth_month > 3 THEN customer_id ELSE NULL END), COUNT(DISTINCT customer_id)), 3) AS repeat_click_rate
      FROM ranking
      GROUP BY template_name
      ORDER BY repeat_click_rate DESC
      )

SELECT
  "0" AS id,
  ROUND(SUM(CASE WHEN repeat_click_rate = 1 THEN 1 ELSE 0 END) / COUNT(*), 3) AS perc_100_repeat_click_rate,
  ROUND(SUM(CASE WHEN repeat_click_rate >= 0.9 THEN 1 ELSE 0 END) / COUNT(*), 3) AS greater_than_perc_90_repeat_click_rate,
  ROUND(SUM(CASE WHEN repeat_click_rate >= 0.8 THEN 1 ELSE 0 END) / COUNT(*), 3) AS greater_than_perc_80_repeat_click_rate
FROM repeat_click_rates




