-- =========================================
-- ATLIQ HARDWARE SQL PROJECT CHALLENGE
-- =========================================

-- Ad Hoc Request 1
SELECT
    COUNT(DISTINCT
        CASE WHEN fiscal_year = 2020
        THEN product_code END
    ) AS unique_products_2020,

    COUNT(DISTINCT
        CASE WHEN fiscal_year = 2021
        THEN product_code END
    ) AS unique_products_2021

FROM fact_gross_price;

-- Ad Hoc Request 2
SELECT
    unique_products_2020,
    unique_products_2021,
    ROUND(
        (unique_products_2021 - unique_products_2020)
        * 100.0 / unique_products_2020,
        2
    ) AS percentage_chg
FROM
(
    SELECT
        COUNT(DISTINCT CASE WHEN fiscal_year = 2020
            THEN product_code END) AS unique_products_2020,
        COUNT(DISTINCT CASE WHEN fiscal_year = 2021
            THEN product_code END) AS unique_products_2021
    FROM fact_gross_price
) AS product_counts;

-- Ad Hoc Request 3
SELECT 
    segment,
    COUNT(segment) AS unique_product_count
FROM dim_product
GROUP BY segment
ORDER BY unique_product_count DESC;

SELECT
    segment,
    COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- Ad Hoc Request 4:
SELECT
    p2020.segment,
    p2020.product_count_2020,
    p2021.product_count_2021,
    p2021.product_count_2021 - p2020.product_count_2020 AS difference
FROM
(
    SELECT
        dp.segment,
        COUNT(DISTINCT fsm.product_code) AS product_count_2020
    FROM dim_product dp
    JOIN fact_sales_monthly fsm
        ON dp.product_code = fsm.product_code
    WHERE fsm.fiscal_year = 2020
    GROUP BY dp.segment
) p2020

JOIN
(
    SELECT
        dp.segment,
        COUNT(DISTINCT fsm.product_code) AS product_count_2021
    FROM dim_product dp
    JOIN fact_sales_monthly fsm
        ON dp.product_code = fsm.product_code
    WHERE fsm.fiscal_year = 2021
    GROUP BY dp.segment
) p2021
    ON p2020.segment = p2021.segment

ORDER BY difference DESC;

-- Ad Hoc Request 5:
WITH manufacturing AS (
    SELECT mc.*, p.product
    FROM fact_manufacturing_cost AS mc
    JOIN dim_product AS p
        ON p.product_code = mc.product_code
)
SELECT
    product_code,
    product,
    manufacturing_cost
FROM manufacturing
WHERE manufacturing_cost = (
    SELECT MAX(manufacturing_cost)
    FROM manufacturing
)
OR manufacturing_cost = (
    SELECT MIN(manufacturing_cost)
    FROM manufacturing
);

-- Ad Hoc Request 6:
WITH Discount AS (
    SELECT id.*, c.customer,c.market
    FROM fact_pre_invoice_deductions AS id
    JOIN dim_customer AS c
        ON c.customer_code = id.customer_code
)
SELECT
    customer_code,
    customer,
    AVG(pre_invoice_discount_pct)*100 AS avg_discount_pct
FROM Discount
WHERE fiscal_year = 2021
  AND market = 'India'
GROUP BY customer_code, customer
ORDER BY avg_discount_pct DESC
LIMIT 5;

-- Ad Hoc Request 7:
select  monthname(s.date) as Month,s.fiscal_year as Year,round(sum(s.sold_quantity*g.gross_price),2) as Gross_Sales_Amount
from fact_sales_monthly as s
join fact_gross_price as g
on s.product_code=g.product_code
join dim_customer as c
on s.customer_code=c.customer_code
where customer='Atliq Exclusive'
group by
MONTH(s.date),
MONTHNAME(s.date),
s.fiscal_year
ORDER BY
    s.fiscal_year,
    MONTH(s.date);

-- Ad Hoc Request 8:
SELECT
CONCAT('Q', QUARTER(date))as Quarter,sum(sold_quantity) as Quantity_sold from fact_sales_monthly 
where fiscal_year=2020
group by quarter(date)
order by Quantity_sold desc

-- Ad Hoc Request 9:
with sales_channel as (select c.channel, round(sum(s.sold_quantity*g.gross_price)/1000000,2) as Gross_Sales_mln
from fact_sales_monthly as s
join dim_customer as c
on c.customer_code=s.customer_code
join fact_gross_price as g
on s.product_code=g.product_code
where s.fiscal_year=2021
group by c.channel)
select channel,Gross_Sales_mln,round(Gross_Sales_mln*100/sum(Gross_Sales_mln) over(),2) as Contribution
from sales_channel
ORDER BY Contribution DESC;

-- Ad Hoc Request 10:
WITH product_sold AS
(
    SELECT
        p.division,
        p.product_code,
        p.product,
        SUM(s.sold_quantity) AS Total_Sold_Qty
    FROM dim_product AS p
    JOIN fact_sales_monthly AS s
        ON p.product_code = s.product_code
    WHERE s.fiscal_year = 2021
    GROUP BY
        p.division,
        p.product_code,
        p.product
),

product_rank AS
(
    SELECT
        *,
        RANK() OVER (
            PARTITION BY division
            ORDER BY Total_Sold_Qty DESC
        ) AS Rank_Order
    FROM product_sold
)

SELECT *
FROM product_rank
WHERE Rank_Order <= 3;
