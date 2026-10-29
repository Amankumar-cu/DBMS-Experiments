-- ============================================================================
-- DBMS LAB EXPERIMENT 5
-- ============================================================================
-- AIM:
-- Create SQL views for department salary summary and employee hierarchy.
-- Test updatability of views. Implement a recursive CTE to display reporting chains.
-- ============================================================================

USE EmployeeManagement;

-- ============================================================================
-- 1. DEPARTMENT SALARY SUMMARY VIEW
-- ============================================================================

-- Create View: Department_Salary_Summary
CREATE OR REPLACE VIEW Department_Salary_Summary AS 
SELECT 
    d.dept_id, 
    d.dept_name, 
    COUNT(e.emp_id) AS total_employees, 
    SUM(e.salary) AS total_salary, 
    AVG(e.salary) AS average_salary, 
    MAX(e.salary) AS highest_salary, 
    MIN(e.salary) AS lowest_salary 
FROM Department d 
LEFT JOIN Employee e ON d.dept_id = e.dept_id 
GROUP BY d.dept_id, d.dept_name;

-- Query the view
SELECT * FROM Department_Salary_Summary;

-- Query the view with conditions (Departments with avg salary > 75,000)
SELECT 
    dept_name, 
    average_salary, 
    total_employees 
FROM Department_Salary_Summary 
WHERE average_salary > 75000;

-- ============================================================================
-- 2. EMPLOYEE HIERARCHY SETUP
-- ============================================================================

-- Add self-referencing manager foreign key column
-- (Using procedure or conditional check to avoid duplicate column errors on rerun)
SET @col_exists := (
    SELECT COUNT(*) 
    FROM information_schema.COLUMNS 
    WHERE TABLE_SCHEMA = 'EmployeeManagement' 
      AND TABLE_NAME = 'Employee' 
      AND COLUMN_NAME = 'manager_id'
);

SET @alter_sql := IF(
    @col_exists = 0, 
    'ALTER TABLE Employee ADD COLUMN manager_id INT NULL, ADD CONSTRAINT fk_employee_manager FOREIGN KEY (manager_id) REFERENCES Employee(emp_id) ON UPDATE CASCADE ON DELETE SET NULL', 
    'SELECT "manager_id column already exists" AS info'
);

PREPARE stmt FROM @alter_sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Populate Organizational Hierarchy across Departments

-- Department Heads (Top Managers with no manager)
UPDATE Employee SET manager_id = NULL WHERE emp_id IN (105, 112, 114, 122, 125);

-- 1. Development Department Hierarchy (Lead: 105 Reyansh Kapoor)
UPDATE Employee SET manager_id = 105 WHERE emp_id IN (103, 104);
UPDATE Employee SET manager_id = 103 WHERE emp_id IN (101, 102);
UPDATE Employee SET manager_id = 104 WHERE emp_id = 106;

-- 2. Human Resources Hierarchy (Lead: 112 Saanvi Desai)
UPDATE Employee SET manager_id = 112 WHERE emp_id IN (107, 108);
UPDATE Employee SET manager_id = 107 WHERE emp_id = 109;
UPDATE Employee SET manager_id = 108 WHERE emp_id IN (110, 111);

-- 3. Accounting Hierarchy (Lead: 114 Navya Pillai)
UPDATE Employee SET manager_id = 114 WHERE emp_id IN (113, 115);
UPDATE Employee SET manager_id = 113 WHERE emp_id IN (116, 117);
UPDATE Employee SET manager_id = 115 WHERE emp_id = 118;

-- 4. Sales Hierarchy (Lead: 122 Pari Anand)
UPDATE Employee SET manager_id = 122 WHERE emp_id IN (119, 120);
UPDATE Employee SET manager_id = 119 WHERE emp_id = 121;
UPDATE Employee SET manager_id = 120 WHERE emp_id IN (123, 124);

