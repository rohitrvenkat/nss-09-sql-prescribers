-- PART 1

-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT 
	npi,
	SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC;
-- NPI: 1881634483 (99,707 total claims)


-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.
SELECT
	nppes_provider_first_name || ' ' || nppes_provider_last_org_name,
	specialty_description,
	total_claims
FROM prescriber
INNER JOIN (
	SELECT 
		npi,
		SUM(total_claim_count) AS total_claims
	FROM prescription
	GROUP BY npi ) AS prescription
	USING(npi)
ORDER BY total_claims DESC;
-- Bruce Pendley, Family Practice (99,707 total claims)


-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT 
	specialty_description,
	SUM(total_claims) as total_claims
FROM prescriber
INNER JOIN (
	SELECT 
		npi, 
		SUM(total_claim_count) AS total_claims
	FROM prescription
	GROUP BY npi ) AS prescription
	USING(npi)
GROUP BY specialty_description
ORDER BY total_claims DESC;
-- Family Practice (9,752,347 total claims)


-- 2b. Which specialty had the most total number of claims for opioids?
SELECT 
	specialty_description,
	SUM(total_claim_count) as opioid_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY opioid_claims DESC;
-- Nurse Practitioner (900,845 total claims for opioids)


-- 2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT 
	specialty_description
FROM prescriber
LEFT JOIN (
	SELECT 
		npi, 
		SUM(total_claim_count) AS total_claims
	FROM prescription
	GROUP BY npi ) AS prescription
	USING(npi)
GROUP BY specialty_description
HAVING SUM(total_claims) IS NULL;
-- There are 15 specialties with no associated prescriptions in the prescription table.


-- 2d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
SELECT 
	specialty_description,
	ROUND(opioid_claims / total_claims * 100, 2) AS opioid_claims_pct
FROM (
	SELECT 
		specialty_description,
		SUM(total_claim_count) AS opioid_claims
	FROM prescription
	INNER JOIN prescriber
	USING(npi)
	INNER JOIN drug
	USING(drug_name)
	WHERE opioid_drug_flag = 'Y'
	GROUP BY specialty_description ) AS opioids
INNER JOIN (
	SELECT
		specialty_description,
		SUM(total_claim_count) AS total_claims
	FROM prescription
	INNER JOIN prescriber
	USING (npi)
	GROUP BY specialty_description ) AS all_drugs
USING (specialty_description)
ORDER BY opioid_claims_pct DESC;
-- Case Manager/Care Coordinator has the highest percentage of total claims that are for opioids (72.00%).


-- 3a. Which drug (generic_name) had the highest total drug cost?
SELECT 
	generic_name,
	SUM(total_drug_cost)::money AS total_drug_cost
