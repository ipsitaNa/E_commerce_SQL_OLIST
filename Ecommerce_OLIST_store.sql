
--finding no of customers, orders and orders per customers

select 
    count(distinct  customer_unique_id) as no_of_cust,
    count(distinct order_id) as no_of_orders,
    round( cast(count(distinct order_id) as float)/cast(count(distinct  customer_unique_id)as float),2) as orders_per_cus
from View_order_merge o 
join customers c on o.customer_id = c.customer_id;

-- finding customers per date
select 
    datepart(year,order_delivered_carrier_date) as year,
    datepart(month,order_delivered_carrier_date) as month,
    datepart(day,order_delivered_carrier_date) as day,
    --datepart('day',order_delivered_carrier_date) as , 
    count(distinct c.customer_id) as no_of_cust
from View_order_merge o 
join customers c on o.customer_id = c.customer_id
where order_delivered_carrier_date is not null
group by 
        datepart(year,order_delivered_carrier_date),
        datepart(month,order_delivered_carrier_date),
        datepart(day,order_delivered_carrier_date)
order by datepart(year,order_delivered_carrier_date),
        datepart(month,order_delivered_carrier_date),
        datepart(day,order_delivered_carrier_date);


 --RUNNING TOTAL for customers who have succesful delivered orders Per monthly and daily.

select 
    datepart(year,order_delivered_carrier_date) as year,
    datepart(month,order_delivered_carrier_date) as month,
    datepart(day,order_delivered_carrier_date) as day,
    --datepart('day',order_delivered_carrier_date) as , 
    count(distinct c.customer_id) as no_of_cust,
    sum(count(distinct c.customer_id))over(partition by 
    datepart(year,order_delivered_carrier_date) ,
    datepart(month,order_delivered_carrier_date)
    order by datepart(year,order_delivered_carrier_date) ,
    datepart(month,order_delivered_carrier_date) ) as monthly_running_total
from View_order_merge o 
join customers c on o.customer_id = c.customer_id
where order_delivered_carrier_date is not null
group by 
        datepart(year,order_delivered_carrier_date),
        datepart(month,order_delivered_carrier_date),
        datepart(day,order_delivered_carrier_date)
order by datepart(year,order_delivered_carrier_date),
        datepart(month,order_delivered_carrier_date),
        datepart(day,order_delivered_carrier_date);

  -- finding no of orders  by order_id individually as well as no of orders in weekday/weekend 
SELECT 
  coalesce(order_id,'GrandTotal') as order_id,
  coalesce(day_of_week,'GrandTotal') as day_of_week,
  sum(count(order_id))over(partition by order_id,day_of_week) as no_of_orders
FROM (
  SELECT 
    order_id,
    CASE WHEN DATEPART(w,order_purchase_timestamp) IN (1,7) THEN 'weekend' ELSE 'weekday' END AS day_of_week
  FROM View_order_merge
)  orders 
GROUP BY grouping sets (order_id,day_of_week)
order by 3 desc;


--finding grandtotal of ORDERS COUNT based on the grouping as well as subtotals 
SELECT 
  coalesce(order_id,'GrandTotal') as order_id,
  coalesce(day_of_week,'GrandTotal') as day_of_week,
  sum(count(order_id))over(partition by order_id,day_of_week) as no_of_orders
FROM (
  SELECT 
    order_id,
    CASE WHEN DATEPART(w,order_purchase_timestamp) IN (1,7) THEN 'weekend' ELSE 'weekday' END AS day_of_week
  FROM View_order_merge
)  orders 
GROUP BY ROLLUP (day_of_week,order_id)
order by 3 desc;


--finding grand toatal and subtotal of SALES per year,month,weekday/weekend and order_ids
SELECT
  coalesce(cast(year as varchar),'GrandTotal') as year,
  coalesce(cast(month as varchar),'GrandTotal') as month,
  coalesce(day_of_week,'GrandTotal') as day_of_week,
  coalesce(order_id,'GrandTotal') as order_id, 
  round(SUM(price),2) as sales
FROM (
  SELECT 
    order_id,
    price,
    CASE WHEN DATEPART(w,order_purchase_timestamp) IN (1,7) THEN 'weekend' ELSE 'weekday' END AS day_of_week,
    month(order_purchase_timestamp) as month,
    year(order_purchase_timestamp) as year
  FROM View_order_merge
  where order_status = 'delivered'
) AS sales
GROUP BY  rollup  (year,[month],day_of_week,order_id)
order by sales desc;

