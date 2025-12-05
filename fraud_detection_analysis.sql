--An empty table is first created before loading the data. 
CREATE TABLE mobile_money_transactions (
    step INT,
    transaction_type VARCHAR(20),  -- Changed from "type" to "transaction_type"
    amount NUMERIC(15, 2),
    nameOrig VARCHAR(50),
    oldbalanceOrg NUMERIC(15, 2),
    newbalanceOrig NUMERIC(15, 2),
    nameDest VARCHAR(50),
    oldbalanceDest NUMERIC(15, 2),
    newbalanceDest NUMERIC(15, 2),
    isFraud INT,
    isFlaggedFraud INT
);

-- An index is being added on the 'isFraud' column to speed up our fraud-finding queries
CREATE INDEX idx_isfraud ON mobile_money_transactions(isFraud);

-- Data is loaded using the copy command
COPY mobile_money_transactions(
    step, 
    transaction_type, 
    amount, 
    nameOrig, 
    oldbalanceOrg, 
    newbalanceOrig, 
    nameDest, 
    oldbalanceDest, 
    newbalanceDest, 
    isFraud, 
    isFlaggedFraud
)
FROM 'C:\Users\Public\Documents\new\mobile_money_raw_data.csv'
--'C:/Users/User/Documents/DATA ANALYTICS/Portfolio_project/Revenue_protection/mobile_money_raw_data.csv' 
DELIMITER ',' 
CSV HEADER;

SELECT COUNT(*) as total_rows
	FROM mobile_money_transactions;

SELECT count (*) 
	FROM mobile_money_transactions 
    WHERE isFraud = 1;

/*The data being used consists of 6,362,620 rows which might be very slow 
or even crash if this is loaded into either python or powerBI. 
Thus, we'd need to reduce the data by creating a new table specifically for 
this analysis.*/ 
CREATE TABLE analytics_data AS
    SELECT * FROM mobile_money_transactions 
    WHERE isFraud = 1

    UNION ALL 
    (SELECT * FROM mobile_money_transactions 
     WHERE isFraud = 0 
     ORDER BY RANDOM() 
     LIMIT 142000);  

SELECT COUNT(*) as total_rows
	FROM analytics_data;

--Checking for nulls in some of the columns.
SELECT 
    COUNT(*) - COUNT(step) AS nulls_in_step,
    COUNT(*) - COUNT(amount) AS nulls_in_amount,
    COUNT(*) - COUNT(nameOrig) AS nulls_in_nameOrig,
    COUNT(*) - COUNT(nameDest) AS nulls_in_nameDest,
    COUNT(*) - COUNT(isFraud) AS nulls_in_isFraud,
	COUNT(*) - COUNT(transaction_type) AS nulls_in_type
FROM analytics_data;

SELECT 
    transaction_type, 
    COUNT(*) as total_count,
    SUM(isFraud) as fraud_cases,
    ROUND((SUM(isFraud)::decimal / COUNT(*)) * 100, 2) as fraud_percentage
FROM 
    analytics_data
GROUP BY 
    transaction_type
ORDER BY 
    fraud_cases DESC;

SELECT 
    isFraud,
    ROUND(AVG(amount), 2) as avg_transaction_amount,
    ROUND(MIN(amount), 2) as min_transaction_amount,
    ROUND(MAX(amount), 2) as max_transaction_amount
FROM 
    analytics_data
GROUP BY 
    isFraud;

COPY (
    SELECT 
        transaction_type, 
        COUNT(*) as total_count,
        SUM(isFraud) as fraud_cases,
        ROUND((SUM(isFraud)::decimal / COUNT(*)) * 100, 2) as fraud_percentage
    FROM 
        analytics_data
    GROUP BY 
        transaction_type
    ORDER BY 
        fraud_cases DESC
) 
TO 'C:\Users\Public\Documents\new\transaction_type_summary.csv' 
DELIMITER ',' 
CSV HEADER;

COPY analytics_data
TO 'C:\Users\Public\Documents\new\fraud_analytics_data.csv' 
DELIMITER ',' 
CSV HEADER;