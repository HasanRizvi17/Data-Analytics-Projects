WITH

base_fields AS (
    SELECT
        b.business_id, b.business_name,
        b.user_id, u.full_name AS user_name, u.mobile_number, u.created_at AS signup_date,
        b.created_at AS business_signup_date,
        DATE_DIFF(CURRENT_DATE(), b.created_at, DAY) AS days_since_signup,
        b.address AS business_address, b.business_type, b.supply_chain_role
        -- business_activity_status -- use events data to get last activity
    FROM {{ref("businesses_latest")}} AS b
    LEFT JOIN {{ref("users_latest")}} AS u ON u.user_id = b.user_id
),

user_no_of_businesses AS (
    SELECT
        user_id,
        COUNT(DISTINCT business_id) AS no_of_businesses_of_parent_user
    FROM {{ ref("businesses_latest") }}
    GROUP BY user_id
),

invoice_stats AS (
    SELECT
        business_id,
        COUNT(DISTINCT p_date) AS active_days_invoice,
        COUNT(DISTINCT DATE_TRUNC(p_date, WEEK)) AS active_weeks_invoice,
        COUNT(DISTINCT DATE_TRUNC(p_date, MONTH)) AS active_months_invoice,
        SUM(no_of_invoices) AS no_of_invoices,
        SUM(invoice_amount_subtotal) AS invoice_amount_subtotal,
        SUM(invoice_amount_final) AS invoice_amount_final,
        MIN(p_date) AS first_invoice_date,
        DATE_DIFF(CURRENT_DATE(), MAX(p_date), DAY) AS days_since_last_invoice
    FROM {{ref("invoices_fct")}}
    GROUP BY business_id
),

quotation_stats AS (
    SELECT
        business_id,
        COUNT(DISTINCT p_date) AS active_days_quotation,
        COUNT(DISTINCT DATE_TRUNC(p_date, WEEK)) AS active_weeks_quotation,
        COUNT(DISTINCT DATE_TRUNC(p_date, MONTH)) AS active_months_quotation,
        SUM(no_of_quotations) AS no_of_quotations,
        SUM(quotation_amount_subtotal) AS quotation_amount_subtotal,
        SUM(quotation_amount_final) AS quotation_amount_final,
        DATE_DIFF(CURRENT_DATE(), MAX(p_date), DAY) AS days_since_last_quotation
    FROM {{ref("quotations_fct")}}
    GROUP BY business_id
),

order_stats AS (
    SELECT
        business_id,
        COUNT(DISTINCT p_date) AS active_days_order,
        COUNT(DISTINCT DATE_TRUNC(p_date, WEEK)) AS active_weeks_order,
        COUNT(DISTINCT DATE_TRUNC(p_date, MONTH)) AS active_months_order,
        SUM(no_of_orders) AS no_of_orders,
        SUM(order_amount_subtotal) AS order_amount_subtotal,
        DATE_DIFF(CURRENT_DATE(), MAX(p_date), DAY) AS days_since_last_order
    FROM {{ref("orders_fct")}}
    GROUP BY business_id
),

contacts_stats AS (
    SELECT
        business_id,
        COUNT(DISTINCT contact_id) AS no_of_contacts,
        -- SUM(CASE WHEN business_relationship = 'customer' THEN 1 ELSE 0 END) AS contacts_as_customers,
        -- SUM(CASE WHEN business_relationship = 'supplier' THEN 1 ELSE 0 END) AS contacts_as_customers,
        SUM(CASE WHEN balance_amount > 0 THEN 1 ELSE 0 END) AS contacts_with_positive_balance,
        SUM(CASE WHEN balance_amount < 0 THEN 1 ELSE 0 END) AS contacts_with_negative_balance,
        SUM(CASE WHEN balance_amount = 0 THEN 1 ELSE 0 END) AS contacts_with_zero_balance
    FROM {{ref("contacts_latest")}}
    GROUP BY business_id
),

contacts_stats_2 AS (
    SELECT
        business_id,
        COUNT(DISTINCT contact_id) AS activated_contacts,
        COUNT(DISTINCT CASE WHEN DATE_DIFF(CURRENT_DATE(), p_date, DAY) <= 14 THEN contact_id ELSE NULL END) AS active_contacts
    FROM {{ref("invoices_fct")}}
    GROUP BY business_id
),

inventory_stats AS (
    SELECT
        business_id,
        COUNT(DISTINCT inventory_id) AS unique_inventory_items,
        SUM(per_item_cost_price * quantity) AS total_inventory_value,
        SUM(quantity) AS total_inventory_quantity,
        MAX(last_stocked_at) AS last_inventory_restock_time,
        DATE_DIFF(CURRENT_DATE(), MAX(last_stocked_at), DAY) AS days_since_last_inventory_restock
    FROM {{ref("inventories_stock_latest")}}
    GROUP BY business_id
),

