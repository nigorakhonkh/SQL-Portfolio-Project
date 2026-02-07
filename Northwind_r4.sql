with employee_details as (
	select 
		e.employee_id as employee_id,
		e.first_name ||' '|| e.last_name as employee_name,
		e.title as title,
		coalesce(e1.first_name ||' '|| e1.last_name,'N/A') as reports_to
		from employees e
		left join employees e1 on e.reports_to = e1.employee_id 
),
employee_orders as (
	select 
		o.employee_id as employee_id,
		count(distinct o.order_id) as total_orders,
		round(sum(od.unit_price * od.quantity * (1 - od.discount))::numeric,2) as total_revenue
		from orders o
		join order_details od on o.order_id = od.order_id
		group by o.employee_id
		
),
team_average as (
	select 
		round(avg(total_orders)::numeric,2) as team_avg_orders,
		round(avg(total_revenue)::numeric,2) as team_avg_revenue
	from employee_orders
),
performance_rank as (
	select 
		employee_id,
        total_revenue,
        dense_rank() over (order by total_revenue desc) as performance_rank
    from employee_orders
	
)

select e.employee_id,
	   e.employee_name,
	   e.title,
	   e.reports_to,
	   coalesce(eo.total_orders,0) as total_orders,
	   coalesce(eo.total_revenue,0) as total_revenue,
	   round(coalesce(eo.total_revenue/eo.total_orders,0),2) as average_order_value,
	   ta.team_avg_revenue,
	   round(coalesce(eo.total_revenue - ta.team_avg_revenue/ta.team_avg_revenue,0) * 100,2) as pct_vs_team_avg,
	   pr.performance_rank
from employee_details e
left join employee_orders eo on e.employee_id = eo.employee_id
cross join team_average ta
left join performance_rank pr on e.employee_id = pr.employee_id

-- employee_id
-- employee_name
-- title
-- reports_to_name
-- total_orders
-- total_revenue
-- avg_order_value
-- team_avg_revenue

-- performance_rank
