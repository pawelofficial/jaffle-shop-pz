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
where id not in (select id from {{ this }} ) 
{% endif %}