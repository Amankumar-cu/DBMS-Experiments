-- ============================================================================
-- DBMS LAB EXPERIMENT 3
-- ============================================================================
-- AIM:
-- Create an Employee–Department–Project schema. Insert at least 30 employees
-- across 5 departments and 8 projects. Write SQL queries demonstrating:
-- selection, projection, aggregates, GROUP BY, HAVING, CASE expressions,
-- and ORDER BY.
-- ============================================================================

-- Step 1: Database Setup
DROP DATABASE IF EXISTS EmployeeManagement;
CREATE DATABASE EmployeeManagement;
USE EmployeeManagement;

-- ============================================================================
-- 1. TABLE CREATION
-- ============================================================================

-- Department Table (5 Departments)
CREATE TABLE Department (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL,
    location VARCHAR(50) NOT NULL
);

-- Employee Table (30 Employees)
CREATE TABLE Employee (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50) NOT NULL,
    gender CHAR(1) CHECK (gender IN ('M', 'F', 'O')),
    salary DECIMAL(10,2) NOT NULL,
    hire_date DATE NOT NULL,
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- Project Table (8 Projects)
CREATE TABLE Project (
    project_id INT PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    budget DECIMAL(12,2) NOT NULL,
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES Department(dept_id)
        ON UPDATE CASCADE ON DELETE SET NULL
);

