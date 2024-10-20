--CREATE TABLE sales 
--(
--  customer_id VARCHAR(1),
--  order_date DATE,
--  product_id INTEGER
--);

--INSERT INTO sales
--VALUES
--  ('A', '2021-01-01', '1'),
--  ('A', '2021-01-01', '2'),
--  ('A', '2021-01-07', '2'),
--  ('A', '2021-01-10', '3'),
--  ('A', '2021-01-11', '3'),
--  ('A', '2021-01-11', '3'),
--  ('B', '2021-01-01', '2'),
--  ('B', '2021-01-02', '2'),
--  ('B', '2021-01-04', '1'),
--  ('B', '2021-01-11', '1'),
--  ('B', '2021-01-16', '3'),
--  ('B', '2021-02-01', '3'),
--  ('C', '2021-01-01', '3'),
--  ('C', '2021-01-01', '3'),
--  ('C', '2021-01-07', '3');

--  CREATE TABLE menu (
--  product_id INTEGER,
--  product_name VARCHAR(5),
--  price INTEGER
--);

--INSERT INTO menu
--VALUES
--  ('1', 'sushi', '10'),
--  ('2', 'curry', '15'),
--  ('3', 'ramen', '12');
  

--CREATE TABLE members (
--  customer_id VARCHAR(1),
--  join_date DATE
--);

--INSERT INTO members
--VALUES
--  ('A', '2021-01-07'),
--  ('B', '2021-01-09');


--ANSWERS
--Complete Table
 SELECT *
  FROM sales s
  LEFT JOIN menu m
  ON s.product_id = m.product_id
  LEFT JOIN members ms
  ON s.customer_id = ms.customer_id

  --Question 1 - What is the total amount each customer spent at the restaurant?
  SELECT s.customer_id,sum (m.price) as Total_Price
  FROM sales s
  LEFT JOIN menu m
  ON s.product_id = m.product_id
  LEFT JOIN members ms
  ON s.customer_id = ms.customer_id
  GROUP BY s.customer_id
  ORDER BY 2 DESC
 
 --Question 2 - How many days has each customer visited the restaurant?
  SELECT s.customer_id, Count ( Distinct s.order_date) as Resturant_Visits
  FROM sales s
  GROUP BY s.customer_id
  ORDER BY 2 DESC

  --Question 3 - What was the first item from the menu purchased by each customer?
  WITH First_Products as
  (
  SELECT s.customer_id, m.product_name, ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.customer_id) as product_row
  FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
  )
  SELECT *
  FROM First_Products
  WHERE product_row = 1 

  --Question 4 - What is the most purchased item on the menu and how many times was it purchased by all customers?
  SELECT m.product_name, COUNT(S.customer_id) as Quantity
  FROM menu m
  JOIN sales s
  ON m.product_id = s.product_id
  GROUP BY m.product_name
  ORDER BY Quantity DESC

  --Question 5 - Which item was the most popular for each customer?
 WITH Popular_Product as
 (
 SELECT s.customer_id as customer_id, m.product_name as product_name, COUNT(m.product_id) as Order_Count, DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(m.product_id) DESC) as Product_rank
  FROM sales s
  JOIN menu m
  ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
 )
 SELECT customer_id, product_name, Order_Count
 FROM Popular_Product
 WHERE Product_rank = 1

 --Question 6 - Which item was purchased first by the customer after they became a member?
 WITH First_Purchase as
 (SELECT s.customer_id as customer_id, m.product_name as product_name, ms.join_date as join_date, ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.customer_id) as rank
 FROM sales s
 LEFT JOIN menu m
 ON s.product_id = m.product_id
 LEFT JOIN members ms
 ON s.customer_id = ms.customer_id
 )
  SELECT customer_id, product_name
  FROM First_Purchase
  WHERE rank = 1

  --Question 7 - Which item was purchased just before the customer became a member?
WITH Order_before_Mem as
(
SELECT s.customer_id as customer_id, m.product_name as Product_name, s.order_date as Order_date, ms.join_date as Join_date, DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) as rank
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members ms
ON s.customer_id = ms.customer_id
WHERE Order_date < Join_date
)
SELECT customer_id, Product_name, Order_date
FROM Order_before_Mem
WHERE rank = 1

--Question 8 - What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT( m.product_id)as Total_items, SUM(m.price) as Total_Amount
FROM sales s
LEFT JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members ms
ON s.customer_id = ms.customer_id
WHERE Order_date < Join_date
GROUP BY s.customer_id

--Question 9 - If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH Customer_Points as
(
SELECT s.customer_id as Customer_Id, m.product_name as Product_Name,
(CASE
WHEN m.product_name = 'sushi' THEN m.price * 2 * 10
ELSE m.price * 10
END) as Points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
) 
SELECT Customer_Id, SUM(Points) as Total_Points
FROM Customer_Points
GROUP BY Customer_Id

--Question 10 - In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH member_pts AS (
	SELECT s.customer_id, 
	       s.order_date, m.join_date, 
		   price,
		   (CASE 
			WHEN order_date BETWEEN m.join_date AND DATEADD(DAY, 6, m.join_date) AND (DATEPART(MONTH, order_date))=1 THEN price*10*2
			ELSE price * 10
		   END) as price_point,
		   s.product_id, product_name
	FROM sales s
	JOIN menu men
	ON s.product_id = men.product_id
	JOIN members m
	ON s.customer_id = m.customer_id
  )
SELECT customer_id, SUM(price_point) as total_pts
FROM member_pts
WHERE DATEPART(MONTH, order_date) = 1
GROUP BY customer_id;