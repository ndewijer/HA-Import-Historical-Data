/* 
Import Toon files

How to:

Prerequisites:
- Download and install: DB Browser for SQLite https://sqlitebrowser.org/ (tested windows and macos version 3.12.2 )
- For Windows: Download and install/configure: WinSCP (https://winscp.net/eng/download.php)
- For Linux: Use commandline for scp

Raw Data:
Toon:
- Backup and download Toon data  (Instellingen -> Internet -> Toon data)
-	extract: "usage.zip"
  extract: "energy_consumption_tarif_hoog_st.csv"
  extract: "energy_consumption_tarif_laag_st.csv"
	extract: "energy_production_tarif_hoog_st.csv"
	extract: "energy_production_tarif_laag_st.csv"
	extract: "energy_solar_st.csv"
	extract: "energy_consumption_tarif_hoog.csv"
	extract: "energy_consumption_tarif_laag.csv"
	extract: "energy_production_tarif_hoog.csv"
	extract: "energy_production_tarif_laag.csv"
	extract: "energy_solar.csv"
	extract: "gas_quantity_CurrentGasQuantity_5yrhours.csv"
	extract: "gas_quantity_CurrentGasQuantity_10yrdays.csv"
SolarEdge:
- Call API and run supporting scripts to generate CSV, read Readme in SolarEdge directory.
GreenChoice:
- Download Meterstranden from https://mijn.greenchoice.nl/meterstanden-overzicht and run supporting scripts to generate seperate CSVs, Readme in GreenChoice directory.

Pre-modication work:

- Backup and download Home Assistant data (disable recorder while making the backup -> Developer tools/Services/Call service: Recorder:disable)
- Stop the Home Assistant core (Developer tools/Services/Call service: Home Assistant Core Integration: Stop)
- Home Assistant data: 
	extract: "home-assistant_v2.db" (from "backup.tar" extract "homeassistant.tar.gz" from "data" folder)
	As an alternative it is also possible to download the "home-assistant_v2.db" directly from the Home Assistant "config" directory (For example: use WinSCP/scp in combination with the Home Assistant SSH addon).
	In case of this method make sure to make a copy of the database so that you can always restore this version of the database.

Modification Work
- Start "DB Browser for SQLite"
- Open project "history.sqbpro". If the database is not loaded directly you have to open the "home-assistant_v2.db" database manually ("Open Database").
- Validate the schema version of the database (Browse Data -> Table: schema_version)
  The script has been tested with schema version 41. With higher versions you should validate if the structure of the "statistics" and "short_term_statistics" tables have changed.
  used fields in table "statistics": metadata_id, state, sum, start_ts, created_ts
  used fields in table "short_term_statistics": sum 

Table creation
- Create the 8 different tables using the SQL Query editor

GUI Import
- Import, one at a time, all the extracted historical data elec* and gas* files from Toon, SolarEdge and/or GreenChoice  (File -> Import -> Table from CSV file...)
  When loading in data from multiple sources, (for example: Toon and GreenChoice, or multiple Toons). The exported files from the second source can be imported into the existing tables.
  You have to create the table manually (field1, field2) in case a Toon file does not contain any data (0 KB). The name of the table should be the name of the file without ".csv",
  another option is to comment out the SQL for the specific file.

Commandline Import
- Enter the database using sqlite3 "sqlite3 home-assistant_v2.db"
- Follow the commands found in this file to import the .csv into tables

- Lookup in the "statistics_meta" table the ID's of the sensors (Browse Data -> Table: statistics_meta; You can use "filter" to find the id of the sensor)
  Below are the sensors you need to find. The names are the default names from the Home Assistant Toon integration. In case another provider is used the names of the sensors can be looked
  up in the Energy dashboard (Settings -> Dashboards -> Energy).

  For Toon they look as follows:
	id  statistic_id                                	source      unit_of_measurement
	2	sensor.gas_meter								recorder	m³
	3	sensor.electricity_meter_feed_in_tariff_1		recorder	kWh
	4	sensor.electricity_meter_feed_in_tariff_2		recorder	kWh
	6	sensor.electricity_meter_feed_out_tariff_1		recorder	kWh
	7	sensor.electricity_meter_feed_out_tariff_2		recorder	kWh
	10	sensor.solar_energy_produced_today				recorder	kWh

  For GreenChoice, they are
  37	sensor.electricity_meter_energy_consumption_tarif_1	recorder	kWh
  38	sensor.electricity_meter_energy_consumption_tarif_2	recorder	kWh
  39	sensor.electricity_meter_energy_production_tarif_1	recorder	kWh
  40	sensor.electricity_meter_energy_production_tarif_2	recorder	kWh

  For SolarEdge it is
  7	sensor.solaredge_ac_energy_kwh	recorder	kWh

- Change the below script and insert the correct ID on the places where the text "* Change *" has been added in the SQL statement.
  The script basically has the same SQL statements for each sensor so in case a sensor is not needed you can comment out that specific part (for example: solar, gas)
- Execute the SQL and wait for it to complete.
- Commit the changes by selecting "Write changes" in the toolbar, if the script ends without errors. In case of an error select "Revert changes" and correct the error and execute this step again.

Post-modication work: 
- Upload "home-assistant_v2.db" to the Home Assistant "config" directory (For example: use WinSCP in combination with the Home Assistant SSH addon). 
- Restart/reboot Home Assistant (physically reboot Home Assistant or login using PUTTY-SSH and execute the "reboot" command)
- Validate the imported historical data in the "Energy Dashboard"
- Enjoy :-)


Background information:

Normal tariff meter values without correction for solar usage
energy_consumption_tarif_hoog_st.csv (hourly - max 5 years)
energy_consumption_tarif_hoog.csv (daily - max 10 years)

Low tariff meter values without correction for solar usage
energy_consumption_tarif_laag_st.csv (hourly - max 5 years)
energy_consumption_tarif_laag.csv (daily - max 10 years)

Normal tariff production meter values 
energy_production_tarif_hoog_st.csv (hourly - max 5 years)
energy_production_tarif_hoog.csv (daily - max 10 years)

Low tariff production meter values
energy_production_tarif_laag_st.csv (hourly - max 5 years)
energy_production_tarif_laag.csv (daily - max 10 years)

Solar production meter values
energy_solar_st.csv (hourly - max 5 years)
energy_solar.csv (daily - max 10 years)

Gas meter values
gas_quantity_CurrentGasQuantity_5yrhours.csv (hourly - max 5 years)
gas_quantity_CurrentGasQuantity_10yrdays.csv (daily - max 10 years)

For Toon the solar sensor is reset every night.
Because of kWh the values have to be divided by 1000.

Long term statistics (1 hour interval) => statistics
Short term statistics (5 min interval) => statistics_short_term

Short term statistics are rolled over to long term statistics.
Both tables need to be updated according to the new imported data which changes the sum column!

*/
/* Remove the temporary tables if they exist */
DROP TABLE IF EXISTS energy_consumption_tarif_hoog_st;
DROP TABLE IF EXISTS energy_consumption_tarif_laag_st;
DROP TABLE IF EXISTS energy_production_tarif_hoog_st;
DROP TABLE IF EXISTS energy_production_tarif_laag_st;
DROP TABLE IF EXISTS energy_solar_st;
DROP TABLE IF EXISTS energy_consumption_tarif_hoog;
DROP TABLE IF EXISTS energy_consumption_tarif_laag;
DROP TABLE IF EXISTS energy_production_tarif_hoog;
DROP TABLE IF EXISTS energy_production_tarif_laag;
DROP TABLE IF EXISTS energy_solar;

