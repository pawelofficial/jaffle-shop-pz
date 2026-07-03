with
source as (
    select * from {{ source('ecom', 'raw_customers') }}
),
renamed as (
    select
        id as customer_id,
        name as customer_name
    from source
)

select * from renamed
{% if is_incremental() %}
where customer_id not in (select customer_id from {{ this }} ) 
{% endif %}