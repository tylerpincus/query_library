-- without email
select 
year_visit,
is_new_customer,
reported_channel_paid_status,
count(distinct transaction_transaction_id) as transactions
from
(
select 
a.transaction_transaction_id,
a.channel_grouping,
a.reported_channel_paid_status,
year(a.date) as year_visit,
b.customer_id,
b.is_new_customer
from
(
select distinct 
b.visit_id, 
b.visitor_id,
b.visit_start_time,
b.date,
b.channel_grouping, 
b.traffic_source_medium,
b.traffic_source_source,
b.traffic_source_campaign,
CASE WHEN b.channel_grouping IN ('Affiliates', 'Paid Search', 'Paid Social', 'Display') OR b.traffic_source_campaign ILIKE ('%paid%') OR b.traffic_source_source ILIKE ('%_aff%') THEN 'Paid' ELSE 'Free' END AS reported_channel_paid_status,
  CASE  
      WHEN b.channel_grouping = 'Paid Search' THEN  
        CASE 
          WHEN b.traffic_source_campaign ILIKE ('%shopping%') THEN 
            CASE WHEN b.traffic_source_campaign ILIKE ('%allbirds brand%') THEN 'Brand shopping' ELSE 'Non-brand shopping' END
          WHEN COALESCE(b.traffic_source_campaign, ' ') IS NOT NULL THEN 
            CASE WHEN b.traffic_source_campaign ILIKE ('%allbirds brand%') THEN 'Brand search' ELSE 'Non-brand search' END
        END
      WHEN b.traffic_source_source ILIKE ('%_aff%') THEN 'Affiliates'
      WHEN b.traffic_source_campaign ILIKE ('%paid_Facebook%') THEN 'Paid Social'
      WHEN b.traffic_source_medium = 'email' OR (channel_grouping = 'Email') THEN 'Email'
      ELSE b.channel_grouping
    END AS ga_channel_cleaned,
a.transaction_transaction_id
from "FIVETRAN"."GOOGLE_ANALYTICS_360".ga_session as b
join
(select distinct visit_id, visitor_id, visit_start_time, transaction_transaction_id from "FIVETRAN"."GOOGLE_ANALYTICS_360".session_hit where transaction_transaction_id is not NULL) as a
on a.visit_id = b.visit_id
and a.visitor_id = b.visitor_id
and a.visit_start_time = b.visit_start_time
where
  b.GEO_NETWORK_COUNTRY = 'United States'
  and b.date between '2018-04-01' and '2020-05-14'
) as a
left join
fact_sales as b
on a.transaction_transaction_id = b.order_name
)
where year_visit in (2018, 2019, 2020)
and channel_grouping <> 'Email'
group by 1,2,3
order by 1,2,3
;

-- with email
select 
year_visit,
is_new_customer,
reported_channel_paid_status,
count(distinct transaction_transaction_id) as transactions
from
(
select 
a.transaction_transaction_id,
a.channel_grouping,
a.reported_channel_paid_status,
year(a.date) as year_visit,
b.customer_id,
b.is_new_customer
from
(
select distinct 
b.visit_id, 
b.visitor_id,
b.visit_start_time,
b.date,
b.channel_grouping, 
b.traffic_source_medium,
b.traffic_source_source,
b.traffic_source_campaign,
CASE WHEN b.channel_grouping IN ('Affiliates', 'Paid Search', 'Paid Social', 'Display') OR b.traffic_source_campaign ILIKE ('%paid%') OR b.traffic_source_source ILIKE ('%_aff%') THEN 'Paid' ELSE 'Free' END AS reported_channel_paid_status,
  CASE  
      WHEN b.channel_grouping = 'Paid Search' THEN  
        CASE 
          WHEN b.traffic_source_campaign ILIKE ('%shopping%') THEN 
            CASE WHEN b.traffic_source_campaign ILIKE ('%allbirds brand%') THEN 'Brand shopping' ELSE 'Non-brand shopping' END
          WHEN COALESCE(b.traffic_source_campaign, ' ') IS NOT NULL THEN 
            CASE WHEN b.traffic_source_campaign ILIKE ('%allbirds brand%') THEN 'Brand search' ELSE 'Non-brand search' END
        END
      WHEN b.traffic_source_source ILIKE ('%_aff%') THEN 'Affiliates'
      WHEN b.traffic_source_campaign ILIKE ('%paid_Facebook%') THEN 'Paid Social'
      WHEN b.traffic_source_medium = 'email' OR (channel_grouping = 'Email') THEN 'Email'
      ELSE b.channel_grouping
    END AS ga_channel_cleaned,
a.transaction_transaction_id
from "FIVETRAN"."GOOGLE_ANALYTICS_360".ga_session as b
join
(select distinct visit_id, visitor_id, visit_start_time, transaction_transaction_id from "FIVETRAN"."GOOGLE_ANALYTICS_360".session_hit where transaction_transaction_id is not NULL) as a
on a.visit_id = b.visit_id
and a.visitor_id = b.visitor_id
and a.visit_start_time = b.visit_start_time
where
  b.GEO_NETWORK_COUNTRY = 'United States'
  and b.date between '2018-04-01' and '2020-05-14'
) as a
left join
fact_sales as b
on a.transaction_transaction_id = b.order_name
)
where year_visit in (2018, 2019, 2020)
group by 1,2,3
order by 1,2,3
;
