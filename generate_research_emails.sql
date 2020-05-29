--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*
--GENERATE RESEARCH EMAILS
--*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*

--This query can be used to identify a subgroup of customers to email for customer research.
--Filtering is available on gender, DMA, acquisition date, recent purchase date, age, new customer status, and number of orders.

SELECT 
    d.email, 
    e.i1gendercode AS gender,
    m.dma,
    MIN(f.happened_at_local_date) AS acq_date,
    MAX(f.happened_at_local_date) AS most_recent_purchase,
    CASE
          WHEN TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) >= 65 THEN '65+'
          WHEN TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) >= 55 AND TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) < 65 THEN '55 - 64'
          WHEN TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) >= 45 AND TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) < 55 THEN '45 - 54'
          WHEN TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) >= 35 AND TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) < 45 THEN '35 - 44'
          WHEN TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) >= 25 AND TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) < 35 THEN '25 - 34'
          WHEN TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) >= 18 AND TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) < 25 THEN '18 - 24'
          WHEN TRY_TO_NUMBER(RIGHT(e.I1combinedage, 2)) < 18 THEN '17 or younger'
          ELSE NULL
    END AS age_bucket,
    MAX(CASE WHEN is_new_customer THEN 1 ELSE 0 END) AS is_new_customer,
    SUM(quantity) AS order_count
    
FROM FACT_SALES AS f
    LEFT JOIN DIM_CUSTOMER AS d
    ON f.customer_id = d.id
    LEFT JOIN EXPERIAN_DATA AS e
    ON d.email = e.email
    LEFT JOIN dma_to_zip_mapping AS m
    ON LEFT(f.shipping_postal_code,5) = m.postal_code
    LEFT JOIN dma_rank AS r
    ON m.dma = r.dma

WHERE quantity > 0
    AND d.email IS NOT NULL
    AND d.email NOT LIKE 'allbirds'
    --AND r.rank IN ('bottom25', 'bottom50')
    --AND r.rank IN ('top10', 'top25')
    --AND age_bucket = '25 - 34'
    --AND e.i1gendercode = 'F'
    --AND taxonomy_style = 'Tree Dasher'

GROUP BY 1, 2, 3, 6

--filter for customers active in the last X amount of time
HAVING MAX(happened_at_local_date) >= '2018-01-01'

ORDER BY RANDOM()

LIMIT 50