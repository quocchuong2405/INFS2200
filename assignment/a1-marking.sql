-- INFS2200 Semester 2 2023 
-- Assignment 1 marking script
-- Alexander Jago a.jago@uq.edu.au
-- The domain: a public transport fare system which is a simplified version of TransLink's

-- Version 1.0

set feedback off;
-- Test framework
-- Before running this file, run
-- @@ TravelDB.sql
-- @@"s4123456.sql"
-- then this file

prompt
prompt Question 1.1 output should be above
pause (press enter to continue)

-- Catch them early
SHOW ERRORS;

-- General set-up
set feedback off;
set linesize 120;
set pagesize 80;
column stop_id format 'a12';
column stop_name format 'a30' word_wrapped;
column zone format 9999;
column charge format 999999;
column constraint_name format 'a20' word_wrapped;
column table_name format 'a10' word_wrapped;
column index_name format 'a10' word_wrapped;
column sequence_name format 'a60' word_wrapped;
column search_condition format 'a70' word_wrapped;
ALTER SESSION SET NLS_DATE_FORMAT='YYYY-MM-DD HH24:Mi:SS';
-- This is also a check for mis-named triggers
prompt Attempting to disable all 4 triggers here, any mis-named ones will cause an error...
alter trigger "BI_TAP_ID" disable;
alter trigger "BI_BASIC_FARES" disable;
alter trigger "BI_EIGHT_HALF" disable;
alter trigger "BI_CONTINUATIONS" disable;
-- We have to do this check here because triggers might interfere with testing 1.2
select trigger_name as "Misnamed or Extra Triggers"  
	from USER_TRIGGERS where status = 'ENABLED';
prompt Please exit and edit the submission if needed to correctly name the triggers (-0.5 marks each) then re-run
pause (otherwise, press enter to continue)


-- test Q1.1 by looking at code and output

-- Q1.2: re-run Q1.1 to show all constraints
prompt Q1.2: showing each constraint for reference
SELECT CONSTRAINT_NAME, CONSTRAINT_TYPE, 
		TABLE_NAME, SEARCH_CONDITION, INDEX_NAME 
	FROM USER_CONSTRAINTS
	WHERE TABLE_NAME IN ('STOPS', 'FARES', 'CUSTOMERS', 'TAPS') AND
	TABLE_NAME NOT LIKE 'SYS_%'
	ORDER BY CONSTRAINT_TYPE;

set termout on;
set serveroutput on format wrapped;
set feedback off;
prompt 
prompt Testing Q1.2 with inserts...
DECLARE
  -- First, declare and initialise the expected exceptions
  CHECK_CONSTRAINT_VIOLATED EXCEPTION;
  PRAGMA EXCEPTION_INIT(CHECK_CONSTRAINT_VIOLATED, -2290);
  UNIQUE_CONSTRAINT_VIOLATED EXCEPTION;
  PRAGMA EXCEPTION_INIT(UNIQUE_CONSTRAINT_VIOLATED, -1);
  INTEGRITY_CONSTRAINT_VIOLATED EXCEPTION;
  PRAGMA EXCEPTION_INIT(INTEGRITY_CONSTRAINT_VIOLATED, -2291);
  NULL_CONSTRAINT_VIOLATED EXCEPTION;
  PRAGMA EXCEPTION_INIT(NULL_CONSTRAINT_VIOLATED, -1400);
  marks NUMBER;
  issues NUMBER;
