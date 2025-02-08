-- Create database and create table
CREATE TABLE power_consumption (
	datetime DATETIME,
    temperature FLOAT,
    humidity FLOAT,
    wind_speed FLOAT,
    general_diffuse_flows FLOAT,
    diffuse_flows FLOAT,
    power_zone_1 FLOAT,
    power_zone_2 FLOAT,
    power_zone_3 FLOAT
);

-- Error --secure-file-priv | put in correct folder
SHOW VARIABLES LIKE 'secure_file_priv';

-- Issue with Datetime format | fix csv file Date column to correct format 
-- then LOAD DATA INFILE -- Import data from file to table
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/powerconsumption.csv'
INTO TABLE power_consumption
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ------------------------------------DATA CLEANING --------------------------------------
SELECT * 
FROM power_consumption;

ALTER TABLE power_consumption  
MODIFY COLUMN datetime DATETIME;
-- check if datetime has updated
DESC power_consumption;

-- Check for NULL values
SELECT * FROM power_consumption  
WHERE 1|2|3|4|5|6|7|8|9 IS NULL;
-- No NULL values

-- Check for duplicates
SELECT datetime, temperature, humidity, COUNT(*) 
FROM power_consumption 
GROUP BY datetime, temperature, humidity, wind_speed, general_diffuse_flows, diffuse_flows, power_zone_1, power_zone_2, power_zone_3 
HAVING COUNT(*) > 1;

-- -------------------------------------DATA TRANSFORMATION --------------------------------
-- Extract date, hour, month
ALTER TABLE power_consumption
ADD COLUMN date DATE,
ADD COLUMN hour INT,
ADD COLUMN minute INT,
ADD COLUMN month INT;

UPDATE power_consumption  
SET date = DATE(datetime),  
    hour = HOUR(datetime), 
	minute = MINUTE(datetime),
    month = MONTH(datetime);

-- Aggregate data for trend analysis

-- Daily power consumption
CREATE TABLE daily_power_consumption
SELECT date,  
       SUM(power_zone_1) AS total_zone_1,  
       SUM(power_zone_2) AS total_zone_2,  
       SUM(power_zone_3) AS total_zone_3  
FROM power_consumption  
GROUP BY date;

-- Show new daily_power_consumption table
SELECT * FROM daily_power_consumption;


-- Hourly and Minute Power consumption
CREATE TABLE hourly_power_consumption AS
SELECT date, hour, minute,
	   AVG(power_zone_1) AS avg_zone_1,
       AVG(power_zone_2) AS avg_zone_2,
       AVG(power_zone_3) AS avg_zone_3
FROM power_consumption
GROUP BY date, hour, minute;

-- Show new hourly_power_consumption table
SELECT * FROM hourly_power_consumption;

-- Create a new feature: Total Power Consumption | adding column to store total
ALTER TABLE power_consumption
ADD COLUMN total_power FLOAT;

UPDATE power_consumption
SET total_power = power_zone_1 + power_zone_2 + power_zone_3;
-- Show new power_consumption table
SELECT * FROM power_consumption;

--  Rolling Average 7 days to smooth out flucuations and reveal trends
-- Use CTE to get daily total calculations
WITH daily_totals AS (
	SELECT 
		DATE(datetime) AS date,
        SUM(power_zone_1+power_zone_2+power_zone_3) AS total_power
	FROM power_consumption
    GROUP BY DATE(datetime)
)
SELECT 
    date,  
    total_power,  
    AVG(total_power) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_avg_7d  
FROM daily_totals
ORDER BY date;

-- Check to see if daily calculation is correct from power_consumption
SELECT DATE(datetime) AS date, SUM(power_zone_1 + power_zone_2 + power_zone_3) AS total_power
FROM power_consumption
GROUP BY DATE(datetime)
ORDER BY date;

-- -------------------------------------DATA EXPLORATION --------------------------------
-- Identify peak consumption per hour on specific date
-- Top 5 hours with highest average power usage
SELECT date, hour, AVG(total_power) AS avg_power_usage
FROM power_consumption
GROUP BY date, hour 
ORDER BY avg_power_usage DESC
LIMIT 5;

-- how does temperature affect power consumption
-- the highest temps were not necessarily the highest power usage
SELECT temperature, AVG(total_power) AS avg_power_usage
FROM power_consumption
GROUP BY temperature
ORDER BY temperature;