-- showing count of orders per_orderid as well as weekday or weekend
SELECT 
  coalesce(order_id,'GrandTotal') as order_id,
  coalesce(day_of_week,'GrandTotal') as day_of_week,
  sum(count(order_id))over(partition by order_id,day_of_week) as no_of_orders
FROM (
  SELECT 
    order_id,
    CASE WHEN DATEPART(w,order_purchase_timestamp) IN (1,7) THEN 'weekend' ELSE 'weekday' END AS day_of_week
  FROM View_order_merge
)  orders 
GROUP BY grouping sets (order_id,day_of_week);

--using same query for ROLLUP- rollup will give the grand totals and subtotals.

SELECT 
  coalesce(order_id,'GrandTotal') as order_id,
  coalesce(day_of_week,'GrandTotal') as day_of_week,
  sum(count(order_id))over(partition by order_id,day_of_week) as no_of_orders
FROM (
  SELECT 
    order_id,
    CASE WHEN DATEPART(w,order_purchase_timestamp) IN (1,7) THEN 'weekend' ELSE 'weekday' END AS day_of_week
  FROM View_order_merge
)  orders 
GROUP BY ROLLUP (day_of_week,order_id)
order by 3 desc;

-- orders in weekday and weekend

SELECT 
  day_of_week,
  sum(count(distinct order_id))over(partition by day_of_week) as no_of_orders
FROM (
  SELECT 
    order_id,
    CASE WHEN DATEPART(w,order_purchase_timestamp) IN (1,7) THEN 'weekend' ELSE 'weekday' END AS day_of_week
  FROM View_order_merge
)  orders
GROUP BY day_of_week;

-- Totals and subtotals of sales weekdays/weekends,monthly,yearly
SELECT
  coalesce(cast(year as varchar),'GrandTotal') as year,
  coalesce(cast(month as varchar),'GrandTotal') as month,
  coalesce(day_of_week,'GrandTotal') as day_of_week,
  coalesce(order_id,'GrandTotal') as order_id, 
  round(SUM(price),2) as sales
FROM (
  SELECT 
    order_id,
    price,
    CASE WHEN DATEPART(w,order_purchase_timestamp) IN (1,7) THEN 'weekend' ELSE 'weekday' END AS day_of_week,
    month(order_purchase_timestamp) as month,
    year(order_purchase_timestamp) as year
  FROM View_order_merge
  where order_status = 'delivered'
) AS sales
GROUP BY  rollup  (year,[month],day_of_week,order_id)
order by sales desc;

--VIEW to have details for evey cus_id their first and last purchase date and order
CREATE OR ALTER   VIEW [dbo].[View_first_last_purchase] as
 select * from (
select customer_unique_id , order_id,
FIRST_VALUE(order_purchase_timestamp)over(partition by  customer_unique_id order by order_purchase_timestamp) as first_ord_dt,
FIRST_VALUE(order_id)over(partition by customer_unique_id order by order_purchase_timestamp) as first_or_id,
LAST_VALUE(order_purchase_timestamp)over(partition by customer_unique_id order by order_purchase_timestamp 
 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING ) as last_ord_dt,
LAST_VALUE(order_id)over(partition by customer_unique_id order by order_purchase_timestamp 
 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) as last_or_id,
ROW_NUMBER()over(partition by customer_unique_id order by order_purchase_timestamp ) as row 
from View_order_merge o 
        join customers c on o.customer_id = c.customer_id 
        where order_status = 'delivered'  ) a 
        where a.row=1;

  --checking if there's any duplicates in the View_first_last_purchase query
  Select * from 
(select 
*,
count(*)over(PARTITION by customer_unique_id) as cnt 
from View_first_last_purchase) as t 
where t.cnt > 1;

--Conversion rate -- taking into conisderation customers who have at least purchased their first item out of total customer present
select 
*,
round((cast (a.no_of_first_orders as float)/cast(a.Total_cust as float)*100),2) as Conversion_rate
from(
select 
count(distinct M.customer_unique_id) as Total_cust,
count(distinct fl.first_order_id) as no_of_first_orders
 from 
View_MASTER_merge M 
left join 
View_first_last_purchase fl 
on M.customer_unique_id = fl.customer_unique_id) a

Total_cust  no_of_first_orders  Conversion_rate
96096       93358               97.15


-- Conversion rate per Product catergory names