CREATE TABLE energy_consumption_tarif_hoog_st(
  field1 FLOAT,
  field2 FLOAT 
);
CREATE TABLE energy_consumption_tarif_hoog(
  field1 FLOAT,
  field2 FLOAT 
);
CREATE TABLE energy_consumption_tarif_laag(
  field1 FLOAT,
  field2 FLOAT 
);
CREATE TABLE energy_consumption_tarif_laag_st(
  field1 FLOAT,
  field2 FLOAT 
);
CREATE TABLE energy_production_tarif_hoog_st(
  field1 FLOAT,
  field2 FLOAT 
);
CREATE TABLE energy_production_tarif_hoog(
  field1 FLOAT,
  field2 FLOAT 
);
CREATE TABLE energy_production_tarif_laag_st(
  field1 FLOAT,
  field2 FLOAT 
);
CREATE TABLE energy_production_tarif_laag(
  field1 FLOAT,
  field2 FLOAT 
);
CREATE TABLE energy_solar_st(
  field1 FLOAT,
  field2 FLOAT 
);
CREATE TABLE energy_solar(
  field1 FLOAT,
  field2 FLOAT 
);

-- When importing via commandline, run the following commands.
/*
.mode csv
.import {path}/energy_consumption_tarif_hoog_st.csv energy_consumption_tarif_hoog_st
.import {path}/energy_consumption_tarif_laag_st.csv energy_consumption_tarif_laag_st
.import {path}/energy_production_tarif_hoog_st.csv energy_production_tarif_hoog_st
.import {path}/energy_production_tarif_laag_st.csv energy_production_tarif_laag_st
.import {path}/energy_solar_st.csv energy_solar_st
.import {path}/energy_gas_st.csv energy_gas_st
.import {path}/energy_consumption_tarif_hoog.csv energy_consumption_tarif_hoog
.import {path}/energy_consumption_tarif_laag.csv energy_consumption_tarif_laag
.import {path}/energy_production_tarif_hoog.csv energy_production_tarif_hoog
.import {path}/energy_production_tarif_laag.csv energy_production_tarif_laag
.import {path}/energy_solar.csv energy_solar
.import {path}/energy_gas.csv energy_gas

*/

