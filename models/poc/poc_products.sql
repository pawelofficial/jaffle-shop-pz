{{
    config(
        materialized='incremental'
        ,tags="poc"
    )
}}

select distinct product_name
from {{ref('products')}}
{% if is_incremental() %}
    where product_name not in (select product_name from {{ this }})
{% endif %}

-- compile without this model existing in db 
-- compile with this model existing in db 