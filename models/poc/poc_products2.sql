{{
    config(
        materialized='incremental'
        ,unique_key="product_id"
        ,tags="poc"
    )
}}

select distinct product_id
,{{cleanup_product_name('product_name') }} as  product_name
from {{ref('products')}}