invoice_median_daily_stats AS (
    SELECT
        DISTINCT business_id,
        PERCENTILE_DISC(no_of_invoices, 0.5) OVER(PARTITION BY business_id) AS median_daily_invoices,
        PERCENTILE_DISC(invoice_amount_final, 0.5) OVER(PARTITION BY business_id) AS median_daily_invoice_amount_final
    FROM (
        SELECT business_id, DATE_TRUNC(p_date, DAY) AS date,
                SUM(no_of_invoices) AS no_of_invoices,
                SUM(invoice_amount_final) AS invoice_amount_final
        FROM {{ref("invoices_fct")}}
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
        FROM {{ref("invoices_fct")}}
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
        FROM {{ref("invoices_fct")}}
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
        FROM {{ref("invoices_latest")}} AS il
        LEFT JOIN {{ref("invoice_items_latest")}} AS iil ON iil.invoice_id = il.invoice_id
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
        FROM {{ref("invoices_fct")}}
        GROUP BY business_id, week
        HAVING COUNT(*) >= 2  
    ) AS temp
    GROUP BY business_id
)

SELECT
    base_fields.*,
    CASE 
        WHEN invoice_stats.no_of_invoices >= 5 OR order_stats.no_of_orders >= 5 OR quotation_stats.no_of_quotations >= 5 OR inventory_stats.unique_inventory_items >= 5 OR contacts_stats.no_of_contacts >= 5 THEN 'Activated'
        ELSE 'Not Activated'
    END AS activation_status,
    CASE
        WHEN LEAST(COALESCE(days_since_last_invoice, 999999), COALESCE(days_since_last_order, 999999), COALESCE(days_since_last_quotation, 999999), COALESCE(days_since_last_inventory_restock, 999999)) BETWEEN 0 AND 3 THEN 'A: Active in last 3 days'
        WHEN LEAST(COALESCE(days_since_last_invoice, 999999), COALESCE(days_since_last_order, 999999), COALESCE(days_since_last_quotation, 999999), COALESCE(days_since_last_inventory_restock, 999999)) BETWEEN 4 AND 7 THEN 'B: Active 4-7 days ago'
        WHEN LEAST(COALESCE(days_since_last_invoice, 999999), COALESCE(days_since_last_order, 999999), COALESCE(days_since_last_quotation, 999999), COALESCE(days_since_last_inventory_restock, 999999)) BETWEEN 8 AND 14 THEN 'C: Active 8-14 days ago'
        WHEN LEAST(COALESCE(days_since_last_invoice, 999999), COALESCE(days_since_last_order, 999999), COALESCE(days_since_last_quotation, 999999), COALESCE(days_since_last_inventory_restock, 999999)) >= 15 THEN 'D: Active more than 14 days ago'
        ELSE 'Never made any entry'
    END AS last_activity_status,
    LEAST(COALESCE(days_since_last_invoice, 999999), COALESCE(days_since_last_order, 999999), COALESCE(days_since_last_quotation, 999999), COALESCE(days_since_last_inventory_restock, 999999)) AS days_since_last_entry_any_module,
    contacts_stats.* EXCEPT (business_id),
    contacts_stats_2.* EXCEPT (business_id),
    invoice_stats.* EXCEPT (business_id),
    invoice_median_daily_stats.* EXCEPT (business_id),
    invoice_median_weekly_stats.* EXCEPT (business_id),
    invoice_median_monthly_stats.* EXCEPT (business_id),
    median_per_invoice_stats.* EXCEPT (business_id),
    quotation_stats.* EXCEPT (business_id),
    order_stats.* EXCEPT (business_id),
    inventory_stats.* EXCEPT (business_id),
    DATE_DIFF(CURRENT_DATE('Asia/Karachi'), first_invoice_date, WEEK) + 1 AS no_of_weeks_since_first_invoice,
    atleast_2_invoices_weeks.no_of_weeks_with_atleast_2_invoices,
    SAFE_DIVIDE(atleast_2_invoices_weeks.no_of_weeks_with_atleast_2_invoices, (DATE_DIFF(CURRENT_DATE('Asia/Karachi'), first_invoice_date, WEEK) + 1)) AS perc_active_weeks
FROM base_fields
LEFT JOIN user_no_of_businesses ON user_no_of_businesses.user_id = base_fields.user_id
LEFT JOIN contacts_stats ON contacts_stats.business_id = base_fields.business_id
LEFT JOIN contacts_stats_2 ON contacts_stats_2.business_id = base_fields.business_id
LEFT JOIN invoice_stats ON invoice_stats.business_id = base_fields.business_id
LEFT JOIN invoice_median_daily_stats ON invoice_median_daily_stats.business_id = base_fields.business_id
LEFT JOIN invoice_median_weekly_stats ON invoice_median_weekly_stats.business_id = base_fields.business_id
LEFT JOIN invoice_median_monthly_stats ON invoice_median_monthly_stats.business_id = base_fields.business_id
LEFT JOIN median_per_invoice_stats ON median_per_invoice_stats.business_id = base_fields.business_id
LEFT JOIN quotation_stats ON quotation_stats.business_id = base_fields.business_id
LEFT JOIN order_stats ON order_stats.business_id = base_fields.business_id
LEFT JOIN inventory_stats ON inventory_stats.business_id = base_fields.business_id
LEFT JOIN atleast_2_invoices_weeks ON atleast_2_invoices_weeks.business_id = base_fields.business_id
-- LEFT JOIN external_data.businesses_non_db_data AS non_db ON non_db.business_id = base_fields.business_id
-- WHERE (non_db.user_status = 'Activated' OR non_db.deactivation_reason NOT IN ('Duplicate Account', 'Test Account'))
