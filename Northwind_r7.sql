with region_metrics as (
	select 
		c.country as country,
		c.city as city,
		count(distinct c.customer_id) as customer_count,
		count(distinct o.order_id) as total_orders,
		round(sum(od.unit_price*od.quantity*(1-od.discount))::numeric,2) as total_revenue,
		round(avg(od.unit_price*od.quantity*(1-od.discount))::numeric,2) as avg_order_value
		from customers c
		inner join orders o  on o.customer_id = c.customer_id
		inner join order_details od on o.order_id = od.order_id
		group by c.country,c.city
),
top_products as (
	select 
	    c.country,
        c.city,
        p.product_name,
        row_number() over (partition by c.country, c.city order by sum(od.quantity) desc) as row_num
        from customers c
     	join orders o on o.customer_id = c.customer_id
    	join order_details od on od.order_id = o.order_id
    	join products p on p.product_id = od.product_id
  		group by c.country, c.city, p.product_name
)
select rm.country,
	   rm.city,
	   rm.customer_count,
	   rm.total_revenue,
	   rm.avg_order_value,
	   rank() over (partition by rm.country order by rm.total_revenue desc) as revenue_rank,
	   round(rm.total_revenue/sum(rm.total_revenue) over (partition by rm.country)*100, 4 ) as country_revenue_pct,
	   tp.product_name as top_product
	   from region_metrics rm
	   left join top_products tp on rm.country = tp.country
	   							and rm.city = tp.city
								and tp.row_num = 1
		order by rm.country, revenue_rank