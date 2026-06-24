{{
    config(
        materialized='incremental',
        tags="poc"
    )
}}

select
    cast(null as varchar) as model_name,
    cast(null as timestamp_ntz) as run_started_at,
    cast(null as timestamp_ntz) as run_completed_at
where 1 = 0