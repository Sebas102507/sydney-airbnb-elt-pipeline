------------------QUESTION 1--------------------------------

WITH lga_performance AS (
    -- Step 1: Calculate revenue per active listing for each LGA.
    SELECT
        dl.lga_name,
        dl.lga_code,
        SUM((30 - fl.availability_30) * fl.price) AS revenue_per_active_listing
    FROM
        gold.fact_listing AS fl
    JOIN
        silver.scd_property AS sp ON fl.scd_property_id = sp.dbt_scd_id
    JOIN
        gold.dim_suburb AS ds ON fl.property_suburb_id = ds.suburb_id
    JOIN
        gold.dim_lga AS dl ON ds.lga_code = dl.lga_code
    WHERE
        fl.has_availability = TRUE
    GROUP BY
        dl.lga_name,
        dl.lga_code
),

ranked_lgas AS (
    -- Step 2: Rank all LGAs.
    SELECT
        lga_name,
        lga_code,
        revenue_per_active_listing,
        RANK() OVER (ORDER BY revenue_per_active_listing DESC) as rank_desc,
        RANK() OVER (ORDER BY revenue_per_active_listing ASC) as rank_asc
    FROM
        lga_performance
),

top_bottom_lgas AS (
    -- Step 3: Select the Top 3 and Bottom 3 performers.
    SELECT
        lga_name,
        lga_code,
        revenue_per_active_listing,
        CASE
            WHEN rank_desc <= 3 THEN 'Top 3 Performing'
            WHEN rank_asc <= 3 THEN 'Lowest 3 Performing'
        END AS performance_group
    FROM
        ranked_lgas
    WHERE
        rank_desc <= 3 OR rank_asc <= 3
)

-- Step 4: Join the selected LGAs with their specific demographic data.
SELECT
    p.performance_group,
    p.lga_name,
    ROUND(p.revenue_per_active_listing, 2) AS revenue_per_active_listing,
    
    -- Show the specific demographic characteristics for each LGA
    d.median_age_persons,
    d.average_household_size,
    d.median_tot_hhd_inc_weekly AS median_weekly_household_income
    
FROM
    top_bottom_lgas AS p
JOIN
    gold.ref_census_statistical_measures AS d 
    ON p.lga_code = d.lga_code
ORDER BY
    -- Order by performance to group top and bottom LGAs together
    p.revenue_per_active_listing DESC;


--- The query was created from scrath because any of the view have the total (not average) revenue per active listing base on the property/listing id (not by host id) 





------------------QUESTION 2--------------------------------

WITH
  -- First, aggregate neighbourhood revenue up to the LGA level.
  lga_revenue_from_neighbourhoods AS (
    SELECT
      s.lga_code,
      -- Get the average LGA revenue by averaging the revenues of its neighbourhoods
      n.avg_revenue_per_active_listing
    FROM
      gold.dm_listing_neighbourhood n
      INNER JOIN gold.dim_suburb s ON n.listing_neighbourhood = s.suburb_name
  )
  
-- Now, join the aggregated LGA revenue with census data and calculate the correlation.

SELECT
  CORR(
    c.median_age_persons,
    r.avg_revenue_per_active_listing
  ) AS correlation_coefficient
FROM
  gold.ref_census_statistical_measures c
  INNER JOIN lga_revenue_from_neighbourhoods r ON c.lga_code = r.lga_code;




------------------QUESTION 3--------------------------------


WITH neighbourhood_performance AS (
    -- Step 1: Calculate revenue per active listing for each neighbourhood.
    SELECT
        ds.suburb_name AS listing_neighbourhood,
        SUM((30 - fl.availability_30) * fl.price) AS revenue_per_listing
    FROM
        gold.fact_listing AS fl
    JOIN
        silver.scd_property AS sp ON fl.scd_property_id = sp.dbt_scd_id
    JOIN
        gold.dim_suburb AS ds ON fl.property_suburb_id = ds.suburb_id
    WHERE
        fl.has_availability = TRUE
    GROUP BY
        ds.suburb_name
),

