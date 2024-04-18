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

invoice_stats AS (
    SELECT
        business_id,
        DATE_TRUNC(p_date, WEEK) AS week,
        COUNT(DISTINCT p_date) AS active_days_invoice,
        SUM(no_of_invoices) AS no_of_invoices,
        SUM(invoice_amount_subtotal) AS invoice_amount_subtotal,
        SUM(invoice_amount_final) AS invoice_amount_final,
        COUNT(DISTINCT contact_id) AS active_contacts_invoice
    FROM facts.invoices_fct`
    GROUP BY business_id, week
),

quotation_stats AS (
    SELECT
        business_id,
        DATE_TRUNC(p_date, WEEK) AS week,
        COUNT(DISTINCT p_date) AS active_days_quotation,
        SUM(no_of_quotations) AS no_of_quotations,
        SUM(quotation_amount_subtotal) AS quotation_amount_subtotal,
        SUM(quotation_amount_final) AS quotation_amount_final
    FROM facts.quotations_fct`
    GROUP BY business_id, week
),

order_stats AS (
    SELECT
        business_id,
        DATE_TRUNC(p_date, WEEK) AS week,
        COUNT(DISTINCT p_date) AS active_days_order,
        SUM(no_of_orders) AS no_of_orders,
        SUM(order_amount_subtotal) AS order_amount_subtotal
    FROM facts.orders_fct`
    GROUP BY business_id, week
),

contacts_stats AS (
    SELECT
        business_id,
        DATE_TRUNC(created_at, WEEK) AS week,
        COUNT(DISTINCT contact_id) AS no_of_contacts_created
    FROM latest_data.contacts_latest`
    GROUP BY business_id, week
),

inventory_stats AS (
    SELECT
        isl.business_id,
        DATE_TRUNC(il.created_at, WEEK) AS week,
        COUNT(DISTINCT isl.inventory_id) AS no_of_new_skus_created
    FROM latest_data.inventories_stock_latest` AS isl
    LEFT JOIN latest_data.inventories_latest`AS il ON il.inventory_id = isl.inventory_id
    GROUP BY isl.business_id, week
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

,final AS (
    SELECT
        base_fields.*,
        invoice_stats.* EXCEPT (business_id),
        contacts_stats.* EXCEPT (business_id, week),
        -- contacts_stats_2.* EXCEPT (business_id),
        -- invoice_median_daily_stats.* EXCEPT (business_id),
        -- invoice_median_weekly_stats.* EXCEPT (business_id),
        -- invoice_median_monthly_stats.* EXCEPT (business_id),
        -- median_per_invoice_stats.* EXCEPT (business_id),
        quotation_stats.* EXCEPT (business_id, week),
        order_stats.* EXCEPT (business_id, week),
        inventory_stats.* EXCEPT (business_id, week)
    -- LEFT JOIN user_no_of_businesses ON user_no_of_businesses.user_id = base_fields.user_id
    FROM invoice_stats
    LEFT JOIN base_fields ON invoice_stats.business_id = base_fields.business_id
    LEFT JOIN contacts_stats ON contacts_stats.business_id = base_fields.business_id AND contacts_stats.week = invoice_stats.week
    -- LEFT JOIN invoice_median_daily_stats ON invoice_median_daily_stats.business_id = base_fields.business_id
    -- LEFT JOIN invoice_median_weekly_stats ON invoice_median_weekly_stats.business_id = base_fields.business_id
    -- LEFT JOIN invoice_median_monthly_stats ON invoice_median_monthly_stats.business_id = base_fields.business_id
    -- LEFT JOIN median_per_invoice_stats ON median_per_invoice_stats.business_id = base_fields.business_id
    LEFT JOIN quotation_stats ON quotation_stats.business_id = base_fields.business_id AND quotation_stats.week = invoice_stats.week
    LEFT JOIN order_stats ON order_stats.business_id = base_fields.business_id AND order_stats.week = invoice_stats.week
    LEFT JOIN inventory_stats ON inventory_stats.business_id = base_fields.business_id AND inventory_stats.week = invoice_stats.week
    -- LEFT JOIN atleast_2_invoices_weeks ON atleast_2_invoices_weeks.business_id = base_fields.business_id
    -- LEFT JOIN external_data.businesses_non_db_data AS non_db ON non_db.business_id = base_fields.business_id
    -- WHERE (non_db.user_status = 'Activated' OR non_db.deactivation_reason NOT IN ('Duplicate Account', 'Test Account'))
     
)

SELECT *
FROM final
ORDER BY business_id, week


