

describe task dbt_dev.raw.insert_mock_order;
alter task dbt_dev.raw.insert_mock_order resume;

select count(*) from raw.raw_orders; --61948 

create or replace task dbt_dev.raw.insert_mock_order
  schedule = '1 minute'
as
insert into dbt_dev.raw.raw_orders (
    id, customer, ordered_at, store_id,
    subtotal, tax_paid, order_total
)
with pick as (
    select customer, store_id
    from dbt_dev.raw.raw_orders
    order by random() limit 1
),
amt as (
    select uniform(100, 5000, random()) as subtotal   -- see units note below
),
calc as (
    select subtotal, round(subtotal * 0.06) as tax_paid
    from amt
)
select
    uuid_string(),                       -- id: fresh random UUID
    pick.customer,                       -- picked from an existing row
    current_timestamp(),                 -- ordered_at
    pick.store_id,                       -- picked from the SAME existing row
    calc.subtotal,
    calc.tax_paid,
    calc.subtotal + calc.tax_paid        -- order_total = subtotal + tax
from pick cross join calc;

alter task