top_5_neighbourhoods AS (
    -- Step 2: Select the top 5 neighbourhoods and keep their performance metric.
    SELECT
        listing_neighbourhood,
        revenue_per_listing
    FROM
        neighbourhood_performance
    ORDER BY
        revenue_per_listing DESC
    LIMIT 5
),

listing_type_performance AS (
    -- Step 3: Calculate total stays for each listing type within each of the top 5 neighbourhoods.
    SELECT
        ds.suburb_name AS listing_neighbourhood,
        sp.property_type,
        sp.room_type,
        sp.accommodates,
        SUM(30 - fl.availability_30) AS total_stays
    FROM
        gold.fact_listing AS fl
    JOIN
        silver.scd_property AS sp ON fl.scd_property_id = sp.dbt_scd_id
    JOIN
        gold.dim_suburb AS ds ON fl.property_suburb_id = ds.suburb_id
    WHERE
        ds.suburb_name IN (SELECT listing_neighbourhood FROM top_5_neighbourhoods) AND fl.has_availability = TRUE
    GROUP BY
        ds.suburb_name,
        sp.property_type,
        sp.room_type,
        sp.accommodates
),

ranked_listing_types AS (
    -- Step 4: Rank the listing types within each neighbourhood based on total stays.
    SELECT
        listing_neighbourhood,
        property_type,
        room_type,
        accommodates,
        total_stays,
        RANK() OVER (PARTITION BY listing_neighbourhood ORDER BY total_stays DESC) as rnk
    FROM
        listing_type_performance
)


-- Step 5: Join the top neighbourhood data with its best listing type.
SELECT
    rlt.listing_neighbourhood,
    rlt.property_type,
    rlt.room_type,
    rlt.accommodates,
    ROUND(t5n.revenue_per_listing::NUMERIC, 2) AS estimated_revenue_per_active_listing,
    rlt.total_stays AS total_number_of_stays
FROM
    ranked_listing_types AS rlt
JOIN
    top_5_neighbourhoods AS t5n ON rlt.listing_neighbourhood = t5n.listing_neighbourhood
WHERE
    rlt.rnk = 1 -- Filter for only the #1 listing type in each neighbourhood
ORDER BY
    estimated_revenue_per_active_listing DESC;



------------------QUESTION 4--------------------------------


-- This joins the fact table with dimension and SCD tables to link each listing to its host and its specific LGA (Local Government Area).
WITH joined_data AS (
    SELECT
        sp.listing_id,
        sh.host_id,
        dl.lga_code
    FROM
        gold.fact_listing fl
    JOIN
        silver.scd_host sh ON fl.scd_host_id = sh.dbt_scd_id -- Join to get host details from the historical host table
    JOIN
        silver.scd_property sp ON fl.scd_property_id = sp.dbt_scd_id -- Join to get property details from the historical property table
    JOIN
        gold.dim_suburb dsub ON fl.host_suburb_id = dsub.suburb_id -- Join to get suburb details
    JOIN
        gold.dim_lga dl ON dsub.lga_code = dl.lga_code -- Join to get the LGA code from the suburb
),

-- This CTE identifies only the hosts who own more than one property.
-- It serves as a filter to ensure the analysis only focuses on multi-listing hosts.
hosts_with_multiple_listings AS (
    SELECT
        host_id
    FROM
        joined_data
    GROUP BY
        host_id
    HAVING
        COUNT(DISTINCT listing_id) > 1 -- Filters for hosts with more than one unique listing
),

-- This CTE analyzes the strategy of each multi-listing host.
-- It counts the number of distinct LGAs each host operates in and categorizes them.
host_analysis AS (
    SELECT
        -- A CASE statement to classify the host's strategy based on the number of distinct LGAs.
        CASE
            WHEN COUNT(DISTINCT jd.lga_code) = 1 THEN 'Concentrated in one LGA'
            ELSE 'Distributed across multiple LGAs'
        END AS host_strategy
    FROM
        joined_data jd
    WHERE
        jd.host_id IN (SELECT host_id FROM hosts_with_multiple_listings) -- Ensures we only analyze hosts with multiple listings
    GROUP BY
        jd.host_id
),

