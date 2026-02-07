with product_det as (
	select 
		p.product_id as product_id,
		p.product_name as product_name,
		s.company_name as supplier,
		c.category_name as category,
		p.units_in_stock as units_in_stock,
		p.reorder_level as reorder_level,
		case
			when p.units_in_stock =0 and p.reorder_level = 0 then 'Yes'
			when p.units_in_stock < p.reorder_level then 'No'
			else 'Checking' 
			end as need_reorder,
		Max(p.units_in_stock * p.unit_price) as inventory_value,
		coalesce(sum(od.quantity),0) as total_unit_sold
		from products p
		join suppliers s on p.supplier_id = s.supplier_id
		join categories c on p.category_id = c.category_id
		left join order_details od on p.product_id = od.product_id

		group by p.product_id, p.product_name,p.units_in_stock,p.reorder_level,s.company_name,c.category_name),
		
product_revenue as (
	select 
		p.product_id,
        p.supplier_id ,
        s.company_name as supplier_name,
        p.product_name as product_name,
        sum(od.unit_price * od.quantity* (1- od.discount)) as total_revenue
    from products p
    join order_details od on od.product_id = p.product_id
    join suppliers s on p.supplier_id = s.supplier_id
    group by p.supplier_id, s.company_name, p.product_name,p.product_id
),

supplier_rank as (
	 select 
	 	product_id,
        supplier_name,
        product_name,
        total_revenue,
        dense_rank() over (partition by supplier_name order by total_revenue desc) as supplier_rank
    from product_revenue
)

select 
	pd.product_id,
	pd.product_name,
	pd.supplier,
	pd.category,
	pd.units_in_stock,
	pd.reorder_level,
	pd.need_reorder,
	pd.inventory_value,
	pd.total_unit_sold,
	sr.supplier_rank
	from product_det pd
	join supplier_rank sr on pd.product_id = sr.product_id