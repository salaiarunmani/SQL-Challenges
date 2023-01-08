CREATE SCHEMA dannys_diner;
use dannys_diner;
CREATE TABLE sales(customer_id VARCHAR(1),order_date DATE,product_id integer);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', 10),
  ('2', 'curry', 15),
  ('3', 'ramen', 12);
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
-- 1. What is the total amount each customer spent at the restaurant?
select s.customer_id,sum(price) Amount_spend
from sales s join menu m
on s.product_id=m.product_id
group by s.customer_id;
  
-- 2. How many days has each customer visited the restaurant?
select customer_id,count(distinct order_date) visited_days
from sales
group by customer_id; 

-- 3. What was the first item from the menu purchased by each customer?
select customer_id,product_name from(
	select customer_id,product_name,
	dense_rank() over(partition by customer_id order by order_date) as first_order from sales s 
    inner join menu m on s.product_id=m.product_id)x
where first_order=1 group by customer_id,product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
select m.product_name,count(s.product_id) as Max_Orders
from sales s
inner join menu m on s.product_id=m.product_id
group by product_name 
order by s.product_id desc
limit 1;

-- 5. Which item was the most popular for each customer?
with cte as (select customer_id,product_id,
count(product_id) as c_product from sales group by customer_id,product_id)

select customer_id,product_id,c_product from(
	select customer_id,product_id,c_product,
	rank() over(partition by customer_id order by c_product desc) as first_order from cte)a
where first_order=1

-- 6 .Which item was purchased first by the customer after they became a member?
select customer_id,order_date,product_name from(
	select s.customer_id,s.order_date,m.product_name,mm.join_date,
    row_number() over(partition by customer_id order by s.order_date) ranking from sales s
    inner join menu m on s.product_id=m.product_id
    inner join members mm on s.customer_id=mm.customer_id
    and s.order_date>=mm.join_date)x
    where ranking = 1

-- 7. Which item was purchased just before the customer became a member?	
select customer_id,order_date,product_name from(
	select s.customer_id,s.order_date,s.product_id,m.product_name,mm.join_date,
    dense_rank() over(partition by customer_id order by s.order_date desc) ranking from sales s
    inner join members mm on s.customer_id=mm.customer_id
    and s.order_date<mm.join_date
    inner join menu m on s.product_id=m.product_id)x
    where ranking = 1
-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id,count(m.price) Quantity,sum(m.price) Total_Amount from sales s
inner join menu m on s.product_id=m.product_id
inner join members mm on s.customer_id=mm.customer_id
and s.order_date<mm.join_date
group by s.customer_id
order by Total_Amount;
  
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?  
select customer_id,sum(points_Earned) as Total_points from 
(
select s.customer_id,m.product_name,m.price,case
when m.product_name='sushi' then price *10*2 else price *10
end as Points_Earned
	from sales s inner join menu m on s.product_id=m.product_id)x
group by customer_id;

-- 10.In the first week after a customer joins the program (including their join date) they earn 2x points 
-- on all items, not just sushi - how many points do customer A and B have at the end of January?
select customer_id,sum(Earned_points) as Earned_points from (
	select s.customer_id,s.order_date,m.product_name,mm.join_date,
	date_add(mm.join_date, interval 6 Day) as _7_days_after_joining,
	last_day(mm.join_date) as month_end,
	case
		when s.order_date > mm.join_date and m.product_name='sushi' then m.price*20
		when s.order_date > mm.join_date then m.price*10
		when s.order_date >= mm.join_date and s.order_date <= date_add(mm.join_date, interval 6 Day) then m.price *20
		when s.order_date > date_add(mm.join_date, interval 6 Day) and s.order_date <= last_day(mm.join_date) and m.product_name='sushi' then m.price * 20
		when s.order_date > date_add(mm.join_date, interval 6 Day) and s.order_date <= last_day(mm.join_date) and m.product_name in ('curry','Raman') then m.price * 10
		else 0
	end as Earned_points
	from sales s
	inner join menu m on s.product_id=m.product_id
	inner join members mm on s.customer_id=mm.customer_id)x
    group by customer_id; 


