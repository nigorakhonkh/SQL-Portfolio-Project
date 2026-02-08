with category_summary as (
	select 
		  c.category_id,
		  c.category_name,
		  count(distinct p.product_id) as product_count,
		  round(sum(od.unit_price * od.quantity * (1 - od.discount))::numeric,2) as total_revenue
    from categories c
    inner join products p on c.category_id = p.category_id
    inner join order_details od on p.product_id = od.product_id
    group by c.category_id, c.category_name
),
totals as (
	select 
		sum(total_revenue) as grand_total
		from category_summary
),
category_pct as (
	select 
		cs.*,
		(cs.total_revenue/t.grand_total)*100 as revenue_pct
		from category_summary cs
		cross join totals t
)
select 
	category_id,
	category_name,
	product_count,
	total_revenue,
	round((revenue_pct)::numeric,4) as revenue_pct,
	round(sum(revenue_pct) over (order by total_revenue desc)::numeric,4) as cumulative_pct,
	round(total_revenue::numeric / product_count, 2) as avg_product_revenue
from category_pct
order by total_revenue desc;


