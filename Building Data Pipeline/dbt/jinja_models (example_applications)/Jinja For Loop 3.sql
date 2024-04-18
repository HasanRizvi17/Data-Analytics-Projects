-- using get_column_values macro from the dbt_utils package to create a list of unique values in the entry_type field
{% set entry_types = dbt_utils.get_column_values(table=ref('fct_entry'), column='entry_type') %}

SELECT
    DATE_TRUNC(p_date, MONTH) AS p_month,
    SUM(no_of_stock_entry) AS total_stock_entry,
    SUM(quantity_double) AS total_quantity,
    {% for entry_type_value in entry_types %}
    SUM(CASE WHEN entry_type = '{{entry_type_value}}' THEN no_of_stock_entry ELSE 0 END) AS no_of_{{entry_type_value}}_stock_entry,
    SUM(CASE WHEN entry_type = '{{entry_type_value}}' THEN quantity_double ELSE 0 END) AS {{entry_type_value}}_quantity
    {% if not loop.last %} , {% endif %}
    {% endfor %}
    -- we can also run separate for loops for the aggregated fields for stock_entry and quantity above
FROM {{ ref('fct_entry') }}
GROUP BY p_month



