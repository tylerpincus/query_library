-- to find age distribution of US NCA Retail B&M + eComm;
select acquisition_date,
count(distinct case when age_group = 'a.18-24' then customer_id else NULL end) as customers_18_24,
count(distinct case when age_group = 'b.25-34' then customer_id else NULL end) as customers_25_34,
count(distinct case when age_group = 'c.35-44' then customer_id else NULL end) as customers_35_44,
count(distinct case when age_group = 'd.45+' then customer_id else NULL end) as customers_45_above,
count(distinct case when age_group = 'e.unknown' then customer_id else NULL end) as customers_unknown_age
from
(
select
a.customer_id,
case
when try_cast(right(c.i1combinedage, 2) as integer) <= 25 then 'a.18-24'
when try_cast(right(c.i1combinedage, 2) as integer) <= 35 then 'b.25-34'
when try_cast(right(c.i1combinedage, 2) as integer) <= 45 then 'c.35-44'
when try_cast(right(c.i1combinedage, 2) as integer) > 45 then 'd.45+'
else 'e.unknown' end
as age_group,
min(a.happened_at_local_date) as acquisition_date
from
fact_sales as a 
left join
dim_customer as b
on a.customer_id = b.id
left join
experian_data as c
on b.email = c.email
where 
a.profit_center_country = 'United States'
group by 1, 2
)
where acquisition_date between '2019-01-01' and '2020-05-16'
group by 1
order by 1
;
