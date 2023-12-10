-------------------------- TASK 1 --------------------------------

-- Task 1.1 
-- Write an SQL statement to find out which constraints have been created
-- on the four tables CUSTOMER, FARES, STOPS and TAPS.

SELECT * FROM USER_CONSTRAINTS

--ALTER TABLE CUSTOMERS ADD CONSTRAINT PK_CUST_ID PRIMARY KEY (customer_id);
--ALTER TABLE STOPS ADD CONSTRAINT PK_STOP_ID PRIMARY KEY (stop_id);
--ALTER TABLE TAPS ADD CONSTRAINT PK_TAP_ID PRIMARY KEY (tap_id);

-- Task 1.2

-- 4: PK_FARES
ALTER TABLE FARES ADD CONSTRAINT PK_FARES PRIMARY KEY (zone_count, class);

-- 5: FK_STOP_ID
ALTER TABLE TAPS ADD CONSTRAINT FK_STOP_ID FOREIGN KEY (stop_id) REFERENCES STOPS(stop_id);

-- 6: FK_CUST_ID
ALTER TABLE TAPS ADD CONSTRAINT FK_CUST_ID FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id);

-- 7: CK_FARE_CLASS
ALTER TABLE FARES ADD CONSTRAINT CK_FARE_CLASS CHECK (class IN ( 'Adult', 'Concession') AND class IS NOT NULL);

-- 8: CK_CUST_CLASS
ALTER TABLE CUSTOMERS ADD CONSTRAINT CK_CUST_CLASS CHECK (class IN ('Adult', 'Concession') AND class IS NOT NULL);

-- 9: CK_FARE_AMOUNT
ALTER TABLE FARES ADD CONSTRAINT CK_FARE_AMOUNT CHECK (amount > 0 AND amount IS NOT NULL);

-- 10: CK_STOP_ZONE
ALTER TABLE STOPS ADD CONSTRAINT CK_STOP_ZONE CHECK ((zone BETWEEN 1 AND 8) AND zone IS NOT NULL);

-- 11: CK_FARE_ZONE
ALTER TABLE FARES ADD CONSTRAINT CK_FARE_ZONE CHECK ((zone_count BETWEEN 1 AND 8) AND zone_count IS NOT NULL);

-- 12: CK_TAP_CHARGE
ALTER TABLE TAPS ADD CONSTRAINT CK_TAP_CHARGE CHECK (charge >= 0 AND charge IS NOT NULL);

-- 13: CK_TIMESTAMP
ALTER TABLE TAPS ADD CONSTRAINT CK_TIMESTAMP CHECK (timestamp IS NOT NULL);

-- 14: CK_CUST_ID
ALTER TABLE TAPS ADD CONSTRAINT CK_CUST_ID CHECK (customer_id IS NOT NULL);

-- 15: CK_STOP_ID
ALTER TABLE TAPS ADD CONSTRAINT CK_STOP_ID CHECK (stop_id IS NOT NULL);

----------------------------------------------------------------------

----------------------------- TASK 2 ---------------------------------

-- Task 2.1
CREATE SEQUENCE "TAP_ID_SEQ" INCREMENT BY 1 START WITH 3000;

-- Task 2.2
CREATE OR REPLACE TRIGGER "BI_TAP_ID" 
BEFORE INSERT ON "TAPS"
FOR EACH ROW
BEGIN
    SELECT "TAP_ID_SEQ".NEXTVAL INTO :NEW.tap_id FROM DUAL;
END;
/

-- Task 2.3
CREATE OR REPLACE TRIGGER "BI_BASIC_FARES"
BEFORE INSERT ON TAPS
FOR EACH ROW
DECLARE
    tap_cur_zone STOPS.zone%TYPE;
    tap_on_zone STOPS.zone%TYPE;
    fare_amount FARES.amount%TYPE;
    fare_class FARES.class%TYPE;
    tap_count INT;
BEGIN
    -- Get the tap zone for the current tap
    SELECT zone
    INTO tap_cur_zone
    FROM STOPS
    WHERE stop_id = :NEW.stop_id;

    -- Get the fare class for the customer
    SELECT class
    INTO fare_class
    FROM CUSTOMERS
    WHERE customer_id = :NEW.customer_id;

    -- Count the number of taps for the customer
    SELECT COUNT(*)
    INTO tap_count
    FROM TAPS
    WHERE customer_id = :NEW.customer_id;

    -- Check the tap_count is even or not 
    -- If yes, it's a tap-off event
    -- Calculate previous tap-on zone and charge
    IF MOD(tap_count, 2) = 1 THEN
        SELECT zone
        INTO tap_on_zone
        FROM STOPS
        WHERE stop_id = (
            SELECT stop_id
            FROM TAPS
            WHERE tap_id = (SELECT MAX(tap_id)
                            FROM TAPS
                            WHERE customer_id = :NEW.customer_id)
        );

        SELECT amount
        INTO fare_amount
        FROM FARES
        WHERE zone_count = ABS(tap_cur_zone - tap_on_zone) + 1 AND class = fare_class;

        -- Update the charge for the tap-off record
        :NEW.charge := fare_amount;
    ELSE
        :NEW.charge := 0; -- Tap-on charge
    END IF;