BEGIN
	marks := 0;
	BEGIN
		-- 4 PK_FARES
		INSERT INTO FARES VALUES (1, 'Concession', 400); 
		DBMS_OUTPUT.PUT_LINE('PK_FARES violation');
    EXCEPTION
	  WHEN UNIQUE_CONSTRAINT_VIOLATED THEN  -- catch the ORA-00001 exception
		marks := marks + 2;
		null; -- this was expected
	END;
	
	BEGIN
		-- 5 FK_STOP_ID
		INSERT INTO TAPS VALUES (2500, 1, 'notfound', to_date('2023-08-01'), 100); 
		DBMS_OUTPUT.PUT_LINE('FK_STOP_ID violation');
	EXCEPTION
		WHEN INTEGRITY_CONSTRAINT_VIOLATED THEN
			marks := marks + 2;
	END;	
	
	BEGIN
		-- 6 FK_CUST_ID
		INSERT INTO TAPS VALUES (2502, -1, '600000', to_date('2023-08-01'), 100); 
		DBMS_OUTPUT.PUT_LINE('FK_CUST_ID violation');
	EXCEPTION
		WHEN INTEGRITY_CONSTRAINT_VIOLATED THEN
			marks := marks + 2;
			null;
	END;
	
	BEGIN
		-- 7 CK_FARE_CLASS (incorrect value)
		INSERT INTO FARES VALUES (1, 'Other', 100); 
		DBMS_OUTPUT.PUT_LINE('CK_FARE_CLASS value violation');	
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 1;
	END;
	BEGIN
		-- 7 CK_FARE_CLASS (null value)
		INSERT INTO FARES VALUES (1, null, 100); 
		DBMS_OUTPUT.PUT_LINE('CK_FARE_CLASS null violation');	
	EXCEPTION
		WHEN NULL_CONSTRAINT_VIOLATED THEN
			marks := marks + 1;
	END;

	BEGIN
		-- 8 CK_CUST_CLASS (incorrect value)
		INSERT INTO CUSTOMERS VALUES (9001, 'Other');
		DBMS_OUTPUT.PUT_LINE('CK_CUST_CLASS value violation');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 1;
	END;
	BEGIN
		-- 8 CK_CUST_CLASS (null value)
		INSERT INTO CUSTOMERS VALUES (9000, NULL);		
		DBMS_OUTPUT.PUT_LINE('CK_CUST_CLASS null violation');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 1;
		WHEN NULL_CONSTRAINT_VIOLATED THEN
			marks := marks + 1;
	END;

	BEGIN
		-- 9 CK_FARE_AMOUNT (incorrect value)
		UPDATE FARES SET amount = 0 where zone_count = 1 and class = 'Concession';
		DBMS_OUTPUT.PUT_LINE('CK_FARE_AMOUNT value violation');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 1;
	END;
	BEGIN
		-- 9 CK_FARE_AMOUNT (null value)
		UPDATE FARES SET amount = null where zone_count = 1 and class = 'Concession';
		DBMS_OUTPUT.PUT_LINE('CK_FARE_AMOUNT null violation');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 1;
		WHEN NULL_CONSTRAINT_VIOLATED THEN
			marks := marks + 1;
	END;
	
	BEGIN
		-- 10 CK_STOP_ZONE (incorrect values)
		INSERT INTO STOPS VALUES ('fake-stop-1', 'Fake Stop 1', 0); 
		DBMS_OUTPUT.PUT_LINE('CK_STOP_ZONE value violation (low)');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 0.75;
	END;
	BEGIN
		-- 10 CK_STOP_ZONE (incorrect values)
		INSERT INTO STOPS VALUES ('fake-stop-2', 'Fake Stop 2', 9); 
		DBMS_OUTPUT.PUT_LINE('CK_STOP_ZONE value violation (high)');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 0.75;
	END;	
	BEGIN
		-- 10 CK_STOP_ZONE (null)
		INSERT INTO STOPS VALUES ('fake-stop-3', 'Fake Stop 3', null); 
		DBMS_OUTPUT.PUT_LINE('CK_STOP_ZONE null violation');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 0.5;
		WHEN NULL_CONSTRAINT_VIOLATED THEN
			marks := marks + 0.5;
	END;	

	BEGIN
		-- 11 CK_FARE_ZONE (values)
		INSERT INTO FARES VALUES (0, 'Adult', 100); 
		DBMS_OUTPUT.PUT_LINE('CK_FARE_ZONE value violation (adult low)');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 0.375;		
	END;
	BEGIN
		-- 11 CK_FARE_ZONE (values)
		INSERT INTO FARES VALUES (0, 'Concession', 100); 
		DBMS_OUTPUT.PUT_LINE('CK_FARE_ZONE value violation (concession low)');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 0.375;		
	END;
	BEGIN
		-- 11 CK_FARE_ZONE (values)
		INSERT INTO FARES VALUES (9, 'Adult', 100); 
		DBMS_OUTPUT.PUT_LINE('CK_FARE_ZONE value violation (adult high)');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 0.375;		
	END;
	BEGIN
		-- 11 CK_FARE_ZONE (values)
		INSERT INTO FARES VALUES (9, 'Concession', 100); 
		DBMS_OUTPUT.PUT_LINE('CK_FARE_ZONE value violation (concession high)');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 0.375;		
	END;
	
	BEGIN
		-- 11 CK_FARE_ZONE (nulls)
		INSERT INTO FARES VALUES (null, 'Adult', 100); 
		INSERT INTO FARES VALUES (null, 'Concession', 100); 
		DBMS_OUTPUT.PUT_LINE('CK_FARE_ZONE null violation');
	EXCEPTION
		WHEN NULL_CONSTRAINT_VIOLATED THEN
			marks := marks + 0.5;
	END;



	BEGIN
		-- 12 CK_TAP_CHARGE (value)
		INSERT INTO TAPS VALUES (2503, 1, '600000', to_date('2023-08-01'), -100);
		DBMS_OUTPUT.PUT_LINE('CK_TAP_CHARGE value violation');	
	EXCEPTION
	WHEN CHECK_CONSTRAINT_VIOLATED THEN
		marks := marks + 1;
	WHEN NULL_CONSTRAINT_VIOLATED THEN
			marks := marks + 1;
	END;
	BEGIN
		-- 12 CK_TAP_CHARGE (nulls)
		INSERT INTO TAPS VALUES (2504, 1, '600000', to_date('2023-08-01'), null);
		DBMS_OUTPUT.PUT_LINE('CK_TAP_CHARGE null violation');	
	EXCEPTION
	WHEN CHECK_CONSTRAINT_VIOLATED THEN
		marks := marks + 1;
	WHEN NULL_CONSTRAINT_VIOLATED THEN
			marks := marks + 1;
	END;

	BEGIN
		-- 13 CK_TIMESTAMP
		INSERT INTO TAPS VALUES (2505, 1, '600000', null, 0);
		DBMS_OUTPUT.PUT_LINE('CK_TIMESTAMP violation');
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 2;		
		WHEN NULL_CONSTRAINT_VIOLATED THEN
			marks := marks + 2;
	END;

	BEGIN
		-- 14 CK_STOP_ID
		INSERT INTO TAPS VALUES (2506, 1, null, to_date('2023-08-01'), 0);
		DBMS_OUTPUT.PUT_LINE('CK_STOP_ID violation');	
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 2;		
		WHEN NULL_CONSTRAINT_VIOLATED THEN
			marks := marks + 2;
	END;

	BEGIN
		-- 15 CK_CUST_ID
		INSERT INTO TAPS VALUES (2507, null, '600000', to_date('2023-08-01'), 0);
		DBMS_OUTPUT.PUT_LINE('CK_CUST_ID violation');	
	EXCEPTION
		WHEN CHECK_CONSTRAINT_VIOLATED THEN
			marks := marks + 2;		
		WHEN NULL_CONSTRAINT_VIOLATED THEN
			marks := marks + 2;
	END;
	DBMS_OUTPUT.PUT_LINE('');
	DBMS_OUTPUT.PUT_LINE('***** ' || TO_CHAR(marks / 4.0) || ' marks for Q1.2. *****');	
	DBMS_OUTPUT.PUT_LINE('');
END;
/


select COLUMN_VALUE as "Missing/misnamed for Q1" 
	FROM table(sys.dbms_debug_vc2coll('PK_CUST_ID', 'PK_STOP_ID', 'PK_TAP_ID',
	'PK_FARES', 'FK_STOP_ID', 'FK_CUST_ID',
	'CK_FARE_CLASS', 'CK_CUST_CLASS', 'CK_FARE_AMOUNT', 
	'CK_STOP_ZONE', 'CK_FARE_ZONE', 'CK_TAP_CHARGE', 
	'CK_TIMESTAMP', 'CK_STOP_ID', 'CK_CUST_ID')) MINUS
	(select constraint_name from USER_CONSTRAINTS where TABLE_NAME in ('CUSTOMERS', 'FARES', 'STOPS', 'TAPS'));

