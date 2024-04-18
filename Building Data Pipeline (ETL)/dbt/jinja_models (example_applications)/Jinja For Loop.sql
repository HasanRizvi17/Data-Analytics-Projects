{% set status_values = dbt_utils.get_column_values(table=source("mongo_raw_data", "order_statuses"), column="state_name") %}

SELECT 
    line_item_id AS order_line_id,
    {% for status in status_values %}
        MAX(CASE WHEN state_name = "{{status}}" THEN created_at ELSE NULL END) AS {{status | lower}}_at
        {% if not loop.last %} , {% endif %}
    {% endfor %}
    ,
    {% for status in status_values %}
        MIN(CASE WHEN state_name = "{{status}}" THEN created_at ELSE NULL END) AS first_{{status | lower}}_at
        {% if not loop.last %} , {% endif %}
    {% endfor %}
FROM {{ source("mongo_raw_data", "order_statuses") }}
GROUP BY order_line_id