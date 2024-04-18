{% set all_columns = dbt_utils.get_filtered_columns_in_relation(from=ref('dim_contacts')) %}
{% set required_columns = dbt_utils.get_filtered_columns_in_relation(from=ref('dim_contacts'), 
except=['mobile_number',
'user_id',
'business_id',
'contact_name',
'contact_type_name',
'contact_type_value',
'last_activity',
'status',
'is_user',
'created_at',
'deleted_at']
) %}

SELECT
    {% for column in all_columns %}
        {% if column in required_columns %}
            COALESCE({{ column }}, 0) AS {{ column }} {% if not loop.last %} , {% endif %} 
        {% else %}
            {{ column }} {% if not loop.last %} , {% endif %}
        {% endif %}
    {% endfor %}
FROM {{ ref('dim_contacts') }}
WHERE business_id = 'c92a0321-63ad-4986-bc38-e6c1503abaf3'