pause Q1.1 and Q1.2 complete (press enter to continue)


-- NOTE: Q1.1 to Q2.2 is very easy for ChatGPT to generate
-- To be fair, it's also very easy to Google.


-- Q2.3
-- Trigger to fill in Taps.amount based on the Fares table (no continuations)

-- TESTING for Q2.1, Q2.2, Q2.3
-- Trial inserts 

-- Create two new customers for testing
DELETE FROM TAPS WHERE customer_id >= 9000;
DELETE FROM CUSTOMERS WHERE customer_id >= 9000;
INSERT INTO CUSTOMERS (customer_id, class) VALUES (9000, 'Adult');
INSERT INTO CUSTOMERS (customer_id, class) VALUES (9001, 'Concession');
INSERT INTO CUSTOMERS (customer_id, class) VALUES (9002, 'Adult');

-- Test for hardcoding throughout by adding 2 cents to all fares
DELETE FROM FARES;
INSERT INTO FARES VALUES(1,'Adult',400);
INSERT INTO FARES VALUES(1,'Concession',200);
INSERT INTO FARES VALUES(2,'Adult',700);
INSERT INTO FARES VALUES(2,'Concession',350);
INSERT INTO FARES VALUES(3,'Adult',1000);
INSERT INTO FARES VALUES(3,'Concession',500);
INSERT INTO FARES VALUES(4,'Adult',1300);
INSERT INTO FARES VALUES(4,'Concession',650);
INSERT INTO FARES VALUES(5,'Adult',1600);
INSERT INTO FARES VALUES(5,'Concession',800);
INSERT INTO FARES VALUES(6,'Adult',1900);
INSERT INTO FARES VALUES(6,'Concession',950);
INSERT INTO FARES VALUES(7,'Adult',2200);
INSERT INTO FARES VALUES(7,'Concession',1100);
INSERT INTO FARES VALUES(8,'Adult',2500);
INSERT INTO FARES VALUES(8,'Concession',1250);
UPDATE FARES SET amount = amount + 2;
-- SELECT * FROM FARES;