-- Most energy intensive month
-- Summer months have the highest total power usage
SELECT month, SUM(total_power) as total_usage
FROM power_consumption
GROUP BY month
ORDER BY total_usage DESC;

-- Analyze the impact of wind speed on power usage
SELECT wind_speed, AVG(total_power) AS avg_power_usage
FROM power_consumption
GROUP BY wind_speed
ORDER BY wind_speed;

-- Compare energy production and consumption
SELECT p.date, p.total_power, e.production_kWh,
	(e.production_kWh - p.total_power) AS net_energy
FROM daily_power_consumption p
JOIN energy_production e ON p.date = e.date;

-- Measuring Diffuse Flows
-- Aggregate solar energy to daily & monthly levels
-- General Diffuse Flows mesures total scattered solar radiation from the atmoshphere
-- Diffuse Flows measure the portion of radiation reaching a surface indirectly
SELECT date, AVG(general_diffuse_flows) as avg_general_diffuse,
	AVG(diffuse_flows) as avg_diffuse
FROM power_consumption
GROUP BY date
ORDER BY date;

-- Monthly aggregation -- identify peak solar months
SELECT month, AVG(general_diffuse_flows) as avg_general_diffuse,
	AVG(diffuse_flows) as avg_diffuse,(avg(general_diffuse_flows)-avg(diffuse_flows)) as delta
FROM power_consumption
GROUP BY month
ORDER BY delta DESC;

-- Correlation between Solar radiation & power consumption
-- Does solar radiation affect power consumption?
SELECT AVG(general_diffuse_flows) AS avg_general_diffuse,
		AVG(diffuse_flows) AS avg_diffuse,
        AVG(power_zone_1 + power_zone_2 + power_zone_3) as avg_power_consumption
FROM power_consumption;

-- correlate by hour
SELECT hour,
		AVG(general_diffuse_flows) AS avg_general_diffuse,
        AVG(diffuse_flows) AS avg_diffuse,
        AVG(power_zone_1 + power_zone_2 + power_zone_3) as avg_power_consumption,
        RANK() OVER(ORDER BY AVG(power_zone_1 + power_zone_2 + power_zone_3) DESC) AS consumption_rank
FROM power_consumption
GROUP BY hour
ORDER BY consumption_rank;

-- Peak Solar Radiation & Power demand
-- solar radiation is at its highest during may/june months
SELECT date, general_diffuse_flows, diffuse_flows
FROM power_consumption
ORDER BY general_diffuse_flows DESC
LIMIT 10;

-- power demand is highest in July 
SELECT date, power_zone_1+power_zone_2+power_zone_3 as total_power
FROM power_consumption
ORDER BY total_power DESC
LIMIT 10;

-- showing total power per day or specific date
SELECT date, SUM(total_power) AS daily_total_power
FROM power_consumption
-- WHERE date = '2017-01-01'
GROUP BY date
-- ORDER BY daily_total_power DESC;

-- Average power consumption morning, evening, and night
SELECT 
	CASE
		WHEN hour BETWEEN 5 AND 11 THEN 'Morning'
        WHEN hour BETWEEN 12 AND 17 THEN 'EVENING'
        ELSE 'Night'
	END AS time_period,
    AVG(power_zone_1+power_zone_2+power_zone_3) AS avg_power_consumption
FROM power_consumption
GROUP BY time_period
ORDER BY avg_power_consumption DESC;

-- Create a solar energy potential metric
-- Values closest to 1 -> high solar potential (clear skys, daytime, max sunlight) good for solar power
-- Values closest to 0 -> low solar potential (cloudy, nighttime, weak sunlight)
SELECT datetime, month, 
	(general_diffuse_flows + diffuse_flows)/(SELECT MAX(general_diffuse_flows + diffuse_flows) 
		FROM power_consumption) AS solar_potential
FROM power_consumption
ORDER BY solar_potential DESC;


-- SELECT * FROM daily_power_consumption
-- INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/power_consumption.csv'
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"'
-- LINES TERMINATED BY '\n';
-- SELECT * FROM  daily_power_consumption;
-- SELECT * FROM hourly_power_consumption;
 SELECT * FROM power_consumption;
-- DESC daily_power_consumption;
-- DESC hourly_power_consumption;
-- DESC power_consumption;