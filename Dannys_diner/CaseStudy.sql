/* ------------
   Case Study
   ------------*/

use dannys_diner
select * from members 
select * from menu
select * from Sales


-- 1. Total amount each customer spent at the restaurant
select s.customer_id, sum(m.price)
from Sales as s inner join menu as m on s.product_id = m.product_id
group by s.customer_id

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(order_date)
from Sales 
group by customer_id


-- 3. What was the first item from the menu purchased by each customer?
With products_rank as(
select  *,
DENSE_RANK() over(partition by customer_id order by order_date) as rnk
from Sales
),
distinct_products as (
select distinct customer_id, product_name
from products_rank as pr join menu as m on pr.product_id = m.product_id
where pr.rnk=1
)
select customer_id, STRING_AGG(product_name,',') as first_items_bought
from distinct_products
group by customer_id


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select top 1 product_name as most_purchased_item, COUNT(customer_id) as times_purchased
from Sales as s join menu as m on s.product_id = m.product_id
group by product_name
order by times_purchased desc


-- 5. Which item was the most popular for each customer?
wITH PRODUCT_COUNT AS(
select customer_id, product_name,
dense_rank() over(partition by customer_id order by COUNT(product_name) desc) as items_rank
from Sales as s join menu as m on s.product_id = m.product_id
group by customer_id, product_name
)
SELECT customer_id, product_name as most_popular_item
from PRODUCT_COUNT
where items_rank = 1


-- 6. Which item was purchased first by the customer after they became a member?
With member_first_item as (
select s.customer_id, s.order_date, mb.join_date, m.product_name,
rank() over(partition by s.customer_id order by s.order_date) as rk
from sales as s join members as mb on s.customer_id = mb.customer_id
	join menu as m on s.product_id = m.product_id
where s.order_date > mb.join_date
)
select customer_id, product_name as first_member_item
from member_first_item
where rk = 1


-- 7. Which item was purchased just before the customer became a member?
With last_item as (
select s.customer_id, s.order_date, mb.join_date, m.product_name,
rank() over(partition by s.customer_id order by s.order_date desc) as rn
from sales as s join members as mb on s.customer_id = mb.customer_id
	join menu as m on s.product_id = m.product_id
where s.order_date < mb.join_date
)
select customer_id, product_name as first_member_item
from last_item
where rn = 1


-- 8. What is the total items and amount spent for each member before they became a member?
select s.customer_id, count(s.product_id) as total_items, sum(m.price) as total_amount
from sales as s join members as mb on s.customer_id = mb.customer_id
	join menu as m on s.product_id = m.product_id
where s.order_date < mb.join_date
group by s.customer_id


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
select customer_id, SUM(points) as toal_points from(
select s.customer_id,
case when m.product_name = 'sushi' then m.price * 20 
	else  m.price * 10
	end as points
from sales as s join menu as m on s.product_id = m.product_id
) as alias 
group by customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
-- dayscount : 0(includes join date) to 6
select s.customer_id, 
		--s.order_date, 
		--mb.join_date, 
		--abs(DATEDIFF(DAY,s.order_date,mb.join_date)) as dayscount,
		sum(m.price * 20) as total_points
from sales as s 
	join members as mb on s.customer_id = mb.customer_id
	join menu as m on s.product_id = m.product_id
where s.order_date >= mb.join_date 
	and abs(DATEDIFF(DAY,s.order_date,mb.join_date)) <= 6
group by s.customer_id
