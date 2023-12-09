/*******  CASE STUDY  ********/

/****  Digital Analysis ****/

select * from campaign_identifier
select * from event_identifier
select * from events
select * from page_hierarchy
select * from users order by user_id


--1. How many users are there?
select COUNT(distinct user_id) from users

--2. How many cookies does each user have on average?
With cookies as(
select user_id, COUNT(cookie_id) as countcookie 
from users
group by user_id
)
select AVG(countcookie)
from cookies 

---OR
WITH totals AS(
SELECT
	COUNT (DISTINCT (user_id)) as total_users,
	COUNT(cookie_id) as total_cookies
FROM users
)
select (total_cookies/total_users) as average_cookies_per_user
from totals


--3. What is the unique number of visits by all users per month?
-- To o/p: user_id, unique count_visists, date(MONTH)
select DATEPART(month,event_time) as month,COUNT(distinct visit_id) as unique_visits
from events 
group by DATEPART(month,event_time)
order by DATEPART(month,event_time) 


--4. What is the number of events for each event type?
select e.event_type, ei.event_name, COUNT(*) as no_of_visits
from events as e join event_identifier as ei on e.event_type = ei.event_type
group by e.event_type, ei.event_name
order by e.event_type


--5. What is the percentage of visits which have a purchase event?
With purchase_events as(
select COUNT(distinct visit_id) as count_purch_events
from events 
where event_type=3
)
select round((count_purch_events* 100.0)/(select COUNT(distinct visit_id) from events),2) as percent_visits
--(cast(count_purch_events as float)/(select COUNT(distinct visit_id) from events))*100.0 as percent_visits
from purchase_events

--OR
select 
  100 * count(distinct e.visit_id)/
    (select count(distinct visit_id) from events) as percentage_purchase
from events as e
join event_identifier as ei
  on e.event_type = ei.event_type
where ei.event_name = 'Purchase';


--6. What is the percentage of visits which view the checkout page but do not have a purchase event?
/*
visit_id which view the checkout page but do not have a purchase event i.e abandoned carts
total visit_ids which view the checkout page  i.e total_initiated_checkouts
*/

With cart_abandonment_cte as(
select visit_id, max(case when page_id=12 and event_type=1 then 1 else 0 end) as initiated_checkouts,
max(case when event_type=3 then 1 else 0 end) as purchases
from events
group by visit_id
)
select sum(initiated_checkouts) as total_initiated_checkouts,
sum(purchases) as purchases, 
round(100-(sum(purchases)*100.0/sum(initiated_checkouts)),2) as cart_abandonment_rate
from cart_abandonment_cte




--7. What are the top 3 pages by number of views?
With cte as(
select top 3 page_id,count(distinct visit_id) as total_views
from events
group by page_id
order by count(distinct visit_id) desc
)
select cte.page_id, pg.page_name, total_views
from cte join page_hierarchy as pg on pg.page_id=cte.page_id


--8. What is the number of views and cart adds for each product category?
--product category, event type=1 no of views, event type=2 cart adds
select pg.product_category, COUNT(distinct case when event_type = 1 then visit_id end)as 'no_of_views',
COUNT(distinct case when event_type = 2 then visit_id end)as 'cart_adds'
from events as e join page_hierarchy as pg on pg.page_id = e.page_id
group by pg.product_category


--9. What are the top 3 products by purchases?
--product_id
--eventy_type=3
--count()
select top 3 pg.product_id,pg.page_name , COUNT(distinct visit_id) as purchase_count
from page_hierarchy as pg 
	join events as e on pg.page_id=e.page_id 
where visit_id in(select visit_id from events where event_type=3) and product_id is not null
group by pg.product_id,pg.page_name
order by purchase_count desc



/****  Product Funnel Analysis ****/

/*
Creating a new output table with following details:

How many times was each product viewed?
How many times was each product added to cart?
How many times was each product added to a cart but not purchased (abandoned)?
How many times was each product purchased?
*/


IF OBJECT_ID('product_performance_report') IS NOT NULL 
BEGIN 
	DROP TABLE product_performance_report
END;
/*
--Not optimal
With product_views as(
select page_name, COUNT(visit_id) as view_count
from page_hierarchy as pg join events e on pg.page_id=e.page_id
where pg.product_id is not null and e.event_type = 1
group by page_name
),
product_cart_adds as(
select page_name, COUNT(visit_id) as add_to_cart
from page_hierarchy as pg join events e on pg.page_id=e.page_id
where pg.product_id is not null and e.event_type = 2
group by page_name
),
abandoned_cart as(
select pg.page_name, COUNT(visit_id) as abandoned
from page_hierarchy as pg join events e on pg.page_id=e.page_id
where event_type=2 and visit_id not in(   --ignoring purchased visit ids
select distinct visit_id
from events as e
where event_type=3)  
group by page_name
),
purchased_products as(
select page_name, COUNT(visit_id) as purchased
from page_hierarchy as pg join events e on pg.page_id=e.page_id
where e.event_type = 2 and visit_id in(select distinct visit_id
from events as e
where event_type=3)
group by page_name
)
select pv.page_name,pv.view_count, pca.add_to_cart, ac.abandoned, pr.purchased
into product_performance_report
from product_views as pv 
join product_cart_adds as pca on pv.page_name = pca.page_name
join abandoned_cart as ac on ac.page_name = pca.page_name 
join purchased_products as pr on pr.page_name = ac.page_name
*/
--SET STATISTICS TIME, IO OFF

IF OBJECT_ID('product_performance_report') IS NOT NULL 
BEGIN 
	DROP TABLE product_performance_report
