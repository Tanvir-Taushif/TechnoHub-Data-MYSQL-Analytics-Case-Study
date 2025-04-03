-- create database technohub_analysis;
use technohub_analysis;
show tables;
select
*
from factsales;

-- Customer Spending Analysis

with customerspending as
(
	select
    s.customer_id,
    round(sum(s.quantity*p.price*(1-discount))) as 'total_spend'
    from factsales s
    join products p
    on s.product_id = p.product_id
    group by s.customer_id
)
select
concat(c.first_name,' ',c.last_name) as 'customer_name',
cs.total_spend
from customerspending cs
join customers c
on cs.customer_id = c.customer_id
order by total_spend desc;

-- without cte

select
	concat(c.first_name,' ',c.last_name) as 'customer_name',
	round(sum(s.quantity*p.price*(1-discount))) as 'total_spend'
from factsales s
join products p
on s.product_id = p.product_id
join customers c
on s.customer_id = c.customer_id
group by s.customer_id, c.first_name,c.last_name
order by total_spend desc;
    
-- Monthly Sales per Product Category

with CategoryMonthlySell as
(
	select
	p.category,
	monthname(str_to_date(sale_date,'%m/%d/%Y')) as 'month',
	year(str_to_date(sale_date,'%m/%d/%Y')) as 'year',
	round(sum(s.quantity*p.price*(1-discount))) as 'total_revenue'
	from factsales s
	join products p
	on s.product_id = p.product_id
	group by p.category,month(str_to_date(sale_date,'%m/%d/%Y')),month,year
)
select
category,
SUM(CASE WHEN year = 2024 AND month = 'March' THEN total_revenue ELSE 0 END) AS 'Mar_2024',
SUM(CASE WHEN year = 2024 AND month = 'April' THEN total_revenue ELSE 0 END) AS 'Apr_2024',
SUM(CASE WHEN year = 2024 AND month = 'May' THEN total_revenue ELSE 0 END) AS 'May_2024',
SUM(CASE WHEN year = 2024 AND month = 'June' THEN total_revenue ELSE 0 END) AS 'Jun_2024',
SUM(CASE WHEN year = 2024 AND month = 'July' THEN total_revenue ELSE 0 END) AS 'Jul_2024',
SUM(CASE WHEN year = 2024 AND month = 'August' THEN total_revenue ELSE 0 END) AS 'Aug_2024',
SUM(CASE WHEN year = 2024 AND month = 'September' THEN total_revenue ELSE 0 END) AS 'Sep_2024',
SUM(CASE WHEN year = 2024 AND month = 'October' THEN total_revenue ELSE 0 END) AS 'Oct_2024',
SUM(CASE WHEN year = 2024 AND month = 'November' THEN total_revenue ELSE 0 END) AS 'Nov_2024',
SUM(CASE WHEN year = 2024 AND month = 'December' THEN total_revenue ELSE 0 END) AS 'Dec_2024',
SUM(CASE WHEN year = 2025 AND month = 'January' THEN total_revenue ELSE 0 END) AS 'Jan_2025',
SUM(CASE WHEN year = 2025 AND month = 'February' THEN total_revenue ELSE 0 END) AS 'Feb_2025',
SUM(CASE WHEN year = 2025 AND month = 'March' THEN total_revenue ELSE 0 END) AS 'Mar_2025'
from categoryMonthlySell
group by category
order by category;
-- Top Selling Products
SELECT
    s.product_id,
    p.product_name,
    SUM(s.quantity) AS sold_quantity,
    round(sum(s.quantity*p.price*(1-discount))) as total_revenue
FROM factsales s
JOIN products p 
ON s.product_id = p.product_id
GROUP BY s.product_id, p.product_name, p.stock_quantity
ORDER BY total_revenue DESC;

-- Discount Effectiveness

select
case
	when s.discount = 0 then 'No Discount'
    else 'Discount'
end as discount_category,
count(s.sale_id) as 'total_transaction', 
round(sum(s.quantity*p.price*(1-discount))) as 'total_revenue'
from factsales s
join products p
on s.product_id=p.product_id
group by discount_category;