-- Now we have this Results table just for testing so that we can compare to it
CREATE TABLE Results (tap_id INT, customer_id INT, stop_id VARCHAR2(15), timestamp DATE, charge INT);
-- Q2.2
INSERT INTO Results VALUES(3000,9001,'600000','2023-05-01 12:34:56',0);
INSERT INTO Results VALUES(3001,9001,'600010','2023-05-01 13:45:07',202);
-- Q2.3 zones 1-4 basic
INSERT INTO Results VALUES(3002,9001,'600000','2023-06-01 12:34:56',0);
INSERT INTO Results VALUES(3010,9000,'600000','2023-06-01 12:34:56',0);
INSERT INTO Results VALUES(3003,9001,'600010','2023-06-01 13:45:07',202);
INSERT INTO Results VALUES(3011,9000,'600010','2023-06-01 13:45:07',402);
INSERT INTO Results VALUES(3004,9001,'600000','2023-06-02 12:34:56',0);
INSERT INTO Results VALUES(3012,9000,'600000','2023-06-02 12:34:56',0);
INSERT INTO Results VALUES(3005,9001,'600390','2023-06-02 13:45:07',352);
INSERT INTO Results VALUES(3013,9000,'600390','2023-06-02 13:45:07',702);
INSERT INTO Results VALUES(3006,9001,'600000','2023-06-03 12:34:56',0);
INSERT INTO Results VALUES(3014,9000,'600000','2023-06-03 12:34:56',0);
INSERT INTO Results VALUES(3007,9001,'600087','2023-06-03 13:45:07',502);
INSERT INTO Results VALUES(3015,9000,'600087','2023-06-03 13:45:07',1002);
INSERT INTO Results VALUES(3008,9001,'600000','2023-06-04 12:34:56',0);
INSERT INTO Results VALUES(3016,9000,'600000','2023-06-04 12:34:56',0);
INSERT INTO Results VALUES(3009,9001,'600241','2023-06-04 13:45:07',652);
INSERT INTO Results VALUES(3017,9000,'600241','2023-06-04 13:45:07',1302);
-- Q2.3 zones 5-8 and interleaved
INSERT INTO Results VALUES(3018,9001,'600000','2023-06-05 12:34:56',0);
INSERT INTO Results VALUES(3019,9000,'600000','2023-06-05 12:34:56',0);
INSERT INTO Results VALUES(3020,9001,'600118','2023-06-05 13:45:07',802);
INSERT INTO Results VALUES(3021,9000,'600118','2023-06-05 13:45:07',1602);
INSERT INTO Results VALUES(3022,9001,'600000','2023-06-06 12:34:56',0);
INSERT INTO Results VALUES(3023,9000,'600000','2023-06-06 12:34:56',0);
INSERT INTO Results VALUES(3024,9001,'600117','2023-06-06 13:45:07',952);
INSERT INTO Results VALUES(3025,9000,'600117','2023-06-06 13:45:07',1902);
INSERT INTO Results VALUES(3026,9000,'600000','2023-06-07 12:34:56',0);
INSERT INTO Results VALUES(3027,9001,'600000','2023-06-07 12:34:56',0);
INSERT INTO Results VALUES(3029,9000,'600494','2023-06-07 13:45:07',2202);
INSERT INTO Results VALUES(3029,9001,'600494','2023-06-07 13:45:07',1102);
INSERT INTO Results VALUES(3030,9000,'600000','2023-06-08 12:34:56',0);
INSERT INTO Results VALUES(3031,9001,'600000','2023-06-08 12:34:56',0);
INSERT INTO Results VALUES(3032,9000,'600496','2023-06-08 13:45:07',2502);
INSERT INTO Results VALUES(3033,9001,'600496','2023-06-08 13:45:07',1252);
-- Q2.4 Trips 1-8
INSERT INTO Results VALUES(3034,9001,'600000','2023-07-01 11:34:56',0);
INSERT INTO Results VALUES(3035,9000,'600000','2023-07-01 11:34:56',0);
INSERT INTO Results VALUES(3036,9001,'600010','2023-07-01 11:45:07',202);
INSERT INTO Results VALUES(3037,9000,'600010','2023-07-01 11:45:07',402);
INSERT INTO Results VALUES(3038,9001,'600000','2023-07-01 12:34:56',0);
INSERT INTO Results VALUES(3039,9000,'600000','2023-07-01 12:34:56',0);
INSERT INTO Results VALUES(3040,9001,'600390','2023-07-01 12:45:07',352);
INSERT INTO Results VALUES(3041,9000,'600390','2023-07-01 12:45:07',702);
INSERT INTO Results VALUES(3042,9001,'600000','2023-07-01 13:34:56',0);
INSERT INTO Results VALUES(3043,9000,'600000','2023-07-01 13:34:56',0);
INSERT INTO Results VALUES(3044,9001,'600087','2023-07-01 13:45:07',502);
INSERT INTO Results VALUES(3045,9000,'600087','2023-07-01 13:45:07',1002);
INSERT INTO Results VALUES(3046,9001,'600000','2023-07-01 14:34:56',0);
INSERT INTO Results VALUES(3047,9000,'600000','2023-07-01 14:34:56',0);
INSERT INTO Results VALUES(3048,9001,'600241','2023-07-01 14:45:07',652);
INSERT INTO Results VALUES(3049,9000,'600241','2023-07-01 14:45:07',1302);
INSERT INTO Results VALUES(3050,9001,'600000','2023-07-01 15:34:56',0);
INSERT INTO Results VALUES(3051,9000,'600000','2023-07-01 15:34:56',0);
INSERT INTO Results VALUES(3052,9001,'600118','2023-07-01 15:45:07',802);
INSERT INTO Results VALUES(3053,9000,'600118','2023-07-01 15:45:07',1602);
INSERT INTO Results VALUES(3054,9001,'600000','2023-07-01 16:34:56',0);
INSERT INTO Results VALUES(3055,9000,'600000','2023-07-01 16:34:56',0);
INSERT INTO Results VALUES(3056,9001,'600117','2023-07-01 16:45:07',952);
INSERT INTO Results VALUES(3057,9000,'600117','2023-07-01 16:45:07',1902);
INSERT INTO Results VALUES(3058,9001,'600000','2023-07-01 17:34:56',0);
INSERT INTO Results VALUES(3059,9000,'600000','2023-07-01 17:34:56',0);
INSERT INTO Results VALUES(3060,9001,'600494','2023-07-01 17:45:07',1102);
INSERT INTO Results VALUES(3061,9000,'600494','2023-07-01 17:45:07',2202);
INSERT INTO Results VALUES(3062,9001,'600000','2023-07-01 18:34:56',0);
INSERT INTO Results VALUES(3063,9000,'600000','2023-07-01 18:34:56',0);
INSERT INTO Results VALUES(3064,9001,'600496','2023-07-01 18:45:07',1252);
INSERT INTO Results VALUES(3065,9000,'600496','2023-07-01 18:45:07',2502);
-- Q2.4 Trips 9-16
INSERT INTO Results VALUES(3066,9001,'600000','2023-07-02 12:34:56',0);
INSERT INTO Results VALUES(3067,9000,'600000','2023-07-02 12:34:56',0);
INSERT INTO Results VALUES(3068,9001,'600010','2023-07-02 13:45:07',101);
INSERT INTO Results VALUES(3069,9000,'600010','2023-07-02 13:45:07',201);
INSERT INTO Results VALUES(3070,9001,'600000','2023-07-02 18:34:56',0);
INSERT INTO Results VALUES(3071,9000,'600000','2023-07-02 18:34:56',0);
INSERT INTO Results VALUES(3072,9001,'600390','2023-07-02 19:45:07',176);
INSERT INTO Results VALUES(3073,9000,'600390','2023-07-02 19:45:07',351);
INSERT INTO Results VALUES(3074,9001,'600000','2023-07-03 12:34:56',0);
INSERT INTO Results VALUES(3075,9000,'600000','2023-07-03 12:34:56',0);
INSERT INTO Results VALUES(3076,9001,'600087','2023-07-03 13:45:07',251);
INSERT INTO Results VALUES(3077,9000,'600087','2023-07-03 13:45:07',501);
INSERT INTO Results VALUES(3078,9001,'600000','2023-07-03 18:34:56',0);
INSERT INTO Results VALUES(3079,9000,'600000','2023-07-03 18:34:56',0);
INSERT INTO Results VALUES(3080,9001,'600241','2023-07-03 19:45:07',326);
INSERT INTO Results VALUES(3081,9000,'600241','2023-07-03 19:45:07',651);
INSERT INTO Results VALUES(3082,9001,'600000','2023-07-04 12:34:56',0);
INSERT INTO Results VALUES(3083,9000,'600000','2023-07-04 12:34:56',0);
INSERT INTO Results VALUES(3084,9001,'600118','2023-07-04 13:45:07',401);
INSERT INTO Results VALUES(3085,9000,'600118','2023-07-04 13:45:07',801);
INSERT INTO Results VALUES(3086,9001,'600000','2023-07-04 18:34:56',0);
INSERT INTO Results VALUES(3087,9000,'600000','2023-07-04 18:34:56',0);
INSERT INTO Results VALUES(3088,9001,'600117','2023-07-04 19:45:07',476);
INSERT INTO Results VALUES(3089,9000,'600117','2023-07-04 19:45:07',951);
INSERT INTO Results VALUES(3090,9001,'600000','2023-07-05 12:34:56',0);
INSERT INTO Results VALUES(3091,9000,'600000','2023-07-05 12:34:56',0);
INSERT INTO Results VALUES(3092,9001,'600494','2023-07-05 13:45:07',551);
INSERT INTO Results VALUES(3093,9000,'600494','2023-07-05 13:45:07',1101);
INSERT INTO Results VALUES(3094,9001,'600000','2023-07-05 18:34:56',0);
INSERT INTO Results VALUES(3095,9000,'600000','2023-07-05 18:34:56',0);
INSERT INTO Results VALUES(3096,9001,'600496','2023-07-05 19:45:07',626);
INSERT INTO Results VALUES(3097,9000,'600496','2023-07-05 19:45:07',1251);
-- Q2.4 Timing edge cases
INSERT INTO Results VALUES(3098,9001,'600000','2023-07-09 11:34:45',0);
INSERT INTO Results VALUES(3099,9000,'600000','2023-07-09 11:34:45',0);
INSERT INTO Results VALUES(3100,9001,'600010','2023-07-09 12:34:44',101);
INSERT INTO Results VALUES(3101,9000,'600010','2023-07-09 12:34:44',201);
INSERT INTO Results VALUES(3102,9001,'600000','2023-07-09 18:23:45',0);
INSERT INTO Results VALUES(3103,9000,'600000','2023-07-09 18:23:45',0);
INSERT INTO Results VALUES(3104,9001,'600010','2023-07-09 18:34:57',202);
INSERT INTO Results VALUES(3105,9000,'600010','2023-07-09 18:34:57',402);

