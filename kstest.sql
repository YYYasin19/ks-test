WITH tab1 AS (
    SELECT val,
        MAX(cdf) as cdf
    FROM (
            SELECT val,
                cume_dist() over (
                    order by val
                ) as cdf
            FROM (
                    SELECT { col1 } as val
                    FROM { table1_selection } as temp01
                ) as temp03 -- Change TABLE and COL here
        ) as temp05
    GROUP BY val
),
tab2 AS (
    SELECT val,
        MAX(cdf) as cdf
    FROM (
            SELECT val,
                cume_dist() over (
                    order by val
                ) as cdf
            FROM (
                    SELECT { col2 } as val
                    FROM { table2_selection } as temp02
                ) as temp04 -- Change TABLE and COL here
        ) as temp06
    GROUP BY val
),
cdf_unfilled AS (
    SELECT coalesce(tab1.val, tab2.val) as v,
        tab1.cdf as cdf1,
        tab2.cdf as cdf2
    FROM tab1
        FULL OUTER JOIN tab2 ON tab1.val = tab2.val
),
grouped_table AS (
    -- Step 2: Create a grouper attribute to fill values forward
    SELECT v,
        COUNT(cdf1) over (
            order by v
        ) as _grp1,
        cdf1,
        COUNT(cdf2) over (
            order by v
        ) as _grp2,
        cdf2
    FROM cdf_unfilled
),
filled_cdf AS (
    -- Step 3: Select first non-null value per group (defined by grouper)
    SELECT v,
        first_value(cdf1) over (
            partition by _grp1
            order by v
        ) as cdf1_filled,
        first_value(cdf2) over (
            partition by _grp2
            order by v
        ) as cdf2_filled
    FROM grouped_table
),
replaced_nulls AS (
    -- Step 4: Replace NULL values (often at the begin) with 0 to calculate difference
    SELECT coalesce(cdf1_filled, 0) as cdf1,
        coalesce(cdf2_filled, 0) as cdf2
    FROM filled_cdf
)
-- Step 5: Calculate final statistic
SELECT MAX(ABS(cdf1 - cdf2))
FROM replaced_nulls;
