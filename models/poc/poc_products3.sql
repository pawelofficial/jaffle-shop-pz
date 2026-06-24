-- depends_on: {{ ref('audit_table') }}
{{
    config(
        materialized='incremental',
        unique_key="product_id",
        tags="poc",
        pre_hook="INSERT INTO marts.audit_table (model_name, run_started_at,run_completed_at) VALUES ('{{ this.name }}', '{{ run_started_at }}',null )"
        ,post_hook="UPDATE marts.audit_table SET run_completed_at = CURRENT_TIMESTAMP() WHERE model_name = '{{ this.name }}' AND run_started_at = '{{ run_started_at }}'"
    )
}}



select distinct product_id
,{{cleanup_product_name('product_name') }} as  product_name
from {{ref('products')}}