-- Q2.5 (a) same zone continuation
INSERT INTO Results VALUES(3106,9001,'1132','2023-08-01 08:12:34',0);
INSERT INTO Results VALUES(3107,9002,'1132','2023-08-01 08:12:34',0);
INSERT INTO Results VALUES(3108,9001,'40','2023-08-01 08:30:07',202);
INSERT INTO Results VALUES(3109,9002,'40','2023-08-01 08:30:07',402);
INSERT INTO Results VALUES(3110,9001,'40','2023-08-01 08:36:07',0);
INSERT INTO Results VALUES(3111,9002,'40','2023-08-01 08:36:07',0);
INSERT INTO Results VALUES(3112,9001,'4509','2023-08-01 09:14:56',0);
INSERT INTO Results VALUES(3113,9002,'4509','2023-08-01 09:14:56',0);
-- Q2.5 (b) new zone continuation
INSERT INTO Results VALUES(3114,9001,'319296','2023-08-02 06:12:34',0);
INSERT INTO Results VALUES(3115,9002,'319296','2023-08-02 06:12:34',0);
INSERT INTO Results VALUES(3116,9001,'319144','2023-08-02 06:22:07',202);
INSERT INTO Results VALUES(3117,9002,'319144','2023-08-02 06:22:07',402);
INSERT INTO Results VALUES(3118,9001,'600089','2023-08-02 06:28:07',0);
INSERT INTO Results VALUES(3119,9002,'600089','2023-08-02 06:28:07',0);
INSERT INTO Results VALUES(3120,9001,'600024','2023-08-02 07:14:56',300);
INSERT INTO Results VALUES(3121,9002,'600024','2023-08-02 07:14:56',600);
-- Q2.5 (c) non-continuation
INSERT INTO Results VALUES(3122,9001,'1132','2023-08-03 08:12:34',0);
INSERT INTO Results VALUES(3123,9002,'1132','2023-08-03 08:12:34',0);
INSERT INTO Results VALUES(3124,9001,'40','2023-08-03 08:30:07',202);
INSERT INTO Results VALUES(3125,9002,'40','2023-08-03 08:30:07',402);
INSERT INTO Results VALUES(3126,9001,'40','2023-08-03 09:30:08',0);
INSERT INTO Results VALUES(3127,9002,'40','2023-08-03 09:30:08',0);
INSERT INTO Results VALUES(3128,9001,'4509','2023-08-03 10:14:56',202);
INSERT INTO Results VALUES(3129,9002,'4509','2023-08-03 10:14:56',402);
INSERT INTO Results VALUES(3130,9001,'600331','2023-08-04 09:12:34',0);
INSERT INTO Results VALUES(3131,9002,'600331','2023-08-04 09:12:34',0);
INSERT INTO Results VALUES(3132,9001,'600089','2023-08-04 09:32:34',352);
INSERT INTO Results VALUES(3133,9002,'600089','2023-08-04 09:32:34',702);
-- Q2.5 (d) multi-leg continuation
INSERT INTO Results VALUES(3134,9001,'319144','2023-08-04 09:35:07',0);
INSERT INTO Results VALUES(3135,9002,'319144','2023-08-04 09:35:07',0);
INSERT INTO Results VALUES(3136,9001,'319297','2023-08-04 09:45:34',0);
INSERT INTO Results VALUES(3137,9002,'319297','2023-08-04 09:45:34',0);
INSERT INTO Results VALUES(3138,9001,'319296','2023-08-04 10:23:45',0);
INSERT INTO Results VALUES(3139,9002,'319296','2023-08-04 10:23:45',0);
INSERT INTO Results VALUES(3140,9001,'319144','2023-08-04 10:34:56',0);
INSERT INTO Results VALUES(3141,9002,'319144','2023-08-04 10:34:56',0);
INSERT INTO Results VALUES(3142,9001,'600089','2023-08-04 10:40:12',0);
INSERT INTO Results VALUES(3143,9002,'600089','2023-08-04 10:40:12',0);
INSERT INTO Results VALUES(3144,9001,'600024','2023-08-04 11:31:23',150);
INSERT INTO Results VALUES(3145,9002,'600024','2023-08-04 11:31:23',300);
INSERT INTO Results VALUES(3146,9001,'36','2023-08-04 11:45:07',0);
INSERT INTO Results VALUES(3147,9002,'36','2023-08-04 11:45:07',0);
INSERT INTO Results VALUES(3148,9001,'1132','2023-08-04 12:03:45',0);
INSERT INTO Results VALUES(3149,9002,'1132','2023-08-04 12:03:45',0);
INSERT INTO Results VALUES(3150,9001,'1132','2023-08-04 12:46:24',0);
INSERT INTO Results VALUES(3151,9002,'1132','2023-08-04 12:46:24',0);
INSERT INTO Results VALUES(3152,9001,'40','2023-08-04 13:06:07',0);
INSERT INTO Results VALUES(3153,9002,'40','2023-08-04 13:06:07',0);
INSERT INTO Results VALUES(3154,9001,'600019','2023-08-04 13:26:24',0);
INSERT INTO Results VALUES(3155,9002,'600019','2023-08-04 13:26:24',0);
INSERT INTO Results VALUES(3156,9001,'600331','2023-08-04 14:06:07',0);
INSERT INTO Results VALUES(3157,9002,'600331','2023-08-04 14:06:07',0);
-- Q2.5 edge case (semi-contiguous continuation)
INSERT INTO Results VALUES(3158,9001,'600024','2023-08-05 12:34:56',0);
INSERT INTO Results VALUES(3159,9002,'600024','2023-08-05 12:34:56',0);
INSERT INTO Results VALUES(3160,9001,'600632','2023-08-05 14:56:08',952);
INSERT INTO Results VALUES(3161,9002,'600632','2023-08-05 14:56:08',1902);
INSERT INTO Results VALUES(3162,9001,'600500','2023-08-05 15:56:07',0);
INSERT INTO Results VALUES(3163,9002,'600500','2023-08-05 15:56:07',0);
INSERT INTO Results VALUES(3164,9001,'600495','2023-08-05 16:23:45',300);
INSERT INTO Results VALUES(3165,9002,'600495','2023-08-05 16:23:45',600);

