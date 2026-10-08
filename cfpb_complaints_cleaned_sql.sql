SELECT current_database();

CREATE TABLE complaints (
    date_received TIMESTAMPTZ,
    product TEXT,
    sub_product TEXT,
    issue TEXT,
    sub_issue TEXT,
    company_public_response TEXT,
    company TEXT,
    state TEXT,
    zip_code TEXT,
    tags TEXT,
    submitted_via TEXT,
    date_sent_to_company TIMESTAMPTZ,
    company_response_to_consumer TEXT,
    timely_response TEXT,
    complaint_id BIGINT,
    response_days INTEGER
);

SELECT COUNT(*)
FROM complaints;

SELECT *
FROM complaints
LIMIT 5;

-- ============================================================
-- CFPB CONSUMER COMPLAINT ANALYSIS
-- BUSINESS QUESTIONS + SQL QUERIES
-- ============================================================


-- ============================================================
-- Q1. Which financial products receive the most complaints?
-- ============================================================

SELECT
    product,
    COUNT(*) AS complaint_count
FROM complaints
GROUP BY product
ORDER BY complaint_count DESC;


-- ============================================================
-- Q2. What percentage of total complaints comes from each product?
-- ============================================================

SELECT
    product,
    COUNT(*) AS complaint_count,
    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS complaint_percentage
FROM complaints
GROUP BY product
ORDER BY complaint_percentage DESC;


-- ============================================================
-- Q3. What are the top 10 complaint issues overall?
-- ============================================================

SELECT
    issue,
    COUNT(*) AS complaint_count
FROM complaints
GROUP BY issue
ORDER BY complaint_count DESC
LIMIT 10;


-- ============================================================
-- Q4. What are the top 3 complaint issues for each product?
-- ============================================================

WITH issue_counts AS (
    SELECT
        product,
        issue,
        COUNT(*) AS complaint_count
    FROM complaints
    GROUP BY product, issue
),
ranked_issues AS (
    SELECT
        product,
        issue,
        complaint_count,
        DENSE_RANK() OVER (
            PARTITION BY product
            ORDER BY complaint_count DESC
        ) AS issue_rank
    FROM issue_counts
)
SELECT
    product,
    issue,
    complaint_count,
    issue_rank
FROM ranked_issues
WHERE issue_rank <= 3
ORDER BY product, issue_rank;


-- ============================================================
-- Q5. Which product has the most concentrated complaint problem?
-- ============================================================

WITH issue_counts AS (
    SELECT
        product,
        issue,
        COUNT(*) AS complaint_count
    FROM complaints
    GROUP BY product, issue
),
product_totals AS (
    SELECT
        product,
        COUNT(*) AS total_complaints
    FROM complaints
    GROUP BY product
),
top_issues AS (
    SELECT
        i.product,
        i.issue,
        i.complaint_count,
        p.total_complaints,
        RANK() OVER (
            PARTITION BY i.product
            ORDER BY i.complaint_count DESC
        ) AS issue_rank
    FROM issue_counts i
    JOIN product_totals p
        ON i.product = p.product
)
SELECT
    product,
    issue,
    complaint_count,
    total_complaints,
    ROUND(
        100.0 * complaint_count / total_complaints,
        2
    ) AS issue_percentage
FROM top_issues
WHERE issue_rank = 1
ORDER BY issue_percentage DESC;


-- ============================================================
-- Q6. Which companies receive the most complaints overall?
-- ============================================================

SELECT
    company,
    COUNT(*) AS complaint_count
FROM complaints
WHERE company IS NOT NULL
GROUP BY company
ORDER BY complaint_count DESC
LIMIT 10;


-- ============================================================
-- Q7. Which top 3 companies receive the most complaints
--     within each product?
-- ============================================================

WITH company_product AS (
    SELECT
        product,
        company,
        COUNT(*) AS complaint_count
    FROM complaints
    WHERE company IS NOT NULL
    GROUP BY product, company
),
ranked_companies AS (
    SELECT
        product,
        company,
        complaint_count,
        DENSE_RANK() OVER (
            PARTITION BY product
            ORDER BY complaint_count DESC
        ) AS company_rank
    FROM company_product
)
SELECT
    product,
    company,
    complaint_count,
    company_rank
FROM ranked_companies
WHERE company_rank <= 3
ORDER BY product, company_rank;


-- ============================================================
-- Q8. Which companies have a low timely-response rate
--     despite handling a significant complaint volume?
-- ============================================================

SELECT
    company,
    COUNT(*) AS total_complaints,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN timely_response = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS timely_response_pct
FROM complaints
WHERE company IS NOT NULL
GROUP BY company
HAVING COUNT(*) >= 100
ORDER BY timely_response_pct ASC
LIMIT 15;


-- ============================================================
-- Q9. Which product has the lowest timely-response rate?
-- ============================================================

