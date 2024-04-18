WITH 

subtotals as
      (
      SELECT 
        inv.created_at, inv.updated_at, inv.initiation_at AS invoice_date, inv.invoice_id, inv.friendlyId AS invoice_friendly_id, 
        inv.business_id, inv.user_id,
        business_name, users.mobile_number AS user_mobile_number, inv.contact_id, inv.contact_name, inv.contact_mobile_number,  
        inv.contact_address,  
        ROUND(SUM(items.quantity * items.per_item_sell_price)) as invoice_amount_subtotal, 
        ROUND(SUM(items.quantity * isl.per_item_cost_price)) as cost_of_items_sold, 
        MAX(advance_amount) as advance_amount,
        SUM(items.quantity) as quantity_of_items, 
        COUNT(DISTINCT items.item_id) AS no_of_skus_in_invoice,
        discount_type, discount_amount AS discount, 
        COALESCE(inv.invoice_status, 'publish') AS invoice_status, 
        inv.payment_status, inv.payment_method, inv.payment_terms_due_date, inv.comments,
        inv.order_booker_id, inv.order_booker_name, inv.order_booker_mobile_number,
        -- data related to exposure to order booker module
        ob_settings.display_order_booker_module AS is_exposed_to_orderbooker_module,
        CASE 
          WHEN ob_settings.display_order_booker_module = true AND bus.created_at >= DATE('2023-10-13') THEN bus.created_at
          WHEN ob_settings.display_order_booker_module = true AND bus.created_at < DATE('2023-10-13') THEN DATE('2023-10-13')
          ELSE NULL
        END AS date_of_exposure_to_ob_module,
        CASE
          WHEN (CASE 
                  WHEN ob_settings.display_order_booker_module = true AND bus.created_at >= DATE('2023-10-13') THEN bus.created_at
                  WHEN ob_settings.display_order_booker_module = true AND bus.created_at < DATE('2023-10-13') THEN DATE('2023-10-13')
                  ELSE NULL
                END) > inv.created_at THEN 'Before Exposure to OB Module'
          WHEN (CASE 
                  WHEN ob_settings.display_order_booker_module = true AND bus.created_at >= DATE('2023-10-13') THEN bus.created_at
                  WHEN ob_settings.display_order_booker_module = true AND bus.created_at < DATE('2023-10-13') THEN DATE('2023-10-13')
                  ELSE NULL
                END) <= inv.created_at THEN 'After Exposure to OB Module'
          WHEN (CASE 
                  WHEN ob_settings.display_order_booker_module = true AND bus.created_at >= DATE('2023-10-13') THEN bus.created_at
                  WHEN ob_settings.display_order_booker_module = true AND bus.created_at < DATE('2023-10-13') THEN DATE('2023-10-13')
                  ELSE NULL
                END) IS NULL THEN NULL
          ELSE NULL
        END AS before_or_after_ob_module_launch
        
      FROM latest_data.invoices_latest inv
      left join latest_data.invoice_items_latest items on items.invoice_id = inv.invoice_id
      left join latest_data.businesses_latest bus on bus.business_id = inv.business_id
      left join latest_data.users_latest AS users on users.user_id = inv.user_id
      left join latest_data.inventories_stock_latest isl on isl.inventories_stock_id = items.stock_id
      left join latest_data.order_booker_settings_latest AS ob_settings ON ob_settings.business_id = inv.business_id
      group by inv.created_at, inv.updated_at, invoice_date, inv.invoice_id, inv.friendlyId, inv.business_id, inv.user_id,
                business_name, user_mobile_number, inv.contact_id, inv.contact_name, inv.contact_mobile_number, inv.contact_address,
                discount_type, discount, inv.invoice_status, inv.payment_status, inv.payment_method, inv.payment_terms_due_date, inv.comments,
                inv.order_booker_id, inv.order_booker_name, inv.order_booker_mobile_number,
                is_exposed_to_orderbooker_module, date_of_exposure_to_ob_module, before_or_after_ob_module_launch
      ),

extra_charges_amounts AS
      (
      SELECT inv.invoice_id, inv.business_id, SUM(extra_charges.amount) as extra_charges_amount
      FROM latest_data.invoices_latest inv, UNNEST(inv.extra_charges) extra_charges
      group by inv.invoice_id, inv.business_id
      ),

discount_amounts AS
      (
      SELECT invoice_id, business_id, 
              SUM(case 
                    when discount_type = 'percent' THEN (invoice_amount_subtotal * discount/100)
                    when discount_type = 'flat' THEN discount
                    else 0
                  end 
              ) AS discount_amount
      FROM subtotals
      GROUP BY invoice_id, business_id
      ),

tax_amounts AS
      (
      SELECT s.invoice_id, s.business_id,
              SUM(case 
                    when t.type = 'percent' AND rate IS NOT NULL THEN (invoice_amount_subtotal * rate/100)
                    when t.type = 'flat' AND rate IS NOT NULL THEN rate
                    else 0
                  end 
              ) AS tax_amount,
      FROM subtotals AS s
      LEFT JOIN latest_data.invoice_taxes_latest AS t ON t.invoice_id = s.invoice_id
      GROUP BY s.invoice_id, s.business_id
      ),

invoices_latest_loadsheets AS
      (
      SELECT 
        l.*,
        ROW_NUMBER() OVER(PARTITION BY invoice_id ORDER BY created_at DESC) AS rank
      FROM consumption_layer.loadsheets_raw_consumption AS l
      ),

invoices_latest_loadsheets_2 AS
      (
      SELECT *
      FROM invoices_latest_loadsheets
      WHERE rank = 1
      ),
      