-- Employee_Project Assignment Table (Many-to-Many)
CREATE TABLE Employee_Project (
    emp_id INT,
    project_id INT,
    hours_worked INT NOT NULL CHECK (hours_worked > 0),
    PRIMARY KEY (emp_id, project_id),
    FOREIGN KEY (emp_id) REFERENCES Employee(emp_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES Project(project_id)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ============================================================================
-- 2. DATA INSERTION
-- ============================================================================

-- Inserting 5 Departments
INSERT INTO Department (dept_id, dept_name, location) VALUES
(1, 'Development', 'Delhi'),
(2, 'Human Resources', 'Mumbai'),
(3, 'Accounting', 'Bangalore'),
(4, 'Sales', 'Pune'),
(5, 'Innovation', 'Hyderabad');

-- Inserting 30 Employees
INSERT INTO Employee (emp_id, emp_name, gender, salary, hire_date, dept_id) VALUES
(101, 'Aarush Khanna', 'M', 78000, '2021-01-15', 1),
(102, 'Ishita Roy', 'F', 69000, '2022-03-10', 1),
(103, 'Vivaan Sinha', 'M', 84000, '2020-07-20', 1),
(104, 'Myra Joshi', 'F', 74000, '2021-11-05', 1),
(105, 'Reyansh Kapoor', 'M', 97000, '2019-06-18', 1),
(106, 'Anika Bhatia', 'F', 66000, '2023-01-12', 1),
(107, 'Kabir Malhotra', 'M', 57000, '2022-05-15', 2),
(108, 'Aadhya Menon', 'F', 64000, '2021-09-22', 2),
(109, 'Vihaan Arora', 'M', 60000, '2020-04-11', 2),
(110, 'Kiara Saxena', 'F', 69000, '2023-02-19', 2),
(111, 'Advait Rao', 'M', 62000, '2022-08-01', 2),
(112, 'Saanvi Desai', 'F', 73000, '2019-12-10', 2),
(113, 'Dhruv Mehta', 'M', 90000, '2020-01-25', 3),
(114, 'Navya Pillai', 'F', 94000, '2019-08-14', 3),
(115, 'Arnav Kulkarni', 'M', 78000, '2021-06-30', 3),
(116, 'Tara Chawla', 'F', 87000, '2022-10-17', 3),
(117, 'Ishaan Nair', 'M', 75000, '2023-03-21', 3),
(118, 'Riddhi Shah', 'F', 92000, '2020-11-09', 3),
(119, 'Krish Bansal', 'M', 72000, '2021-02-28', 4),
(120, 'Avni Khurana', 'F', 68000, '2022-04-15', 4),
(121, 'Rudra Mishra', 'M', 76000, '2020-09-12', 4),
(122, 'Pari Anand', 'F', 83000, '2019-07-07', 4),
(123, 'Yuvaan Sethi', 'M', 71000, '2023-01-05', 4),
(124, 'Diya Oberoi', 'F', 79000, '2021-12-18', 4),
(125, 'Atharv Reddy', 'M', 99000, '2018-05-20', 5),
(126, 'Meher Kaur', 'F', 93000, '2020-03-16', 5),
(127, 'Shaurya Das', 'M', 89000, '2021-10-08', 5),
(128, 'Zoya Fernandes', 'F', 95000, '2019-11-25', 5),
(129, 'Ayaan Thakur', 'M', 81000, '2022-07-14', 5),
(130, 'Vanya Kapoor', 'F', 98000, '2023-02-02', 5);

-- Inserting 8 Projects
INSERT INTO Project (project_id, project_name, budget, dept_id) VALUES
(201, 'Smart Web Portal', 550000.00, 1),
(202, 'Cloud Infrastructure', 800000.00, 1),
(203, 'Staff Development Program', 300000.00, 2),
(204, 'Budget Forecasting System', 650000.00, 3),
(205, 'Online Sales Campaign', 480000.00, 4),
(206, 'Customer Insights Study', 400000.00, 4),
(207, 'Predictive Analytics Platform', 950000.00, 5),
(208, 'Cybersecurity Framework', 1100000.00, 5);

-- Assigning Employees to Projects
INSERT INTO Employee_Project (emp_id, project_id, hours_worked) VALUES
(101, 201, 120),
(102, 201, 100),
(103, 202, 150),
(104, 202, 110),
(105, 201, 130),
(106, 202, 90),
(107, 203, 100),
(108, 203, 120),
(109, 203, 80),
(110, 203, 110),
(111, 203, 90),
(112, 203, 130),
(113, 204, 140),
(114, 204, 150),
(115, 204, 120),
(116, 204, 135),
(117, 204, 100),
(118, 204, 145),
(119, 205, 110),
(120, 205, 100),
(121, 206, 120),
(122, 205, 140),
(123, 206, 90),
(124, 206, 130),
(125, 207, 160),
(126, 207, 140),
(127, 208, 150),
(128, 208, 160),
(129, 207, 120),
(130, 208, 135);

-- ============================================================================
-- 3. SQL QUERIES DEMONSTRATING CORE DQL CONCEPTS
-- ============================================================================

-- Q1. SELECTION: Find employees earning more than 80,000
SELECT 
    emp_id, 
    emp_name, 
    salary, 
    dept_id 
FROM Employee 
WHERE salary > 80000;

-- Q2. PROJECTION: Extract only full names and formatted salaries
SELECT 
    emp_name, 
    salary 
FROM Employee;

-- Q3. AGGREGATE FUNCTIONS: Summary statistics across the organization
SELECT 
    COUNT(DISTINCT emp_id) AS total_employees, 
    SUM(salary) AS total_salary, 
    AVG(salary) AS average_salary, 
    MAX(salary) AS highest_salary, 
    MIN(salary) AS lowest_salary 
FROM Employee;

-- Q4. GROUP BY: Department employee headcount
SELECT 
    dept_id, 
    COUNT(*) AS employee_count 
FROM Employee 
GROUP BY dept_id;

-- Q5. GROUP BY WITH JOIN: Department name with average salary
SELECT 
    d.dept_name, 
    COUNT(e.emp_id) AS employee_count,
    AVG(e.salary) AS average_salary 
FROM Department d 
JOIN Employee e ON d.dept_id = e.dept_id 
GROUP BY d.dept_name;

-- Q6. HAVING: Filter departments where average salary exceeds 75,000
SELECT 
    d.dept_name, 
    AVG(e.salary) AS average_salary 
FROM Department d 
JOIN Employee e ON d.dept_id = e.dept_id 
GROUP BY d.dept_name 
HAVING AVG(e.salary) > 75000;

-- Q7. CASE EXPRESSIONS: Categorize employees into salary brackets
SELECT 
    emp_name, 
    salary, 
    CASE 
        WHEN salary >= 90000 THEN 'High Salary' 
        WHEN salary >= 70000 THEN 'Medium Salary' 
        ELSE 'Low Salary' 
    END AS salary_category 
FROM Employee;

-- Q8. ORDER BY: Complete Department project report ordered by budget descending
SELECT 
    p.project_id, 
    p.project_name, 
    d.dept_name, 
    p.budget 
FROM Project p 
JOIN Department d ON p.dept_id = d.dept_id 
ORDER BY p.budget DESC;

-- Q9. ORDER BY: Employees and their project hours ordered from highest to lowest
SELECT 
    e.emp_name, 
    p.project_name, 
    ep.hours_worked 
FROM Employee_Project ep 
JOIN Employee e ON ep.emp_id = e.emp_id 
JOIN Project p ON ep.project_id = p.project_id 
ORDER BY ep.hours_worked DESC;