SELECT
    product,
    COUNT(*) AS total_complaints,
    SUM(
        CASE
            WHEN timely_response = 'Yes' THEN 1
            ELSE 0
        END
    ) AS timely_responses,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN timely_response = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS timely_response_pct
FROM complaints
GROUP BY product
ORDER BY timely_response_pct ASC;


-- ============================================================
-- Q10. Which product-company combinations have high
--      complaint volume and low timely-response performance?
-- ============================================================

WITH company_metrics AS (
    SELECT
        product,
        company,
        COUNT(*) AS complaint_count,
        ROUND(
            100.0 * SUM(
                CASE
                    WHEN timely_response = 'Yes' THEN 1
                    ELSE 0
                END
            ) / COUNT(*),
            2
        ) AS timely_response_pct
    FROM complaints
    WHERE company IS NOT NULL
    GROUP BY product, company
)
SELECT
    product,
    company,
    complaint_count,
    timely_response_pct
FROM company_metrics
WHERE complaint_count >= 100
ORDER BY complaint_count DESC,
         timely_response_pct ASC
LIMIT 20;


-- ============================================================
-- Q11. What is the monthly complaint trend?
-- ============================================================

SELECT
    DATE_TRUNC('month', date_received) AS month,
    COUNT(*) AS complaint_count
FROM complaints
GROUP BY DATE_TRUNC('month', date_received)
ORDER BY month;


-- ============================================================
-- Q12. Which months experienced the largest
--      month-over-month increase in complaints?
-- ============================================================

WITH monthly_complaints AS (
    SELECT
        DATE_TRUNC('month', date_received) AS month,
        COUNT(*) AS complaint_count
    FROM complaints
    GROUP BY DATE_TRUNC('month', date_received)
),
monthly_change AS (
    SELECT
        month,
        complaint_count,
        LAG(complaint_count) OVER (
            ORDER BY month
        ) AS previous_month
    FROM monthly_complaints
)
SELECT
    month,
    complaint_count,
    previous_month,
    complaint_count - previous_month AS complaint_change,
    ROUND(
        100.0 * (complaint_count - previous_month)
        / NULLIF(previous_month, 0),
        2
    ) AS mom_change_pct
FROM monthly_change
WHERE previous_month IS NOT NULL
ORDER BY mom_change_pct DESC;


-- ============================================================
-- Q13. Which products experienced the largest
--      month-over-month increase in complaints?
-- ============================================================

WITH monthly_product AS (
    SELECT
        DATE_TRUNC('month', date_received) AS month,
        product,
        COUNT(*) AS complaint_count
    FROM complaints
    GROUP BY DATE_TRUNC('month', date_received), product
),
monthly_change AS (
    SELECT
        month,
        product,
        complaint_count,
        LAG(complaint_count) OVER (
            PARTITION BY product
            ORDER BY month
        ) AS previous_month
    FROM monthly_product
)
SELECT
    month,
    product,
    complaint_count,
    previous_month,
    complaint_count - previous_month AS complaint_change,
    ROUND(
        100.0 * (complaint_count - previous_month)
        / NULLIF(previous_month, 0),
        2
    ) AS mom_change_pct
FROM monthly_change
WHERE previous_month IS NOT NULL
ORDER BY mom_change_pct DESC
LIMIT 20;


-- ============================================================
-- Q14. Which states have the highest complaint volumes?
-- ============================================================

SELECT
    state,
    COUNT(*) AS complaint_count
FROM complaints
WHERE state IS NOT NULL
GROUP BY state
ORDER BY complaint_count DESC
LIMIT 10;


-- ============================================================
-- Q15. Which states have unusually high complaint volume
--      for specific products?
-- ============================================================

WITH state_product AS (
    SELECT
        state,
        product,
        COUNT(*) AS complaint_count
    FROM complaints
    WHERE state IS NOT NULL
    GROUP BY state, product
),
ranked AS (
    SELECT
        state,
        product,
        complaint_count,
        RANK() OVER (
            PARTITION BY product
            ORDER BY complaint_count DESC
        ) AS state_rank
    FROM state_product
)
SELECT
    state,
    product,
    complaint_count,
    state_rank
FROM ranked
WHERE state_rank <= 3
ORDER BY product, state_rank;


-- ============================================================
-- Q16. Which complaint issues have the highest share
--      within each product?
-- ============================================================

WITH issue_counts AS (
    SELECT
        product,
        issue,
        COUNT(*) AS complaint_count
    FROM complaints
    GROUP BY product, issue
),
product_totals AS (
    SELECT
        product,
        COUNT(*) AS total_complaints
    FROM complaints
    GROUP BY product
)
SELECT
    i.product,
    i.issue,
    i.complaint_count,
    ROUND(
        100.0 * i.complaint_count / p.total_complaints,
        2
    ) AS issue_share_pct
FROM issue_counts i
JOIN product_totals p
    ON i.product = p.product