computed_totals as
  (
    select subtotals.created_at AS invoice_creation_date, DATE(subtotals.invoice_date) AS invoice_date, subtotals.invoice_id, subtotals.invoice_friendly_id,
            subtotals.user_id, subtotals.business_id, 
            subtotals.business_name, subtotals.user_mobile_number, subtotals.contact_id, subtotals.contact_name, subtotals.contact_mobile_number,
            subtotals.contact_address,
            invoice_amount_subtotal, cost_of_items_sold, 
            COALESCE(tax_amount, 0) AS tax_amount, 
            COALESCE(discount_amount, 0) AS discount_amount, 
            -- advance_amount, 
            COALESCE(extra.extra_charges_amount, 0) AS extra_charges_amount,
            ROUND(invoice_amount_subtotal + COALESCE(tax_amount, 0) - COALESCE(discount_amount, 0) + COALESCE(extra.extra_charges_amount, 0)) as invoice_amount_final,
            ROUND((invoice_amount_subtotal + COALESCE(tax_amount, 0) - COALESCE(discount_amount, 0) + COALESCE(extra.extra_charges_amount, 0)) - cost_of_items_sold) as invoice_profit,
            ROUND(advance_amount) AS invoice_amount_paid,
            ROUND((invoice_amount_subtotal + COALESCE(tax_amount, 0) - COALESCE(discount_amount, 0) + COALESCE(extra.extra_charges_amount, 0)) - ROUND(advance_amount)) AS invoice_amount_unpaid,
            subtotals.quantity_of_items,
            no_of_skus_in_invoice, 
            subtotals.invoice_status, 
            CASE WHEN subtotals.invoice_status = 'void' THEN 'void' ELSE subtotals.payment_status END AS payment_status,
            /*
            CASE 
              WHEN subtotals.invoice_status = 'void' THEN 'void' 
              WHEN payment_status IN ('pending', 'partial') AND subtotals.invoice_status != 'void' AND CURRENT_DATE() > DATE(payment_terms_due_date) THEN 'overdue'
              ELSE payment_status
            END AS payment_status_new,
            CASE 
              WHEN payment_status IN ('pending', 'partial') AND CURRENT_DATE() > DATE(payment_terms_due_date) THEN ROUND((invoice_amount_subtotal + COALESCE(tax_amount, 0) - COALESCE(discount_amount, 0) + COALESCE(extra.extra_charges_amount, 0)) - advance_amount)
              ELSE 0
            END AS invoice_amount_overdue,
            */
            subtotals.payment_method, payment_terms_due_date, subtotals.comments,
            order_booker_id, order_booker_name, order_booker_mobile_number,
            is_exposed_to_orderbooker_module, date_of_exposure_to_ob_module, before_or_after_ob_module_launch,
            ls.load_sheet_id AS loadsheet_id, ls.created_at AS loadsheet_creation_date, ls.dispatch_date AS loadsheet_dispatch_date

  from subtotals
  left join tax_amounts tx on subtotals.invoice_id = tx.invoice_id
  left join extra_charges_amounts extra on extra.invoice_id = subtotals.invoice_id 
  left join discount_amounts discount on discount.invoice_id = subtotals.invoice_id
  left join invoices_latest_loadsheets_2 AS ls on ls.invoice_id = subtotals.invoice_id
  )

SELECT
  invoice_creation_date,
  invoice_date,
  invoice_id,
  invoice_friendly_id,
  user_id,
  business_id,
  business_name,
  user_mobile_number,
  contact_id,
  contact_name,
  contact_mobile_number,
  contact_address,
  invoice_amount_subtotal,
  cost_of_items_sold,
  tax_amount,
  discount_amount,
  extra_charges_amount,
  invoice_amount_final,
  invoice_profit,
  (CASE WHEN payment_status = 'paid' THEN invoice_amount_final ELSE invoice_amount_paid END) AS invoice_amount_paid,
  (CASE WHEN payment_status = 'paid' THEN 0 ELSE invoice_amount_unpaid END) AS invoice_amount_unpaid,
  quantity_of_items,
  no_of_skus_in_invoice,
  invoice_status,
  payment_status,
  -- new overdue logics based on invoice_date
  CASE 
    WHEN payment_status IN ('pending', 'partial') AND CURRENT_DATE() > DATE(invoice_date) THEN 'overdue'
    ELSE payment_status
  END AS payment_status_new,
  CASE 
    WHEN payment_status IN ('pending', 'partial') AND CURRENT_DATE() > DATE(invoice_date) THEN (CASE WHEN payment_status = 'paid' THEN 0 ELSE invoice_amount_unpaid END)
    ELSE 0
  END AS invoice_amount_overdue,
  -- old logic backup
  /*
  CASE 
    WHEN payment_status IN ('pending', 'partial') AND CURRENT_DATE() > DATE(payment_terms_due_date) THEN 'overdue'
    ELSE payment_status
  END AS payment_status_new,
  CASE 
    WHEN payment_status IN ('pending', 'partial') AND CURRENT_DATE() > DATE(payment_terms_due_date) THEN (CASE WHEN payment_status = 'paid' THEN 0 ELSE invoice_amount_unpaid END)
    ELSE 0
  END AS invoice_amount_overdue,
  */
  payment_method,
  payment_terms_due_date,
  comments,
  order_booker_id,
  order_booker_name,
  order_booker_mobile_number,
  is_exposed_to_orderbooker_module, 
  date_of_exposure_to_ob_module, 
  before_or_after_ob_module_launch,
  loadsheet_id, loadsheet_creation_date, loadsheet_dispatch_date
  
FROM computed_totals
-- WHERE business_id = '64708aeac1274cdd893c60ff'







