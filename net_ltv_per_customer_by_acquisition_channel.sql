-- query to calculate net ltv per customer by acquisition channel;

select
--ltv.*,
--ga_data.ga_channel_cleaned
ga_data.ga_channel_cleaned,
sum(ltv.net_sales_usd)/count(distinct ltv.customer_id) as net_ltv_per_customer
from
(
  select fp.customer_id,
  fp.first_order_name,
  sum(fs.gross_sales_usd) as gross_sales_usd,
  sum(fs.returns_usd) as returns_usd,
  sum(fs.gross_sales_usd) + sum(returns_usd) as net_sales_usd
  from
  (
    select a.customer_id,
    a.first_purchase_id,
    b.order_name as first_order_name,
    b.happened_at_local_date as first_purchase_date
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
      select id, order_name, happened_at_local_date from birdfactsdev.birdfacts_analytics.fact_sales
    ) as b
    on a.first_purchase_id = b.id  
  ) as fp
  left join
  birdfactsdev.birdfacts_analytics.fact_sales as fs
  on
  fp.customer_id = fs.customer_id
  where datediff('month', fp.first_purchase_date, fs.happened_at_local_date) <= 12
  group by fp.customer_id, fp.first_order_name
) as ltv
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
    a.transaction_transaction_id AS transaction_id
    FROM session_hit a 
    JOIN ga_session b 
    ON a.visit_id = b.visit_id
    AND a.visitor_id = b.visitor_id
    WHERE a.transaction_transaction_id IS NOT NULL
    ) v
    LEFT JOIN
    (
    SELECT
    visitor_id,
    MIN(date) AS first_visit_date
    FROM ga_session
    GROUP BY 1
    ) fv
    ON v.visitor_id = fv.visitor_id
  ) 
    WHERE transaction_visit_rank = 1
) as ga_data
on
ltv.first_order_name = ga_data.ga_transaction_id
group by ga_data.ga_channel_cleaned
order by ga_data.ga_channel_cleaned