END;
/





-- Task 2.4
CREATE OR REPLACE TRIGGER "BI_EIGHT_HALF"
BEFORE INSERT ON TAPS
FOR EACH ROW
DECLARE
	tap_cur_zone STOPS.zone%TYPE;
    tap_on_zone STOPS.zone%TYPE;
    fare_amount FARES.amount%TYPE;
    fare_class FARES.class%TYPE;
    tap_count INT := 0;
    tap_count_seven_days INT := 0;
BEGIN
	-- Get the tap zone for the current tap
    SELECT zone INTO tap_cur_zone
    FROM STOPS
    WHERE stop_id = :NEW.stop_id;

    SELECT class INTO fare_class
    FROM CUSTOMERS
    WHERE customer_id = :NEW.customer_id;
    
    -- Count the number of taps for the customer
    SELECT COUNT(*)
    INTO tap_count
    FROM TAPS
    WHERE customer_id = :NEW.customer_id;
    
	-- Check the tap_count is even or not 
    -- If not, it's a tap-off event
    -- Calculate previous tap-on zone and charge
	IF MOD(tap_count, 2) = 1 THEN
		SELECT zone
        INTO tap_on_zone
        FROM STOPS
        WHERE stop_id = (
            SELECT stop_id
            FROM TAPS
            WHERE tap_id = (SELECT MAX(tap_id)
                            FROM TAPS
                            WHERE customer_id = :NEW.customer_id)
        );

        SELECT amount
        INTO fare_amount
        FROM FARES
        WHERE zone_count = ABS(tap_on_zone - tap_cur_zone) + 1 
		AND class = fare_class;
		
		-- Check the tap count for this customer in the last seven days
		SELECT COUNT(*)
		INTO tap_count_seven_days
		FROM TAPS
		WHERE customer_id = :NEW.customer_id
			AND timestamp >= :NEW.timestamp - INTERVAL '7' DAY
			AND timestamp <= :NEW.timestamp; 
        
		-- Update the charge for the tap-off record
		-- 17 means 9th tap-off
		IF tap_count_seven_days >= 17 THEN 
			-- Half-price
			:NEW.charge := fare_amount / 2;
		ELSE
			:NEW.charge := fare_amount;
		END IF;
    ELSE
        :NEW.charge := 0; -- Tap-on charge
    END IF;
END;
/


-- Task 2.5
-- Actually, I'm stuck with this.
CREATE OR REPLACE TRIGGER "BI_CONTINUATIONS"
BEFORE INSERT ON TAPS
FOR EACH ROW
DECLARE
	tap_cur_zone STOPS.zone%TYPE;
    tap_on_zone STOPS.zone%TYPE;
    fare_amount FARES.amount%TYPE;
    fare_class FARES.class%TYPE;
    tap_count INT := 0;
    tap_count_seven_days INT := 0;
BEGIN
	-- Get the tap zone for the current tap
    SELECT zone INTO tap_cur_zone
    FROM STOPS
    WHERE stop_id = :NEW.stop_id;

    SELECT class INTO fare_class
    FROM CUSTOMERS
    WHERE customer_id = :NEW.customer_id;
    
    -- Count the number of taps for the customer
    SELECT COUNT(*)
    INTO tap_count
    FROM TAPS
    WHERE customer_id = :NEW.customer_id;
    
	-- Check the tap_count is even or not 
    -- If not, it's a tap-off event
    -- Calculate previous tap-on zone and charge
	IF MOD(tap_count, 2) = 1 THEN
		SELECT zone
        INTO tap_on_zone
        FROM STOPS
        WHERE stop_id = (
            SELECT stop_id
            FROM TAPS
            WHERE tap_id = (SELECT MAX(tap_id)
                            FROM TAPS
                            WHERE customer_id = :NEW.customer_id)
        );

        SELECT amount
        INTO fare_amount
        FROM FARES
        WHERE zone_count = ABS(tap_on_zone - tap_cur_zone) + 1 
		AND class = fare_class;
		
		-- Check the tap count for this customer in the last seven days
		SELECT COUNT(*)
		INTO tap_count_seven_days
		FROM TAPS
		WHERE customer_id = :NEW.customer_id
			AND timestamp >= :NEW.timestamp - INTERVAL '7' DAY
			AND timestamp <= :NEW.timestamp; 
        
		-- Update the charge for the tap-off record
		-- 17 means 9th tap-off
		IF tap_count_seven_days >= 17 THEN 
			-- Half-price
			:NEW.charge := fare_amount / 2;
		ELSE
			:NEW.charge := fare_amount;
		END IF;
    ELSE
        :NEW.charge := 0; -- Tap-on charge
    END IF;
END;
/