-- This CTE calculates the total count of hosts for each strategy.
strategy_counts AS (
    SELECT
        host_strategy,
        COUNT(*) AS number_of_hosts
    FROM
        host_analysis
    GROUP BY
        host_strategy
),

-- This CTE gets the grand total of all unique hosts in the entire database.
-- This is used later to calculate the percentage against all hosts, not just multi-listing ones.
total_host_count AS (
    SELECT COUNT(DISTINCT host_id) AS total_hosts
    FROM silver.scd_host
)

-- Final SELECT statement to combine the counts and calculate the required percentages.
SELECT
    sc.host_strategy,
    sc.number_of_hosts,
    -- Calculates the percentage of multi-listing hosts that follow each strategy.
    ROUND(sc.number_of_hosts * 100.0 / (SELECT SUM(number_of_hosts) FROM strategy_counts), 2) AS pct_of_multi_listing_hosts,
    -- Calculates the percentage of ALL hosts in the database that follow each multi-listing strategy.
    ROUND(sc.number_of_hosts * 100.0 / thc.total_hosts, 2) AS pct_of_all_hosts
FROM
    strategy_counts sc
CROSS JOIN -- Use CROSS JOIN to make the total host count available to every row.
    total_host_count thc;


------------------QUESTION 5--------------------------------

WITH single_listing_hosts AS (
    -- Step 1: Identify all hosts who have ever had only one unique listing
    SELECT
        sh.host_id
    FROM
        gold.fact_listing fl
    JOIN
        silver.scd_host sh ON fl.scd_host_id = sh.dbt_scd_id
    JOIN
        silver.scd_property sp ON fl.scd_property_id = sp.dbt_scd_id
    GROUP BY
        sh.host_id
    HAVING
        COUNT(DISTINCT sp.listing_id) = 1
),

listing_total_revenue AS (
    -- Step 2: Calculate the TOTAL LIFETIME revenue for each host using the new formula
    SELECT
        sh.host_id,
        dl.lga_code,
        dl.lga_name,
        SUM(
            CASE
                WHEN fl.has_availability THEN (30 - fl.availability_30) * fl.price
                ELSE 0
            END
        ) AS total_lifetime_revenue -- This calculation has been updated
    FROM
        gold.fact_listing fl
    JOIN
        silver.scd_host sh ON fl.scd_host_id = sh.dbt_scd_id
    JOIN
        gold.dim_suburb dsub ON fl.host_suburb_id = dsub.suburb_id
    JOIN
        gold.dim_lga dl ON dsub.lga_code = dl.lga_code
    GROUP BY
        sh.host_id,
        dl.lga_code,
        dl.lga_name
),

host_comparison AS (
    -- Step 3: For each single-listing host, check if their revenue covers the annualized mortgage
    SELECT
        lr.host_id,
        lr.lga_code,
        lr.lga_name,
        CASE
            WHEN lr.total_lifetime_revenue >= (rcsm.median_mortgage_repay_monthly * 12) THEN 1
            ELSE 0
        END AS covers_mortgage_flag
    FROM
        listing_total_revenue lr
    JOIN
        gold.ref_census_statistical_measures rcsm ON lr.lga_code = rcsm.lga_code
    WHERE
        lr.host_id IN (SELECT host_id FROM single_listing_hosts)
)

-- Step 4: Aggregate by LGA to find the one with the highest percentage
SELECT
    lga_name,
    SUM(covers_mortgage_flag) AS hosts_covering_mortgage,
    COUNT(*) AS total_single_listing_hosts,
    ROUND(SUM(covers_mortgage_flag) * 100.0 / COUNT(*), 2) AS coverage_percentage
FROM
    host_comparison
GROUP BY
    lga_name
ORDER BY
    coverage_percentage desc;