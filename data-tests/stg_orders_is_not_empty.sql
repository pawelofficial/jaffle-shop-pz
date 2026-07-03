with cte as ( 
select count(*) as cnt 
from {{ ref('stg_orders') }}
)
select 1 
where exists 
(
    select * from cte where cnt <=0
)
