drop table if exists vu_customers_sep2019;
create table vu_customers_sep2019 as
select * from
(SELECT 
    a.customer_id, 
    a.happened_at_local_date,
    a.billing_address_id,
    a.shipping_address_id,
    b.email,
    b.first_name,
    b.last_name,
    c.address_line_1 as billing_address_line_1,
    c.address_line_2 as billing_address_line_2,
    c.CITY as billing_city,
    c.POSTAL_CODE as billing_zip_code,
    c.REGION as billing_state,
    c.COUNTRY as billing_country,
    d.address_line_1 as shipping_address_line_1,
    d.address_line_2 as shipping_address_line_2,
    d.CITY as shipping_city,
    d.POSTAL_CODE as shipping_zip_code,
    d.REGION as shipping_state,
    d.COUNTRY as shipping_country,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY happened_at_local_date DESC) AS most_prev_order_num
FROM 
    (
      select * from fact_sales
        where gross_sales_usd > 0 
        and event_type = 'order'
        and shipping_COUNTRY in ('unitedstates', 'united states of america', 'United States', 'USA' ) or billing_country in ('unitedstates', 'united states of america', 'United States', 'USA' )
        and happened_at_local_date <= '2019-09-30'
    ) as a
JOIN
dim_customer as b
 on a.customer_id = b.id
left join
dim_address as c
 on a.billing_address_id = c.id
left join
dim_address as d
 on a.shipping_address_id = d.id
)    
WHERE most_prev_order_num = 1
    and email is not NULL
    and billing_country in ('unitedstates', 'united states of america', 'United States', 'USA')
;


drop table if exists vu_customer_list_sep2019;
create table vu_customer_list_sep2019 as
(
select
    row_number() over(partition by 1 order by 1)  as sequence_number,
    email,
    first_name,
    last_name,
    billing_address_line_1,
    billing_address_line_2,
    billing_city,
    billing_zip_code,
    billing_state,
    billing_country,
    shipping_address_line_1,
    shipping_address_line_2,
    shipping_city,
    shipping_zip_code,
    shipping_state,
    shipping_country
from vu_customers_sep2019
where email is not NULL
and billing_address_line_1 is not NULL
and billing_city is not NULL
and billing_zip_code is not NULL
and billing_state is not NULL
and billing_country is not NULL
and first_name is not NULL
and last_name is not NULL
and billing_state not in 
('BA',
'Ma.',
'CA,',
'HAMILTON',
'CT.',
'N.Y.',
'new york',
'Select',
'IL  60187-4478 USA',
'Missouru',
'Flordia',
'NN',
'MA.',
'NewYork',
'Ill',
'Durham, NC',
'MM',
'MASS',
'Can',
'Washington (state)',
'Fla',
'VIRGINIA',
'Mi.',
'CR',
'イリノイ',
'OR.',
'Fl 2451',
'Ore',
'Quebec',
'N',
'Connecticul',
'OA',
'Uta',
'Conneticut',
'Tennesse',
'Co.',
'AZ .',
'SOUTH CARILINA',
'Colts Neck, NJ',
'Fl.',
'NU',
'ILL',
'NY,',
'Sacramento',
'FL.',
'Palau',
'Md.',
'Va.',
'Ca.',
'Select One...',
'CA.',
'D.C.',
'Northern Mariana Islands',
'Armed Forces Americas',
'Guam',
'',
'Virgin Islands',
'Armed Forces Pacific',
'Puerto Rico',
'Armed Forces Europe')
)
;


drop table if exists vu_customer_list_sep2019_only;
create table vu_customer_list_sep2019_only
as
select * from vu_customer_list_sep2019
where email not in (select distinct email from experian_data)
--and email not in (select distinct email from vu_customer_list_jul2019_only)
;

select max(cast(sequencenumber as integer)) from experian_data;