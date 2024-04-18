{% macro MEDIAN(column) %}
    CASE 
        WHEN MOD(ARRAY_LENGTH(ARRAY_AGG({{ column }} ORDER BY {{ column }})), 2) = 0 
            THEN (ARRAY_AGG({{ column }} ORDER BY {{ column }})[CAST(ROUND(ARRAY_LENGTH(ARRAY_AGG({{ column }} ORDER BY {{ column }}))/2) - 1 AS INT)] + ARRAY_AGG({{ column }} ORDER BY {{ column }})[CAST(ROUND(ARRAY_LENGTH(ARRAY_AGG({{ column }} ORDER BY {{ column }}))/2) AS INT)]) / 2 
        ELSE ARRAY_AGG({{ column }} ORDER BY {{ column }})[CAST(ROUND(ARRAY_LENGTH(ARRAY_AGG({{ column }} ORDER BY {{ column }}))/2) - 1 AS INT)]
    END
{% endmacro %}


{% macro median_backup(column) %}
IF(MOD(ARRAY_LENGTH(ARRAY_AGG({{ column }})), 2) = 0,
    (ARRAY_AGG({{ column }} ORDER BY {{ column }})[SAFE_ORDINAL(CAST(ARRAY_LENGTH(ARRAY_AGG({{ column }})) / 2 AS INT))] +
    ARRAY_AGG({{ column }} ORDER BY {{ column }})[SAFE_ORDINAL(CAST(ARRAY_LENGTH(ARRAY_AGG({{ column }})) / 2 + 1 AS INT))]) / 2,
    ARRAY_AGG({{ column }} ORDER BY {{ column }})[SAFE_ORDINAL(CAST(ARRAY_LENGTH(ARRAY_AGG({{ column }})) / 2 + 1 AS INT))]
)
{% endmacro %}