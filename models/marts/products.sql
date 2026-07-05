with
products as (
    select * from {{ ref('snapshot_stg_products') }}  where dbt_valid_to is null 
)
select 
product_id
product_name
,product_type
,product_description
 from products