/* Remove the temporary tables if they exist */
DROP TABLE IF EXISTS NT_ORIG_NEW;
DROP TABLE IF EXISTS LT_ORIG_NEW;
DROP TABLE IF EXISTS NT_PROD_NEW;
DROP TABLE IF EXISTS LT_PROD_NEW;
DROP TABLE IF EXISTS SOLAR_NEW;
DROP TABLE IF EXISTS GAS_NEW;

/* Create temp tables that can hold the difference between the measurements and create a new sum */
CREATE TABLE "NT_ORIG_NEW" (
	"ts"		  FLOAT,
  "ts_cr"   FLOAT,
	"value"		FLOAT,
	"diff"		FLOAT,
	"old_sum"	FLOAT,
	"new_sum"	FLOAT
);
CREATE TABLE "LT_ORIG_NEW" (
	"ts"		  FLOAT,
  "ts_cr"   FLOAT,
	"value"		FLOAT,
	"diff"		FLOAT,
	"old_sum"	FLOAT,
	"new_sum"	FLOAT
);
CREATE TABLE "NT_PROD_NEW" (
	"ts"		  FLOAT,
  "ts_cr"   FLOAT,
	"value"		FLOAT,
	"diff"		FLOAT,
	"old_sum"	FLOAT,
	"new_sum"	FLOAT
);
CREATE TABLE "LT_PROD_NEW" (
	"ts"		  FLOAT,
  "ts_cr"   FLOAT,
	"value"		FLOAT,
	"diff"		FLOAT,
	"old_sum"	FLOAT,
	"new_sum"	FLOAT
);
CREATE TABLE "SOLAR_NEW" (
	"ts"		  FLOAT,
  "ts_cr"   FLOAT,
	"value"		FLOAT,
	"diff"		FLOAT,
	"old_sum"	FLOAT,
	"new_sum"	FLOAT
);
CREATE TABLE "GAS_NEW" (
	"ts"		INTEGER,
	"value"		FLOAT,
	"diff"		FLOAT,
	"old_sum"	FLOAT,
	"new_sum"	FLOAT
);


/* Insert the hourly records from Toon - max 5 years */
INSERT INTO NT_ORIG_NEW (ts, ts_cr, value)
SELECT round(field1, 0), field1, round(field2, 3)
FROM energy_consumption_tarif_hoog_st;

INSERT INTO LT_ORIG_NEW (ts, ts_cr,value)
SELECT round(field1, 0), field1, round(field2, 3)
FROM energy_consumption_tarif_laag_st;

INSERT INTO NT_PROD_NEW (ts, ts_cr,value)
SELECT round(field1, 0), field1, round(field2, 3)
FROM energy_production_tarif_hoog_st;

INSERT INTO LT_PROD_NEW (ts, ts_cr,value)
SELECT round(field1, 0), field1, round(field2, 3)
FROM energy_production_tarif_laag_st;

INSERT INTO SOLAR_NEW (ts, ts_cr,value)
SELECT round(field1, 0), field1, round(field2, 3)
FROM energy_solar_st;

INSERT INTO GAS_NEW (ts, value)
SELECT field1, round(field2 / 1000.0, 3)
FROM energy_gas_st;


/* Insert the day records from Toon - max 10 years. We only add data that is older than the hourly records */
INSERT INTO NT_ORIG_NEW (ts, ts_cr,value)
SELECT round(field1, 0), field1, round(field2, 3)
FROM energy_consumption_tarif_hoog  
WHERE
  field1 < (SELECT MIN(ts) FROM NT_ORIG_NEW);

INSERT INTO LT_ORIG_NEW (ts, ts_cr,value)
SELECT round(field1, 0), field1, round(field2, 3)
FROM energy_consumption_tarif_laag  
WHERE
  field1 < (SELECT MIN(ts) FROM LT_ORIG_NEW);

