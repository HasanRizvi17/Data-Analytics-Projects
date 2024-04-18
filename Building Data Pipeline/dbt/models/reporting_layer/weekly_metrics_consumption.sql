WITH

base_fields AS (
    SELECT
        b.business_id, b.business_name
        /*
        b.user_id, u.full_name AS user_name, u.mobile_number, u.created_at AS signup_date,
        b.created_at AS business_signup_date,
        DATE_DIFF(CURRENT_DATE(), b.created_at, DAY) AS days_since_signup,
        b.address AS business_address, b.business_type, b.supply_chain_role
        -- business_activity_status -- use events data to get last activity
        */
    FROM latest_data.businesses_latest` AS b
    LEFT JOIN latest_data.users_latest` AS u ON u.user_id = b.user_id
),

signup_stats AS (
    SELECT 
        DATE_TRUNC(business_signup_date, WEEK) AS week,
        COUNT(DISTINCT business_id) AS no_of_new_businesses_onboarded,
        COUNT(DISTINCT CASE WHEN activation_status = 'Activated' THEN business_id ELSE NULL END) AS no_of_new_businesses_activated,
        ROUND(COUNT(DISTINCT CASE WHEN activation_status = 'Activated' THEN business_id ELSE NULL END) / COUNT(DISTINCT business_id), 2) AS activation_rate
    FROM consumption_layer.businesses_dim_consumption`
    GROUP BY week
),

invoice_stats AS (
    SELECT
        DATE_TRUNC(p_date, WEEK) AS week,
        COUNT(DISTINCT business_id) AS active_businesses_invoice,
        SUM(no_of_invoices) AS no_of_invoices,
        ROUND(SUM(no_of_invoices) / COUNT(DISTINCT business_id), 1) AS no_of_invoices_per_business,
        SUM(invoice_amount_subtotal) AS invoice_amount_subtotal,
        SUM(invoice_amount_final) AS invoice_amount_final,
        COUNT(DISTINCT contact_id) AS active_contacts_invoice
    FROM facts.invoices_fct`
    GROUP BY week
),

quotation_stats AS (
    SELECT
        DATE_TRUNC(p_date, WEEK) AS week,
        SUM(no_of_quotations) AS no_of_quotations,
        SUM(quotation_amount_subtotal) AS quotation_amount_subtotal,
        SUM(quotation_amount_final) AS quotation_amount_final
    FROM facts.quotations_fct`
    GROUP BY week
),

order_stats AS (
    SELECT
        DATE_TRUNC(p_date, WEEK) AS week,
        SUM(no_of_orders) AS no_of_orders,
        SUM(order_amount_subtotal) AS order_amount_subtotal
    FROM facts.orders_fct`
    GROUP BY week
),

contacts_stats AS (
    SELECT
        DATE_TRUNC(created_at, WEEK) AS week,
        COUNT(DISTINCT contact_id) AS no_of_contacts_created
    FROM latest_data.contacts_latest`
    GROUP BY week
),

inventory_stats AS (
    SELECT
        DATE_TRUNC(il.created_at, WEEK) AS week,
        COUNT(DISTINCT isl.inventory_id) AS no_of_new_skus_created
    FROM latest_data.inventories_stock_latest` AS isl
    LEFT JOIN latest_data.inventories_latest`AS il ON il.inventory_id = isl.inventory_id
    GROUP BY week
),

ledger_stats AS (
  SELECT 
    DATE_TRUNC(t.transaction_time, WEEK) AS week,
    COUNT(DISTINCT business_id) AS active_businesses_ledger,
    COUNT(DISTINCT t.transaction_id) AS no_ledger_transactions_total,
    COUNT(DISTINCT CASE WHEN transaction_type = 'payment_made_against_invoice' THEN t.transaction_id ELSE NULL END) AS no_of_payments_against_invoices,
    COUNT(DISTINCT CASE WHEN transaction_type IN ('manual_payment_made_by_customer', 'manual_payment_made_to_customer', 'refund_processed') THEN t.transaction_id ELSE NULL END) AS no_of_manual_payments_ledger
  FROM consumption_layer.ledger_transactions_raw_consumption` AS t
  WHERE transaction_type NOT IN ('invoice_issued')
  GROUP BY week
  ORDER BY week DESC
),

ledger_view_stats AS (
  SELECT 
    DATE(x.week) AS week,
    x.no_of_ledger_views,
    y.avg_ledger_view_time_per_view_seconds
  FROM (
    SELECT 
      DATE_TRUNC(v.ledger_view_timestamp, WEEK) AS week,
      COUNT(*) AS no_of_ledger_views,
    FROM consumption_layer.ledger_views_raw_consumption` AS v
    GROUP BY week
  ) AS x
  LEFT JOIN (
    SELECT 
      DISTINCT
      DATE_TRUNC(v.ledger_view_timestamp, WEEK) AS week,
      PERCENTILE_DISC(ledger_view_time_seconds, 0.5) OVER(PARTITION BY DATE_TRUNC(v.ledger_view_timestamp, WEEK)) AS avg_ledger_view_time_per_view_seconds
    FROM consumption_layer.ledger_views_raw_consumption` AS v
  ) AS y ON y.week = x.week
)


