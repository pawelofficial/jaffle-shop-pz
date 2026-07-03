with
source as (
    select * from {{ source('ecom', 'raw_products') }}
),
renamed as (
    select
        sku as product_id,
        name as product_name,
        type as product_type,
        description as product_description,
        {{ cents_to_dollars('price') }} as product_price,
        coalesce(type = 'jaffle', false) as is_food_item,
        coalesce(type = 'beverage', false) as is_drink_item
    from source
)
select * from renamed
{% if is_incremental() %}
where product_id not in (select product_id from {{ this }} ) 
{% endif %}