END;
--Optimal solution
WITH purchase_visit_id AS (
SELECT DISTINCT(visit_id)
FROM events
WHERE event_type = 3
),
view_cart AS (
SELECT a.visit_id,
		b.page_name, 
		SUM(CASE WHEN a.event_type = 1 THEN 1 ELSE 0 END) AS page_view,
		SUM(CASE WHEN a.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart
FROM events AS a
JOIN page_hierarchy AS b
on a.page_id=b.page_id
WHERE b.product_id IS NOT NULL
GROUP BY a.visit_id, b.page_name
),
product_performance AS (
SELECT  vc.visit_id, 
		page_name, 
		page_view, 
		add_to_cart, 
		CASE WHEN pv.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
FROM view_cart AS vc
LEFT JOIN purchase_visit_id AS pv
on vc.visit_id = pv.visit_id
)
SELECT  page_name AS product, 
		SUM(page_view) AS page_view,
		SUM(add_to_cart) AS cart_adds,
		SUM(CASE WHEN add_to_cart = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
		SUM(CASE WHEN add_to_cart = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
into product_performance_report
FROM product_performance
GROUP BY page_name
ORDER BY product

select * from product_performance_report



/*
	Aggregating the data for the above points for each product category instead of individual products.
*/

IF OBJECT_ID('product_category_performance_report') IS NOT NULL 
BEGIN 
	DROP TABLE product_category_performance_report
END;

WITH purchase_visit_id AS (
SELECT DISTINCT(visit_id)
FROM events
WHERE event_type = 3
),
view_cart AS (
SELECT a.visit_id,
		b.page_name,
		b.product_category, 
		SUM(CASE WHEN a.event_type = 1 THEN 1 ELSE 0 END) AS page_view,
		SUM(CASE WHEN a.event_type = 2 THEN 1 ELSE 0 END) AS add_to_cart
FROM events AS a
JOIN page_hierarchy AS b
on a.page_id=b.page_id
WHERE b.product_id IS NOT NULL
GROUP BY a.visit_id,b.page_name,b.product_category
),
product_category_performance AS (
SELECT  vc.visit_id,
		page_name,
		product_category, 
		page_view, 
		add_to_cart, 
		CASE WHEN pv.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase  
	--purchase is happening on products & not category which is why page_name needs to be included in view_cart
FROM view_cart AS vc
LEFT JOIN purchase_visit_id AS pv
on vc.visit_id = pv.visit_id
)
SELECT  product_category, 
		SUM(page_view) AS page_view,
		SUM(add_to_cart) AS cart_adds,
		SUM(CASE WHEN add_to_cart = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned,
		SUM(CASE WHEN add_to_cart = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
into product_category_performance_report
FROM product_category_performance
GROUP BY product_category
ORDER BY product_category

select * from product_category_performance_report


-- Which product had the most views, cart adds and purchases?
--simple approach
select top 1 product as most_viewed
from product_performance_report
order by page_view desc

--All in one approach
With product_ranking as(
select product, 
RANK() over(order by page_view desc) as r1,
RANK() over(order by cart_adds desc) as r2,
RANK() over(order by purchases desc) as r3
from product_performance_report
)
select p1.product as most_viewed_product, --p1.r1,
	p2.product as most_added_to_cart_product, --p2.r2,
	p3.product as most_purchased_product --p3.r3
from product_ranking p1
join product_ranking p2 on p1.r1=p2.r2
join product_ranking p3 on p2.r2=p3.r3
where p1.r1=1

select * from product_performance_report

-- Which product was most likely to be abandoned?
select top 1 product as most_likely_abandoned
from product_performance_report
order by abandoned desc

-- Which product had the highest view to purchase percentage?
select top 1 product,round((purchases*100.0/page_view),2) as view_to_purchase_percent
from product_performance_report
order by view_to_purchase_percent desc

-- What is the average conversion rate from view to cart add & from cart add to purchase
select round(avg(cart_adds*100.0/page_view),2) as avg_view_to_cart_percent,
		round(avg(purchases*100.0/cart_adds),2) as avg_cart_to_purchase_percent
from product_performance_report


/****  Campaigns Analysis ****/
select * from campaign_identifier

/* Generating a table for every unique visit id containing below params:
user_id
visit_id
visit_start_time: the earliest event_time for each visit
page_views: count of page views for each visit
cart_adds: count of product cart add events for each visit
purchase: 1/0 flag if a purchase event exists for each visit
campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date
impression: count of ad impressions for each visit
click: count of ad clicks for each visit
cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart
*/
drop table if exists campaignAnalysis;

With cte1 as(
select visit_id,user_id, MIN(event_time) as visit_start_time, 
sum(case when event_type=1 then 1 else 0 end) as page_views,
sum(case when event_type=2 then 1 else 0 end) as cart_adds,
sum(case when event_type=4 then 1 else 0 end) as impression,
sum(case when event_type=5 then 1 else 0 end) as click,
max(case when event_type=3 then 1 else 0 end) as purchase,  
string_agg(case when event_type=2 then page_name end,',') as cart_products
from events as e 
left join page_hierarchy as pg on e.page_id=pg.page_id
right join users as u on e.cookie_id=u.cookie_id
--where visit_id='001597'
group by visit_id, user_id
)
select a.*, c.campaign_name
into campaignAnalysis
from cte1 as a 
join campaign_identifier as c on a.visit_start_time >= c.start_date and a.visit_start_time<=c.end_date

select * from campaignAnalysis 
