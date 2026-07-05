with
source as (
    select * from {{ source('ecom', 'raw_stores') }}
),
renamed as (
    select
        *  
    from source
)
select * from renamed
{% if is_incremental() %}
where supply_uuid not in (select supply_uuid from {{ this }} ) 
{% endif %}