INSERT INTO NT_PROD_NEW (ts, ts_cr,value)
SELECT round(field1, 0), field1, round(field2, 3)
FROM energy_production_tarif_hoog
WHERE
  field1 < (SELECT MIN(ts) FROM NT_PROD_NEW);

INSERT INTO LT_PROD_NEW (ts, ts_cr,value)
SELECT round(field1, 0), field1, round(field2, 3)
FROM energy_production_tarif_laag
WHERE
  field1 < (SELECT MIN(ts) FROM LT_PROD_NEW);
  
INSERT INTO SOLAR_NEW (ts, ts_cr,value)
SELECT round(field1, 0), field1, round(field2, 3)
FROM energy_solar
WHERE
  field1 < (SELECT MIN(ts) FROM SOLAR_NEW);  

INSERT INTO GAS_NEW (ts, value)
SELECT field1, round(field2 / 1000.0, 3)
FROM gas_quantity_CurrentGasQuantity_10yrdays
WHERE
  field1 < (SELECT MIN(ts) FROM GAS_NEW);  
  
/* Remove any overlapping records from Toon which are already in Home Assistant */
DELETE FROM NT_ORIG_NEW
WHERE
ts >= (SELECT MIN(start_ts) FROM statistics WHERE metadata_id = 38); /* Change */

DELETE FROM LT_ORIG_NEW
WHERE
ts >= (SELECT MIN(start_ts) FROM statistics WHERE metadata_id = 37); /* Change */

DELETE FROM NT_PROD_NEW
WHERE
ts >= (SELECT MIN(start_ts) FROM statistics WHERE metadata_id = 40); /* Change */

DELETE FROM LT_PROD_NEW
WHERE
ts >= (SELECT MIN(start_ts) FROM statistics WHERE metadata_id = 39); /* Change */

DELETE FROM SOLAR_NEW
WHERE
ts >= (SELECT MIN(start_ts) FROM statistics WHERE metadata_id = 7); /* Change */

DELETE FROM GAS_NEW
WHERE
ts >= (SELECT MIN(start_ts) FROM statistics WHERE metadata_id = 2); /* Change */

/* Insert the data from Home Assistant so that we can adjust the records with the new calculated sum */
INSERT INTO NT_ORIG_NEW (ts, ts_cr,value, old_sum)
SELECT start_ts, created_ts, state, sum
FROM statistics
WHERE metadata_id = 38; /* Change */

INSERT INTO LT_ORIG_NEW (ts, ts_cr,value, old_sum)
SELECT start_ts, created_ts, state, sum
FROM statistics
WHERE metadata_id = 37; /* Change */

INSERT INTO NT_PROD_NEW (ts, ts_cr,value, old_sum)
SELECT start_ts, created_ts, state, sum
FROM statistics
WHERE metadata_id = 40; /* Change */

INSERT INTO LT_PROD_NEW (ts, ts_cr,value, old_sum)
SELECT start_ts, created_ts, state, sum
FROM statistics
WHERE metadata_id = 39; /* Change */

INSERT INTO SOLAR_NEW (ts, ts_cr,value, old_sum)
SELECT start_ts, created_ts, state, sum
FROM statistics
WHERE metadata_id = 7; /* Change */

INSERT INTO GAS_NEW (ts, value, old_sum)
SELECT start_ts, state, sum
FROM statistics
WHERE metadata_id = 2; /* Change */

/* 
Calculate the difference from the previous record in the table 
  - For the Toon values calculate the diff from the previous record from the imported values (use value column / old_sum column is empty)
  - For the Home Assistant values calculate the diff from the previous record from the existing sum column (use old_sum column / old_sum column is not empty)
*/
WITH CTE_DIFF_NT_ORIG_VALUE AS (
	SELECT ts, round(value - (lag(value, 1, 0) OVER (ORDER BY ts)), 3) AS diff
	FROM NT_ORIG_NEW
	ORDER BY ts
)
UPDATE NT_ORIG_NEW
SET diff = CTE_DIFF_NT_ORIG_VALUE.diff
FROM CTE_DIFF_NT_ORIG_VALUE
WHERE
  NT_ORIG_NEW.ts = CTE_DIFF_NT_ORIG_VALUE.ts AND
  NT_ORIG_NEW.old_sum IS NULL;

WITH CTE_DIFF_NT_ORIG_SUM AS (
	SELECT ts, old_sum - (lag(old_sum, 1, 0) OVER (ORDER BY ts)) AS diff
	FROM NT_ORIG_NEW
	ORDER BY ts
)
UPDATE NT_ORIG_NEW
SET diff = CTE_DIFF_NT_ORIG_SUM.diff
FROM CTE_DIFF_NT_ORIG_SUM
WHERE
  NT_ORIG_NEW.ts = CTE_DIFF_NT_ORIG_SUM.ts AND
  NT_ORIG_NEW.old_sum IS NOT NULL;
  