-- Marking by trip, not by tap
create view CorrectTrips as
with CustTaps as 
(select row_number() over 
	(partition by customer_id order by timestamp, tap_id) as rn, 
	tap_id, customer_id, stop_id, timestamp, charge
	from Taps),
ResultTaps as 
(select row_number() over 
	(partition by customer_id order by timestamp, tap_id) as rn, 
	tap_id, customer_id, stop_id, timestamp, charge
	from Results),
CustTrips as
(select customer_id, 
	B.stop_id as board_stop, B.timestamp as board_time, B.charge as board_charge,
	A.stop_id as alight_stop, A.timestamp as alight_time, A.charge as alight_charge
	from CustTaps A join CustTaps B 
	using (customer_id)
	where mod(A.rn, 2) = 0 
	and A.rn = B.rn + 1
	and B.charge = 0),
ResultTrips as
(select customer_id, 
	B.stop_id as board_stop, B.timestamp as board_time, B.charge as board_charge,
	A.stop_id as alight_stop, A.timestamp as alight_time, A.charge as alight_charge
	from ResultTaps A join ResultTaps B 
	using (customer_id)
	where mod(A.rn, 2) = 0 
	and A.rn = B.rn + 1
	and B.charge = 0)
select *
	from CustTrips join ResultTrips
	using (customer_id, board_stop, board_time, board_charge, alight_stop, alight_time, alight_charge);

prompt
prompt ***** QUESTION 2 ******

select sequence_name, last_number, min_value, INCREMENT_BY from user_sequences;
prompt Q2.1: 0.5 marks for correct name (TAP_ID_SEQ), 1 mark for starting at 3000, 1 mark for incrementing by 1 
pause (press enter to continue)

select trigger_name from user_triggers;
prompt 0.5 marks each for Q2.2, Q2.3, Q2.4, Q2.5 for correct naming (which should be the case by here)
show errors trigger BI_TAP_ID;
show errors trigger BI_BASIC_FARES;
show errors trigger BI_EIGHT_HALF;
show errors trigger BI_CONTINUATIONS;
prompt 0.5 marks each for Q2.2, Q2.3, Q2.4, Q2.5 when no compilation errors

pause (press enter to continue)

prompt
prompt Testing Q2.1, Q2.2
prompt 

ALTER TRIGGER "BI_TAP_ID" ENABLE;

INSERT INTO Taps (customer_id, stop_id, timestamp, charge)	
	VALUES (9001, '600000', TO_DATE('2023-05-01 12:34:56', 'YYYY-MM-DD HH24:MI:SS'), 0);
INSERT INTO Taps (customer_id, stop_id, timestamp, charge)
	VALUES (9001, '600010', TO_DATE('2023-05-01 13:45:07', 'YYYY-MM-DD HH24:MI:SS'), 202);

select count(*) as "Q2.2 test-case marks" 
from Results join Taps using (tap_id, customer_id, stop_id, timestamp);

pause Q2.1, Q2.2 done (press enter to continue)


ALTER TRIGGER "BI_BASIC_FARES" ENABLE;

-- Test one-zone trip (concession)
INSERT INTO Taps (customer_id, stop_id, timestamp)	
	VALUES (9001, '600000', TO_DATE('2023-06-01 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600010', TO_DATE('2023-06-01 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... two-zone trip 
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-06-02 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600390', TO_DATE('2023-06-02 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... three-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-06-03 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600087', TO_DATE('2023-06-03 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... four-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-06-04 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600241', TO_DATE('2023-06-04 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));

-- Test one-zone trip (adult)
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-06-01 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600010', TO_DATE('2023-06-01 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... two-zone trip 
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-06-02 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600390', TO_DATE('2023-06-02 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... three-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-06-03 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600087', TO_DATE('2023-06-03 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... four-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-06-04 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600241', TO_DATE('2023-06-04 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));

-- Interleave trips to ensure against e.g. tap_id - 1

-- ... five-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-06-05 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-06-05 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600118', TO_DATE('2023-06-05 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600118', TO_DATE('2023-06-05 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... six-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-06-06 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-06-06 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600117', TO_DATE('2023-06-06 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600117', TO_DATE('2023-06-06 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... seven-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-06-07 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-06-07 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600494', TO_DATE('2023-06-07 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600494', TO_DATE('2023-06-07 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... eight-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-06-08 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-06-08 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600496', TO_DATE('2023-06-08 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600496', TO_DATE('2023-06-08 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));

-- Charge for customer 9001 so far should be 0, 202, 0, 202, 0, 352, 0, 502, 0, 652, 0, 802, 0, 952, 0, 1102, 0, 1252
-- (repeat one-zone fare to test Q2.2)
-- prompt Charge for customer 9000 should be 0, 402, 0, 702, 0, 1002, 0, 1302, 0, 1602, 0, 1902, 0, 2202, 0, 2502

