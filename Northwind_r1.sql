--SMTH is wrong
with product_det as(
	select
	p.product_id as Product_id,
	p.product_name as Product_Name,
	c.category_name as category_name
	from products p
	inner join categories c on c.category_id=p.category_id	
),
order_summary as (
select
	od.order_id as order_id,
	od.product_id as product_id,
	round((od.unit_price*od.quantity)::numeric,2) as gross_revenue,
	sum(od.discount) as discount_amount,
	round((sum(od.unit_price*od.quantity - od.discount))::numeric,2) as net_revenue,
	to_char(o.order_date, 'YYYY-MM') as year_month
	from order_details od
	left join orders o on od.order_id = o.order_id
	group by od.order_id,od.product_id,o.order_date
	),
product_revenue as (
    select 
        p.category_id,
		od.product_id,
        c.category_name,
        p.product_name,
		extract(year from o.order_date) as order_year,
		extract (month from o.order_date) as order_month,
        sum(od.unit_price * od.quantity - od.discount) as total_revenue
    from products p
    join order_details od on p.product_id = od.product_id
    join categories c on p.category_id = c.category_id
	join orders o on od.order_id = o.order_id
    group by p.category_id, od.product_id, c.category_name, p.product_name,order_year, order_month
),
-- select* from order_details
ranked_products as (
    select 
		product_id,
		category_id,
        category_name,
        product_name,
        total_revenue,
        dense_rank() over (
            partition by category_id 
            order by total_revenue desc
        ) as category_rank
    from product_revenue
),
--select * from ranked_products
mom_revenue as (
	select
		product_id,
		order_year,
		order_month,
		total_revenue,
		lag (total_revenue) over (partition by product_id order by order_year,order_month) as prev_month_revenue,
		total_revenue - lag (total_revenue) over (partition by product_id order by order_year,order_month) as mom_revenue_change
	from product_revenue	
)

--select * from mom_revenue
select
    pd.product_id,
    pd.product_name,
    pd.category_name,
    os.gross_revenue,
    os.discount_amount,
    os.net_revenue,
    os.year_month,
    rp.category_rank,
    mr.prev_month_revenue,
    mr.mom_revenue_change
from product_det pd
join ranked_products rp on pd.product_id = rp.product_id
join mom_revenue mr on pd.product_id = mr.product_id
join order_summary os on pd.product_id = os.product_id