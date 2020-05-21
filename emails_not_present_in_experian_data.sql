-- customers in US that made a retail purchase at one of our stores, do not have a shipping address, and do not exist in our experian database;
with emails_list_of_customers_without_shipping_address as
  (select distinct email from birdfactsdev.birdfacts_analytics.dim_customer
    where id in
  (
    select distinct customer_id from birdfactsdev.birdfacts_analytics.fact_sales
    where profit_center_country = 'United States'
    and sales_channel = 'Retail Brick & Mortar'
    and shipping_address_id in
    (
      select distinct shipping_address_id
      from
      (
      select profit_center_name, shipping_address_id, count(distinct order_name) as num_orders
      from
      birdfactsdev.birdfacts_analytics.fact_sales
      where profit_center_country = 'United States'
      and sales_channel = 'Retail Brick & Mortar'
      group by 1, 2
      order by 3 desc
      )
      where num_orders > 10
      and shipping_address_id is not NULL
    )
  )
  and email is not NULL
)
select 
row_number() over(partition by 1 order by 1)  as SEQUENCE_NUMBER,
email,
NULL as FIRST_NAME,
NULL as LAST_NAME,
NULL as BILLING_ADDRESS_LINE_1,
NULL as BILLING_ADDRESS_LINE_2,
NULL as BILLING_CITY,
NULL as BILLING_ZIP_CODE,
NULL as BILLING_STATE,
NULL as BILLING_COUNTRY,
NULL as SHIPPING_ADDRESS_LINE_1,
NULL as SHIPPING_ADDRESS_LINE_2,
NULL as SHIPPING_CITY,
NULL as SHIPPING_ZIP_CODE,
NULL as SHIPPING_STATE,
NULL as SHIPPING_COUNTRY
from emails_list_of_customers_without_shipping_address where email not in (select distinct email from birdfactsdev.birdfacts_analytics.experian_data)
;



-- customers in US that made a retail purchase at one of our stores, have a shipping address, and do not exist in our experian database;
with emails_list_of_customers_with_shipping_address as
(
select 
b.email,
b.FIRST_NAME,
b.LAST_NAME,
c.ADDRESS_LINE_1 AS BILLING_ADDRESS_LINE_1,
c.ADDRESS_LINE_2 AS BILLING_ADDRESS_LINE_2,
c.CITY as BILLING_CITY,
c.POSTAL_CODE as BILLING_ZIP_CODE,
c.REGION as BILLING_STATE,
c.COUNTRY as BILLING_COUNTRY,
d.ADDRESS_LINE_1 AS SHIPPING_ADDRESS_LINE_1,
d.ADDRESS_LINE_2 AS SHIPPING_ADDRESS_LINE_2,
d.CITY as SHIPPING_CITY,
d.POSTAL_CODE as SHIPPING_ZIP_CODE,
d.REGION as SHIPPING_STATE,
d.COUNTRY as SHIPPING_COUNTRY
from
  (
    select distinct customer_id, shipping_address_id, billing_address_id from birdfactsdev.birdfacts_analytics.fact_sales
    where profit_center_country = 'United States'
    and sales_channel = 'Retail Brick & Mortar'
    and shipping_address_id not in
    (
      select distinct shipping_address_id
      from
      (
      select profit_center_name, shipping_address_id, count(distinct order_name) as num_orders
      from
      birdfactsdev.birdfacts_analytics.fact_sales
      where profit_center_country = 'United States'
      and sales_channel = 'Retail Brick & Mortar'
      group by 1, 2
      order by 3 desc
      )
      where num_orders > 10
      and shipping_address_id is not NULL
    )
  ) as a
  left join
  birdfactsdev.birdfacts_analytics.dim_customer as b
  on a.customer_id = b.id
  left join
  birdfactsdev.birdfacts_analytics.dim_address as c
  on a.billing_address_id = c.id
  left join
  birdfactsdev.birdfacts_analytics.dim_address as d
  on a.shipping_address_id = d.id
)
select row_number() over(partition by 1 order by 1)  as SEQUENCE_NUMBER,
* from emails_list_of_customers_with_shipping_address where email not in (select distinct email from experian_data)
;


