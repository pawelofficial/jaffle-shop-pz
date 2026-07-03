with
source as (
    select * from {{ source('ecom', 'raw_stores') }}
),
renamed as (
    select
        id as location_id,
        name as location_name,
        tax_rate,
        {{ dbt.date_trunc('day', 'opened_at') }} as opened_date
    from source
)
select * from renamed
{% if is_incremental() %}
where location_id not in (select location_id from {{ this }} ) 
{% endif %}