create database elevate_labs;

use elevate_labs;

create table products(
product_id varchar(20) primary key,
product_name varchar(100),
category varchar(20),
price decimal(10,2)
);


create table customers(
customer_id varchar(20) primary key,
customer_name varchar(30),
segment varchar(30),
city varchar(20)
);


create table orders(
order_id varchar(20) primary key,
order_date date,
customer_id varchar(20),
product_id varchar(20),
foreign key(customer_id) references customers(customer_id),
foreign key(product_id) references products(product_id),
quantity int
);


create table sales(
order_id varchar(20) primary key,
sales_amount decimal(10,2),
foreign key(order_id) references orders(order_id)
);


-- 1. Find the total sales amount for the entire dataset.

select sum(sales_amount) as total_sales
from sales;


-- 2. Which product category generated the highest revenue?

select p.category,sum(sales_amount) as revenue
from products p
join orders o on p.product_id = o.product_id
join sales s on o.order_id = s.order_id
group by p.category
order by sum(sales_amount) desc
limit 1;


-- 3. What is the average order value (AOV)?

select avg(sales_amount)
from sales;


-- 4. Find the top 5 customers by total purchase amount.

select c.customer_name, sum(sales_amount) as total_purchese
from customers c
join orders o on c.customer_id = o.customer_id 
join sales s on o.order_id = s.order_id
group by c.customer_name
order by sum(sales_amount) desc
limit 5;


-- 5. How many orders does each customer make?

select c.customer_name , count(o.order_id) as Orders_placed
from customers c
join orders o on c.customer_id = o.customer_id
group by c.customer_id;


-- Which city generated the maximum revenue?

select c.city, sum(s.sales_amount) as revenue
from customers c
join orders o on c.customer_id = o.customer_id 
join sales s on o.order_id = s.order_id
group by c.city;


-- 7. Find the total quantity sold per product.

select p.product_name, sum(o.quantity) as total_quantity_sold
from products p
join orders o on p.product_id = o.product_id
group by p.product_name;


-- 8. Which segment (Consumer / Corporate / Home Office) buys the most?

select c.segment, sum(s.sales_amount) total_sales
from customers c
join orders o on c.customer_id = o.customer_id
join sales s on o.order_id = s.order_id
group by c.segment 
order by sum(s.sales_amount) desc limit 1;


-- 9. What is the monthly sales trend?

select date_format(o.order_date,'%M') as order_month, sum(s.sales_amount) as total_sales
from orders o
join sales s on o.order_id = s.order_id
group by date_format(o.order_date,'%M'),month(o.order_date)
order by month(o.order_date);


-- 10. What is the most profitable product (highest revenue per product)?

select p.product_name, sum(s.sales_amount) as total_sales
from products p 
join orders o on p.product_id = o.product_id
join sales s on s.order_id = s.order_id
where p.price < (select avg(price) from products)
and o.quantity > (select avg(quantity) from orders)
group by p.product_name
order by sum(s.sales_amount) desc
limit 1;


-- 11. Find orders whose sales amount is higher than the maximum sales amount of the ‘Consumer’ segment.

select o.order_id, sum(s.sales_amount) as total_sales
from orders o 
join sales s on o.order_id = s.order_id
group by o.order_id
having sum(s.sales_amount) > (
		select max(s2.sales_amount) as maximums_sales
		from sales s2
		join orders o2 on o2.order_id = s2.order_id
		join customers c2 on o2.customer_id = c2.customer_id
		where c2.segment = 'Consumer'
);


-- 12. Find the second-highest priced product in each category.

select p1.category, p1.product_name, p1.price
from products p1
where p1.price = (
    select MAX(p2.price)
    from products p2
    where p2.category = p1.category
	and p2.price < (
          select MAX(price)
          from products
          where category = p1.category
      )
);


-- 13. Show products with total sales greater than 10,000

create or replace view top_products as
select p.product_id, p.product_name, sum(s.sales_amount) as total_sales
from products p
join orders o on p.product_id = o.product_id
join sales s on o.order_id = s.order_id
group by p.product_id, p.product_name
having total_sales > 10000
order by total_sales desc;

select * from top_products;


-- 14. Rank customers by total sales within each segment

select customer_id, customer_name, segment,
       sum(s.sales_amount) as total_sales,
       rank() over(partition by segment order by sum(s.sales_amount) desc) as rank_in_segment
from customers c
join orders o on c.customer_id = o.customer_id
join sales s on o.order_id = s.order_id
group by customer_id, customer_name, segment;


-- 15. show average sales per customer compared to their segment average

select customer_id, customer_name, segment, total_sales,
       avg(total_sales) over(partition by segment) as segment_avg
from (
    select c.customer_id, c.customer_name, c.segment, sum(s.sales_amount) as total_sales
    from customers c
    join orders o on c.customer_id = o.customer_id
    join sales s on o.order_id = s.order_id
    group by c.customer_id, c.customer_name, c.segment
) as sub;


