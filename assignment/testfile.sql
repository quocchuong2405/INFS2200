INSERT INTO CUSTOMERS VALUES(100,'Adult');
INSERT INTO CUSTOMERS VALUES(101,'Adult');
INSERT INTO CUSTOMERS VALUES(102,'Adult');
INSERT INTO CUSTOMERS VALUES(103,'Concession');
INSERT INTO CUSTOMERS VALUES(104,'Concession');
INSERT INTO CUSTOMERS VALUES(105,'Concession');


SELECT customer_id, tap_id, count(*)
FROM TAPS
WHERE customer_id = 2


SELECT count(*)
FROM TAPS
WHERE customer_id = 201

SELECT * FROM STOPS

SELECT stop_id
FROM TAPS
WHERE tap_id = (SELECT MAX(tap_id) FROM TAPS WHERE customer_id = 2);

SELECT *
FROM TAPS
WHERE customer_id = 201

--1	Adult	400
--1	Concession	200
--2	Adult	700
--2	Concession	350
--3	Adult	1000
--3	Concession	500
--4	Adult	1300
--4	Concession	650
--5	Adult	1600
--5	Concession	800
--6	Adult	1900
--6	Concession	950
--7	Adult	2200
--7	Concession	1100
--8	Adult	2500
--8	Concession	1250


--  STOPS (stop_id VARCHAR2(15), stop_name VARCHAR2(60), zone INT);
--STOPS VALUES('1','Herschel Street Stop 1 near North Quay',1);
--STOPS VALUES('10','Ann Street Stop 10 at King George Square',1);
--STOPS VALUES('100','Parliament Stop 94A Margaret St',1);
--STOPS VALUES('1000','Handford Rd at Songbird Way',2);
--STOPS VALUES('10000','Balcara Ave near Allira Cr',2);
--STOPS VALUES('10001','Nudgee Rd at Golf Course, stop 35/32',2);
--STOPS VALUES('10002','Nudgee Rd at Golf Course, stop 32/35',2);
--STOPS VALUES('10003','Approach Rd near Mellifont St, stop 31',2);
--
--STOPS VALUES('300215','Nerang Broadbeach Rd at Fairway Drive',5);
--STOPS VALUES('300216','Griffith St at Coolangatta East',6);
--STOPS VALUES('301407','Old Coach Rd near Coomera Springs Bvd',4);

-- ######################### TEST 2.3 ###################################
-- TAPS (tap_id INT, customer_id INT, stop_id VARCHAR2(15), timestamp DATE, charge INT);
-- CASE 1: ADULT
-- Tap-on event
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (101, '1', TO_DATE('2023-08-12 18:14:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
-- Tap-off event
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (101, '1000', TO_DATE('2023-08-12 19:14:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 2

-- -> Fare = (2 - 1) + 1 = 2 => 700
-- CASE 2: ADULT
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (101, '1', TO_DATE('2023-08-12 19:14:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
-- Tap-off event
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (101, '300215', TO_DATE('2023-08-12 20:14:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 5
-- -> Fare = abs(1 - 5) + 1 = 5 => 1600

-- CASE 3: Concession
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (103, '300215', TO_DATE('2023-08-12 19:14:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 5
-- Tap-off event
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (103, '1', TO_DATE('2023-08-12 20:14:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
-- -> Fare = abs(1 - 5) + 1 = 5 => Concession => 800
-- ######################### TEST 2.3 END ###################################




INSERT INTO CUSTOMERS VALUES(200,'Adult');
INSERT INTO CUSTOMERS VALUES(201,'Adult');
INSERT INTO CUSTOMERS VALUES(202,'Adult');
INSERT INTO CUSTOMERS VALUES(203,'Concession');
INSERT INTO CUSTOMERS VALUES(204,'Concession');
INSERT INTO CUSTOMERS VALUES(205,'Concession');

-- 1
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '1', TO_DATE('2023-09-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '1000', TO_DATE('2023-09-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 2
-- 2
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '1', TO_DATE('2023-09-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '300215', TO_DATE('2023-09-02 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 5
-- 3
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '301407', TO_DATE('2023-09-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 4
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '1000', TO_DATE('2023-09-03 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
-- 4
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '301407', TO_DATE('2023-09-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 4
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '300215', TO_DATE('2023-09-04 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 5
-- 5
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '301407', TO_DATE('2023-09-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 4
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '1', TO_DATE('2023-09-05 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
-- 6
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '1', TO_DATE('2023-09-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '10', TO_DATE('2023-09-06 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
-- 7
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '1', TO_DATE('2023-09-06 01:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '100', TO_DATE('2023-09-06 01:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
-- 8
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '301407', TO_DATE('2023-09-07 01:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 4
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '300215', TO_DATE('2023-09-07 01:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 5


-- 9 -- In range
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '1', TO_DATE('2023-09-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '10', TO_DATE('2023-09-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1

-- 10 -- Out of range
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '1', TO_DATE('2023-09-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1
INSERT INTO TAPS (customer_id, stop_id, timestamp)
VALUES (201, '10', TO_DATE('2023-09-13 00:00:00', 'YYYY-MM-DD HH24:MI:SS')); -- Zone 1



-- drop
DELETE FROM TAPS WHERE tap_id = 3022;
DELETE FROM TAPS WHERE tap_id = 3023;
DELETE FROM TAPS WHERE tap_id = 3024;
DELETE FROM TAPS WHERE tap_id = 3025;


SELECT *
FROM TAPS
WHERE customer_id = 201

SELECT count(*)
FROM TAPS 
WHERE customer_id = 201
AND timestamp >= TO_DATE('2023-09-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS') - INTERVAL '7' DAY
AND timestamp <= TO_DATE('2023-09-08 00:00:00', 'YYYY-MM-DD HH24:MI:SS');