select 
*,
round((cast (a.no_of_first_orders as float)/cast(a.Total_cust as float)*100),2) as Convr_rt_per_prodCateg
from(
select 
M.product_category_name,
count(distinct M.customer_unique_id) as Total_cust,
count(distinct fl.first_order_id) as no_of_first_orders
 from 
View_MASTER_merge M 
left join 
View_first_last_purchase fl 
on M.customer_unique_id = fl.customer_unique_id
where M.product_category_name is not NULL 
group by M.product_category_name) a
order by Convr_rt_per_prodCateg desc

--TOPIC  Calculating Percentage (%) of Total Sum in SQL
-- THIS IS THE CONTRIBUTION PER PROD CATEGORY PER TOTAL SALES

-- in the CTE i have used View_order_merge where  orders left join ord_item dataset a
/*I did a cross join [View_master_merge,Total_price] so that every row will have 
Ive selected all records from the "View_master_merge" table and join each record with all the records from the 
"Total_price" table. */

with Total_price as (
select round(sum(V.price),2) as total_price
from View_order_merge V where V.order_status = 'delivered' 
 -- 13221498.11
)
select 
product_category_name, 
count(o.order_id) as ord_qty,
round(sum(o.price),2) as sales_per_categ,
tp.total_price,
round(sum(o.price)/tp.total_price *100,2)as contribution_per_prods
 from View_order_merge o 
left join products p on p.product_id = o.product_id
cross join 
 Total_price tp 
 where product_category_name is not null 
 and order_status = 'delivered' 
 group by product_category_name,tp.total_price
 having count(o.order_id) > 0
 order by 3 desc;

 -- PERCENTAGE TO TOTAL PER GROUP
 /* The next question to ask is how this is changing over time?

What we are attempting to do here is to group our data into months, 
compute the total for that group and for each row within that group compute a ratio*/

select a.[year],a.[month],a.product_category_name,a.sales_monthly,a.prod_price,a.per_cat_contri 
from (
select 
datepart(year,order_purchase_timestamp) as year,
datepart(month,order_purchase_timestamp) as month,
product_category_name,
round(sum(price)over( partition by 
datepart(year,order_purchase_timestamp),datepart(month,order_purchase_timestamp)),2)
as sales_monthly,
sum(price)over( partition by 
datepart(year,order_purchase_timestamp),datepart(month,order_purchase_timestamp),product_category_name) as prod_price,
round(sum(price)over( partition by 
datepart(year,order_purchase_timestamp),datepart(month,order_purchase_timestamp),product_category_name)
/sum(price)over( partition by 
datepart(year,order_purchase_timestamp),datepart(month,order_purchase_timestamp))*100,2) as per_cat_contri,
ROW_NUMBER()over(PARTITION by
 datepart(year,order_purchase_timestamp),datepart(month,order_purchase_timestamp),
product_category_name 
order by order_purchase_timestamp ) as r_n 
from View_order_merge o 
join products p on o.product_id = p.product_id
where product_category_name is not null and order_status = 'delivered'
) a 
where a.r_n = 1
order by 1,2,3,5 desc;

-- find top 5 sales product yearly and monthly


with ProdPrice_monthly as (
select 
datepart(year,order_purchase_timestamp) as year,
datepart(month,order_purchase_timestamp) as month,
product_category_name,
round(sum(price)over( partition by 
datepart(year,order_purchase_timestamp),datepart(month,order_purchase_timestamp),product_category_name),2) as prod_price
from View_order_merge o 
join products p on o.product_id = p.product_id
where product_category_name is not null and order_status = 'delivered'),
rankprod as (
select *,
dense_rank()over(PARTITION by p.YEAR,p.month order by p.prod_price desc ) as rnk
from ProdPrice_monthly p 
)
select 
Distinct * from rankprod r
where r.rnk <=5 
order by r.year,r.month,r.rnk;
   

-- Aggregating into "All Other" to the above top 5 query
/*The problem with the above query set is that we are missing data on how much business the other prod categ closed to put 
the visualization in context */

--creating view for the above query
create or alter VIEW V_top_n_Sales as 
with ProdPrice_monthly as (
select 
datepart(year,order_purchase_timestamp) as year,
datepart(month,order_purchase_timestamp) as month,
product_category_name,
round(sum(price)over( partition by 
datepart(year,order_purchase_timestamp),datepart(month,order_purchase_timestamp),product_category_name),2) as prod_price
from View_order_merge o 
join products p on o.product_id = p.product_id
where product_category_name is not null and order_status = 'delivered'),
rankprod as (
select *,
dense_rank()over(PARTITION by p.YEAR,p.month order by p.prod_price desc ) as rnk
from ProdPrice_monthly p 
)
-- aggreagting "all other products" 
select distinct  year,
[month],
product_category_name,
prod_price
 from V_top_n_Sales 
 where rnk <=5 
 union all 
 select distinct
 datepart(year,order_purchase_timestamp) as year,
