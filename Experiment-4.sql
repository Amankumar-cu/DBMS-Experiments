-- ============================================================================
-- DBMS LAB EXPERIMENT 4
-- ============================================================================
-- AIM:
-- Using the Employee schema, write queries with INNER JOIN, LEFT JOIN,
-- self-join, 3-way join, correlated subqueries, EXISTS, and simulated
-- INTERSECT and EXCEPT. Compare execution plans using EXPLAIN.
-- ============================================================================

USE EmployeeManagement;

-- ============================================================================
-- 1. ADVANCED JOINS
-- ============================================================================

-- Q1. INNER JOIN: Retrieve employee details alongside their assigned department
SELECT 
    e.emp_id, 
    e.emp_name, 
    d.dept_name, 
    d.location 
FROM Employee e 
INNER JOIN Department d ON e.dept_id = d.dept_id;

-- Q2. LEFT JOIN: Retrieve all departments and any assigned employees (including depts with no employees)
SELECT 
    d.dept_id, 
    d.dept_name, 
    e.emp_id, 
    e.emp_name 
FROM Department d 
LEFT JOIN Employee e ON d.dept_id = e.dept_id;

-- Q3. SELF JOIN: Find pairs of employees working in the same department
SELECT 
    e1.emp_name AS Employee_1, 
    e2.emp_name AS Employee_2, 
    e1.dept_id AS Department_ID
FROM Employee e1 
JOIN Employee e2 ON e1.dept_id = e2.dept_id AND e1.emp_id < e2.emp_id
ORDER BY e1.dept_id, e1.emp_name;

-- Q4. 3-WAY JOIN: Combine Employee, Department, and Project via Employee_Project
SELECT 
    e.emp_name, 
    d.dept_name, 
    p.project_name, 
    ep.hours_worked 
FROM Employee e 
JOIN Department d ON e.dept_id = d.dept_id 
JOIN Employee_Project ep ON e.emp_id = ep.emp_id 
JOIN Project p ON ep.project_id = p.project_id;

-- ============================================================================
-- 2. SUBQUERIES AND SET OPERATIONS
-- ============================================================================

-- Q5. CORRELATED SUBQUERY: Find employees earning more than the average salary of their own department
SELECT 
    e.emp_id, 
    e.emp_name, 
    e.salary, 
    e.dept_id 
FROM Employee e 
WHERE e.salary > (
    SELECT AVG(e2.salary) 
    FROM Employee e2 
    WHERE e2.dept_id = e.dept_id
);

-- Q6. EXISTS: Identify employees who are actively assigned to at least one project
SELECT 
    e.emp_id, 
    e.emp_name, 
    e.dept_id 
FROM Employee e 
WHERE EXISTS (
    SELECT 1 
    FROM Employee_Project ep 
    WHERE ep.emp_id = e.emp_id
);

-- Q7. SIMULATED INTERSECT: Employees in Development (dept_id = 1) who ALSO work on Smart Web Portal (project_id = 201)
-- (MySQL simulation of INTERSECT using EXISTS / subquery)
SELECT 
    e.emp_id, 
    e.emp_name 
FROM Employee e 
WHERE e.dept_id = 1 
  AND EXISTS (
      SELECT 1 
      FROM Employee_Project ep 
      WHERE ep.emp_id = e.emp_id 
        AND ep.project_id = 201
  );

-- Q8. SIMULATED EXCEPT: Employees in Development (dept_id = 1) who DO NOT work on Smart Web Portal (project_id = 201)
-- (MySQL simulation of EXCEPT / MINUS using NOT EXISTS)
SELECT 
    e.emp_id, 
    e.emp_name 
FROM Employee e 
WHERE e.dept_id = 1 
  AND NOT EXISTS (
      SELECT 1 
      FROM Employee_Project ep 
      WHERE ep.emp_id = e.emp_id 
        AND ep.project_id = 201
  );

-- ============================================================================
-- 3. COMPARING EXECUTION PLANS USING EXPLAIN
-- ============================================================================

-- EXPLAIN Analysis 1: INNER JOIN
-- Demonstrates indexed foreign key lookup (ref/eq_ref) vs full table scan (ALL)
EXPLAIN 
SELECT 
    e.emp_id, 
    e.emp_name, 
    d.dept_name 
FROM Employee e 
INNER JOIN Department d ON e.dept_id = d.dept_id;

-- EXPLAIN Analysis 2: LEFT JOIN
-- Shows preservation of outer table rows (Department evaluated as primary driving table)
EXPLAIN 
SELECT 
    d.dept_name, 
    e.emp_name 
FROM Department d 
LEFT JOIN Employee e ON d.dept_id = e.dept_id;

-- EXPLAIN Analysis 3: SELF JOIN
-- Shows dual instances of the same table with index scan on dept_id
EXPLAIN 
SELECT 
    e1.emp_name, 
    e2.emp_name 
FROM Employee e1 
JOIN Employee e2 ON e1.dept_id = e2.dept_id AND e1.emp_id < e2.emp_id;

-- EXPLAIN Analysis 4: 3-WAY JOIN
-- Shows multi-table join tree and join buffer optimization
EXPLAIN 
SELECT 
    e.emp_name, 
    d.dept_name, 
    p.project_name 
FROM Employee e 
JOIN Department d ON e.dept_id = d.dept_id 
JOIN Employee_Project ep ON e.emp_id = ep.emp_id 
JOIN Project p ON ep.project_id = p.project_id;

-- EXPLAIN Analysis 5: CORRELATED SUBQUERY
-- Shows DEPENDENT SUBQUERY evaluation per outer row
EXPLAIN 
SELECT 
    e.emp_name, 
    e.salary 
FROM Employee e 
WHERE e.salary > (
    SELECT AVG(e2.salary) 
    FROM Employee e2 
    WHERE e2.dept_id = e.dept_id
);

-- EXPLAIN Analysis 6: EXISTS Query
-- Shows semi-join transformation or materialization by the MySQL query optimizer
EXPLAIN 
SELECT 
    e.emp_id, 
    e.emp_name 
FROM Employee e 
WHERE EXISTS (
    SELECT 1 
    FROM Employee_Project ep 
    WHERE ep.emp_id = e.emp_id
);

-- EXPLAIN Analysis 7: Simulated EXCEPT
-- Demonstrates NOT EXISTS execution cost compared to outer joins
EXPLAIN 
SELECT 
    e.emp_id, 
    e.emp_name 
FROM Employee e 
WHERE e.dept_id = 1 
  AND NOT EXISTS (
      SELECT 1 
      FROM Employee_Project ep 
      WHERE ep.emp_id = e.emp_id 
        AND ep.project_id = 201
  );