-- 5. Innovation Hierarchy (Lead: 125 Atharv Reddy)
UPDATE Employee SET manager_id = 125 WHERE emp_id IN (126, 127, 128);
UPDATE Employee SET manager_id = 126 WHERE emp_id = 129;
UPDATE Employee SET manager_id = 128 WHERE emp_id = 130;

-- ============================================================================
-- 3. EMPLOYEE HIERARCHY VIEW
-- ============================================================================

-- Create View: Employee_Hierarchy
CREATE OR REPLACE VIEW Employee_Hierarchy AS 
SELECT 
    e.emp_id, 
    e.emp_name AS employee_name, 
    e.manager_id, 
    IFNULL(m.emp_name, 'TOP LEVEL / HEAD') AS manager_name, 
    e.salary, 
    e.dept_id,
    d.dept_name
FROM Employee e 
LEFT JOIN Employee m ON e.manager_id = m.emp_id
LEFT JOIN Department d ON e.dept_id = d.dept_id;

-- Query the hierarchy view
SELECT * FROM Employee_Hierarchy ORDER BY dept_id, manager_id;

-- ============================================================================
-- 4. VIEW UPDATABILITY TESTING
-- ============================================================================

-- TEST 1: Updatable View (Simple view with 1:1 mapping to base table rows)
CREATE OR REPLACE VIEW Employee_Basic AS 
SELECT 
    emp_id, 
    emp_name, 
    salary, 
    dept_id 
FROM Employee;

-- Perform update through the updatable view
UPDATE Employee_Basic 
SET salary = 79000.00 
WHERE emp_id = 101;

-- Verify update propagated directly to the underlying Employee base table
SELECT 
    emp_id, 
    emp_name, 
    salary 
FROM Employee 
WHERE emp_id = 101;

-- TEST 2: Non-Updatable View (Aggregate view with GROUP BY and aggregate functions)
-- Attempting to update an aggregate column in a complex view will be REJECTED.
-- EXPECTED: Error 1288 (HY000): The target table Department_Salary_Summary of the UPDATE is not updatable
-- UNCOMMENT TO TEST:
-- UPDATE Department_Salary_Summary 
-- SET average_salary = 80000 
-- WHERE dept_id = 1;

-- ============================================================================
-- 5. RECURSIVE COMMON TABLE EXPRESSIONS (CTE)
-- ============================================================================

-- Recursive CTE 1: Complete Organizational Reporting Hierarchy (Top-Down)
WITH RECURSIVE EmployeeChain AS (
    -- Anchor Member: Top-level managers with NULL manager_id (Level 0)
    SELECT 
        emp_id, 
        emp_name, 
        manager_id, 
        0 AS level, 
        CAST(emp_name AS CHAR(500)) AS reporting_chain 
    FROM Employee 
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive Member: Subordinates pointing to current level
    SELECT 
        e.emp_id, 
        e.emp_name, 
        e.manager_id, 
        ec.level + 1, 
        CONCAT(ec.reporting_chain, ' -> ', e.emp_name) 
    FROM Employee e 
    INNER JOIN EmployeeChain ec ON e.manager_id = ec.emp_id
)
SELECT 
    emp_id, 
    emp_name, 
    manager_id, 
    level, 
    reporting_chain 
FROM EmployeeChain 
ORDER BY level, reporting_chain;

-- Recursive CTE 2: Reporting Chain for a Specific Employee (Bottom-Up to Root)
WITH RECURSIVE ReportingChain AS (
    -- Anchor Member: Target employee (Aarush Khanna, emp_id = 101)
    SELECT 
        emp_id, 
        emp_name, 
        manager_id, 
        0 AS level 
    FROM Employee 
    WHERE emp_id = 101

    UNION ALL

    -- Recursive Member: Traverse upwards to the employee's manager
    SELECT 
        e.emp_id, 
        e.emp_name, 
        e.manager_id, 
        rc.level + 1 
    FROM Employee e 
    JOIN ReportingChain rc ON e.emp_id = rc.manager_id
)
SELECT 
    emp_id, 
    emp_name, 
    manager_id, 
    level 
FROM ReportingChain;
