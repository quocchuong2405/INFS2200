SET TIMING ON;

-- 1.1
SELECT s_parent.stop_name AS station_name, SUM(t.charge) AS revenue
FROM TAPS t
JOIN STOPS s ON s.stop_id = t.stop_id
JOIN STOPS s_parent ON s.parent_station = s_parent.stop_id
GROUP BY s_parent.stop_name
ORDER BY revenue DESC
FETCH FIRST 10 ROWS ONLY;


-- 1.2
SELECT s_parent.stop_name AS station_name, SUM(t.charge) AS revenue
FROM TAPS t
JOIN STOPS s ON s.stop_id = t.stop_id
JOIN STOPS s_parent ON s.parent_station = s_parent.stop_id
JOIN CUSTOMERS c ON t.customer_id = c.customer_id
WHERE c."class" = 'Concession'
    AND (t.charge >= 350)
GROUP BY s_parent.stop_name
ORDER BY revenue DESC
FETCH FIRST 10 ROWS ONLY;


-- 1.3
CREATE OR REPLACE VIEW V_STATION_BOARDINGS AS
SELECT
    s_parent.stop_name AS station_name,
    TO_CHAR(t."timestamp", 'Day') AS DOW,
    c."class" AS fare_class,
    COUNT(*) AS boardings
FROM TAPS t
JOIN STOPS s ON t.stop_id = s.stop_id
JOIN STOPS s_parent ON s.parent_station = s_parent.stop_id
JOIN CUSTOMERS c ON t.customer_id = c.customer_id
WHERE t.charge = 0
GROUP BY
    s_parent.stop_name,
    TO_CHAR(t."timestamp", 'D'),
    TO_CHAR("timestamp", 'Day'),
    c."class"
ORDER BY
    s_parent.stop_name,
    TO_NUMBER(TO_CHAR(t."timestamp", 'D')),
    c."class";
	

-- 1.4
CREATE MATERIALIZED VIEW MV_STATION_BOARDINGS
AS
SELECT
    s_parent.stop_name AS station_name,
    TO_CHAR(t."timestamp", 'Day') AS DOW,
    c."class" AS fare_class,
    COUNT(*) AS boardings
FROM TAPS t
JOIN STOPS s ON t.stop_id = s.stop_id
JOIN STOPS s_parent ON s.parent_station = s_parent.stop_id
JOIN CUSTOMERS c ON t.customer_id = c.customer_id
WHERE t.charge = 0
GROUP BY
    s_parent.stop_name,
    TO_CHAR(t."timestamp", 'D'),
    TO_CHAR("timestamp", 'Day'),
    c."class"
ORDER BY
    s_parent.stop_name,
    TO_NUMBER(TO_CHAR(t."timestamp", 'D')),
    c."class";

    

-- 1.5
EXPLAIN PLAN FOR
SELECT * FROM V_STATION_BOARDINGS;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


EXPLAIN PLAN FOR
SELECT * FROM MV_STATION_BOARDINGS;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


-- 2.1 453
SELECT *
FROM STOPS s
WHERE REGEXP_INSTR(s.stop_name, '^B[aeiouyAEIOUY]*[R|r]{1,2}[aeiouyAEIOUY]*[B|b]| B[aeiouyAEIOUY]*[R|r]{1,2}[aeiouyAEIOUY]*[B|b]|^K[aeiouyAEIOUY]+[N|n]| K[aeiouyAEIOUY]+[N|n]') > 0
ORDER BY s.stop_name;


--EXPLAIN PLAN FOR
--SELECT *
--FROM STOPS s
--WHERE REGEXP_INSTR(s.stop_name, '^B[aeiouyAEIOUY]*[R|r]{1,2}[aeiouyAEIOUY]*[B|b]| B[aeiouyAEIOUY]*[R|r]{1,2}[aeiouyAEIOUY]*[B|b]|^K[aeiouyAEIOUY]+[N|n]| K[aeiouyAEIOUY]+[N|n]') > 0
--ORDER BY s.stop_name;
--SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


-- 2.2 
CREATE OR REPLACE FUNCTION MyFunctionBasedIndex(p_string IN VARCHAR2) RETURN NUMBER DETERMINISTIC
IS
BEGIN
  RETURN REGEXP_INSTR(p_string, '^B[aeiouyAEIOUY]*[R|r]{1,2}[aeiouyAEIOUY]*[B|b]| B[aeiouyAEIOUY]*[R|r]{1,2}[aeiouyAEIOUY]*[B|b]|^K[aeiouyAEIOUY]+[N|n]| K[aeiouyAEIOUY]+[N|n]');
END;
/
CREATE INDEX IDX_PINK ON STOPS(MyFunctionBasedIndex(stop_name));

-- 2.3
EXPLAIN PLAN FOR
SELECT /*+ INDEX(s IDX_PINK) */ *
FROM STOPS s
WHERE MyFunctionBasedIndex(s.stop_name) > 0
ORDER BY s.stop_name;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);


-- 2.4
SELECT COUNT(*)
FROM TAPS t1
WHERE EXISTS (
	SELECT charge
	FROM TAPS t2
	WHERE t1.customer_id = t2.customer_id
	AND t1.stop_id = t2.stop_id
	AND t1.charge = t2.charge
	AND t2.charge > 0
	GROUP BY t2.customer_id, t2.stop_id, t2.charge
	HAVING COUNT(*) >= 201
);


-- 2.5
CREATE BITMAP INDEX BIDX_CUST_ID
ON TAPS (customer_id);

CREATE BITMAP INDEX BIDX_STOP_ID
ON TAPS (stop_id);

CREATE BITMAP INDEX BIDX_CHARGE
ON TAPS (charge);


-- 3.1.A
ANALYZE INDEX PK_TAPID VALIDATE STRUCTURE;
SELECT Height
FROM INDEX_STATS;

-- 3.1.B
SELECT LF_BLKS
FROM INDEX_STATS;

-- 3.1.C
SELECT BLOCKS
FROM USER_TABLES
WHERE TABLE_NAME = 'TAPS';


-- 3.2
ALTER SESSION SET OPTIMIZER_MODE = RULE;
EXPLAIN PLAN FOR
SELECT * FROM TAPS
WHERE tap_id > 100;
SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);

-- 3.3
ALTER SESSION SET OPTIMIZER_MODE = CHOOSE;
EXPLAIN PLAN FOR
SELECT * FROM TAPS
WHERE tap_id > 100;
SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);

-- 3.4
ALTER SESSION SET OPTIMIZER_MODE = CHOOSE;
EXPLAIN PLAN FOR
SELECT * FROM TAPS
WHERE tap_id > 73900;
SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);

-- 3.5
ALTER SESSION SET OPTIMIZER_MODE = CHOOSE;
EXPLAIN PLAN FOR
SELECT * FROM TAPS
WHERE tap_id = 10000;
SELECT PLAN_TABLE_OUTPUT FROM TABLE (DBMS_XPLAN.DISPLAY);