datepart(month,order_purchase_timestamp) as month,
  'All other products' as product_category_name,
 round(sum(price)over( partition by 
datepart(year,order_purchase_timestamp),datepart(month,order_purchase_timestamp))
,2) as prod_price
from View_order_merge o 
join products p on o.product_id = p.product_id
where  order_status = 'delivered'
and product_category_name not in (select product_category_name from
                                      V_top_n_Sales where rnk <=5)
            and product_category_name is not null
                                order by year, [month],prod_price ; 

--product analysis AOV, orders, revenue

select 
p.product_id,
count(order_id) as orders,
round(sum(price),2) as revenue,
round(avg(price),2) as AOV
from View_order_merge o 
join products p on o.product_id = p.product_id
group by p.product_id 
order by 2 desc;

----finding new customers per week
/*
new_cust_per_week Date                    week
69                2017-01-09 00:00:00.000 2
173               2017-01-16 00:00:00.000 3
345               2017-01-23 00:00:00.000 4 */

select 
count(a.customer_unique_id) as new_cust_per_week,
DATEADD(wk, DATEDIFF(wk, 0, created), 0) as FirstDayOfWeek,
case when DATEPART(wk,created) = 53 then 1 else DATEPART(wk,created) end as week
from
(Select distinct customer_unique_id, min(order_purchase_timestamp) as created 
    from View_order_merge o 
join customers c on o.customer_id = c.customer_id
where DATEPART(year,order_purchase_timestamp) in (2017,2018) 
group by customer_unique_id )a
group by DATEADD(wk, DATEDIFF(wk, 0, created), 0),
case when DATEPART(wk,created) = 53 then 1 else DATEPART(wk,created) end 
order by 2;    

--CUSTOMER LIFE CYCLES
-- NEW CUSTOMERS VS ACTIVE CUSTOMERS VS LAPSED CUSTOMERS
-- active custoerm who are active within 6  months else beyond are lapsed customer

with order_seq as (
select 
customer_unique_id,
c.customer_id,
order_purchase_timestamp as ord_dt,
ROW_NUMBER()over(PARTITION by customer_unique_id order by 
order_purchase_timestamp) as cust_order_seq,
lag(order_purchase_timestamp)over(partition by customer_unique_id order by 
order_purchase_timestamp) as prev_order_date
from customers c 
left join View_order_merge o 
on c.customer_id = o.customer_id),
 days_differnece as (
select 
ord_dt,
customer_unique_id,
customer_id,
cust_order_seq,
CASE when prev_order_date is null then ord_dt 
    ELSE prev_order_date end  as prev_order_date,
coalesce(DATEDIFF(day,prev_order_date,ord_dt),0) as days_between_ords
from order_seq),
customer_life_cycle as (
 SELECT
    ord_dt,
    customer_unique_id,
    customer_id,
    CASE when cust_order_seq = 1 then 'New Customer'
         When days_between_ords > 0 and days_between_ords < 180 then 'Active Customer'
         When days_between_ords > 180 then 'Lapsed Customer' Else 'Not Reqquired'
         End as customer_life_cycle,
    cust_order_seq,
    prev_order_date,
    days_between_ords
from days_differnece)
select  
lc.customer_unique_id,
c.customer_state,
c.customer_city,
o.order_id,
lc.ord_dt,
lc.prev_order_date,
lc.cust_order_seq,
lc.customer_life_cycle,
lc.days_between_ords
from customers c 
left join View_order_merge o  on c.customer_id = o.customer_id
left join customer_life_cycle lc on c.customer_id = lc.customer_id
where o.order_status = 'delivered' ;        