WITH CTE_DIFF_LT_ORIG_VALUE AS (
	SELECT ts, round(value - (lag(value, 1, 0) OVER (ORDER BY ts)), 3) AS diff
	FROM LT_ORIG_NEW
	ORDER BY ts
)
UPDATE LT_ORIG_NEW
SET diff = CTE_DIFF_LT_ORIG_VALUE.diff
FROM CTE_DIFF_LT_ORIG_VALUE
WHERE
  LT_ORIG_NEW.ts = CTE_DIFF_LT_ORIG_VALUE.ts AND
  LT_ORIG_NEW.old_sum IS NULL;

WITH CTE_DIFF_LT_ORIG_SUM AS (
	SELECT ts, old_sum - (lag(old_sum, 1, 0) OVER (ORDER BY ts)) AS diff
	FROM LT_ORIG_NEW
	ORDER BY ts
)
UPDATE LT_ORIG_NEW
SET diff = CTE_DIFF_LT_ORIG_SUM.diff
FROM CTE_DIFF_LT_ORIG_SUM
WHERE
  LT_ORIG_NEW.ts = CTE_DIFF_LT_ORIG_SUM.ts AND
  LT_ORIG_NEW.old_sum IS NOT NULL;

  
WITH CTE_DIFF_NT_PROD_VALUE AS (
	SELECT ts, round(value - (lag(value, 1, 0) OVER (ORDER BY ts)), 3) AS diff
	FROM NT_PROD_NEW
	ORDER BY ts
)
UPDATE NT_PROD_NEW
SET diff = CTE_DIFF_NT_PROD_VALUE.diff
FROM CTE_DIFF_NT_PROD_VALUE
WHERE
  NT_PROD_NEW.ts = CTE_DIFF_NT_PROD_VALUE.ts AND
  NT_PROD_NEW.old_sum IS NULL;

WITH CTE_DIFF_NT_PROD_SUM AS (
	SELECT ts, old_sum - (lag(old_sum, 1, 0) OVER (ORDER BY ts)) AS diff
	FROM NT_PROD_NEW
	ORDER BY ts
)
UPDATE NT_PROD_NEW
SET diff = CTE_DIFF_NT_PROD_SUM.diff
FROM CTE_DIFF_NT_PROD_SUM
WHERE
  NT_PROD_NEW.ts = CTE_DIFF_NT_PROD_SUM.ts AND
  NT_PROD_NEW.old_sum IS NOT NULL;
 

WITH CTE_DIFF_LT_PROD_VALUE AS (
	SELECT ts, round(value - (lag(value, 1, 0) OVER (ORDER BY ts)), 3) AS diff
	FROM LT_PROD_NEW
	ORDER BY ts
)
UPDATE LT_PROD_NEW
SET diff = CTE_DIFF_LT_PROD_VALUE.diff
FROM CTE_DIFF_LT_PROD_VALUE
WHERE
  LT_PROD_NEW.ts = CTE_DIFF_LT_PROD_VALUE.ts AND
  LT_PROD_NEW.old_sum IS NULL;

WITH CTE_DIFF_LT_PROD_SUM AS (
	SELECT ts, old_sum - (lag(old_sum, 1, 0) OVER (ORDER BY ts)) AS diff
	FROM LT_PROD_NEW
	ORDER BY ts
)
UPDATE LT_PROD_NEW
SET diff = CTE_DIFF_LT_PROD_SUM.diff
FROM CTE_DIFF_LT_PROD_SUM
WHERE
  LT_PROD_NEW.ts = CTE_DIFF_LT_PROD_SUM.ts AND
  LT_PROD_NEW.old_sum IS NOT NULL;


WITH CTE_DIFF_SOLAR_VALUE AS (
	SELECT ts, round(value - (lag(value, 1, 0) OVER (ORDER BY ts)), 3) AS diff
	FROM SOLAR_NEW
	ORDER BY ts
)
UPDATE SOLAR_NEW
SET diff = CTE_DIFF_SOLAR_VALUE.diff
FROM CTE_DIFF_SOLAR_VALUE
WHERE
  SOLAR_NEW.ts = CTE_DIFF_SOLAR_VALUE.ts AND
  SOLAR_NEW.old_sum IS NULL;

