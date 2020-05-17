-- query to compare YoY change in new customers acquired in the United States;

SET (nca_month) = (4);
SET (nca_year_last, nca_year_current) = (2019, 2020);

select left(c.mosaichousehold, 1) as mosaic_group,
year(a.happened_at_local_date) || right(0 || month(a.happened_at_local_date), 2) as yearmonth,
count(distinct a.customer_id) as num_acquisitions
from
fact_sales as a
left join
dim_customer as b
on a.customer_id = b.id
left join
experian_data as c
on b.email = c.email
where month(a.happened_at_local_date) = $nca_month and year(a.happened_at_local_date) in ($nca_year_last, $nca_year_current)
and a.sales_channel = 'eCommerce'
and a.profit_center_country = 'United States'
and a.is_new_customer = 'TRUE'
group by 1, 2
order by 1, 2
;