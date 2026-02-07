with shipper_det as (
	select 
	shipper_id,
	company_name as shipper_name
	from shippers
),
shipped_orders as (
	select 
	ship_via,
	count(shipped_date) as total_orders,
	sum(freight) as total_freight,
	round(avg(shipped_date - order_date)::numeric,2) as avg_days_to_ship,
	count(case when shipped_date <= required_date then 1 end) as on_time_shipments,
	count (case when shipped_date > required_date then 1 end) as late_shipments,
    round(count(case when shipped_date <= required_date then 1 end)*100/count(shipped_date)) as on_time_pct	
	from orders
	where shipped_date is not null and required_date is not null 
	group by ship_via
)

-- select distinct * from orders
-- select * from shippers
select 
	sd.shipper_id,
	sd.shipper_name,
	so.total_orders,
	so.total_freight,
	round((so.total_freight/so.total_orders)::numeric,2) as avg_freight_per_order,
	so.avg_days_to_ship,
	so.on_time_shipments,
	so.late_shipments,
	so.on_time_pct
	from shipped_orders so
	right join shipper_det sd on sd.shipper_id = so.ship_via
