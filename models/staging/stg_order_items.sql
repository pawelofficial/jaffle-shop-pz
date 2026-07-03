with
source as (
    select * from {{ source('ecom', 'raw_items') }}
),
renamed as (
    select
        id as order_item_id,
        order_id,
        sku as product_id
    from source
)
select * from renamed
{% if is_incremental() %}
where order_item_id not in (select order_item_id from {{ this }} ) 
{% endif %}
