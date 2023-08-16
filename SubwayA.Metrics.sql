
drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');

drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Mustard Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Lettuce'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce'),
(13,'Chipotle Sauce');

drop table if exists burgers;
CREATE TABLE burgers(burger_id integer,burger_name varchar(30)); 

INSERT INTO burgers(burger_id ,burger_name) 
 VALUES (1	,'Non Veg burger'),
(2	,'Veg burger');

drop table if exists burger_recipes;
CREATE TABLE burger_recipes(burger_id integer,ingredients varchar(24)); 

INSERT INTO burger_recipes(burger_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,5,6,7,9,11,12,13');

drop table burger_recipes;

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2021 21:30:45','25km','25mins',null),
(8,2,'01-10-2021  00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2021 18:50:20','10km','10minutes',null);

drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,burger_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,burger_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');



select * from customer_orders;
select * from driver_order;
select * from driver;
SELECT * FROM ingredients;
select * from burgers;
select * from burger_recipes;

A. Burger Metrics

--Creating a stored Procedure for successful orders
 Go
CREATE or ALTER PROCEDURE sp_order_delivered As
    
   BEGIN
        select *, 
          case when cancellation in  ('Cancellation' ,'Customer Cancellation') then 'c' else 'nc'end as delivered_order
          from driver_order
   END
   exec sp_order_delivered;

--clean driver order table
DROP TABLE IF EXISTS clean_driver_orders;
CREATE TABLE clean_driver_orders(
             order_id integer,
			 driver_id integer,
			 pickup_time datetime,
			 distance VARCHAR(7),
			 duration VARCHAR(10),
			 cancellation VARCHAR(23),
			 delivered_order varchar(4)
);

INSERT INTO clean_driver_orders(order_id,driver_id,pickup_time,distance,duration,cancellation,delivered_order)
EXEC sp_order_delivered;

select * from clean_driver_orders;


1.How many burgers were ordered?

select COUNT(burger_id) from customer_orders;

2. How many unique customer  orders were made?

select count(distinct customer_id) as No_of_customers from customer_orders;

3. How many successful orders were delivered by each driver?

with successful_order as(select *, 
          case when cancellation in  ('Cancellation' ,'Customer Cancellation') then 'c' else 'nc'end as delivered_order
          from driver_order)

select driver_id, count(distinct order_id) from successful_order
where delivered_order ='nc'
group by driver_id ;
 
4. How many of each type of burger was delivered?
with burger_delivered as(
         select * from
              (select *, 
                case when cancellation in  ('Cancellation' ,'Customer Cancellation') then 'c' else 'nc'end as delivered_order
                from driver_order) a
		 where delivered_order = 'nc'),

customer_distinct_order as
( select distinct order_id, burger_id,  order_date from customer_orders)

select distinct b.burger_id, b.burger_name,COUNT(b.burger_id) as No_Of_delivered
from  burger_delivered bd
inner join customer_distinct_order c on bd.order_id  = c.order_id
inner join burgers b
on c.burger_id = b.burger_id 
group by  b.burger_id, b.burger_name;

5.How many vag and non veg burger ordered by each customer?
select c.customer_id,b.burger_name ,COUNT(b.burger_name) as No_of_Order
from customer_orders c
left join burgers b on c.burger_id = b.burger_id
group by c.customer_id,c.burger_id,b.burger_name
order by b.burger_name;

6.What was the maximum number of burgers delivered in single order?

with burger_delivered as(
select * from customer_orders 
where order_id in 
                (
				  select order_id 
				  from (select *, 
                              case when cancellation in  ('Cancellation' ,'Customer Cancellation') then 'c' else 'nc'end as delivered_order
                               from driver_order) a
		         where delivered_order = 'nc')
              )
select TOP 1 order_id,count(order_id) as No_Of_burgers
from burger_delivered
group by order_id
order by No_Of_burgers DESC;

7.For each customer, how many delivered burger had atleast 1 change and how many had no change?

select * from customer_orders;
select * from driver_order;
With temp_customer_orders as(
   select order_id,customer_id,burger_id, 
   case when not_include_items is NULL or not_include_items = ' ' then '0'else not_include_items end as not_include_items,
   case when extra_items_included is NULL or extra_items_included = ' ' or extra_items_included = 'NaN' then '0' else extra_items_included end as  extra_items_included
   from customer_orders
)
select customer_id,changedetails,COUNT(order_id) no_of_time_changes
from
    (select c.order_id,c.customer_id,
      case when c.not_include_items = '0' and c.extra_items_included = '0' then 'no change' else 'change' end as changedetails
    from temp_customer_orders c
    left join clean_driver_orders d on c.order_id = d.order_id
    where d.delivered_order = 'nc')a
group by customer_id,changedetails;

8. How many burgers were delivered that had both exclusion and extra?

With temp_customer_orders as(
   select order_id,customer_id,burger_id, 
   case when not_include_items is NULL or not_include_items = ' ' then '0'else not_include_items end as not_include_items,
   case when extra_items_included is NULL or extra_items_included = ' ' or extra_items_included = 'NaN' then '0' else extra_items_included end as  extra_items_included
   from customer_orders
)
select IncludedORExcludedDetails, count(IncludedORExcludedDetails)
from
    (select c.*,
      case when c.not_include_items != '0' and c.extra_items_included != '0' then 'both inc exc' else 'either 1 inc or exc' end as IncludedORExcludedDetails
    from temp_customer_orders c
    left join clean_driver_orders d on c.order_id = d.order_id
    where d.delivered_order = 'nc')a
group by IncludedORExcludedDetails;

9.What was the total number of burgers ordered for each hour of the day?
select  hours_bucket,count(hours_bucket) burger_order_perhour
from 
(select * , Concat(datepart(hour,order_date),'-',(datepart(hour,order_date)+1)) hours_bucket
from customer_orders)a
group by hours_bucket;

10.What was the  number of burgers ordered for each day of the week?
select dow,count(distinct order_id) No_of_orders
from
   (select *,datename(dw,order_date) dow from
    customer_orders)a
group by dow;

--B.Driver and Customer Experience

1.What was the average time in minutes it took for each driver to arrive at Subway cantre to pickup the order?
With temp_driver_order 
as     (select c.*,d.driver_id,d.pickup_time, datediff(minute, c.order_date, d.pickup_time)diff
       from customer_orders c
       inner join driver_order d 
       on c.order_id = d.order_id
       where d.pickup_time is not null ) 

select driver_id,avg(diff) driver_avg_time_in_minutes--sum(diff)/count(order_id) avg_mins
from
     (select *, row_number() over(partition by order_id order by diff)rn
     from temp_driver_order)a
      where rn = 1
	 group by driver_id ;

2.What was the average distance travelled for each customer?

  select * from customer_orders;
  
  select customer_id,avg(distance) avg_distance from 
  (select c.customer_id, cast(trim(replace(d.distance,'km','')) as decimal(4,2)) distance,d.order_id
  from customer_orders c
  inner join driver_order d
  on c.order_id = d.order_id
  where d.distance is not NULL) a
  group by  customer_id;

  3.what was the difference between longest and shortest delivery time for all orders?
  select max(duration) - min(duration) as diff
  from
  (select order_id,cast(left(duration,2) as int) duration
  from driver_order
  where pickup_time is not NULL)a

  4.What is the succesfuly delivered percentage for each driver?
  select driver_id,(s*1.0/d )*100 as delivered_percentage
  from
 ( select driver_id,sum(cancel_details) s,count(driver_id) d
  from
  (select *,
  case when lower(cancellation) like '%cancel%' then 0 else 1 end as cancel_details
  from driver_order)a
  group by driver_id) b;


/*
WITH temp_driver_order as(
  select order_id,driver_id,pickup_time,distance,duration, case when cancellation in ('Cancellation','Customer Cancellation') then '0' else 1 end as cancellation  from driver_order
)

select * from temp_driver_order where;*/