WITH CTE_DIFF_SOLAR_SUM AS (
	SELECT ts, old_sum - (lag(old_sum, 1, 0) OVER (ORDER BY ts)) AS diff
	FROM SOLAR_NEW
	ORDER BY ts
)
UPDATE SOLAR_NEW
SET diff = CTE_DIFF_SOLAR_SUM.diff
FROM CTE_DIFF_SOLAR_SUM
WHERE
  SOLAR_NEW.ts = CTE_DIFF_SOLAR_SUM.ts AND
  SOLAR_NEW.old_sum IS NOT NULL;

UPDATE GAS_NEW
SET diff = CTE_DIFF_GAS_VALUE.diff
FROM CTE_DIFF_GAS_VALUE
WHERE
  GAS_NEW.ts = CTE_DIFF_GAS_VALUE.ts AND
  GAS_NEW.old_sum IS NULL;

WITH CTE_DIFF_GAS_SUM AS (
	SELECT ts, old_sum - (lag(old_sum, 1, 0) OVER (ORDER BY ts)) AS diff
	FROM GAS_NEW
	ORDER BY ts
)
UPDATE GAS_NEW
SET diff = CTE_DIFF_GAS_SUM.diff
FROM CTE_DIFF_GAS_SUM
WHERE
  GAS_NEW.ts = CTE_DIFF_GAS_SUM.ts AND
  GAS_NEW.old_sum IS NOT NULL;
  
/* Cleanup possible wrong values:
        - Remove the first record if no diff could be determined (Toon data)
        - Diff is null  => The point where Toon data goes over to Home Assistant data 
		- Diff < 0		=> Probably new meter installed (measurement should be low)
		- Diff > 1000	=> Incorrect value 
   First handle the first two cases and then correct to 0 when incorrect value
*/
DELETE FROM NT_ORIG_NEW
WHERE
ROWID IN (
  SELECT ROWID FROM NT_ORIG_NEW
  WHERE
    old_sum IS NULL
  ORDER BY ts
  LIMIT 1
);

UPDATE NT_ORIG_NEW
SET diff = round(old_sum, 3)
WHERE (diff IS NULL);

UPDATE NT_ORIG_NEW
SET diff = round(value, 3)
WHERE (diff < 0.0) AND (value < 25);

UPDATE NT_ORIG_NEW
SET diff = 0
WHERE (diff < 0.0) OR (diff > 1000.0);


DELETE FROM LT_ORIG_NEW
WHERE
ROWID IN (
  SELECT ROWID FROM LT_ORIG_NEW
  WHERE
    old_sum IS NULL
  ORDER BY ts
  LIMIT 1
);

UPDATE LT_ORIG_NEW
SET diff = round(old_sum, 3)
WHERE (diff IS NULL);

UPDATE LT_ORIG_NEW
SET diff = round(value, 3)
WHERE (diff < 0.0) AND (value < 25);

UPDATE LT_ORIG_NEW
SET diff = 0
WHERE (diff < 0.0) OR (diff > 1000.0);


DELETE FROM NT_PROD_NEW
WHERE
ROWID IN (
  SELECT ROWID FROM NT_PROD_NEW
  WHERE
    old_sum IS NULL
  ORDER BY ts
  LIMIT 1
);

UPDATE NT_PROD_NEW
SET diff = round(old_sum, 3)
WHERE (diff IS NULL);

UPDATE NT_PROD_NEW
SET diff = round(value, 3)
WHERE (diff < 0.0) AND (value < 25);

UPDATE NT_PROD_NEW
SET diff = 0
WHERE (diff < 0.0) OR (diff > 1000.0);


DELETE FROM LT_PROD_NEW
WHERE
ROWID IN (
  SELECT ROWID FROM LT_PROD_NEW
  WHERE
    old_sum IS NULL
  ORDER BY ts
  LIMIT 1
);

UPDATE LT_PROD_NEW
SET diff = round(old_sum, 3)
WHERE (diff IS NULL);

UPDATE LT_PROD_NEW
SET diff = round(value, 3)
WHERE (diff < 0.0) AND (value < 25);

UPDATE LT_PROD_NEW
SET diff = 0
WHERE (diff < 0.0) OR (diff > 1000.0);


DELETE FROM SOLAR_NEW
WHERE
ROWID IN (
  SELECT ROWID FROM SOLAR_NEW
  WHERE
    old_sum IS NULL
  ORDER BY ts
  LIMIT 1
);

UPDATE SOLAR_NEW
SET diff = round(old_sum, 3)
WHERE (diff IS NULL);

UPDATE SOLAR_NEW
SET diff = value
WHERE (diff < 0.0) AND (value < 25);

