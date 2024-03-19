-- Create database
CREATE DATABASE IF NOT EXISTS walmartSales;

CREATE TABLE IF NOT EXISTS Sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
	gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_pct FLOAT(6,4) NOT NULL,
    total DECIMAL(12,4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_pct FLOAT(11,9),
    gross_income DECIMAL(12,4),
    rating FLOAT(2,1)
);

SELECT * FROM walmartsales.sales;

-- ----------- EXPLORATORY DATA ANALYSIS ---------
-- ----------Feature Engineering -----------------
-- 1) time_of_day : Cette colonne nous permettra de fournir les indicateurs de ventes à différents moments de la journée.
-- Cela aidera à répondre à la question à quel moment de la journée les ventes sont le plus effectuées.

SELECT 
	time,
    (CASE
		WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN "Morning"
        WHEN time BETWEEN '00:00:00' AND '16:00:00' THEN "Afternoon"
        ELSE "Evening"
	END
    ) AS time_of_day
FROM sales;

-- Ajoutons la colonne "time_of_day" dans la table "sales" (modification):
ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);

-- Remplissons la colonne nouvellement crééé
UPDATE sales
SET time_of_day = (
	CASE
		WHEN time BETWEEN '00:00:00' AND '12:00:00' THEN "Morning"
        WHEN time BETWEEN '00:00:00' AND '16:00:00' THEN "Afternoon"
        ELSE "Evening"
	END
);

-- 2) day_name : Cette colonne aidera à répondre à la question à quels jours de la semaine chaque filiale
-- est la plus sollicitée.
-- Les libellés des jours seront extraits de la colonne "days" et feront aussi l'objet de création d'une autre colonne.

SELECT date,
DAYNAME(date) AS day_name
FROM sales;

ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales
SET day_name = DAYNAME(date);

-- 3) month_name : Cette colonne aidera à déterminer quel mois de l'année l'entreprise enregistre le plus de ventes et de profit
-- Cette donnée sera extraite de la colonne "date".

SELECT date,
MONTHNAME(date)
FROM sales;

ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

UPDATE sales
SET month_name = MONTHNAME(date);

-- -------- BUSINESS ANALYSIS ---------------------------
-- GENERICS QUESTIONS

-- Quelles villes (uniques) y a t-il dans la base de données?
SELECT
	DISTINCT city
FROM sales;

-- Quelles filiales (uniques) y a t-il dans la base de données?
SELECT
	DISTINCT branch
FROM sales;

-- Dans quelle ville est implantée chaque filiale?
SELECT
	DISTINCT city,
    branch
FROM sales;

-- PRODUCT ANALYSIS
-- How many unique product lines does the data have ?
-- Combien de gammes de produits uniques les données contiennent-elles ?
SELECT
	COUNT(DISTINCT product_line)
FROM sales;

-- What is the most common payment method?
-- Quel est le mode de paiement le plus courant ?
SELECT
	payment,
	COUNT(payment) AS nb_payment
FROM sales
GROUP BY payment
ORDER BY nb_payment DESC;

-- What is the most selling product line?
-- Quelle est la gamme de produits la plus vendue ?
SELECT
	product_line,
	COUNT(product_line) AS most_selled
FROM sales
GROUP BY product_line
ORDER BY most_selled DESC; 

-- What is the most revenue by month?
-- Quel est le revenu le plus élevé par mois ?
SELECT
	month_name as MONTH,
    SUM(total) AS total_revenue
FROM sales
GROUP BY MONTH
ORDER BY total_revenue DESC;

-- What month had the largest cogs ?
-- Quel mois a le COGS le plus important ?
SELECT
	month_name as MONTH,
    SUM(cogs) AS total_cogs
FROM sales
GROUP BY MONTH
ORDER BY total_cogs DESC;

-- What product line had the largest revenue?
-- Quelle gamme de produits a généré les revenus les plus importants ?

SELECT
	product_line,
    SUM(total) AS cumul_revenue
FROM sales
GROUP BY product_line
ORDER BY cumul_revenue DESC;

-- What is the city with the largest revenue?
-- Quelle est la ville (par conséquent la filiale) avec les revenus les plus importants ?
SELECT
	branch,
	city,
    SUM(total) AS cumul_revenue
FROM sales
GROUP BY city, branch
ORDER BY cumul_revenue DESC;

-- What product line had the largest tax?
-- Quelle gamme de produits était soumise à la taxe la plus élevée ?
SELECT 
	product_line,
    AVG(tax_pct) AS TAX
FROM sales
GROUP BY product_line
ORDER BY TAX DESC;

-- Fetch each product line and add column to those product line showing "good", "bad". Goo if its greater than average sales?
-- Récupérez chaque ligne de produits et ajoutez une colonne à ces lignes de produits indiquant « bon », « mauvais ». Bon, si les ventes sont supérieures à la moyenne ?
SELECT
	product_line,
	CASE
		WHEN AVG(quantity) > 6 THEN "Good"
        ELSE "Bad"
    END AS appreciation
FROM sales
GROUP BY product_line;

