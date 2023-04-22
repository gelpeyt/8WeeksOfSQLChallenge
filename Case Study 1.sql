-- Case Study 1: Danny's Diner
-- Link to the Case Study: https://8weeksqlchallenge.com/case-study-1/

-- Creation of Database and Tables, and Populating the Tables
CREATE DATABASE dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- To view the contents of the tables.
SELECT *
FROM sales;

SELECT *
FROM menu;

SELECT *
FROM members;

-- CASE STUDY QUESTIONS

-- 1. What is the total amount each customer spent at the restaurant?

SELECT s.customer_id, SUM(m.price) as total_sales
FROM sales s INNER JOIN menu m
	ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- Customer A spent $76. Customer B spent $74. and Customer C spent the least with $36.

-- 2. How many days has each customer visited the restaurant?

SELECT s.customer_id, COUNT(DISTINCT s.order_date)
FROM sales s
GROUP BY s.customer_id;

--Customer A visited for 4 days. Customer B has visited for 6 days. Customer C has visited for 2 days.

-- 3. What was the first item from the menu purchased by each customer?

SELECT rn.customer_id, rn.product_name
FROM (
	SELECT s.*, m.product_name, DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as row_num
	FROM sales s JOIN menu m
		ON s.product_id = m.product_id
	) rn
WHERE rn.row_num = 1;

-- Customer A's first order is sushi and curry. Customer B's first order is curry, and Customer C's first order is ramen.

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 (COUNT(s.product_id)) as most_purchased_item, m.product_name
FROM sales s JOIN menu m
	ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY most_purchased_item desc;

-- The most purchased item on the menu is ramen, which is purchased 8 times in total.

-- 5. Which item was the most popular for each customer?

WITH most_popular_order as (
	SELECT s.customer_id, m.product_name, COUNT(s.product_id) as order_count,
		DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id) DESC) as order_ranking
	FROM sales s JOIN menu m
		ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
	)

SELECT customer_id, product_name, order_count
FROM most_popular_order pop
WHERE order_ranking = 1;

/* Customer A and C's most popular order is ramen. Customer B's enjoys all items. */
	
-- 6. Which item was purchased first by the customer after they became a member?

WITH member_sales AS (
	SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
		DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) as rank
	FROM sales s JOIN members m
		ON s.customer_id = m.customer_id
	WHERE s.order_date >= m.join_date
	)

SELECT ms.customer_id, m.product_name
FROM member_sales ms JOIN menu m
	ON ms.product_id = m.product_id
WHERE rank = 1;

-- Customer A's first order after being a member is curry while Customer B's is sushi.

-- 7. Which item was purchased just before the customer became a member?

WITH member_sales AS (
	SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
		DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date desc) as rank
	FROM sales s JOIN members m
		ON s.customer_id = m.customer_id
	WHERE s.order_date < m.join_date
	)

SELECT ms.customer_id, m.product_name
FROM member_sales ms JOIN menu m
	ON ms.product_id = m.product_id
WHERE rank = 1;

-- Before becoming a member, Customer A's last order was sushi and curry, while Customer B's is sushi.

-- 8. What is the total items and amount spent for each member before they became a member? 

SELECT s.customer_id, COUNT(DISTINCT s.product_id) as unique_total_items, SUM(m2.price) AS total_sales
FROM sales s JOIN members m
	ON s.customer_id = m.customer_id JOIN menu m2
	ON s.product_id = m2.product_id
WHERE s.order_date < m.join_date
GROUP BY s.customer_id;

-- Before becoming a member, Customer A and B spent $25 and $40 accordingly on 2 items.

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many 
-- points would each customer have?

WITH price_points AS (
	SELECT *,
	CASE
		WHEN product_id = '1' THEN price * 20
		ELSE price * 10
		END AS points
	FROM menu
	)

SELECT s.customer_id, SUM(p.points) as total_points
FROM price_points p JOIN sales s
	ON p.product_id = s.product_id
GROUP BY s.customer_id

-- Customer A would have 860 points. Customer B would have 940 points. Customer C would have 360 points.

/* 10. In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - how many points do customer A and 
B have at the end of January? */


WITH get_week AS (
	SELECT *, DATEADD (DAY, 6, mm.join_date) AS last_date
	FROM members mm
	)

SELECT s.customer_id,
SUM(CASE
	WHEN s.product_id = 1 THEN m.price * 20
	WHEN s.order_date BETWEEN g.join_date AND g.last_date THEN m.price * 20
	ELSE m.price * 10
	END
) AS points
FROM sales s JOIN get_week g
		ON s.customer_id = g.customer_id
	JOIN menu m
		ON s.product_id = m.product_id
WHERE s.order_date < '2021-02-01'
GROUP BY s.customer_id;

-- At the end of January, Customer A had 1370 points while Customer B has 820 points.

-- BONUS QUESTIONS

-- Join All The Things

SELECT sl.customer_id, sl.order_date, mn.product_name, mn.price,
	(CASE
		WHEN sl.customer_id NOT IN (SELECT customer_id FROM members) THEN 'N'
		WHEN sl.order_date < mm.join_date THEN 'N'
		ELSE 'Y'
		END
	) as member
FROM sales sl LEFT JOIN menu mn
	ON sl.product_id = mn.product_id LEFT JOIN members mm
		ON sl.customer_id = mm.customer_id;


-- Rank All The Things
WITH membership AS (
	SELECT sl.customer_id, sl.order_date, mn.product_name, mn.price,
		(CASE
			WHEN sl.customer_id NOT IN (SELECT customer_id FROM members) THEN 'N'
			WHEN sl.order_date < mm.join_date THEN 'N'
			ELSE 'Y'
			END
		) AS member		
	FROM sales sl LEFT JOIN menu mn
		ON sl.product_id = mn.product_id LEFT JOIN members mm
			ON sl.customer_id = mm.customer_id
	)

SELECT *, 
	(CASE
		WHEN mbshp.member = 'N' THEN NULL
		ELSE DENSE_RANK() OVER (PARTITION BY mbshp.customer_id, mbshp.member ORDER BY mbshp.order_date)
		END
	) AS ranking
FROM membership mbshp
ORDER BY mbshp.customer_id, mbshp.order_date, mbshp.price desc;
