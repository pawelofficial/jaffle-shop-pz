with

products as (

    select * from {{ ref('stg_products') }}

)

select 
product_id
,upper(product_name) as product_name
--,product_name
,product_type
,product_description

 from products
