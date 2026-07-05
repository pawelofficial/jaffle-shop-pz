
create table if not exists dbt_dev.raw.observability_task (
    logged_at             timestamp_ntz,
    raw_customers_count   number,
    raw_items_count       number,
    raw_orders_count      number,
    raw_products_count    number,
    raw_stores_count      number,
    raw_supplies_count    number
);
select * from observability_task;
/*
2026-07-05 01:00:54.615	935	90900	61948	11	7	66
2026-07-05 01:01:54.635	936	90900	61948	12	7	66
2026-07-05 01:02:54.530	937	90900	61948	13	8	67
2026-07-05 01:36:54.603	971	91005	61982	47	42	101
*/
 --------------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------------
alter task dbt_dev.raw.INSERT_MOCK_CUSTOMER suspend;
alter task dbt_dev.raw.INSERT_MOCK_ITEMS suspend;
alter task dbt_dev.raw.INSERT_MOCK_ORDER suspend;
alter task dbt_dev.raw.INSERT_MOCK_PRODUCT suspend;
alter task dbt_dev.raw.INSERT_MOCK_STORES suspend;
alter task dbt_dev.raw.INSERT_MOCK_SUPPLIES suspend;
alter task dbt_dev.raw.LOG_OBSERVABILITY suspend;
show tasks;

create or replace task dbt_dev.raw.log_observability -- standalone: snapshots table counts every minute
  schedule = '1 minute'
as
insert into dbt_dev.raw.observability_task (
    logged_at,
    raw_customers_count,
    raw_items_count,
    raw_orders_count,
    raw_products_count,
    raw_stores_count,
    raw_supplies_count
)
select
    current_timestamp()::timestamp_ntz,
    (select count(*) from dbt_dev.raw.raw_customers),
    (select count(*) from dbt_dev.raw.raw_items),
    (select count(*) from dbt_dev.raw.raw_orders),
    (select count(*) from dbt_dev.raw.raw_products),
    (select count(*) from dbt_dev.raw.raw_stores),
    (select count(*) from dbt_dev.raw.raw_supplies)
;

create or replace task dbt_dev.raw.insert_mock_customer 
  schedule = '1 minute'
as
insert into dbt_dev.raw.raw_customers (
    id, name , updated_at timestamp_ntz
)
select
    uuid_string(),                       
    left(uuid_string(),5),
    current_timestamp()::timestamp_ntz
;
--
create or replace task dbt_dev.raw.insert_mock_items -- driver: mints a new order_id and its 1-5 line items, each picking a random product sku
  schedule = '1 minute'
as
insert into dbt_dev.raw.raw_items (
    id, order_id, sku
)
with o as (
    -- one brand-new order, and how many line items it will have
    select uuid_string() as order_id,
           uniform(1, 5, random()) as n_items
),
lines as (
    -- up to 5 candidate line slots (0..4)
    select seq4() as ln
    from table(generator(rowcount => 5))
),
picked as (
    -- assign each line slot a random product
    select l.ln, p.sku
    from lines l
    cross join dbt_dev.raw.raw_products p
    qualify row_number() over (partition by l.ln order by random()) = 1
)
select
    uuid_string() as id,
    o.order_id,
    picked.sku
from o
join picked on picked.ln < o.n_items   -- keep only n_items of the 5 slots
;
--
create or replace task dbt_dev.raw.insert_mock_order -- backfill: builds the order header for any order that has items but no header yet
  after dbt_dev.raw.insert_mock_items   -- DAG child: runs each cycle right after items are created (no own schedule)
as
insert into dbt_dev.raw.raw_orders (
    id, customer, ordered_at, store_id, subtotal, tax_paid, order_total
)
with new_orders as (
    -- orders that exist in raw_items but don't have a header row yet;
    -- subtotal is the real sum of their line items' product prices (in cents)
    select
        i.order_id,
        sum(p.price) as subtotal
    from dbt_dev.raw.raw_items i
    join dbt_dev.raw.raw_products p on i.sku = p.sku
    where not exists (
        select 1 from dbt_dev.raw.raw_orders o where o.id = i.order_id
    )
    group by i.order_id
),
with_customer as (
    -- pick a random customer per order
    select no.order_id, no.subtotal, c.id as customer_id
    from new_orders no
    cross join dbt_dev.raw.raw_customers c
    qualify row_number() over (partition by no.order_id order by random()) = 1
),
with_store as (
    -- pick a random store per order, keeping its tax_rate for the tax math
    select wc.order_id, wc.subtotal, wc.customer_id,
           s.id as store_id, s.tax_rate
    from with_customer wc
    cross join dbt_dev.raw.raw_stores s
    qualify row_number() over (partition by wc.order_id order by random()) = 1
)
select
    order_id as id,
    customer_id as customer,
    DATEADD(
      'minute',
      FLOOR(UNIFORM(0::float, 1::float, RANDOM())
            * DATEDIFF('minute', '2024-01-01', CURRENT_TIMESTAMP)),
      '2024-01-01'::TIMESTAMP_NTZ
    ) as ordered_at,
    store_id,
    subtotal,
    round(subtotal * tax_rate)            as tax_paid,
    subtotal + round(subtotal * tax_rate) as order_total
from with_store
;
create or replace task dbt_dev.raw.insert_mock_product -- truly random 
  schedule = '1 minute'
as
insert into dbt_dev.raw.raw_products (
    sku,name,type,price,description
)
select
     left(uuid_string(),3) || '-' ||  left(uuid_string(),3)   as sku                
    ,left(uuid_string(),5) as name 
    ,left(uuid_string(),5) as type 
    , uniform(0, 500, random()) as price
    ,left(uuid_string(),5) as description 

create or replace task dbt_dev.raw.insert_mock_stores -- truly random 
  schedule = '1 minute'
as
insert into dbt_dev.raw.raw_stores (
    id,name,opened_at,tax_rate
)
select
    left(uuid_string(),5) as id,
    left(uuid_string(),5) as name,
DATEADD(
  'day',
  FLOOR(UNIFORM(0::float, 1::float, RANDOM())
        * DATEDIFF('day', '2015-01-01', CURRENT_DATE)),
  '2015-01-01'::TIMESTAMP_NTZ
) + INTERVAL '9 hours'  AS opened_at,
    uniform(0, 100, random())/100.0 as tax_rate
;
alter task dbt_dev.raw.insert_mock_stores resume;
--
create or replace task dbt_dev.raw.insert_mock_supplies -- truly random 
  schedule = '1 minute'
as
insert into dbt_dev.raw.raw_supplies (
   id,name,cost,perishable,sku
)
with pick as ( 
    select sku 
    from dbt_dev.raw.raw_products
    order by random() limit 1 
)
select
    left(uuid_string(),5) as id,
    left(uuid_string(),5) as name,
    uniform(0, 100,random() )  as cost,
    case when uniform(0, 100,random() ) > 50 then True else False end as perishable ,
    sku 
    from pick 
    ;
alter task dbt_dev.raw.insert_mock_supplies resume;
--------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------