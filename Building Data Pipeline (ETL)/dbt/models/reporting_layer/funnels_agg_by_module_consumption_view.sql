WITH 

invoice_temp_funnels AS
      (
      SELECT 
        'Invoice' AS module, 
        COUNT(*) AS total_businesses,
        COUNT(DISTINCT CASE WHEN COALESCE(no_of_invoices, 0) >= 1 THEN bus.business_id ELSE NULL END) AS businesses_with_atleast_1_invoice,
        COUNT(DISTINCT CASE WHEN COALESCE(no_of_invoices, 0) >= 2 THEN bus.business_id ELSE NULL END) AS businesses_with_atleast_2_invoices,
        COUNT(DISTINCT CASE WHEN COALESCE(no_of_invoices, 0) >= 5 THEN bus.business_id ELSE NULL END) AS businesses_with_atleast_5_invoices
      FROM dimension.businesses_dim` AS bus
      LEFT JOIN external_data.businesses_non_db_data AS non_db ON non_db.business_id = bus.business_id
      WHERE (non_db.user_status = 'Activated' OR non_db.deactivation_reason NOT IN ('Duplicate Account', 'Test Account'))
      ),
      
invoice_temp_funnels_2 AS
      (
      SELECT module, 'A: Total' AS funnel_stage, total_businesses AS no_of_businesses FROM invoice_temp_funnels
      UNION ALL
      SELECT module, 'B: Created >= 1 Invoices' AS funnel_stage, businesses_with_atleast_1_invoice AS no_of_businesses FROM invoice_temp_funnels
      UNION ALL
      SELECT module, 'C: Created >= 2 Invoices' AS funnel_stage, businesses_with_atleast_2_invoices AS no_of_businesses FROM invoice_temp_funnels
      UNION ALL
      SELECT module, 'D: Created >= 5 Invoices' AS funnel_stage, businesses_with_atleast_5_invoices AS no_of_businesses FROM invoice_temp_funnels
      ),

invoice_funnel_final AS
      (
      SELECT  
            invoice_temp_funnels_2.*,
            ROUND(no_of_businesses / (FIRST_VALUE(no_of_businesses) OVER(ORDER BY funnel_stage)), 3) AS overall_conversion,
            COALESCE(ROUND(no_of_businesses / (LAG(no_of_businesses, 1) OVER(ORDER BY funnel_stage)), 3), 1) AS conversion_from_previous_stage,
      FROM invoice_temp_funnels_2
      ORDER BY funnel_stage
      ),

inventory_temp_funnels AS
      (
      SELECT 
        'Inventory' AS module, 
        COUNT(*) AS total_businesses,
        COUNT(DISTINCT CASE WHEN COALESCE(unique_inventory_items, 0) >= 1 THEN bus.business_id ELSE NULL END) AS businesses_with_atleast_1_inventory_item_added,
        COUNT(DISTINCT CASE WHEN COALESCE(unique_inventory_items, 0) >= 2 THEN bus.business_id ELSE NULL END) AS businesses_with_atleast_2_inventory_items_added,
        COUNT(DISTINCT CASE WHEN COALESCE(unique_inventory_items, 0) >= 5 THEN bus.business_id ELSE NULL END) AS businesses_with_atleast_5_inventory_items_added
      FROM dimension.businesses_dim` AS bus
      LEFT JOIN external_data.businesses_non_db_data AS non_db ON non_db.business_id = bus.business_id
      WHERE (non_db.user_status = 'Activated' OR non_db.deactivation_reason NOT IN ('Duplicate Account', 'Test Account'))
      ),
      
inventory_temp_funnels_2 AS
      (
      SELECT module, 'A: Total' AS funnel_stage, total_businesses AS no_of_businesses FROM inventory_temp_funnels
      UNION ALL
      SELECT module, 'B: Created >= 1 Inventory Items' AS funnel_stage, businesses_with_atleast_1_inventory_item_added AS no_of_businesses FROM inventory_temp_funnels
      UNION ALL
      SELECT module, 'C: Created >= 2 Inventory Items' AS funnel_stage, businesses_with_atleast_2_inventory_items_added AS no_of_businesses FROM inventory_temp_funnels
      UNION ALL
      SELECT module, 'D: Created >= 5 Inventory Items' AS funnel_stage, businesses_with_atleast_5_inventory_items_added AS no_of_businesses FROM inventory_temp_funnels
      ),

inventory_funnel_final AS
      (
      SELECT  
            inventory_temp_funnels_2.*,
            ROUND(no_of_businesses / (FIRST_VALUE(no_of_businesses) OVER(ORDER BY funnel_stage)), 3) AS overall_conversion,
            COALESCE(ROUND(no_of_businesses / (LAG(no_of_businesses, 1) OVER(ORDER BY funnel_stage)), 3), 1) AS conversion_from_previous_stage,
      FROM inventory_temp_funnels_2
      ORDER BY funnel_stage
      ),

contact_temp_funnels AS
      (
      SELECT 
        'Contact' AS module, 
        COUNT(*) AS total_businesses,
        COUNT(DISTINCT CASE WHEN COALESCE(no_of_contacts, 0) >= 1 THEN bus.business_id ELSE NULL END) AS businesses_with_atleast_1_contact_added,
        COUNT(DISTINCT CASE WHEN COALESCE(no_of_contacts, 0) >= 2 THEN bus.business_id ELSE NULL END) AS businesses_with_atleast_2_contacts_added,
        COUNT(DISTINCT CASE WHEN COALESCE(no_of_contacts, 0) >= 5 THEN bus.business_id ELSE NULL END) AS businesses_with_atleast_5_contacts_added
      FROM dimension.businesses_dim AS bus
      LEFT JOIN external_data.businesses_non_db_data AS non_db ON non_db.business_id = bus.business_id
      WHERE (non_db.user_status = 'Activated' OR non_db.deactivation_reason NOT IN ('Duplicate Account', 'Test Account'))
      ),
      
contact_temp_funnels_2 AS
      (
      SELECT module, 'A: Total' AS funnel_stage, total_businesses AS no_of_businesses FROM contact_temp_funnels
      UNION ALL
      SELECT module, 'B: Created >= 1 Contacts' AS funnel_stage, businesses_with_atleast_1_contact_added AS no_of_businesses FROM contact_temp_funnels
      UNION ALL
      SELECT module, 'C: Created >= 2 Contacts' AS funnel_stage, businesses_with_atleast_2_contacts_added AS no_of_businesses FROM contact_temp_funnels
      UNION ALL
      SELECT module, 'D: Created >= 5 Contacts' AS funnel_stage, businesses_with_atleast_5_contacts_added AS no_of_businesses FROM contact_temp_funnels
      ),

contact_funnel_final AS
      (
      SELECT  
            contact_temp_funnels_2.*,
            ROUND(no_of_businesses / (FIRST_VALUE(no_of_businesses) OVER(ORDER BY funnel_stage)), 3) AS overall_conversion,
            COALESCE(ROUND(no_of_businesses / (LAG(no_of_businesses, 1) OVER(ORDER BY funnel_stage)), 3), 1) AS conversion_from_previous_stage,
      FROM contact_temp_funnels_2
      ORDER BY funnel_stage
      )

SELECT *
FROM invoice_funnel_final
UNION ALL
SELECT *
FROM inventory_funnel_final
UNION ALL
SELECT *
FROM contact_funnel_final
ORDER BY module, funnel_stage


