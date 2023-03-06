
#1.Provide the list of markets in which customer "Atliq Exclusive" operates 
#  its business in the APAC region.

SELECT DISTINCT
    market
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';

#2. What is the percentage of unique product increase in 2021 vs. 2020?

with cte as
	(select fiscal_year,count(distinct product_code) as unique_product_code_2020
	from fact_gross_price where fiscal_year=2020),
cte2 as
	(select fiscal_year,count(distinct product_code) as unique_product_code_2021
	from fact_gross_price where fiscal_year=2021)
select unique_product_code_2020,unique_product_code_2021,
round((unique_product_code_2021-unique_product_code_2020)/unique_product_code_2020*100,2) as percentage_chg
from cte join cte2;

#3.Provide a report with all the unique product counts for each segment 
#  and sort them in descending order of product counts.

SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

# 4.Which segment had the most increase in unique products in 2021 vs 2020?

with cte as
	(select d.segment,count(distinct(d.product_code)) as product_count_2020 from dim_product d inner join
	fact_gross_price f on d.product_code=f.product_code where f.fiscal_year=2020
	group by d.segment),
cte2 as
	(select d.segment,count(distinct(d.product_code)) as product_count_2021 from dim_product d inner join
	fact_gross_price f on d.product_code=f.product_code where f.fiscal_year=2021
	group by d.segment)
select cte.segment,product_count_2020,product_count_2021,(product_count_2021-product_count_2020) as 
difference from cte cross join cte2 
on cte.segment=cte2.segment order by 4 desc;

# 5.Get the products that have the highest and lowest manufacturing costs.

SELECT 
    d.product_code, d.product, manufacturing_cost
FROM
    dim_product d
        INNER JOIN
    fact_manufacturing_cost fm ON d.product_code = fm.product_code
WHERE
    manufacturing_cost = (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
        OR manufacturing_cost = (SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

# 6.Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the 
#  fiscal year 2021 and in the Indian market.

SELECT 
    d.customer_code,
    customer,
    ROUND(AVG(pre_invoice_discount_pct), 2) AS average_discount_percentage
FROM
    dim_customer d
        INNER JOIN
    fact_pre_invoice_deductions fd ON d.customer_code = fd.customer_code
WHERE
    fiscal_year = 2021 AND market = 'India'
GROUP BY 1 , 2
ORDER BY 3 DESC
LIMIT 5;

# 7.Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of 
# low and high-performing months and take strategic decisions.

with cte as
	(select monthname(date) as month,year(date) as year,gross_price,sold_quantity,
    (gross_price*sold_quantity) as Gross_sales_Amount from fact_sales_monthly fsm 
    inner join fact_gross_price fgp on fsm.product_code=fgp.product_code 
	inner join dim_customer d on d.customer_code=fsm.customer_code
	where customer='Atliq Exclusive')
select month,year,sum(Gross_sales_Amount) as Gross_sales from cte group by 1,2;

# 8.In which quarter of 2020, got the maximum total_sold_quantity?
with cte as
	(select monthname(date) as month,month(date) as month_num,sold_quantity,
	case when month(date)<=3 then 'Q1'
		  when month(date)>3 and month(date)<=6 then 'Q2'
		  when month(date)>6 and month(date)<=9 then 'Q3'
		  else 'Q4' end as Quarter
	from fact_sales_monthly 
	where year(date)=2020 group by 1,2)
select Quarter,sum(sold_quantity) as total_sold_quantity from cte 
group by Quarter order by 2 desc;

# 9.Which channel helped to bring more gross sales in the 
# fiscal year 2021 and the percentage of contribution?

with cte as
	(select channel,fsm.fiscal_year,gross_price,sold_quantity,
	sum((gross_price*sold_quantity)) as total_sales from fact_sales_monthly fsm 
	inner join fact_gross_price fgp on fsm.product_code=fgp.product_code
	inner join dim_customer d on d.customer_code=fsm.customer_code
	where fsm.fiscal_year=2021 group by channel)
select channel,round(total_sales/1000000,3) as gross_sales_mln,
round(total_sales/(sum(total_sales) over())*100,2) as percentage 
from cte;

# 10.Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?

with cte as
	(select d.division,d.product_code,d.product,sum(s.sold_quantity) as total_sold_quantity,
	rank() over(partition by division order by sum(s.sold_quantity) desc) as rank_order
	from dim_product d inner join fact_sales_monthly s 
	on d.product_code=s.product_code where fiscal_year=2021 
	group by d.product_code,d.product)
select division,product,product_code,total_sold_quantity,rank_order 
from cte where rank_order<=3;    
   