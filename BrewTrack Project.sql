CREATE DATABASE brewtrack_sales_db;

USE brewtrack_sales_db;
             
SELECT 
    *
FROM
    coffee_shop_sales;
    
SET SQL_SAFE_UPDATES = 0;

-- ------------CONVERT DATE (transaction_date) COLUMN TO PROPER DATE FORMAT----------------
UPDATE coffee_shop_sales  
SET transaction_date = STR_TO_DATE(transaction_date, '%m/%d/%Y')  
WHERE transaction_date REGEXP '^[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}$';

-- -----------ALTER DATE (transaction_date) COLUMN TO DATE DATA TYPE--------------------------
ALTER TABLE coffee_shop_sales  
MODIFY COLUMN transaction_date DATE;

-- -----CONVERT TIME (transaction_time)  COLUMN TO PROPER DATE FORMAT---------
UPDATE coffee_shop_sales
SET transaction_time = STR_TO_DATE(transaction_time, '%H:%i:%s');

-- ----------ALTER TIME (transaction_time) COLUMN TO DATE DATA TYPE-------------
ALTER TABLE coffee_shop_sales
MODIFY COLUMN transaction_time TIME;


-- -------------DATA TYPES OF DIFFERENT COLUMNS------------------
DESCRIBE coffee_shop_sales;

-- ----------------CHANGE COLUMN NAME `ï»¿transaction_id` to transaction_id----------------
ALTER TABLE coffee_shop_sales
CHANGE COLUMN `ï»¿transaction_id` transaction_id INT;


-- ------------------- TOTAL SALES ----------------------------
SELECT 
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM
    coffee_shop_sales
WHERE
    MONTH(transaction_date) = 5; -- MAY Month
    
    
-- ---------------TOTAL SALES KPI - MOM DIFFERENCE AND MOM GROWTH --------------------------
SELECT 
    MONTH(transaction_date) AS Month,  -- Number of Months
    ROUND(SUM(unit_price * transaction_qty)) AS Total_sales, -- Total SALES Column
    (SUM(unit_price * transaction_qty)- LAG(SUM(unit_price * transaction_qty), 1) -- Difference of Month Sales
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(unit_price * transaction_qty), 1) -- Division by Previous Month Sales
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS MOM_increase_percentage -- Converting into percentage, MOM (Month On Month Sales)
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) IN (4, 5) -- for months of April (PM) and May (CM)
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date); -- This query calculates the total sales for April and May and determines the Month-on-Month (MoM) percentage increase in sales. 
    -- It first sums the total sales for each month and then compares May's sales with April's to measure the growth rate. 
    -- The result will show whether sales increased or decreased from May to June and by what percentage.


-- ----------------------------- TOTAL ORDERS --------------------------------
SELECT COUNT(transaction_id) as Total_Orders
FROM coffee_shop_sales 
WHERE MONTH (transaction_date)= 5; -- for month of (Current Month-May)


-- -------------TOTAL ORDERS KPI - MOM DIFFERENCE AND MOM GROWTH------------------
SELECT 
    MONTH(transaction_date) AS Month,
    ROUND(COUNT(transaction_id)) AS total_orders,
    (COUNT(transaction_id) - LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(COUNT(transaction_id), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS mom_increase_percentage
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) IN (4, 5) -- for April and May
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);
    
    
-- ------------TOTAL QUANTITY SOLD---------------
SELECT SUM(transaction_qty) as Total_Quantity_Sold
FROM coffee_shop_sales 
WHERE MONTH(transaction_date) = 5; -- for month of (Current Month-May)


-- -------------------TOTAL QUANTITY SOLD KPI - MOM DIFFERENCE AND MOM GROWTH------------------------
SELECT 
    MONTH(transaction_date) AS Month,
    ROUND(SUM(transaction_qty)) AS Total_Quantity_Sold,
    (SUM(transaction_qty) - LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date))) / LAG(SUM(transaction_qty), 1) 
    OVER (ORDER BY MONTH(transaction_date)) * 100 AS MOM_Increase_Percentage
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) IN (4, 5)   -- for April and May
GROUP BY 
    MONTH(transaction_date)
ORDER BY 
    MONTH(transaction_date);

-- ------------CALENDAR TABLE – DAILY SALES, QUANTITY and TOTAL ORDERS-----------------
SELECT 
    CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000, 1),'K') AS Total_Sales,
    CONCAT(ROUND(COUNT(transaction_id) / 1000, 1),'K') AS Total_Orders,
    CONCAT(ROUND(SUM(transaction_qty) / 1000, 1),'K') AS Total_Quantity_Sold
FROM 
    coffee_shop_sales
WHERE 
    transaction_date = '2023-05-18'; -- For 18 May 2023
    
