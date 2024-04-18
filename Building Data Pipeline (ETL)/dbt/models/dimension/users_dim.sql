WITH
base_fields AS (
    SELECT
        user_id, full_name AS user_name, mobile_number, created_at AS signup_date,
        DATE_DIFF(CURRENT_DATE(), created_at, DAY) AS days_since_signup
        -- activity_status -- use events data to get last activity
    FROM {{ref("users_latest")}}
),
user_no_of_businesses AS (
    SELECT
        user_id,
        COUNT(DISTINCT business_id) AS no_of_businesses
    FROM latest_data.businesses_latest
    GROUP BY user_id
),
invoice_stats AS (
    SELECT
        user_id,
        COUNT(DISTINCT p_date) AS active_days_invoice,
        COUNT(DISTINCT DATE_TRUNC(p_date, WEEK)) AS active_weeks_invoice,
        COUNT(DISTINCT DATE_TRUNC(p_date, MONTH)) AS active_months_invoice,
        SUM(no_of_invoices) AS no_of_invoices,
        SUM(invoice_amount_subtotal) AS invoice_amount_subtotal,
        SUM(invoice_amount_final) AS invoice_amount_final,
        DATE_DIFF(CURRENT_DATE(), MAX(p_date), DAY) AS days_since_last_invoice
    FROM {{ref("invoices_fct")}}
    GROUP BY user_id
),
quotation_stats AS (
    SELECT
        user_id,
        COUNT(DISTINCT p_date) AS active_days_quotation,
        COUNT(DISTINCT DATE_TRUNC(p_date, WEEK)) AS active_weeks_quotation,
        COUNT(DISTINCT DATE_TRUNC(p_date, MONTH)) AS active_months_quotation,
        SUM(no_of_quotations) AS no_of_quotations,
        SUM(quotation_amount_subtotal) AS quotation_amount_subtotal,
        SUM(quotation_amount_final) AS quotation_amount_final,
        DATE_DIFF(CURRENT_DATE(), MAX(p_date), DAY) AS days_since_last_quotation
    FROM {{ref("quotations_fct")}}
    GROUP BY user_id
),
order_stats AS (
    SELECT
        user_id,
        COUNT(DISTINCT p_date) AS active_days_order,
        COUNT(DISTINCT DATE_TRUNC(p_date, WEEK)) AS active_weeks_order,
        COUNT(DISTINCT DATE_TRUNC(p_date, MONTH)) AS active_months_order,
        SUM(no_of_orders) AS no_of_orders,
        SUM(order_amount_subtotal) AS order_amount_subtotal,
        DATE_DIFF(CURRENT_DATE(), MAX(p_date), DAY) AS days_since_last_order
    FROM {{ref("orders_fct")}}
    GROUP BY user_id
),
contacts_stats AS (
    SELECT
        user_id,
        COUNT(DISTINCT contact_id) AS no_of_contacts,
        -- SUM(CASE WHEN business_relationship = 'customer' THEN 1 ELSE 0 END) AS contacts_as_customers,
        -- SUM(CASE WHEN business_relationship = 'supplier' THEN 1 ELSE 0 END) AS contacts_as_customers,
        SUM(CASE WHEN balance_amount > 0 THEN 1 ELSE 0 END) AS contacts_with_positive_balance,
        SUM(CASE WHEN balance_amount < 0 THEN 1 ELSE 0 END) AS contacts_with_negative_balance,
        SUM(CASE WHEN balance_amount = 0 THEN 1 ELSE 0 END) AS contacts_with_zero_balance
    FROM {{ref("contacts_latest")}}
    GROUP BY user_id
),
contacts_stats_2 AS (
    SELECT
        user_id,
        COUNT(DISTINCT contact_id) AS activated_contacts,
        COUNT(DISTINCT CASE WHEN DATE_DIFF(CURRENT_DATE(), p_date, DAY) <= 14 THEN contact_id ELSE NULL END) AS active_contacts
    FROM {{ref("invoices_fct")}}
    GROUP BY user_id
),
inventory_stats AS (
    SELECT
        user_id,
        COUNT(DISTINCT inventory_id) AS unique_inventory_items,
        SUM(per_item_cost_price * quantity) AS total_inventory_value,
        SUM(quantity) AS total_inventory_quantity,
        MAX(last_stocked_at) AS last_inventory_restock_time
    FROM {{ref("inventories_stock_latest")}}
    GROUP BY user_id
),
invoice_median_daily_stats AS (
    SELECT
        DISTINCT user_id,
        PERCENTILE_DISC(no_of_invoices, 0.5) OVER(PARTITION BY user_id) AS median_daily_invoices,
        PERCENTILE_DISC(invoice_amount_final, 0.5) OVER(PARTITION BY user_id) AS median_daily_invoice_amount_final
    FROM (
        SELECT user_id, DATE_TRUNC(p_date, DAY) AS date,
                SUM(no_of_invoices) AS no_of_invoices,
                SUM(invoice_amount_final) AS invoice_amount_final
        FROM {{ref("invoices_fct")}}
        GROUP BY user_id, date
        )
),
invoice_median_weekly_stats AS (
    SELECT
        DISTINCT user_id,
        PERCENTILE_DISC(no_of_invoices, 0.5) OVER(PARTITION BY user_id) AS median_weekly_invoices,
        PERCENTILE_DISC(invoice_amount_final, 0.5) OVER(PARTITION BY user_id) AS median_weekly_invoice_amount_final
    FROM (
        SELECT user_id, DATE_TRUNC(p_date, WEEK) AS week,
                SUM(no_of_invoices) AS no_of_invoices,
                SUM(invoice_amount_final) AS invoice_amount_final
        FROM {{ref("invoices_fct")}}
        GROUP BY user_id, week
        )
),
invoice_median_monthly_stats AS (
    SELECT
        DISTINCT user_id,
        PERCENTILE_DISC(no_of_invoices, 0.5) OVER(PARTITION BY user_id) AS median_monthly_invoices,
        PERCENTILE_DISC(invoice_amount_final, 0.5) OVER(PARTITION BY user_id) AS median_monthly_invoice_amount_final
    FROM (
        SELECT user_id, DATE_TRUNC(p_date, MONTH) AS month,
                SUM(no_of_invoices) AS no_of_invoices,
                SUM(invoice_amount_final) AS invoice_amount_final
        FROM {{ref("invoices_fct")}}
        GROUP BY user_id, month
        )
),
median_per_invoice_stats AS (
    SELECT
        DISTINCT user_id,
        PERCENTILE_DISC(invoice_amount_subtotal, 0.5) OVER(PARTITION BY user_id) AS median_amount_subtotal_per_invoice,
        PERCENTILE_DISC(unique_invoice_items, 0.5) OVER(PARTITION BY user_id) AS median_items_per_invoice
    FROM (
        SELECT
            il.user_id, il.invoice_id,
            SUM(iil.per_item_sell_price * iil.quantity) AS invoice_amount_subtotal,
            COUNT(DISTINCT iil.item_id) AS unique_invoice_items
        FROM {{ref("invoices_latest")}} AS il
        LEFT JOIN {{ref("invoice_items_latest")}} AS iil ON iil.invoice_id = il.invoice_id
        GROUP BY user_id, invoice_id
        )
)
SELECT
    base_fields.*,
    user_no_of_businesses.no_of_businesses,
    contacts_stats.* EXCEPT (user_id),
    contacts_stats_2.* EXCEPT (user_id),
    invoice_stats.* EXCEPT (user_id),
    invoice_median_daily_stats.* EXCEPT (user_id),
    invoice_median_weekly_stats.* EXCEPT (user_id),
    invoice_median_monthly_stats.* EXCEPT (user_id),
    median_per_invoice_stats.* EXCEPT (user_id),
    quotation_stats.* EXCEPT (user_id),
    order_stats.* EXCEPT (user_id),
    inventory_stats.* EXCEPT (user_id)
FROM base_fields
LEFT JOIN user_no_of_businesses ON user_no_of_businesses.user_id = base_fields.user_id
LEFT JOIN contacts_stats ON contacts_stats.user_id = base_fields.user_id
LEFT JOIN contacts_stats_2 ON contacts_stats_2.user_id = base_fields.user_id
LEFT JOIN invoice_stats ON invoice_stats.user_id = base_fields.user_id
LEFT JOIN invoice_median_daily_stats ON invoice_median_daily_stats.user_id = base_fields.user_id
LEFT JOIN invoice_median_weekly_stats ON invoice_median_weekly_stats.user_id = base_fields.user_id
LEFT JOIN invoice_median_monthly_stats ON invoice_median_monthly_stats.user_id = base_fields.user_id
LEFT JOIN median_per_invoice_stats ON median_per_invoice_stats.user_id = base_fields.user_id
LEFT JOIN quotation_stats ON quotation_stats.user_id = base_fields.user_id
LEFT JOIN order_stats ON order_stats.user_id = base_fields.user_id
LEFT JOIN inventory_stats ON inventory_stats.user_id = base_fields.user_id