-- Customer Retention (Who purchased more than 5 months)
select
*
from factsales
limit 5;

select
customer_id,
month(str_to_date(sale_date,'%m/%d/%Y')) as 'month',
year(str_to_date(sale_date,'%m/%d/%Y')) as 'year'
from factsales;

select
s.customer_id,
concat(c.first_name,' ',c.last_name) as 'customer_name',
count(distinct date_format(str_to_date(sale_date,'%m/%d/%Y'),'%Y-%m')) as 'months_purchased'
from factsales s
join customers c
on s.customer_id = c.customer_id
group by customer_id, c.first_name, c.last_name
having months_purchased >=5
order by months_purchased desc;

-- Payment method Distribution

select
payment_method,
count(distinct sale_id) as total_trnx,
round(count(distinct sale_id)*100/(select count(distinct sale_id) from factsales),1) as 'percentage(%)'
from factsales
group by payment_method;

-- Sales and Inventory
with total_sold as
(
	select
	product_id,
	sum(quantity) as sold_quantity
	from factsales
	group by product_id
)
select
ts.product_id,
p.product_name,
ts.sold_quantity,
p.stock_quantity-ts.sold_quantity as remaining_stock
from total_sold ts
join products p
on ts.product_id = p.product_id
order by sold_quantity desc;

SELECT
    f.product_id,
    p.product_name,
    SUM(f.quantity) AS sold_quantity,
    p.stock_quantity - SUM(f.quantity) AS remaining_stock
FROM factsales f
JOIN products p 
ON f.product_id = p.product_id
GROUP BY f.product_id, p.product_name, p.stock_quantity
ORDER BY sold_quantity DESC;

-- Rolling Sales of customers by last 3 months

select
customer_id,
date_format(str_to_date(sale_date,'%m/%d/%Y'),'%Y-%m') as 'year_month',
round(
	sum(s.quantity*p.price*(1-s.discount))
		over (order by 'year_month' rows between 2 preceding and current row)) as 'total_bought' 
from factsales s 
join products p
on s.product_id = p.product_id
order by year(sale_date),month() asc;


select
s.customer_id,
str_to_date(sale_date,'%m/%d/%Y') as date,
round(s.quantity*p.price*(1-s.discount),1) as spend,
round(
	sum(s.quantity*p.price*(1-s.discount))
		over (
				partition by s.customer_id
				order by str_to_date(s.sale_date, '%m/%d/%Y')
				rows between 2 preceding and current row
			),1
	  ) as 'total_spend' 
from factsales s 
join products p
on s.product_id = p.product_id
order by s.customer_id, date asc;

-- Rolling sales of latest transaction and past 2 months transaction
select
s.customer_id,
str_to_date(sale_date,'%m/%d/%Y') as date,
round(s.quantity*p.price*(1-s.discount)) as spend,
round(
	sum(s.quantity*p.price*(1-s.discount))
		over (
				PARTITION BY s.customer_id
				ORDER BY STR_TO_DATE(s.sale_date, '%m/%d/%Y')
				RANGE BETWEEN INTERVAL 2 MONTH PRECEDING AND CURRENT ROW
			)
	  ) as 'total_spend' 
from factsales s 
join products p
on s.product_id = p.product_id
order by s.customer_id, date asc;

-- Customer's Highest Value Purchase

select
concat(c.first_name,' ',c.last_name) as 'customer_name',
round(s.quantity*p.price*(1-s.discount)) as 'total_spend'
from factsales s
join products p
on s.product_id = p.product_id
join customers c
on s.customer_id = c.customer_id;


select 
  concat(c.first_name, ' ', c.last_name) as customer_name,
	(
		select
        round(max(s.quantity*p.price*(1-s.discount)))
        from factsales s
        join products p
        on s.product_id = p.product_id
        where s.customer_id = c.customer_id
	) as max_spend
from customers c;