-- ------------------- SALES BY WEEKDAYS AND WEEKENDS ---------------
SELECT  
    CASE 
        WHEN DAYOFWEEK(transaction_date) IN (1,7) THEN 'Weekends'  
        ELSE 'Weekdays'  
    END AS Day_Type,  
    CONCAT(ROUND(SUM(unit_price * transaction_qty) / 1000, 1),'K') AS Total_Sales  
FROM coffee_shop_sales  
WHERE MONTH(transaction_date) = 5   -- Filter for May
GROUP BY Day_Type;

-- --------- SALES BY STORE LOCATION ------------------------
SELECT
store_location,
CONCAT(ROUND(SUM(unit_price * transaction_qty)/1000,1),'K') AS Total_Sales  
FROM coffee_shop_sales
WHERE MONTH(transaction_date) = 5   -- Filter for May
GROUP BY store_location
ORDER BY Total_Sales DESC;

-- ------------- SALES TREND OVER PERIOD --------------------
SELECT CONCAT(ROUND(AVG(total_sales) / 1000,1),'K') AS Average_Sales
FROM (
    SELECT 
        SUM(unit_price * transaction_qty) AS Total_Sales
    FROM 
        coffee_shop_sales
	WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        transaction_date
) AS internal_query;

-- ---------- DAILY SALES FOR MONTH SELECTED ----------------
SELECT 
    DAY(transaction_date) AS Day_of_Month,
    ROUND(SUM(unit_price * transaction_qty),1) AS Total_Sales
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) = 5  -- Filter for May
GROUP BY 
   Day_of_Month
ORDER BY 
    Day_of_Month;

# COMPARING DAILY SALES WITH AVERAGE SALES – IF GREATER THAN “ABOVE AVERAGE” and LESSER THAN “BELOW AVERAGE”
SELECT 
    Day_of_month,
    CASE 
        WHEN Total_sales > avg_sales THEN 'Above Average'
        WHEN Total_sales < avg_sales THEN 'Below Average'
        ELSE 'Average'
    END AS Sales_Status,
    Total_sales
FROM (
    SELECT 
        DAY(transaction_date) AS Day_of_month,
        CONCAT(ROUND(SUM(unit_price * transaction_qty)/100,1),'K') AS Total_sales,
        AVG(SUM(unit_price * transaction_qty)) OVER () AS Avg_sales
    FROM 
        coffee_shop_sales
    WHERE 
        MONTH(transaction_date) = 5  -- Filter for May
    GROUP BY 
        Day_of_month
) AS Sales_Data
ORDER BY 
    Day_of_month;

-- ------------- SALES BY PRODUCT CATEGORY --------------------
SELECT 
	Product_Category,
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_shop_sales
WHERE
	MONTH(transaction_date) = 5 -- Filter For MAY Month
GROUP BY Product_Category
ORDER BY  Product_Category DESC;

-- ----------- SALES BY PRODUCTS (TOP 10) -----------------
SELECT 
	Product_Type,
	ROUND(SUM(unit_price * transaction_qty),1) as Total_Sales
FROM coffee_shop_sales
WHERE
	MONTH(transaction_date) = 5 AND(product_category) = 'Coffee'
GROUP BY Product_Type
ORDER BY Total_Sales DESC
LIMIT 10;

-- ---------------- SALES BY DAY | HOUR --------------------
SELECT 
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales,
    SUM(transaction_qty) AS Total_Quantity,
    COUNT(*) AS Total_Orders
FROM 
    coffee_shop_sales
WHERE 
    DAYOFWEEK(transaction_date) = 3 -- Filter for Tuesday (1 is Sunday, 2 is Monday, ..., 7 is Saturday)
    AND HOUR(transaction_time) = 8 -- Filter for hour number 8
    AND MONTH(transaction_date) = 5; -- Filter for May (month number 5)


-- -------- TO GET SALES FROM MONDAY TO SUNDAY FOR MONTH OF MAY -----------
SELECT 
    CASE 
        WHEN DAYOFWEEK(transaction_date) = 2 THEN 'Monday'
        WHEN DAYOFWEEK(transaction_date) = 3 THEN 'Tuesday'
        WHEN DAYOFWEEK(transaction_date) = 4 THEN 'Wednesday'
        WHEN DAYOFWEEK(transaction_date) = 5 THEN 'Thursday'
        WHEN DAYOFWEEK(transaction_date) = 6 THEN 'Friday'
        WHEN DAYOFWEEK(transaction_date) = 7 THEN 'Saturday'
        ELSE 'Sunday'
    END AS Day_of_Week,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
    Day_of_Week;
    

 -- ---------- TO GET SALES FOR ALL HOURS FOR MONTH OF MAY ------------------
SELECT 
    HOUR(transaction_time) AS Hour_of_Day,
    ROUND(SUM(unit_price * transaction_qty)) AS Total_Sales
FROM 
    coffee_shop_sales
WHERE 
    MONTH(transaction_date) = 5 -- Filter for May (month number 5)
GROUP BY 
   Hour_of_Day
ORDER BY 
    Hour_of_Day;

 