ORDER BY i.product, issue_share_pct DESC;


-- ============================================================
-- Q17. For each product, what percentage of complaints
--      are handled on time?
-- ============================================================

SELECT
    product,
    COUNT(*) AS total_complaints,
    ROUND(
        100.0 * AVG(
            CASE
                WHEN timely_response = 'Yes' THEN 1.0
                ELSE 0.0
            END
        ),
        2
    ) AS timely_response_pct
FROM complaints
GROUP BY product
ORDER BY timely_response_pct DESC;


-- ============================================================
-- Q18. Which companies perform below the
--      overall timely-response benchmark?
-- ============================================================

WITH overall_response AS (
    SELECT
        AVG(
            CASE
                WHEN timely_response = 'Yes' THEN 1.0
                ELSE 0.0
            END
        ) * 100 AS overall_response_pct
    FROM complaints
),
company_response AS (
    SELECT
        company,
        COUNT(*) AS complaint_count,
        AVG(
            CASE
                WHEN timely_response = 'Yes' THEN 1.0
                ELSE 0.0
            END
        ) * 100 AS company_response_pct
    FROM complaints
    WHERE company IS NOT NULL
    GROUP BY company
    HAVING COUNT(*) >= 100
)
SELECT
    c.company,
    c.complaint_count,
    ROUND(c.company_response_pct, 2) AS company_response_pct,
    ROUND(o.overall_response_pct, 2) AS overall_response_pct
FROM company_response c
CROSS JOIN overall_response o
WHERE c.company_response_pct < o.overall_response_pct
ORDER BY c.company_response_pct ASC;


-- ============================================================
-- Q19. Which product-company areas should be prioritized
--      for operational improvement?
-- ============================================================

WITH metrics AS (
    SELECT
        product,
        company,
        COUNT(*) AS complaint_count,
        ROUND(
            100.0 * AVG(
                CASE
                    WHEN timely_response = 'Yes' THEN 1.0
                    ELSE 0.0
                END
            ),
            2
        ) AS timely_response_pct
    FROM complaints
    WHERE company IS NOT NULL
    GROUP BY product, company
    HAVING COUNT(*) >= 100
)
SELECT
    product,
    company,
    complaint_count,
    timely_response_pct,
    CASE
        WHEN complaint_count >= 1000
             AND timely_response_pct < 95
            THEN 'High Priority'
        WHEN complaint_count >= 500
             AND timely_response_pct < 95
            THEN 'Medium Priority'
        ELSE 'Lower Priority'
    END AS priority
FROM metrics
ORDER BY
    CASE
        WHEN complaint_count >= 1000
             AND timely_response_pct < 95
            THEN 1
        WHEN complaint_count >= 500
             AND timely_response_pct < 95
            THEN 2
        ELSE 3
    END,
    complaint_count DESC;


-- ============================================================
-- Q20. What are the top business priorities based on
--      complaint volume, issue concentration, trends,
--      and response performance?
-- ============================================================

WITH product_metrics AS (
    SELECT
        product,
        COUNT(*) AS complaint_count,
        ROUND(
            100.0 * AVG(
                CASE
                    WHEN timely_response = 'Yes' THEN 1.0
                    ELSE 0.0
                END
            ),
            2
        ) AS timely_response_pct
    FROM complaints
    GROUP BY product
),
top_issue AS (
    SELECT
        product,
        issue,
        complaint_count,
        RANK() OVER (
            PARTITION BY product
            ORDER BY complaint_count DESC
        ) AS issue_rank
    FROM (
        SELECT
            product,
            issue,
            COUNT(*) AS complaint_count
        FROM complaints
        GROUP BY product, issue
    ) x
)
SELECT
    p.product,
    p.complaint_count,
    p.timely_response_pct,
    t.issue AS top_complaint_issue,
    t.complaint_count AS top_issue_count,
    ROUND(
        100.0 * t.complaint_count / p.complaint_count,
        2
    ) AS top_issue_share_pct
FROM product_metrics p
JOIN top_issue t
    ON p.product = t.product
    AND t.issue_rank = 1
ORDER BY p.complaint_count DESC;


SELECT
    product,
    COUNT(*) AS total_complaints,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN timely_response = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS timely_response_pct
FROM complaints
GROUP BY product
ORDER BY total_complaints DESC;

SELECT
    DATE_TRUNC('month', date_received) AS month,
    COUNT(*) AS complaint_count,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN timely_response = 'Yes' THEN 1
                ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS timely_response_pct
FROM complaints
WHERE product = 'Student loan'
GROUP BY DATE_TRUNC('month', date_received)
ORDER BY month;

SELECT
    DATE_TRUNC('month', date_received) AS month,
    COUNT(*) AS complaint_count,
    COUNT(DISTINCT company) AS companies
FROM complaints
WHERE product = 'Student loan'
GROUP BY DATE_TRUNC('month', date_received)
ORDER BY month;