WITH MaxSpend AS ( -- using cte
  SELECT 
    s.customer_id,
    ROUND(MAX(s.quantity * p.price * (1 - s.discount))) AS max_spend
  FROM factsales s
  JOIN products p 
  ON s.product_id = p.product_id
  GROUP BY s.customer_id
)
SELECT 
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  ms.max_spend
FROM customers c
JOIN MaxSpend ms ON c.customer_id = ms.customer_id;

SELECT 
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
ROUND(MAX(s.quantity * p.price * (1 - s.discount))) AS max_spend
FROM factsales s
JOIN products p 
ON s.product_id = p.product_id
JOIN customers c
on c.customer_id = s.customer_id
GROUP BY s.customer_id, c.first_name,c.last_name;

-- Top 3 customers by spending

with customer_spending as
(
	select
	customer_id,
	round(sum(s.quantity * p.price * (1 - s.discount))) as total_spend
	FROM factsales s
	JOIN products p 
	ON s.product_id = p.product_id
	group by customer_id
),
ranking_customer as
(
	select
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	cs.total_spend,
	row_number() over(order by total_spend desc) as ranking
	from customer_spending cs
	JOIN customers c
	on c.customer_id = cs.customer_id
)
select
*
from ranking_customer
where ranking<=3;


WITH ranking_customer AS ( -- using single cte
  SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    ROUND(SUM(s.quantity * p.price * (1 - s.discount))) AS total_spend,
    ROW_NUMBER() OVER (ORDER BY SUM(s.quantity * p.price * (1 - s.discount)) DESC) AS ranking
  FROM factsales s
  JOIN products p ON s.product_id = p.product_id
  JOIN customers c ON s.customer_id = c.customer_id
  GROUP BY s.customer_id,c.first_name, c.last_name
)
SELECT 
  customer_name,
  total_spend
FROM ranking_customer
WHERE ranking <= 3;


-- Comparing Current Month's sell to previous month's

with sell_analysis as
(
	select
	year(str_to_date(sale_date,'%m/%d/%Y')) as sold_year,
	month(str_to_date(sale_date,'%m/%d/%Y')) as sold_month,
	round(sum(s.quantity*p.price*(1-s.discount))) as total_sell,
	lag(
		round(
			sum(
				s.quantity*p.price*(1-s.discount)
				))) 
				over(
					order by 
					year(str_to_date(sale_date,'%m/%d/%Y')),
					month(str_to_date(sale_date,'%m/%d/%Y'))
					) as previous_month_sell
	from factsales s
	join products p
	on s.product_id = p.product_id
	group by 1,2
	order by 1,2
)
select
	sold_year,
    sold_month,
    total_sell,
    previous_month_sell,
    round((total_sell - previous_month_sell)*100/total_sell,1) as 'precent_chage(%)'
from sell_analysis;

-- Running Total of each product over time

select
s.product_id,
p.product_name,
str_to_date(sale_date,'%m/%d/%Y') as date,
round(s.quantity*p.price*(1-s.discount)) as spend,
round(
	sum(s.quantity*p.price*(1-s.discount))
		over (
				PARTITION BY s.customer_id
				ORDER BY STR_TO_DATE(s.sale_date, '%m/%d/%Y')
			)
	  ) as 'total_spend' 
from factsales s 
join products p
on s.product_id = p.product_id
order by s.product_id, date asc;

-- Customer Segmentation using sales tier
with customer_segmentation as
(
	select
	s.customer_id,
	CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
	round(sum(s.quantity*p.price*(1-s.discount))) as total_spend,
	ntile(4) over(
			order by round(sum(s.quantity*p.price*(1-s.discount))) desc
			) as sales_tier
	from factsales s
	join products p
	on s.product_id = p.product_id
	join customers c
	on s.customer_id = c.customer_id
	group by s.customer_id, c.first_name, c.last_name
)
select
	customer_name,
    total_spend,
    CASE 
           WHEN sales_tier = 1 THEN 'High Spender'
           WHEN sales_tier = 2 THEN 'Medium-High Spender'
           WHEN sales_tier = 3 THEN 'Medium-Low Spender'
           ELSE 'Low Spender'
	end as customer_tier
from customer_segmentation;