--SQL Advance Case Study


--1. List all the states in which we have customers who have bought cellphones 
--from 2005 till today.
--Q1--BEGIN 
	

	SELECT State
	FROM DIM_LOCATION AS A
	INNER JOIN FACT_TRANSACTIONS AS B
	ON A.IDLocation = B.IDLocation
	WHERE Date BETWEEN '2005-01-01' AND GETDATE ()



--Q1--END

--2. What state in the US is buying the most 'Samsung' cell phones?
--Q2--BEGIN
	
	SELECT TOP 1 STATE
	FROM DIM_LOCATION AS A
		INNER JOIN FACT_TRANSACTIONS AS B
		ON A.IDLocation = B.IDLocation
		INNER JOIN DIM_MODEL AS C
		ON B.IDModel = C.IDModel
		INNER JOIN DIM_MANUFACTURER AS D
		ON C.IDManufacturer = D.IDManufacturer
	WHERE COUNTRY = 'US' AND Manufacturer_Name = 'SAMSUNG'
	GROUP BY STATE
	ORDER BY SUM(QUANTITY) DESC




--Q2--END

--3. Show the number of transactions for each model per zip code per state. 

--Q3--BEGIN      

	SELECT MODEL_NAME, STATE, ZIPCODE, COUNT (IDCUSTOMER) AS NO_OF_TRANS
	FROM DIM_MODEL AS A INNER JOIN
			FACT_TRANSACTIONS AS B
			ON A.IDModel = B.IDModel INNER JOIN
			DIM_LOCATION AS C
			ON B.IDLocation = C.IDLocation
	GROUP BY Model_Name, STATE, ZIPCODE

	
--Q3--END

--4. Show the cheapest cellphone (Output should contain the price also)

--Q4--BEGIN

	SELECT TOP 1 Manufacturer_Name, Model_Name, Unit_price
	FROM DIM_MODEL AS A
		INNER JOIN DIM_MANUFACTURER AS B
		ON A.IDManufacturer = B.IDManufacturer
	ORDER BY Unit_price

	
--Q4--END

--5. Find out the average price for each model in the top5 manufacturers in 
--terms of sales quantity and order by average price. 

--Q5--BEGIN
	

	SELECT MODEL_NAME, AVG (UNIT_PRICE) AS AVG_PRICE
	FROM DIM_MODEL AS X
	INNER JOIN DIM_MANUFACTURER AS Y
	ON X.IDManufacturer = Y.IDManufacturer
	WHERE MANUFACTURER_NAME IN (
						SELECT TOP 5 MANUFACTURER_NAME
						FROM DIM_MANUFACTURER AS A
							INNER JOIN DIM_MODEL AS B
							ON A.IDManufacturer = B.IDManufacturer
							INNER JOIN FACT_TRANSACTIONS AS C
							ON B.IDModel = C.IDModel
						GROUP BY Manufacturer_Name
						ORDER BY SUM (QUANTITY) DESC)
	GROUP BY MODEL_NAME
	ORDER BY AVG (UNIT_PRICE)



--Q5--END

--6. List the names of the customers and the average amount spent in 2009, 
--where the average is higher than 500 

--Q6--BEGIN

	

	SELECT CUSTOMER_NAME, AVG (TOTALPRICE) AS AVG_AMT_SPENT
	FROM DIM_CUSTOMER AS A
		INNER JOIN FACT_TRANSACTIONS AS B
		ON A.IDCustomer = B.IDCustomer
	WHERE DATEPART (YEAR, DATE) = 2009
	GROUP BY Customer_Name
	HAVING AVG (TOTALPRICE) > 500 


--Q6--END
	
--7. List if there is any model that was in the top 5 in terms of quantity, 
--simultaneously in 2008, 2009 and 2010

--Q7--BEGIN  


	SELECT TOP 5 MODEL_NAME
		FROM (SELECT MODEL_NAME, SUM (QUANTITY) AS QUANT
					FROM DIM_MODEL AS A
					INNER JOIN FACT_TRANSACTIONS AS B
					ON A.IDModel = B.IDModel
					WHERE DATEPART (YEAR, DATE) = 2008
					GROUP BY MODEL_NAME
			INTERSECT
					SELECT MODEL_NAME, SUM (QUANTITY) AS QUANT
					FROM DIM_MODEL AS A
					INNER JOIN FACT_TRANSACTIONS AS B
					ON A.IDModel = B.IDModel
					WHERE DATEPART (YEAR, DATE) = 2009
					GROUP BY MODEL_NAME
			INTERSECT
					SELECT MODEL_NAME, SUM (QUANTITY) AS QUANT
					FROM DIM_MODEL AS A
					INNER JOIN FACT_TRANSACTIONS AS B
					ON A.IDModel = B.IDModel
					WHERE DATEPART (YEAR, DATE) = 2009
					GROUP BY MODEL_NAME) AS X
		ORDER BY QUANT DESC






	