FROM drug
INNER JOIN prescription
	USING(drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC;
-- INSULIN GLARGINE,HUM.REC.ANLOG ($104,264,066.35)


-- 3b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.
SELECT 
	generic_name,
	SUM(total_drug_cost)::money / SUM(total_day_supply) AS drug_cost_per_day
FROM drug
INNER JOIN prescription
	USING(drug_name)
GROUP BY generic_name
ORDER BY drug_cost_per_day DESC;
-- C1 ESTERASE INHIBITOR ($3495.22 per day)


-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT 
	drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type
FROM drug;


-- 4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type,
	SUM(total_drug_cost)::money AS total_drug_cost
FROM drug
INNER JOIN prescription
	USING(drug_name)
GROUP BY drug_type
ORDER BY total_drug_cost DESC;
-- More money was spent on opioids than on antibiotics ($105,080,626.37 vs. $38,435,121.26).


-- 5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT 
	COUNT(DISTINCT cbsa)
FROM cbsa
INNER JOIN fips_county
	USING(fipscounty)
WHERE state = 'TN';
-- There are 10 CBSAs in Tennessee.


-- 5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT
	cbsaname,
	SUM(population) AS total_population
FROM cbsa
INNER JOIN fips_county
	USING(fipscounty)
INNER JOIN population
	USING(fipscounty)
WHERE state = 'TN'
GROUP BY cbsaname
ORDER BY total_population DESC;
-- Largest CBSA: Nashville-Davidson--Murfreesboro--Franklin, TN (1,830,410)
-- Smallest CBSA: Morristown, TN (116,352)


-- 5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT
	county,
	population
FROM cbsa
RIGHT JOIN fips_county
	USING(fipscounty)
INNER JOIN population
	USING(fipscounty)
WHERE state = 'TN'
AND cbsa IS NULL
ORDER BY population DESC;
-- Sevier County (95,523) is the largest county which is not included in a CBSA.


-- 6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT 
	drug_name, 
	total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;


-- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT 
	drug_name, 
	total_claim_count,
	opioid_drug_flag
FROM prescription
INNER JOIN drug
	USING(drug_name)
WHERE total_claim_count >= 3000;


-- 6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT 
	drug_name, 
	total_claim_count,
	opioid_drug_flag,
	nppes_provider_first_name, 
	nppes_provider_last_org_name
FROM prescription
INNER JOIN drug
	USING(drug_name)
INNER JOIN prescriber
	USING(npi)
WHERE total_claim_count >= 3000;


-- 7a. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opioid_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will likely only need to use the prescriber and drug tables.
SELECT 
	npi, 
	drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' 
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';


-- 7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT 
	npi, 
	drug_name,
	total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
	USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';


-- 7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT 
	npi, 
	drug_name,
	COALESCE(total_claim_count, 0) AS total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
	USING(npi, drug_name)
WHERE specialty_description = 'Pain Management'
AND nppes_provider_city = 'NASHVILLE'
AND opioid_drug_flag = 'Y';


-- PART 2

-- 1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(DISTINCT NPI)
FROM PRESCRIBER
WHERE NPI NOT IN
		(SELECT DISTINCT NPI
		 FROM PRESCRIPTION)
-- 4458 NPIs


-- 2a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT 
	generic_name,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
using(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;


 -- 2b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT 
	generic_name,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
using(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;


-- 2c. Which drugs appear in the top five prescribed for both Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
	(SELECT generic_name
	 FROM prescriber
	 INNER JOIN prescription USING(npi)
	 INNER JOIN drug USING(drug_name)
	 WHERE specialty_description = 'Family Practice'
	 GROUP BY generic_name
	 ORDER BY SUM(total_claim_count) DESC
	 LIMIT 5) 
INTERSECT
	(SELECT generic_name
	 FROM prescriber
	 INNER JOIN prescription USING(npi)
	 INNER JOIN drug USING(drug_name)
	 WHERE SPECIALTY_DESCRIPTION = 'Cardiology'
	 GROUP BY generic_name
	 ORDER BY SUM(total_claim_count) DESC
	 LIMIT 5);


-- 3a. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT 
	npi,
	SUM(total_claim_count) as total_claims,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'NASHVILLE'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;


-- 3b. Now, report the same for Memphis.
SELECT 
	npi,
	SUM(total_claim_count) as total_claims,
	nppes_provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE nppes_provider_city = 'MEMPHIS'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;


-- 3c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
	(SELECT 
 		npi,
		SUM(total_claim_count) AS total_claims,
		nppes_provider_city
	FROM prescriber
	INNER JOIN prescription 
	USING(npi)
	WHERE nppes_provider_city = 'NASHVILLE'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5)
UNION
	(SELECT 
 		npi,
		SUM(total_claim_count) AS total_claims,
		nppes_provider_city
	FROM prescriber
	INNER JOIN prescription 
	USING(npi)
	WHERE nppes_provider_city = 'MEMPHIS'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5)
UNION
	(SELECT 
	 	npi,
		SUM(total_claim_count) AS total_claims,
		nppes_provider_city
	FROM prescriber
	INNER JOIN prescription 
	USING(npi)
	WHERE nppes_provider_city = 'KNOXVILLE'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5)
UNION
	(SELECT 
	 	npi,
		SUM(total_claim_count) AS total_claims,
		nppes_provider_city
	FROM prescriber
	INNER JOIN prescription 
	USING(npi)
	WHERE nppes_provider_city = 'CHATTANOOGA'
	GROUP BY npi, nppes_provider_city
	ORDER BY total_claims DESC
	LIMIT 5)
ORDER BY total_claims DESC;


--4. Find all counties which had an above-average (for the state) number of overdose deaths in 2017. Report the county name and number of overdose deaths.
SELECT 
	county,
	overdose_deaths
FROM overdose_deaths
INNER JOIN fips_county 
USING(fipscounty)
WHERE year = 2017
	AND overdose_deaths >
		(SELECT AVG(overdose_deaths)
			FROM overdose_deaths
			WHERE year = 2017)
ORDER BY overdose_deaths DESC;


-- 5a. Write a query that finds the total population of Tennessee.
SELECT SUM(population) AS total_population
FROM population
-- Total Population of Tennessee: 6,597,381
 
 
-- 5b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
SELECT
	county,
	ROUND(population / SUM(population) OVER() * 100, 2) AS population_pct
FROM population
INNER JOIN fips_county
USING (fipscounty)
ORDER BY population_pct DESC;


-- BONUS

-- In this set of exercises you are going to explore additional ways to group and organize the output of a query when using postgres. 

-- For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management Specialists compared to those from Pain Managment specialists.

-- 1. Write a query which returns the total number of claims for these two groups. Your output should look like this: 

-- specialty_description         |total_claims|
-- ------------------------------|------------|
-- Interventional Pain Management|       55906|
-- Pain Management               |       70853|

SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY specialty_description


-- 2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this. Your output should look like this:

-- specialty_description         |total_claims|
-- ------------------------------|------------|
--                               |      126759|
-- Interventional Pain Management|       55906|
-- Pain Management               |       70853|

	(SELECT
	 	NULL AS specialty_description,
	 	SUM(total_claim_count) AS total_claims
	 FROM prescriber
	 INNER JOIN prescription
	 USING(npi)
	 WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management'))
UNION
	(SELECT 
	 	specialty_description,
	 	SUM(total_claim_count) AS total_claims
	 FROM prescriber
	 INNER JOIN prescription
	 USING(npi)
	 WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
	 GROUP BY specialty_description);


-- 3. Now, instead of using UNION, make use of GROUPING SETS (https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) to achieve the same output.
SELECT 
	specialty_description,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS(specialty_description, ())


-- 4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:

-- specialty_description         |opioid_drug_flag|total_claims|
-- ------------------------------|----------------|------------|
--                               |                |      129726|
--                               |Y               |       76143|
--                               |N               |       53583|
-- Pain Management               |                |       72487|
-- Interventional Pain Management|                |       57239|

SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS(opioid_drug_flag, specialty_description, ())


-- 5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the output from the previous query?
SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(opioid_drug_flag, specialty_description)


-- 6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result?
SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(specialty_description, opioid_drug_flag)


-- 7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?
SELECT 
	specialty_description,
	opioid_drug_flag,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING (drug_name)
WHERE specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY CUBE(specialty_description, opioid_drug_flag)


-- 8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. For the purpose of this question, we will put a drug into one of the six listed categories if it has the category name as part of its generic name. For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and "CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

-- The end result of this question should be a table formatted like this:

-- city       |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-- -----------|-------|--------|-----------|--------|---------|-----------|
-- CHATTANOOGA|   1323|    3689|      68315|   12126|    49519|       1317|
-- KNOXVILLE  |   2744|    4811|      78529|   20946|    84730|       9186|
-- MEMPHIS    |   4697|    3666|      68036|    4898|    38295|        189|
-- NASHVILLE  |   2043|    6119|      88669|   13572|    62859|       1261|

-- For this question, you should look into use the crosstab function, which is part of the tablefunc extension (https://www.postgresql.org/docs/9.5/tablefunc.html). In order to use this function, you must (one time per database) run the command
-- 	CREATE EXTENSION tablefunc;

-- Hint #1: First write a query which will label each drug in the drug table using the six categories listed above.
-- Hint #2: In order to use the crosstab function, you need to first write a query which will produce a table with one row_name column, one category column, and one value column. So in this case, you need to have a city column, a drug label column, and a total claim count column.
-- Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes. If the query that you are using also uses single quotes, you'll need to escape them by turning them into double-single quotes.

CREATE EXTENSION tablefunc; 

SELECT *
FROM CROSSTAB($$
	SELECT
		nppes_provider_city AS city,
		CASE
			WHEN generic_name like '%CODEINE%' THEN 'codeine'
			WHEN generic_name like '%FENTANYL%' THEN 'fentanyl'
			WHEN generic_name like '%HYDROCODONE%' THEN 'hyrdocodone'
			WHEN generic_name like '%MORPHINE%' THEN 'morphine'
			WHEN generic_name like '%OXYCODONE%' THEN 'oxycodone'
			WHEN generic_name like '%OXYMORPHONE%' THEN 'oxymorphone'
		END AS drug_type,
		SUM(total_claim_count) AS total_claims
	FROM prescriber
	INNER JOIN prescription
	USING(npi)
	INNER JOIN drug
	USING (drug_name)
	WHERE nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
	GROUP BY city, drug_type
	ORDER BY city, drug_type $$)
AS (city text,
	codeine numeric,
	fentanyl numeric,
	hyrdocodone numeric,
	morphine numeric,
	oxycodone numeric,
	oxymorphone numeric)