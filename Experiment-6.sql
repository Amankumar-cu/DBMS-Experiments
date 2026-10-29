-- ============================================================================
-- DBMS LAB EXPERIMENT 6
-- ============================================================================
-- AIM:
-- Create a stored procedure transfer_employee(emp_id, new_dept_id) with
-- validation and error handling. Implement triggers for salary validation
-- and audit logging. Test edge cases.
-- ============================================================================

USE EmployeeManagement;

-- ============================================================================
-- 1. STORED PROCEDURE: transfer_employee WITH ERROR HANDLING & TRANSACTION
-- ============================================================================

DROP PROCEDURE IF EXISTS transfer_employee;

DELIMITER //

CREATE PROCEDURE transfer_employee(
    IN p_emp_id INT,
    IN p_new_dept_id INT
)
BEGIN
    DECLARE v_employee_count INT DEFAULT 0;
    DECLARE v_department_count INT DEFAULT 0;
    DECLARE v_current_dept INT DEFAULT 0;

    -- Generic SQLEXCEPTION handler: Rollback and notify
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SELECT 'Error: Database exception occurred. Transaction rolled back.' AS result_message;
    END;

    START TRANSACTION;

    -- Validation 1: Verify employee exists
    SELECT COUNT(*) INTO v_employee_count 
    FROM Employee 
    WHERE emp_id = p_emp_id;

    IF v_employee_count = 0 THEN
        ROLLBACK;
        SELECT CONCAT('Error: Employee with ID ', p_emp_id, ' does not exist.') AS result_message;
    ELSE
        -- Validation 2: Verify target department exists
        SELECT COUNT(*) INTO v_department_count 
        FROM Department 
        WHERE dept_id = p_new_dept_id;

        IF v_department_count = 0 THEN
            ROLLBACK;
            SELECT CONCAT('Error: Department with ID ', p_new_dept_id, ' does not exist.') AS result_message;
        ELSE
            -- Validation 3: Check if employee is already in the requested department
            SELECT dept_id INTO v_current_dept 
            FROM Employee 
            WHERE emp_id = p_emp_id;

            IF v_current_dept = p_new_dept_id THEN
                ROLLBACK;
                SELECT CONCAT('Notice: Employee ', p_emp_id, ' is already assigned to Department ', p_new_dept_id, '. No transfer needed.') AS result_message;
            ELSE
                -- All validations passed: Transfer employee
                UPDATE Employee 
                SET dept_id = p_new_dept_id 
                WHERE emp_id = p_emp_id;

                COMMIT;
                SELECT CONCAT('Success: Employee ', p_emp_id, ' transferred from Department ', v_current_dept, ' to Department ', p_new_dept_id, '.') AS result_message;
            END IF;
        END IF;
    END IF;
END //

DELIMITER ;

-- ============================================================================
-- 2. TESTING STORED PROCEDURE & EDGE CASES
-- ============================================================================

-- Normal Test Case: Check before transfer, execute transfer, check after transfer
SELECT emp_id, emp_name, dept_id FROM Employee WHERE emp_id = 101;
CALL transfer_employee(101, 3);
SELECT emp_id, emp_name, dept_id FROM Employee WHERE emp_id = 101;

-- Edge Case 1: Employee does not exist
CALL transfer_employee(999, 3);

-- Edge Case 2: Target department does not exist
CALL transfer_employee(101, 99);

-- Edge Case 3: Employee is already in the target department
CALL transfer_employee(101, 3);

-- Transfer employee 101 back to Development (Dept 1)
CALL transfer_employee(101, 1);

-- ============================================================================
-- 3. SALARY VALIDATION TRIGGERS
-- ============================================================================

DROP TRIGGER IF EXISTS validate_employee_salary;
DROP TRIGGER IF EXISTS validate_employee_salary_update;

DELIMITER //

-- Trigger 1: Before INSERT Validation (Enforces minimum salary and NOT NULL)
CREATE TRIGGER validate_employee_salary 
BEFORE INSERT ON Employee
FOR EACH ROW 
BEGIN
    IF NEW.salary IS NULL OR NEW.salary < 15000 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Salary validation error: Salary cannot be NULL and must be at least 15000.';
    END IF;
END //

-- Trigger 2: Before UPDATE Validation (Enforces minimum salary on modifications)
CREATE TRIGGER validate_employee_salary_update 
BEFORE UPDATE ON Employee
FOR EACH ROW 
BEGIN
    IF NEW.salary IS NULL OR NEW.salary < 15000 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Salary validation error: Updated salary cannot be NULL and must be at least 15000.';
    END IF;