/*
invoice_median_daily_stats AS (
    SELECT
        DISTINCT business_id,
        PERCENTILE_DISC(no_of_invoices, 0.5) OVER(PARTITION BY business_id) AS median_daily_invoices,
        PERCENTILE_DISC(invoice_amount_final, 0.5) OVER(PARTITION BY business_id) AS median_daily_invoice_amount_final
    FROM (
        SELECT business_id, DATE_TRUNC(p_date, DAY) AS date,
                SUM(no_of_invoices) AS no_of_invoices,
                SUM(invoice_amount_final) AS invoice_amount_final
        FROM facts.invoices_fct`
        GROUP BY business_id, date
        )
),

invoice_median_weekly_stats AS (
    SELECT
        DISTINCT business_id,
        PERCENTILE_DISC(no_of_invoices, 0.5) OVER(PARTITION BY business_id) AS median_weekly_invoices,
        PERCENTILE_DISC(invoice_amount_final, 0.5) OVER(PARTITION BY business_id) AS median_weekly_invoice_amount_final
    FROM (
        SELECT business_id, DATE_TRUNC(p_date, WEEK) AS week,
                SUM(no_of_invoices) AS no_of_invoices,
                SUM(invoice_amount_final) AS invoice_amount_final
        FROM facts.invoices_fct`
        GROUP BY business_id, week
        )
),

invoice_median_monthly_stats AS (
    SELECT
        DISTINCT business_id,
        PERCENTILE_DISC(no_of_invoices, 0.5) OVER(PARTITION BY business_id) AS median_monthly_invoices,
        PERCENTILE_DISC(invoice_amount_final, 0.5) OVER(PARTITION BY business_id) AS median_monthly_invoice_amount_final
    FROM (
        SELECT business_id, DATE_TRUNC(p_date, MONTH) AS month,
                SUM(no_of_invoices) AS no_of_invoices,
                SUM(invoice_amount_final) AS invoice_amount_final
        FROM facts.invoices_fct`
        GROUP BY business_id, month
        )
),

median_per_invoice_stats AS (
    SELECT
        DISTINCT business_id,
        PERCENTILE_DISC(invoice_amount_subtotal, 0.5) OVER(PARTITION BY business_id) AS median_amount_subtotal_per_invoice,
        PERCENTILE_DISC(unique_invoice_items, 0.5) OVER(PARTITION BY business_id) AS median_items_per_invoice
    FROM (
        SELECT
            il.business_id, il.invoice_id,
            SUM(iil.per_item_sell_price * iil.quantity) AS invoice_amount_subtotal,
            COUNT(DISTINCT iil.item_id) AS unique_invoice_items
        FROM latest_data.invoices_latest` AS il
        LEFT JOIN latest_data.invoice_items_latest` AS iil ON iil.invoice_id = il.invoice_id
        GROUP BY business_id, invoice_id
        )
),

atleast_2_invoices_weeks AS (
    SELECT
        business_id, 
        COUNT(*) AS no_of_weeks_with_atleast_2_invoices 
    FROM (
        SELECT 
            business_id, 
            DATE_TRUNC(p_date, WEEK) AS week,
            COUNT(*) AS no_of_invoices
        FROM facts.invoices_fct`
        GROUP BY business_id, week
        HAVING COUNT(*) >= 2  
    ) AS temp
    GROUP BY business_id
)
*/

-- signups and activations

,final AS (
    SELECT
        invoice_stats.week,
        signup_stats.* EXCEPT(week),
        invoice_stats.* EXCEPT(week),
        contacts_stats.* EXCEPT (week),
        quotation_stats.* EXCEPT (week),
        order_stats.* EXCEPT (week),
        inventory_stats.* EXCEPT (week),
        ledger_stats.* EXCEPT (week),
        ledger_view_stats.* EXCEPT (week)
    FROM invoice_stats
    LEFT JOIN signup_stats ON signup_stats.week = invoice_stats.week
    LEFT JOIN contacts_stats ON contacts_stats.week = invoice_stats.week
    LEFT JOIN quotation_stats ON quotation_stats.week = invoice_stats.week
    LEFT JOIN order_stats ON order_stats.week = invoice_stats.week
    LEFT JOIN inventory_stats ON inventory_stats.week = invoice_stats.week
    LEFT JOIN ledger_stats ON ledger_stats.week = invoice_stats.week
    LEFT JOIN ledger_view_stats ON ledger_view_stats.week = invoice_stats.week
)

SELECT *
FROM final
ORDER BY week DESC
