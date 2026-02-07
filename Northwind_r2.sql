with order_summary as (
	select 
		c.customer_id as customer_id,
		count(distinct o.order_id) as total_orders,
		round(sum(od.unit_price * od.quantity * (1 - od.discount))::numeric,2) as total_spent,
		min(order_date) as first_order,
		max(order_date) as last_order
		from orders  o
		join customers c on o.customer_id = c.customer_id
		join order_details od on o.order_id = od.order_id
		group by c.customer_id
		
),
customer_tier as (
		select
		customer_id,
		total_spent,
		NTILE(3) OVER (order by total_spent desc) as tier_num
		from order_summary
),
-- select * from customer_tier
spending_rank as (
	select 
	customer_id,
	total_spent,
	rank() over (order by total_spent desc) as spending_rank
	from order_summary
	
)

-- select * from spending_rank
select
    c.customer_id,
    c.company_name,
    c.country,
    os.total_orders,
    os.total_spent,
    round((os.total_spent / os.total_orders)::numeric, 2) as avg_order_value,
    sr.spending_rank,
	ct.tier_num,
	os.first_order,
	os.last_order
from customers c
join order_summary os on c.customer_id = os.customer_id
join spending_rank sr on c.customer_id = sr.customer_id
join customer_tier ct on c.customer_id = ct.customer_id


