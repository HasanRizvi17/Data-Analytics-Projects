WITH 

orders_data AS (
    SELECT 
        DATE(il.created_at) AS p_date,
        il.order_id, il.user_id, il.business_id, il.contact_id, il.type AS order_type
    FROM {{ ref('orders_latest') }} AS il
),

order_items_data AS (
    SELECT 
        il.order_id,
        iil.item_id, iil.stock_id, iil.name, iil.code, iil.per_item_sell_price, iil.quantity, iil.sell_currency
    FROM {{ ref('orders_latest') }} AS il
    LEFT JOIN {{ ref('order_items_latest') }} AS iil ON iil.order_id = il.order_id
),

order_items_stats AS (
    SELECT 
        order_id,
        SUM(per_item_sell_price * quantity) AS order_amount_subtotal,
        COUNT(DISTINCT item_id) AS unique_order_items
    FROM order_items_data
    GROUP BY order_id
),

final_orders_dataset AS (
    SELECT 
        orders_data.*,
        order_items_stats.order_amount_subtotal,
        order_items_stats.unique_order_items
    FROM orders_data
    LEFT JOIN order_items_stats ON order_items_stats.order_id = orders_data.order_id 
),

orders_stats AS (
SELECT p_date, order_id, user_id, business_id, contact_id, order_type,
        COUNT(DISTINCT order_id) AS no_of_orders,
        SUM(order_amount_subtotal) AS order_amount_subtotal
FROM final_orders_dataset
GROUP BY p_date, order_id, user_id, business_id, contact_id, order_type
)

SELECT
    orders_stats.*,
    SUM(no_of_orders) OVER(PARTITION BY user_id, business_id, contact_id, order_type ORDER BY p_date ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS cum_no_of_invoices,
    SUM(order_amount_subtotal) OVER(PARTITION BY user_id, business_id, contact_id, order_type ORDER BY p_date ROWS BETWEEN UNBOUNDED PRECEDING AND 0 PRECEDING) AS cum_order_amount_subtotal
FROM orders_stats



