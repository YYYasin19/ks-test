WITH tab1 AS (
    -- Step 0: Prepare data source and value column
    SELECT { col1 } as val
    FROM { table1_selection }
),
tab2 AS (
    SELECT { col2 } as val
    FROM { table2_selection }
),
tab1_cdf AS (
    -- Step 1: Calculate the CDF over the value column
    SELECT val,
        cume_dist() over (
            order by val
        ) as cdf
    FROM tab1
),
tab2_cdf AS (
    SELECT val,
        cume_dist() over (
            order by val
        ) as cdf
    FROM tab2
),
tab1_grouped AS (
    -- Step 2: Remove unnecessary values, s.t. we have (x, cdf(x)) rows only
    SELECT val,
        MAX(cdf) as cdf
    FROM tab1_cdf
    GROUP BY val
),
tab2_grouped AS (
    SELECT val,
        MAX(cdf) as cdf
    FROM tab2_cdf
    GROUP BY val
),
joined_cdf AS (
    -- Step 3: combine the cdfs
    SELECT coalesce(tab1_grouped.val, tab2_grouped.val) as v,
        tab1_grouped.cdf as cdf1,
        tab2_grouped.cdf as cdf2
    FROM tab1_grouped
        FULL OUTER JOIN tab2_grouped ON tab1_grouped.val = tab2_grouped.val
),
-- Step 4: Create a grouper id based on the value count; this is just a helper for forward-filling
grouped_cdf AS (
    SELECT v,
        COUNT(cdf1) over (
            order by v
        ) as _grp1,
        cdf1,
        COUNT(cdf2) over (
            order by v
        ) as _grp2,
        cdf2
    FROM joined_cdf
),
-- Step 5: Forward-Filling: Select first non-null value per group (defined in the prev. step)
filled_cdf AS (
    SELECT v,
        first_value(cdf1) over (
            partition by _grp1
            order by v
        ) as cdf1_filled,
        first_value(cdf2) over (
            partition by _grp2
            order by v
        ) as cdf2_filled
    FROM grouped_cdf
),
-- Step 6: Replace NULL values (at the beginning) with 0 to calculate difference
replaced_nulls AS (
    SELECT coalesce(cdf1_filled, 0) as cdf1,
        coalesce(cdf2_filled, 0) as cdf2
    FROM filled_cdf
) -- Step 7: Calculate final statistic as max. distance
SELECT MAX(ABS(cdf1 - cdf2))
FROM replaced_nulls;