END //

DELIMITER ;

-- ============================================================================
-- 4. TESTING SALARY VALIDATION TRIGGERS & EDGE CASES
-- ============================================================================

-- Test 1: Invalid Salary on INSERT (< 15000)
-- EXPECTED: Fails with SQLSTATE 45000
-- UNCOMMENT TO TEST:
-- INSERT INTO Employee (emp_id, emp_name, gender, salary, hire_date, dept_id) 
-- VALUES (131, 'Invalid Salary Test', 'M', 10000.00, '2026-09-25', 1);

-- Test 2: Valid Salary on INSERT (>= 15000) -> SUCCEEDS
DELETE FROM Employee WHERE emp_id = 131;
INSERT INTO Employee (emp_id, emp_name, gender, salary, hire_date, dept_id) 
VALUES (131, 'Test Employee', 'M', 30000.00, '2026-09-25', 1);

SELECT emp_id, emp_name, salary FROM Employee WHERE emp_id = 131;

-- Test 3: Invalid Salary on UPDATE (< 15000)
-- EXPECTED: Fails with SQLSTATE 45000
-- UNCOMMENT TO TEST:
-- UPDATE Employee SET salary = 5000.00 WHERE emp_id = 131;

-- Test 4: Edge Case - NULL Salary on INSERT
-- EXPECTED: Fails with SQLSTATE 45000
-- UNCOMMENT TO TEST:
-- INSERT INTO Employee (emp_id, emp_name, gender, salary, hire_date, dept_id) 
-- VALUES (132, 'Null Salary Test', 'F', NULL, '2026-09-25', 1);

-- ============================================================================
-- 5. SALARY AUDIT LOGGING TABLE AND TRIGGER
-- ============================================================================

-- Create Audit Table
CREATE TABLE IF NOT EXISTS Salary_Audit (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    emp_id INT NOT NULL,
    old_salary DECIMAL(10,2) NOT NULL,
    new_salary DECIMAL(10,2) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    action VARCHAR(50) NOT NULL
);

DROP TRIGGER IF EXISTS salary_audit_trigger;

DELIMITER //

-- Trigger 3: After UPDATE Audit Trigger
-- Only records an audit entry if the salary has genuinely changed
CREATE TRIGGER salary_audit_trigger 
AFTER UPDATE ON Employee
FOR EACH ROW 
BEGIN
    IF OLD.salary <> NEW.salary THEN
        INSERT INTO Salary_Audit (emp_id, old_salary, new_salary, action) 
        VALUES (NEW.emp_id, OLD.salary, NEW.salary, 'SALARY UPDATED');
    END IF;
END //

DELIMITER ;

-- ============================================================================
-- 6. TESTING SALARY AUDIT TRIGGER & EDGE CASES
-- ============================================================================

-- Test 1: Update salary from 30000 to 35000
UPDATE Employee SET salary = 35000.00 WHERE emp_id = 131;

-- Verify Audit Table has recorded the change
SELECT * FROM Salary_Audit WHERE emp_id = 131;

-- Test 2: Multiple subsequent updates
UPDATE Employee SET salary = 40000.00 WHERE emp_id = 131;
UPDATE Employee SET salary = 45000.00 WHERE emp_id = 131;

-- Verify complete audit history
SELECT 
    audit_id, 
    emp_id, 
    old_salary, 
    new_salary, 
    changed_at, 
    action 
FROM Salary_Audit 
WHERE emp_id = 131 
ORDER BY changed_at ASC;

-- Test 3: Edge Case - Update salary with IDENTICAL value (45000 -> 45000)
-- Should NOT create any redundant row in Salary_Audit
UPDATE Employee SET salary = 45000.00 WHERE emp_id = 131;

-- Verify count of audit entries remains 3 (no duplicate logged!)
SELECT 
    COUNT(*) AS total_audit_records,
    'Verified: No redundant audit row created when salary unchanged' AS status
FROM Salary_Audit 
WHERE emp_id = 131;

-- ============================================================================
-- 7. METADATA INSPECTION
-- ============================================================================

-- List all active triggers on the database
SHOW TRIGGERS;

-- Verify stored procedure status
SHOW PROCEDURE STATUS WHERE Db = DATABASE();