--Q7--END	

--8. Show the manufacturer with the 2nd top sales in the year of 2009 and the 
--manufacturer with the 2nd top sales in the year of 2010.

--Q8--BEGIN


	SELECT MANUFACTURER_NAME
	FROM (
			SELECT MANUFACTURER_NAME, DENSE_RANK () OVER (ORDER BY SUM (QUANTITY) DESC) AS RANKS
			FROM DIM_MANUFACTURER AS C
					INNER JOIN DIM_MODEL AS D
					ON C.IDManufacturer = D.IDManufacturer
					INNER JOIN FACT_TRANSACTIONS AS E
					ON D.IDModel = E.IDModel
			WHERE  DATEPART (YEAR, DATE) = 2009
			GROUP BY Manufacturer_Name) AS X
	WHERE RANKS = 2
	UNION ALL
	SELECT MANUFACTURER_NAME
	FROM (
			SELECT MANUFACTURER_NAME, DENSE_RANK () OVER (ORDER BY SUM (QUANTITY) DESC) AS RANKS
			FROM DIM_MANUFACTURER AS C
					INNER JOIN DIM_MODEL AS D
					ON C.IDManufacturer = D.IDManufacturer
					INNER JOIN FACT_TRANSACTIONS AS E
					ON D.IDModel = E.IDModel
			WHERE  DATEPART (YEAR, DATE) = 2010
			GROUP BY Manufacturer_Name) AS X
	WHERE RANKS = 2




--Q8--END

--9. Show the manufacturers that sold cellphones in 2010 but did not in 2009

--Q9--BEGIN

	SELECT MANUFACTURER_NAME 
	FROM DIM_MANUFACTURER
	WHERE MANUFACTURER_NAME NOT IN (
							SELECT MANUFACTURER_NAME
							FROM DIM_MANUFACTURER AS A
							INNER JOIN DIM_MODEL AS B
							ON A.IDManufacturer = B.IDManufacturer
							INNER JOIN FACT_TRANSACTIONS AS C
							ON B.IDModel = C.IDModel
							WHERE DATEPART (YEAR, DATE) = 2009)
	
	AND Manufacturer_Name IN (SELECT MANUFACTURER_NAME
							FROM DIM_MANUFACTURER AS A
							INNER JOIN DIM_MODEL AS B
							ON A.IDManufacturer = B.IDManufacturer
							INNER JOIN FACT_TRANSACTIONS AS C
							ON B.IDModel = C.IDModel
							WHERE DATEPART (YEAR, DATE) = 2010)




--Q9--END

--Find top 100 customers and their average spend, average quantity by each 
--year. Also find the percentage of change in their spend.

--Q10--BEGIN
	

	SELECT TOP 10 CUSTOMER_NAME, AVG (TOTALPRICE) AS AVG_PRICE, AVG (QUANTITY) AS AVG_QUANT, 
	DATEPART (YEAR, DATE) AS YEARS,
	LAG (AVG (TOTALPRICE)) OVER (PARTITION BY DATEPART (YEAR, DATE) ORDER BY AVG (TOTALPRICE)) AS PREV_SPEND,
	(AVG (TOTALPRICE) - LAG (AVG (TOTALPRICE)) OVER (PARTITION BY DATEPART (YEAR, DATE) ORDER BY AVG (TOTALPRICE)))/
	LAG (AVG (TOTALPRICE)) OVER (PARTITION BY DATEPART (YEAR, DATE) ORDER BY AVG (TOTALPRICE)) *100 AS PERCENT_CHANGE

	FROM DIM_CUSTOMER AS A
	INNER JOIN FACT_TRANSACTIONS AS B
	ON A.IDCustomer = B.IDCustomer
	GROUP BY Customer_Name, DATEPART (YEAR, DATE)
	ORDER BY AVG (TOTALPRICE) DESC, AVG (QUANTITY) DESC



--Q10--END
	