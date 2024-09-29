-- create table DDL command
create table df_orders (
[order_id] int primary key,
[order_date] date,
[ship_mode] varchar (20),
[segment] varchar (20),
[country] varchar (20),
[city] varchar (20),
[state] varchar (20),
[postal_code] varchar (20),
[region] varchar (20),
[category] varchar (20),
[sub_category] varchar (20),
[product_id] varchar (50),
[quantity] int,
[discount] decimal (7,2),
[sale_price] decimal (7,2),
[profit] decimal (7,2))

-- to see all data
select * from df_orders

-- Find top 10 highest reveue generating products
select top 10 with ties product_id, sum(profit) total_profit from df_orders
group by product_id
order by 2 desc

-- Find top 5 highest selling products in each region
with cte as
(select region, product_id, sum(sale_price) qty_sale,
dense_rank() over(partition by region order by sum(sale_price) desc) rn
from df_orders
group by region, product_id)
select * from cte where rn <= 5

-- Find month over month growth comparison for 2022 and 2023 sales eg: jan 2022 vs jan 2023
with cte as
(select year(order_date) order_year, month(order_date) order_month, sum(sale_price) total_sale from df_orders
group by year(order_date), month(order_date))
select order_month,
sum(case when order_year = 2022 then total_sale else 0 end) as sale_2022,
sum(case when order_year = 2023 then total_sale else 0 end) as sale_2023,
cast(cast(round(((sum(case when order_year = 2023 then total_sale else 0 end)) - (sum(case when order_year = 2022 then total_sale else 0 end))) * 100.0 / (sum(case when order_year = 2022 then total_sale else 0 end)), 2) as float) as varchar) + '%' as inc_or_dec_in_2023
from cte
group by order_month
order by order_month

-- For each category which month had highest sales
with cte as
(select category, format(order_date, 'MMM-yyyy') mnth_yr, sum(sale_price) total_sale,
dense_rank() over(partition by category order by sum(sale_price) desc) rn
from df_orders
group by category, format(order_date, 'MMM-yyyy'))
select category, mnth_yr, total_sale
from cte
where rn = 1

-- Which sub category had highest growth by profit in 2023 compare to 2022?
with cte as
(select sub_category, year(order_date) order_year, sum(profit) total_profit from df_orders
group by sub_category, year(order_date)),
cte2 as
(select sub_category,
sum(case when order_year = 2022 then total_profit else 0 end) as profit_2022,
sum(case when order_year = 2023 then total_profit else 0 end) as profit_2023
from cte
group by sub_category)
select top 1 with ties *,
(profit_2023 - profit_2022) * 100.0 / profit_2022 profit_percentage
from cte2
order by 4 desc