UPDATE SOLAR_NEW
SET diff = 0
WHERE (diff < 0.0) OR (diff > 1000.0);

DELETE FROM GAS_NEW
WHERE
ROWID IN (
  SELECT ROWID FROM GAS_NEW
  WHERE
    old_sum IS NULL
  ORDER BY ts
  LIMIT 1
);

UPDATE GAS_NEW
SET diff = round(old_sum, 3)
WHERE (diff IS NULL);

UPDATE GAS_NEW
SET diff = value
WHERE (diff < 0.0) AND (value < 25);

UPDATE GAS_NEW
SET diff = 0
WHERE (diff < 0.0) OR (diff > 1000.0);

/* Calculate the new sum
   It is calculated by calculating the sum until the record that is currently processed
*/
WITH CTE_SUM_NT_ORIG AS (
    SELECT ts, SUM(diff) OVER (ORDER BY ts) AS new_sum
    FROM NT_ORIG_NEW
)
UPDATE NT_ORIG_NEW
SET new_sum = round(CTE_SUM_NT_ORIG.new_sum, 3)
FROM CTE_SUM_NT_ORIG
WHERE
  NT_ORIG_NEW.ts = CTE_SUM_NT_ORIG.ts;

WITH CTE_SUM_LT_ORIG AS (
    SELECT ts, SUM(diff) OVER (ORDER BY ts) AS new_sum
    FROM LT_ORIG_NEW
)
UPDATE LT_ORIG_NEW
SET new_sum = round(CTE_SUM_LT_ORIG.new_sum, 3)
FROM CTE_SUM_LT_ORIG
WHERE
  LT_ORIG_NEW.ts = CTE_SUM_LT_ORIG.ts;

WITH CTE_SUM_NT_PROD AS (
    SELECT ts, SUM(diff) OVER (ORDER BY ts) AS new_sum
    FROM NT_PROD_NEW
)
UPDATE NT_PROD_NEW
SET new_sum = round(CTE_SUM_NT_PROD.new_sum, 3)
FROM CTE_SUM_NT_PROD
WHERE
  NT_PROD_NEW.ts = CTE_SUM_NT_PROD.ts;

WITH CTE_SUM_LT_PROD AS (
    SELECT ts, SUM(diff) OVER (ORDER BY ts) AS new_sum
    FROM LT_PROD_NEW
)
UPDATE LT_PROD_NEW
SET new_sum = round(CTE_SUM_LT_PROD.new_sum, 3)
FROM CTE_SUM_LT_PROD
WHERE
  LT_PROD_NEW.ts = CTE_SUM_LT_PROD.ts;

WITH CTE_SUM_SOLAR AS (
    SELECT ts, SUM(diff) OVER (ORDER BY ts) AS new_sum
    FROM SOLAR_NEW
)
UPDATE SOLAR_NEW
SET new_sum = round(CTE_SUM_SOLAR.new_sum, 3)
FROM CTE_SUM_SOLAR
WHERE
  SOLAR_NEW.ts = CTE_SUM_SOLAR.ts;

WITH CTE_SUM_GAS AS (
    SELECT ts, SUM(diff) OVER (ORDER BY ts) AS new_sum
    FROM GAS_NEW
)
UPDATE GAS_NEW
SET new_sum = round(CTE_SUM_GAS.new_sum, 3)
FROM CTE_SUM_GAS
WHERE
  GAS_NEW.ts = CTE_SUM_GAS.ts;

  
/* Copy the new information to the statistics table
id			=> primary key and automatically filled with ROWID
sum			=> calculated new_sum value
metadata_id	=> the fixed metadata id of this statistics (see top)
created_ts	=> set to the timestamp of the statistic
start_ts	=> timestamp of the statistic
The sum is updated in case the record is already in Home Assistant

"where true" is needed to remove parsing ambiguity
*/
INSERT INTO statistics (state, sum, metadata_id, created_ts, start_ts)
SELECT value, new_sum, 38, ts_cr, ts FROM NT_ORIG_NEW WHERE true /* Change */
ON CONFLICT DO UPDATE SET sum = excluded.sum;

INSERT INTO statistics (state, sum, metadata_id, created_ts, start_ts)
SELECT value, new_sum, 37, ts_cr, ts FROM LT_ORIG_NEW WHERE true /* Change */
ON CONFLICT DO UPDATE SET sum = excluded.sum;

INSERT INTO statistics (state, sum, metadata_id, created_ts, start_ts)
SELECT value, new_sum, 40, ts_cr, ts FROM NT_PROD_NEW WHERE true /* Change */
ON CONFLICT DO UPDATE SET sum = excluded.sum;

