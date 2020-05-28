-- What % of orders are ship to addresses east of the Rockies vs West of the Rockies?;
select
case when 
SHIPPING_REIGION in ('Colorado', 'New Mexico', 'Wyoming', 'Montana', 'Idaho', 'Washington', 'Oregon', 'California', 'Nevada', 'Arizona', 'Utah') then 'west' else 'east' end as location,
count(distinct order_name) as num_orders
from
fact_sales
where sales_channel = 'eCommerce'
and profit_center_country = 'United States'
and year(happened_at_local_date) = 2019
and event_type = 'order'
group by 1
order by 1

-- what % of orders are >$800?;

select location, count(distinct order_name) from
(
select
order_name,
case when 
SHIPPING_REIGION in ('Colorado', 'New Mexico', 'Wyoming', 'Montana', 'Idaho', 'Washington', 'Oregon', 'California', 'Nevada', 'Arizona', 'Utah') then 'west' else 'east' end as location,
sum(gross_sales_usd) as gross_sales_usd
from
fact_sales
where sales_channel = 'eCommerce'
and profit_center_country = 'United States'
and year(happened_at_local_date) = 2019
and event_type = 'order'
group by 1, 2
order by 1, 2
)
where gross_sales_usd >= 800
group by 1 order by 1

-- what % of orders are >$300?;

select location, count(distinct order_name) from
(
select
order_name,
case when 
SHIPPING_REIGION in ('Colorado', 'New Mexico', 'Wyoming', 'Montana', 'Idaho', 'Washington', 'Oregon', 'California', 'Nevada', 'Arizona', 'Utah') then 'west' else 'east' end as location,
sum(gross_sales_usd) as gross_sales_usd
from
fact_sales
where sales_channel = 'eCommerce'
and profit_center_country = 'United States'
and year(happened_at_local_date) = 2019
and event_type = 'order'
group by 1, 2
order by 1, 2
)
where gross_sales_usd >= 300
group by 1 order by 1


-- What % of orders contain >1 or <= 1 unit?
select location, count(distinct order_name) from
(
select
order_name,
case when 
SHIPPING_REIGION in ('Colorado', 'New Mexico', 'Wyoming', 'Montana', 'Idaho', 'Washington', 'Oregon', 'California', 'Nevada', 'Arizona', 'Utah') then 'west' else 'east' end as location,
sum(quantity) as quantity
from
fact_sales
where sales_channel = 'eCommerce'
and profit_center_country = 'United States'
and year(happened_at_local_date) = 2019
and event_type = 'order'
group by 1, 2
order by 1, 2
)
where quantity > 1
group by 1 order by 1

-- What % of orders contain >1 unit where two different styles are present?
select location, count(distinct order_name) from
(
select
order_name,
case when 
SHIPPING_REIGION in ('Colorado', 'New Mexico', 'Wyoming', 'Montana', 'Idaho', 'Washington', 'Oregon', 'California', 'Nevada', 'Arizona', 'Utah') then 'west' else 'east' end as location,
sum(quantity) as quantity,
count(distinct taxonomy_style) as num_styles
from
fact_sales
where sales_channel = 'eCommerce'
and profit_center_country = 'United States'
and year(happened_at_local_date) = 2019
and event_type = 'order'
group by 1, 2
order by 1, 2
)
where quantity > 1 and num_styles>= 2
group by 1 order by 1



-- What % of 1 unit orders contain a tree product?;
select location, count(distinct order_name) from
(
select
order_name,
case when 
SHIPPING_REIGION in ('Colorado', 'New Mexico', 'Wyoming', 'Montana', 'Idaho', 'Washington', 'Oregon', 'California', 'Nevada', 'Arizona', 'Utah') then 'west' else 'east' end as location,
sum(quantity) as quantity,
sum(case when material_family = 'Tree' then 1 else 0 end) as tree_present
from
fact_sales
where sales_channel = 'eCommerce'
and profit_center_country = 'United States'
and year(happened_at_local_date) = 2019
and event_type = 'order'
group by 1, 2
order by 1, 2
)
where quantity = 1 and tree_present >= 1
group by 1 order by 1


-- What % of >1 units orders contain a tree product and a non tree product?
select location, count(distinct order_name) from
(
select
order_name,
case when 
SHIPPING_REIGION in ('Colorado', 'New Mexico', 'Wyoming', 'Montana', 'Idaho', 'Washington', 'Oregon', 'California', 'Nevada', 'Arizona', 'Utah') then 'west' else 'east' end as location,
sum(quantity) as quantity,
sum(case when material_family = 'Tree' then 1 else 0 end) as tree_present,
sum(case when material_family <> 'Tree' then 1 else 0 end) as non_tree_present
from
fact_sales
where sales_channel = 'eCommerce'
and profit_center_country = 'United States'
and year(happened_at_local_date) = 2019
and event_type = 'order'
group by 1, 2
order by 1, 2
)
where quantity > 1 and tree_present >= 1 and non_tree_present >= 1
group by 1 order by 1


-- What % of >1 units orders contain only tree products?;
select location, count(distinct order_name) from
(
select
order_name,
case when 
SHIPPING_REIGION in ('Colorado', 'New Mexico', 'Wyoming', 'Montana', 'Idaho', 'Washington', 'Oregon', 'California', 'Nevada', 'Arizona', 'Utah') then 'west' else 'east' end as location,
sum(quantity) as quantity,
sum(case when material_family = 'Tree' then 1 else 0 end) as tree_present,
sum(case when material_family <> 'Tree' then 1 else 0 end) as non_tree_present
from
fact_sales
where sales_channel = 'eCommerce'
and profit_center_country = 'United States'
and year(happened_at_local_date) = 2019
and event_type = 'order'
group by 1, 2
order by 1, 2
)
where quantity > 1 and tree_present >= 1 and non_tree_present = 0
group by 1 order by 1


-- yoy sales and orders from US ecomm
select
year(happened_at_local_date) as calendar_year,
case when 
    SHIPPING_REIGION in ('Colorado', 'New Mexico', 'Wyoming', 'Montana', 'Idaho', 'Washington', 'Oregon', 'California', 'Nevada', 'Arizona', 'Utah') then 'west' else 'east' end as location,
sum(gross_sales_usd) as gross_sales_usd,
count(distinct order_name) as num_orders
from
fact_sales
where sales_channel = 'eCommerce'
and profit_center_country = 'United States'
and year(happened_at_local_date) <= 2019
and event_type = 'order'
group by 1, 2
order by 1, 2