--PER YEAR--MONTHLY CONVERSION RATE
-- total sales per month / total distinct customer
-- count distinct window function is not supported in SQL, do ranking per year per month over customer and take the max rank from it
WIth b_t as (
select 
DATEPART(year,order_purchase_timestamp) as year,
DATEPART(month,order_purchase_timestamp) as month,
customer_unique_id,
price,
round(sum(price)over(partition by 
DATEPART(year,order_purchase_timestamp),
DATEPART(month,order_purchase_timestamp)),2) as sales_per_monthly
from View_order_merge o 
join customers c on o.customer_id = c.customer_id
--where customer_unique_id='001926cef41060fae572e2e7b30bd2a4'
 where order_status = 'delivered'),
 cte as (
select 
*,
dense_rank()over(partition by b_t.year,b_t.month order by customer_unique_id) as dr
from b_t),
 max_t as (
     select 
     cte.year,
     cte.MONTH,
     cte.customer_unique_id,
     cte.price,
     cte.sales_per_monthly,
     max(dr)over(partition by cte.YEAR,cte.MONTH order by cte.YEAR,cte.MONTH ) as distinct_cust_count    
     from cte
 )select 
 *,
 round(sales_per_monthly/distinct_cust_count,2) as conversion_rate_monthly
  from max_t;                

  --- Z-SCORES to know about the sales and customers per month 
--In statistics, the z-score (or standard score) of an observation is the number of standard deviations that it is above or below the population me   
/*  is the observation,  is the mean and  is the standard deviation. 
comparing the  performace of sales and no of customers monthly in terms of z score. Taken 95% CI z score lying between +-1.964 . anything less or beyond is an outlier*/

--Creating a view first
create or alter view view_mon_cov_rat as 
WIth b_t as (
select 
DATEPART(year,order_purchase_timestamp) as year,
DATEPART(month,order_purchase_timestamp) as month,
customer_unique_id,
price,
round(sum(price)over(partition by 
DATEPART(year,order_purchase_timestamp),
DATEPART(month,order_purchase_timestamp)),2) as sales_per_monthly
from View_order_merge o 
join customers c on o.customer_id = c.customer_id
--where customer_unique_id='001926cef41060fae572e2e7b30bd2a4'
 where order_status = 'delivered'),
 cte as (
select 
*,
dense_rank()over(partition by b_t.year,b_t.month order by customer_unique_id) as dr
from b_t),
 max_t as (
     select 
     cte.year,
     cte.MONTH,
     cte.customer_unique_id,
     cte.price,
     cte.sales_per_monthly,
     max(dr)over(partition by cte.YEAR,cte.MONTH order by cte.YEAR,cte.MONTH ) as distinct_cust_count    
     from cte
 )select 
 *,
 round(sales_per_monthly/distinct_cust_count,2) as conversion_rate_monthly
  from max_t;

select 
    [year],
    month,
    round(abs(sales_per_monthly - year_mean_sal)/nullif(year_stddev_sal,0),2) as z_score_sales,
    round(abs(distinct_cust_count - year_mean_cust)/nullif(year_sddev_cust,0),2) as z_score_cust
from 
    (
    select 
    year,
    [month],
     customer_unique_id,
     sales_per_monthly,
     distinct_cust_count,
    round(avg(sales_per_monthly)over(partition by year),2) as year_mean_sal,
    round(STDEV(sales_per_monthly)over(partition by year),2) as year_stddev_sal,
    round(avg(distinct_cust_count)over(partition by year),2) as year_mean_cust,
    round(STDEV(distinct_cust_count)over(partition by year),2) as year_sddev_cust
    from(
        select 
        *,
        row_number()over(partition by year,month order by customer_unique_id) as rw_n
   from view_mon_cov_rat
)q1
where q1.rw_n = 1
) q2 
 order by 1,2

-----MONTHLY GRWOTH SALES PERCENTAGE

select 
*,
round(((b.monthly_sales - b.prev_monthly_sale)/nullif(b.prev_monthly_sale,0))*100,2) as monthly_growth_perc
from
(select 
a.[year],
a.[month],
a.customer_unique_id,
a.monthly_sales,
lag(a.monthly_sales)over(order by a.YEAR,a.month) as prev_monthly_sale 
from
(select 
DATEPART(year,o.order_purchase_timestamp) as year,
DATEPART(month,o.order_purchase_timestamp) as month,
c.customer_unique_id,
order_id,
order_item_id,
round(sum(price)over(PARTITION by DATEPART(year,o.order_purchase_timestamp),
DATEPART(month,o.order_purchase_timestamp)),2) as monthly_sales,
ROW_NUMBER()over(PARTITION by DATEPART(year,o.order_purchase_timestamp),
DATEPART(month,o.order_purchase_timestamp) order by order_purchase_timestamp) as row_n
 from 
View_order_merge o 
left join customers  c on o.customer_id = c.customer_id
where o.order_status = 'delivered') a
where a.row_n = 1)b
order by 1,2;

