-- this query depends on customer_id. customer_id is currently setup to be a random number that refreshes every day based on shopify birdfacts update;
-- so update this table - vu_acquisition_channel whenever you need to use the table while joining with email id;
-- use this table as needed 

drop table vu_acquisition_channel;
create table vu_acquisition_channel as 
select first_purchase.customer_id,
first_purchase.first_sales_channel,
first_purchase.first_purchase_date,
first_purchase.first_purchase_country,
acq_channel.*,
dim_customer.email
from
(
select a.customer_id,
a.first_purchase_id,
b.order_name as first_order_name,
b.sales_channel as first_sales_channel,
b.happened_at_local_date as first_purchase_date,
b.profit_center_country as first_purchase_country
from
  (
    select distinct customer_id,
    min(id) over (partition by customer_id order by id asc) as first_purchase_id
    from birdfactsdev.birdfacts_analytics.fact_sales 
    where customer_id is not NULL
    and event_type = 'order' 
    and line_type in ('product', 'gift_card') 
  ) as a
left join
  (
    select id, order_name, sales_channel, happened_at_local_date, profit_center_country from birdfactsdev.birdfacts_analytics.fact_sales
  ) as b
on a.first_purchase_id = b.id  
) as first_purchase
left join
(
SELECT
  visit_id AS ga_visit_id, 
  visitor_id AS ga_visitor_id,
  page_hostname AS ga_page_hostname,
  visit_start_time AS visit_start_time_utc,
  visit_date AS visit_date_local_time,
  channel_grouping AS ga_channel_grouping, 
  CASE WHEN channel_grouping IN ('Affiliates', 'Paid Search', 'Paid Social', 'Display') OR traffic_source_campaign ILIKE ('%paid%') OR traffic_source ILIKE ('%_aff%') THEN 'Paid' ELSE 'Free' END AS reported_channel_paid_status,
  CASE  
      WHEN channel_grouping = 'Paid Search' THEN  
        CASE 
          WHEN traffic_source_campaign ILIKE ('%shopping%') THEN 
            CASE WHEN traffic_source_campaign ILIKE ('%allbirds brand%') THEN 'Brand shopping' ELSE 'Non-brand shopping' END
          WHEN COALESCE(traffic_source_campaign, ' ') IS NOT NULL THEN 
            CASE WHEN traffic_source_campaign ILIKE ('%allbirds brand%') THEN 'Brand search' ELSE 'Non-brand search' END
        END
      WHEN traffic_source ILIKE ('%_aff%') THEN 'Affiliates'
      WHEN traffic_source_campaign ILIKE ('%paid_Facebook%') THEN 'Paid Social'
      WHEN traffic_source_medium = 'email' OR (channel_grouping = 'Email') THEN 'Email'
      ELSE channel_grouping
    END AS ga_channel_cleaned,
  device_is_mobile AS ga_device_is_mobile,
  device_operating_system AS ga_device_operating_system,
  device_browser AS ga_device_browser,
  DEVICE_DEVICE_CATEGORY as ga_device_category,
  traffic_source AS ga_traffic_source,
  traffic_source_medium AS ga_traffic_source_medium,
  referer AS ga_referer,
  traffic_source_campaign AS ga_traffic_source_campaign,
  transaction_id AS ga_transaction_id,
  visitor_first_visit_date AS ga_visitor_first_visit_date
  FROM
  (
    SELECT 
    v.*, 
    ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY v.visit_start_time, v.visitor_id) AS transaction_visit_rank,
    fv.first_visit_date AS visitor_first_visit_date
    FROM
    (
    SELECT DISTINCT 
    a.visit_id, 
    a.visitor_id,
    a.visit_start_time,
    a.page_hostname,
    b.date AS visit_date,
    b.channel_grouping, 
    b.device_is_mobile,
    b.device_operating_system,
    b.device_browser,
    b.traffic_source_medium,
    a.referer,
    b.traffic_source_source AS traffic_source,
    b.traffic_source_campaign,
    b.DEVICE_DEVICE_CATEGORY,
    a.transaction_transaction_id AS transaction_id
    FROM "FIVETRAN"."GOOGLE_ANALYTICS_360".session_hit a 
    JOIN "FIVETRAN"."GOOGLE_ANALYTICS_360".ga_session b 
    ON a.visit_id = b.visit_id
    AND a.visitor_id = b.visitor_id
    WHERE a.transaction_transaction_id IS NOT NULL
    ) v
    LEFT JOIN
    (
    SELECT
    visitor_id,
    MIN(date) AS first_visit_date
    FROM "FIVETRAN"."GOOGLE_ANALYTICS_360".ga_session
    GROUP BY 1
    ) fv
    ON v.visitor_id = fv.visitor_id
  ) 
    WHERE transaction_visit_rank = 1
) as acq_channel
on first_purchase.first_order_name = acq_channel.ga_transaction_id
left join
dim_customer
on first_purchase.customer_id = dim_customer.id;




-- quick query to summarize the acquisitions by a google analytics channel and acquisition yearmonth;
SELECT 
ACQUISITION_YEARMONTH,
GA_CHANNEL_CLEANED,
COUNT(DISTINCT CUSTOMER_ID) AS NUM_CUSTOMERS
FROM
(
select
year(a.first_purchase_date) || right(0 || month(a.first_purchase_date), 2) as acquisition_yearmonth,
a.GA_CHANNEL_CLEANED,
a.customer_id,
left(d.MOSAICHOUSEHOLD,1) as Mosaic_Group
from
vu_acquisition_channel as a
left join
dim_customer as c
on a.customer_id = c.id
left join
experian_data as d
on c.email = d.email
where a.first_purchase_country = 'United States'
and a.first_purchase_date >= '2019-01-01')
GROUP BY 1,2
ORDER BY 1,2