-- Which branch sold more products than average product sold ?
-- Quelle branche a vendu plus de produits que la moyenne des produits vendus ?
SELECT 
	branch,
    SUM(quantity) as sum_qty
FROM sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT AVG(quantity) FROM sales);

-- What is the most common product line by gender ?
-- Quelle est la gamme de produits la plus courante par sexe ?
SELECT
	gender,
    product_line,
    COUNT(gender) AS total_cust
FROM sales
GROUP BY gender, product_line
ORDER BY total_cust DESC;

-- What is the average rating of each product line ?
-- Quelle est la note moyenne de chaque gamme de produits ?
SELECT 
	product_line,
    ROUND(AVG(rating),2) AS avg_rating
FROM sales
GROUP BY product_line
ORDER BY avg_rating DESC;

-- SALES ANALYSIS
-- Number of sales made in each time of the day per weekday ?
-- Nombre de ventes réalisées à chaque heure de la journée par jour de la semaine ?
SELECT 
	time_of_day,
    COUNT(*) AS total_sales
FROM sales
GROUP BY time_of_day
ORDER BY total_sales DESC;

-- Number of sales made in each time at Saturday ?
-- Nombre de ventes réalisées à chaque heure de la journée le Samedi ?
SELECT 
	time_of_day,
    COUNT(*) AS total_sales
FROM sales
WHERE day_name = "Monday"
GROUP BY time_of_day
ORDER BY total_sales DESC;

-- Which of the customer types brings the most revenue ?
-- Lequel des types de clients génère le plus de revenus ?
SELECT
	customer_type,
    SUM(total) AS total_revenue
FROM sales
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- Which city has the largest tax percent /tax_pct ?
-- Quelle ville a le pourcentage d'impôt le plus élevé /tax_pct ?
SELECT
	city,
    AVG(tax_pct) AS tax
FROM sales
GROUP BY city
ORDER BY tax DESC;

-- Which customer type pay the most in tax_pct?
-- Quel type de client paie le plus en tax_pct ?
SELECT
	customer_type,
    ROUND(SUM(tax_pct),2) AS total_tax
FROM sales
GROUP BY customer_type
ORDER BY total_tax DESC;


-- CUSTOMER ANALYSIS
-- How many unique customer types does the data have?
-- Combien de types de clients uniques les données contiennent-elles ?
SELECT
	COUNT(DISTINCT(customer_type)) AS Nbr_customer
FROM sales;

-- How many unique payment methods does the data have?
-- Combien de méthodes de paiement uniques les données contiennent-elles ?
SELECT
	COUNT(DISTINCT(payment)) AS Nbr_method_pay
FROM sales;

-- What is the most common customer type?
-- Quel est le type de client le plus courant ?

-- Which customer type buys the most?
-- Quel type de client achète le plus ?
SELECT
	customer_type,
    COUNT(*) AS count_cust
FROM sales
GROUP BY customer_type
ORDER BY count_cust DESC;
    

-- What is the gender of most of the customers ?
-- Quel est le sexe de la plupart des clients ?
SELECT
	gender,
    COUNT(customer_type) AS gender_by_customer
FROM sales
GROUP BY gender;


-- What is the gender distribution per branch?
-- Quelle est la répartition hommes/femmes par filiale ?
SELECT
	gender,
    branch,
    COUNT(customer_type) AS gender_per_branch
FROM sales
GROUP BY branch, gender
ORDER BY gender_per_branch;

-- What is the gender distribution in particular branch?
-- Quelle est la répartition hommes/femmes dans une filiale particuière ?
SELECT
	gender,
    branch,
    COUNT(customer_type) AS gender_per_branch
FROM sales
WHERE branch = "A"
GROUP BY branch, gender
ORDER BY gender_per_branch;

-- Which time of the day do customers give most ratings?
-- À quel moment de la journée les clients attribuent-ils le plus d’évaluations ?
SELECT
	time_of_day,
    AVG(rating) AS avg_of_rating
FROM sales
GROUP BY time_of_day
ORDER BY avg_of_rating DESC;

-- Which time of the day do customers give most ratings per branch ?
-- À quel moment de la journée les clients attribuent-ils le plus d’évaluations par filiale ?
SELECT
	time_of_day,
    branch,
    AVG(rating) AS avg_of_rating
FROM sales
WHERE branch = "A"
GROUP BY time_of_day, branch
ORDER BY avg_of_rating DESC;

-- Which day of the week has the best average ratings ?
-- Quel jour de la semaine a la meilleure moyenne d'audience ?
SELECT
	day_name,
    AVG(rating) AS avg_of_rating
FROM sales
GROUP BY day_name
ORDER BY avg_of_rating DESC;

-- Which day of the week has the best average ratings per branch ?
-- Quel jour de la semaine a la meilleure moyenne d'audience par filiale ?
SELECT
	branch,
    day_name,
    AVG(rating) AS avg_of_rating
FROM sales
WHERE branch = "B"
GROUP BY day_name, branch
ORDER BY avg_of_rating DESC;


    