{% test is_greater_zero(model, column_name) %}

with validation as (

    select
        {{ column_name }} as greater_zero_field

    from {{ model }}

),

validation_errors as (

    select
        greater_zero_field

    from validation
    -- if this is true, then even_field is actually odd!
    where (greater_zero_field is not null) and (greater_zero_field<0)

)

select *
from validation_errors

{% endtest %}