INSERT INTO statistics (state, sum, metadata_id, created_ts, start_ts)
SELECT value, new_sum, 39, ts_cr, ts FROM LT_PROD_NEW WHERE true /* Change */
ON CONFLICT DO UPDATE SET sum = excluded.sum;

INSERT INTO statistics (state, sum, metadata_id, created_ts, start_ts)
SELECT value, new_sum, 7, ts_cr, ts FROM SOLAR_NEW WHERE true /* Change */
ON CONFLICT DO UPDATE SET sum = excluded.sum;

INSERT INTO statistics (state, sum, metadata_id, created_ts, start_ts)
SELECT new_sum, new_sum, 2, ts, ts FROM GAS_NEW WHERE true /* Change */
ON CONFLICT DO UPDATE SET sum = excluded.sum;

/* Also update the short term statistics. 
We calculate the delta with which the sum was changed and add that to the current measurements
*/
UPDATE statistics_short_term 
SET sum = sum + (
  SELECT (new_sum - sum) as correction_factor
  FROM
    statistics_short_term as SST, NT_ORIG_NEW AS SN
  WHERE
    SST.metadata_id = 38 AND /* Change */
    SST.start_ts = SN.ts
  ORDER BY state DESC
  LIMIT 1
)
WHERE
  metadata_id = 38; /* Change */

UPDATE statistics_short_term 
SET sum = sum + (
  SELECT (new_sum - sum) as correction_factor
  FROM
    statistics_short_term as SST, LT_ORIG_NEW AS SN
  WHERE
    SST.metadata_id = 37 AND /* Change */
    SST.start_ts = SN.ts
  ORDER BY state DESC
  LIMIT 1
)
WHERE
  metadata_id = 37; /* Change */

UPDATE statistics_short_term 
SET sum = sum + (
  SELECT (new_sum - sum) as correction_factor
  FROM
    statistics_short_term as SST, NT_PROD_NEW AS SN
  WHERE
    SST.metadata_id = 40 AND /* Change */
    SST.start_ts = SN.ts
  ORDER BY state DESC
  LIMIT 1
)
WHERE
  metadata_id = 40; /* Change */

UPDATE statistics_short_term 
SET sum = sum + (
  SELECT (new_sum - sum) as correction_factor
  FROM
    statistics_short_term as SST, LT_PROD_NEW AS SN
  WHERE
    SST.metadata_id = 39 AND /* Change */
    SST.start_ts = SN.ts
  ORDER BY state DESC
  LIMIT 1
)
WHERE
  metadata_id = 39; /* Change */

UPDATE statistics_short_term 
SET sum = sum + (
  SELECT (new_sum - sum) as correction_factor
  FROM
    statistics_short_term as SST, SOLAR_NEW AS SN
  WHERE
    SST.metadata_id = 7 AND /* Change */
    SST.start_ts = SN.ts
  ORDER BY state DESC
  LIMIT 1
)
WHERE
  metadata_id = 7; /* Change */

UPDATE statistics_short_term 
SET sum = sum + (
  SELECT (new_sum - sum) as correction_factor
  FROM
    statistics_short_term as SST, GAS_NEW AS SN
  WHERE
    SST.metadata_id = 2 AND /* Change */
    SST.start_ts = SN.ts
  ORDER BY state DESC
  LIMIT 1
)
WHERE
  metadata_id = 2; /* Change */
  
/* Remove the temporary tables */
DROP TABLE IF EXISTS NT_ORIG_NEW;
DROP TABLE IF EXISTS LT_ORIG_NEW;
DROP TABLE IF EXISTS NT_PROD_NEW;
DROP TABLE IF EXISTS LT_PROD_NEW;
DROP TABLE IF EXISTS SOLAR_NEW;
DROP TABLE IF EXISTS GAS_NEW;
    
DROP TABLE IF EXISTS energy_consumption_tarif_hoog_st;
DROP TABLE IF EXISTS energy_consumption_tarif_laag_st;
DROP TABLE IF EXISTS energy_production_tarif_hoog_st;
DROP TABLE IF EXISTS energy_production_tarif_laag_st;
DROP TABLE IF EXISTS energy_solar_st;
DROP TABLE IF EXISTS energy_gas_st;
DROP TABLE IF EXISTS energy_consumption_tarif_hoog;
DROP TABLE IF EXISTS energy_consumption_tarif_laag;
DROP TABLE IF EXISTS energy_production_tarif_hoog;
DROP TABLE IF EXISTS energy_production_tarif_laag;
DROP TABLE IF EXISTS energy_solar;
DROP TABLE IF EXISTS energy_gas;