select customer_id, timestamp, stop_id, zone, Taps.tap_id, Taps.charge, Results.tap_id as true_tap_id, Results.charge as true_charge, class
from Results left join Taps using (customer_id, timestamp, stop_id) join Stops using (stop_id) join Customers using (customer_id)
where ((Taps.charge != Results.charge) or (Taps.charge is null))
and timestamp between TO_DATE('2023-06-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') and TO_DATE('2023-07-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
order by timestamp asc;
prompt Any incorrect rows are above:

-- 1/32nd mark for each correct row
select count(*) * 0.09375 as "Q2.3 test-case marks" 
from Results join Taps using (customer_id, stop_id, timestamp, charge)
where timestamp between TO_DATE('2023-06-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') and TO_DATE('2023-07-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

pause Q2.3 done (press enter to continue)

-- 2.4 Eight then free (no continuations)

ALTER TRIGGER "BI_BASIC_FARES" DISABLE;
ALTER TRIGGER "BI_EIGHT_HALF" ENABLE;

-- Testing for 2.4

-- First set up eight trips in the week by repeating 2.3 all in one day.
-- If anyone has incorrectly dome eight-lifetime rather than eight-in-seven days, this will also catch that.
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-01 11:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-01 11:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600010', TO_DATE('2023-07-01 11:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600010', TO_DATE('2023-07-01 11:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-01 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-01 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600390', TO_DATE('2023-07-01 12:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600390', TO_DATE('2023-07-01 12:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-01 13:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-01 13:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600087', TO_DATE('2023-07-01 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600087', TO_DATE('2023-07-01 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-01 14:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-01 14:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600241', TO_DATE('2023-07-01 14:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600241', TO_DATE('2023-07-01 14:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-01 15:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-01 15:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600118', TO_DATE('2023-07-01 15:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600118', TO_DATE('2023-07-01 15:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-01 16:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-01 16:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600117', TO_DATE('2023-07-01 16:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600117', TO_DATE('2023-07-01 16:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-01 17:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-01 17:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600494', TO_DATE('2023-07-01 17:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600494', TO_DATE('2023-07-01 17:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-01 18:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-01 18:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600496', TO_DATE('2023-07-01 18:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600496', TO_DATE('2023-07-01 18:45:07', 'YYYY-MM-DD HH24:MI:SS'));

-- Test eight-then-half eligible
-- Test one-zone trip 
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-02 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-02 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600010', TO_DATE('2023-07-02 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600010', TO_DATE('2023-07-02 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... two-zone trip 
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-02 18:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-02 18:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600390', TO_DATE('2023-07-02 19:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600390', TO_DATE('2023-07-02 19:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... three-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-03 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-03 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600087', TO_DATE('2023-07-03 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600087', TO_DATE('2023-07-03 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... four-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-03 18:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-03 18:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600241', TO_DATE('2023-07-03 19:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600241', TO_DATE('2023-07-03 19:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... five-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-04 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-04 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600118', TO_DATE('2023-07-04 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600118', TO_DATE('2023-07-04 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... six-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-04 18:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-04 18:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600117', TO_DATE('2023-07-04 19:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600117', TO_DATE('2023-07-04 19:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... seven-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-05 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-05 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600494', TO_DATE('2023-07-05 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600494', TO_DATE('2023-07-05 13:45:07', 'YYYY-MM-DD HH24:MI:SS'));
-- ... eight-zone trip
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-05 18:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-05 18:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600496', TO_DATE('2023-07-05 19:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600496', TO_DATE('2023-07-05 19:45:07', 'YYYY-MM-DD HH24:MI:SS'));
	
-- test having the eighth trip just inside the window
-- this actually reveals some edge cases that might need a re-think
-- because trip #9 needs to *finish* less than 168 hours after trip #1 started
-- (at least per the sample solution)
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-09 11:34:45', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-09 11:34:45', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600010', TO_DATE('2023-07-09 12:34:44', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600010', TO_DATE('2023-07-09 12:34:44', 'YYYY-MM-DD HH24:MI:SS'));
-- test just outside the window
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600000', TO_DATE('2023-07-09 18:23:45', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600000', TO_DATE('2023-07-09 18:23:45', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600010', TO_DATE('2023-07-09 18:34:57', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9000, '600010', TO_DATE('2023-07-09 18:34:57', 'YYYY-MM-DD HH24:MI:SS'));

select customer_id, timestamp, stop_id, zone, Taps.tap_id, Taps.charge, Results.tap_id as true_tap_id, Results.charge as true_charge, class
from Results left join Taps using (customer_id, timestamp, stop_id) join Stops using (stop_id) join Customers using (customer_id)
where ((Taps.charge != Results.charge) or (Taps.charge is null))
and timestamp between TO_DATE('2023-07-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') and TO_DATE('2023-07-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS')
order by timestamp asc;

prompt Any incorrect results for Q2.4 are above.
/*
-- 1/32nd mark for base case (1 mark total)
select count(*) * 0.03125 as "Q2.4 trips 1-8 marks"
from Results join Taps using (customer_id, stop_id, timestamp, charge)
where timestamp between TO_DATE('2023-07-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') and TO_DATE('2023-07-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
-- 1/16th mark for discount case (2 marks total)
select count(*) * 0.0625 as "Q2.4 trips 9-16 marks"
from Results join Taps using (customer_id, stop_id, timestamp, charge)
where timestamp between TO_DATE('2023-07-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS') and TO_DATE('2023-07-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
-- 1/4th mark for edge cases (2 marks total)
select count(*) * 0.25 as "Q2.4 edge case marks"
from Results join Taps using (customer_id, stop_id, timestamp, charge)
where timestamp between TO_DATE('2023-07-09 00:00:00', 'YYYY-MM-DD HH24:MI:SS') and TO_DATE('2023-07-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
*/

select count(*) / 16.0 as "Q2.4 Trips 1-8 marks"
from CorrectTrips where board_time > TO_DATE('2023-07-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
and alight_time < TO_DATE('2023-07-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

select count(*) / 8.0 as "Q2.4 Trips 9-16 marks"
from CorrectTrips where board_time > TO_DATE('2023-07-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
and alight_time < TO_DATE('2023-07-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

select count(*) / 2.0 as "Q2.5 edge case marks"
from CorrectTrips where board_time > TO_DATE('2023-07-09 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
and alight_time < TO_DATE('2023-07-10 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

pause Q2.4 done (press enter to continue)

-- 2.5 Continuations (no eight-then-half)

alter trigger "BI_EIGHT_HALF" disable;
alter trigger "BI_BASIC_FARES" disable;
alter trigger "BI_CONTINUATIONS" enable;

-- show errors;

-- Testing for 2.5

-- Test Continuation

-- Test Example A
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '1132', TO_DATE('2023-08-01 08:12:34', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '1132', TO_DATE('2023-08-01 08:12:34', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '40', TO_DATE('2023-08-01 08:30:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '40', TO_DATE('2023-08-01 08:30:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '40', TO_DATE('2023-08-01 08:36:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '40', TO_DATE('2023-08-01 08:36:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '4509', TO_DATE('2023-08-01 09:14:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '4509', TO_DATE('2023-08-01 09:14:56', 'YYYY-MM-DD HH24:MI:SS'));

-- Test Example B
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '319296', TO_DATE('2023-08-02 06:12:34', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '319296', TO_DATE('2023-08-02 06:12:34', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '319144', TO_DATE('2023-08-02 06:22:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '319144', TO_DATE('2023-08-02 06:22:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600089', TO_DATE('2023-08-02 06:28:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600089', TO_DATE('2023-08-02 06:28:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600024', TO_DATE('2023-08-02 07:14:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600024', TO_DATE('2023-08-02 07:14:56', 'YYYY-MM-DD HH24:MI:SS'));

-- Test Example C
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '1132', TO_DATE('2023-08-03 08:12:34', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '1132', TO_DATE('2023-08-03 08:12:34', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '40', TO_DATE('2023-08-03 08:30:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '40', TO_DATE('2023-08-03 08:30:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '40', TO_DATE('2023-08-03 09:30:08', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '40', TO_DATE('2023-08-03 09:30:08', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '4509', TO_DATE('2023-08-03 10:14:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '4509', TO_DATE('2023-08-03 10:14:56', 'YYYY-MM-DD HH24:MI:SS'));

-- Test Example D
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600331', TO_DATE('2023-08-04 09:12:34', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600331', TO_DATE('2023-08-04 09:12:34', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600089', TO_DATE('2023-08-04 09:32:34', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600089', TO_DATE('2023-08-04 09:32:34', 'YYYY-MM-DD HH24:MI:SS'));
		
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '319144', TO_DATE('2023-08-04 09:35:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '319144', TO_DATE('2023-08-04 09:35:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '319297', TO_DATE('2023-08-04 09:45:34', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '319297', TO_DATE('2023-08-04 09:45:34', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '319296', TO_DATE('2023-08-04 10:23:45', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '319296', TO_DATE('2023-08-04 10:23:45', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '319144', TO_DATE('2023-08-04 10:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '319144', TO_DATE('2023-08-04 10:34:56', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600089', TO_DATE('2023-08-04 10:40:12', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600089', TO_DATE('2023-08-04 10:40:12', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600024', TO_DATE('2023-08-04 11:31:23', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600024', TO_DATE('2023-08-04 11:31:23', 'YYYY-MM-DD HH24:MI:SS'));

INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '36', TO_DATE('2023-08-04 11:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '36', TO_DATE('2023-08-04 11:45:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '1132', TO_DATE('2023-08-04 12:03:45', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '1132', TO_DATE('2023-08-04 12:03:45', 'YYYY-MM-DD HH24:MI:SS'));
		
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '1132', TO_DATE('2023-08-04 12:46:24', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '1132', TO_DATE('2023-08-04 12:46:24', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '40', TO_DATE('2023-08-04 13:06:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '40', TO_DATE('2023-08-04 13:06:07', 'YYYY-MM-DD HH24:MI:SS'));		

INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600019', TO_DATE('2023-08-04 13:26:24', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600019', TO_DATE('2023-08-04 13:26:24', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600331', TO_DATE('2023-08-04 14:06:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600331', TO_DATE('2023-08-04 14:06:07', 'YYYY-MM-DD HH24:MI:SS'));		

-- Test Edge Case E semi-contiguous
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600024', TO_DATE('2023-08-05 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600024', TO_DATE('2023-08-05 12:34:56', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600632', TO_DATE('2023-08-05 14:56:08', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600632', TO_DATE('2023-08-05 14:56:08', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600500', TO_DATE('2023-08-05 15:56:07', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600500', TO_DATE('2023-08-05 15:56:07', 'YYYY-MM-DD HH24:MI:SS'));	
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9001, '600495', TO_DATE('2023-08-05 16:23:45', 'YYYY-MM-DD HH24:MI:SS'));
INSERT INTO Taps (customer_id, stop_id, timestamp)
	VALUES (9002, '600495', TO_DATE('2023-08-05 16:23:45', 'YYYY-MM-DD HH24:MI:SS'));	

-- Show incorrect rows for 2.5
select customer_id, timestamp, stop_id, zone, Taps.tap_id, Taps.charge, Results.tap_id as true_tap_id, Results.charge as true_charge, class
from Results left join Taps using (customer_id, timestamp, stop_id) join Stops using (stop_id) join Customers using (customer_id)
where ((Taps.charge != Results.charge) or (Taps.charge is null))
and (timestamp between TO_DATE('2023-08-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') and TO_DATE('2023-08-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS'))
order by timestamp asc;

prompt Any incorrect rows (taps) for Q2.5 are above.

select count(*) * 0.25 as "Q2.5 example A marks"
from CorrectTrips where board_time > TO_DATE('2023-08-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
and alight_time < TO_DATE('2023-08-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

select count(*) * 0.25 as "Q2.5 example B marks"
from CorrectTrips where board_time > TO_DATE('2023-08-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
and alight_time < TO_DATE('2023-08-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

select count(*) * 0.25 as "Q2.5 example C marks"
from CorrectTrips where board_time > TO_DATE('2023-08-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
and alight_time < TO_DATE('2023-08-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

select count(*) * (3.0/14.0) as "Q2.5 example D marks"
from CorrectTrips where board_time > TO_DATE('2023-08-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
and alight_time < TO_DATE('2023-08-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

select count(*) * 0.25 as "Q2.5 example E marks"
from CorrectTrips where board_time > TO_DATE('2023-08-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS') 
and alight_time < TO_DATE('2023-08-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS');

prompt Q2.5 done
prompt 

pause press enter to finish

drop view CorrectTrips;
drop table results;

