# DBMS Lab Experiments (1 to 6)

Comprehensive MySQL implementation of Database Management System lab practicals, covering Entity-Relationship (ER) modeling, relational schema conversion with integrity constraints, multi-table queries, execution plan comparisons (`EXPLAIN`), views, recursive CTEs, stored procedures with transactions, and triggers with audit logging.

---

## Repository Index & Experiment Mapping

| File | Experiment | Aim / Description |
| :--- | :--- | :--- |
| **[Experiment-1.sql](file:///Experiment-1.sql)** | **Experiment 1** | Conceptual ER Model design for an Indian e-commerce platform with entities (`Customer`, `Product`, `Order`, `OrderItem`, `Seller`, `Category`, `Payment`, `Delivery`, `Address`), primary/composite/multi-valued attributes, weak entities, product specialization hierarchy, and participation constraints. |
| **[Experiment-2.sql](file:///Experiment-2.sql)** | **Experiment 2** | Relational schema conversion with MySQL `CREATE TABLE` DDL, primary keys, foreign keys, `NOT NULL`, `UNIQUE`, `ON DELETE CASCADE`, and `ON DELETE SET NULL`. Includes sample data and demonstrations of referential integrity violations. |
| **[Experiment-3.sql](file:///Experiment-3.sql)** | **Experiment 3** | Creation of `EmployeeManagement` schema (`Department`, `Employee`, `Project`, `Employee_Project`). Inserts 30 employees across 5 departments and 8 projects. Demonstrates Selection, Projection, Aggregates (`COUNT`, `SUM`, `AVG`, `MAX`, `MIN`), `GROUP BY`, `HAVING`, `CASE` expressions, and `ORDER BY`. |
| **[Experiment-4.sql](file:///Experiment-4.sql)** | **Experiment 4** | Advanced queries using `INNER JOIN`, `LEFT JOIN`, `SELF JOIN`, `3-WAY JOIN`, correlated subqueries, `EXISTS`, simulated `INTERSECT`, and simulated `EXCEPT`. Compares query execution plans using MySQL `EXPLAIN`. |
| **[Experiment-5.sql](file:///Experiment-5.sql)** | **Experiment 5** | Database Views for Department Salary Summary and Employee Hierarchy. Tests view updatability (single-table vs non-updatable aggregate views). Implements recursive Common Table Expressions (`WITH RECURSIVE`) for organizational reporting chains. |
| **[Experiment-6.sql](file:///Experiment-6.sql)** | **Experiment 6** | Stored procedure `transfer_employee(emp_id, new_dept_id)` with transaction management, error handling (`SQLEXCEPTION`), and rollback. `BEFORE INSERT`/`UPDATE` triggers for salary validation. `AFTER UPDATE` trigger for salary audit logging into `Salary_Audit`. Comprehensive edge-case testing. |
| **[DBMS-Experiments.pdf](file:///DBMS-Experiments.pdf)** | **Lab Record** | Complete documented lab record with source code, outputs, query screenshots, and analysis. |

---

## Detailed Experiment Overview

### 🛒 Experiment 1: E-Commerce ER Diagram Design
- **Entities**:
  - `Customer` (Composite name, Unique email, Multi-valued phone numbers)
  - `Address` (Weak/dependent entity tied to customer with house/flat, street, city, state, pincode)
  - `Seller` (Indian marketplace sellers with verified GSTIN numbers)
  - `Category` (Self-referencing hierarchical categories)
  - `Product` (Superclass catalog item with pricing, inventory, seller, and category links)
  - **Product Specialization (Disjoint/Total ISA Hierarchy)**:
    - `Product_Electronics` (Warranty, brand, model number, wattage)
    - `Product_Clothing` (Size, color, fabric type, target gender)
  - `Order` & `OrderItem` (OrderItem is a weak entity identified by `(order_id, item_number)`)
  - `Payment` (UPI, Cards, NetBanking, COD transactions)
  - `Delivery` (Logistics fulfillment with tracking AWB and Indian couriers: Delhivery, BlueDart, Ekart)
- **Constraints**: Specified cardinality ratios and partial vs total participation constraints.

---

### 🗄️ Experiment 2: Relational Schema & Referential Integrity
- Converts the ER diagram into production-grade MySQL tables.
- **Constraints implemented**:
  - `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `UNIQUE`, `CHECK`
  - `ON DELETE CASCADE` on `OrderItem`, `Customer_Phone`, `Product_Electronics`, `Product_Clothing`
  - `ON DELETE SET NULL` on `Category` (self-reference and product category link) and `Address`
- **Violations Demonstrated**:
  1. Foreign Key constraint violation on `INSERT`
  2. `NOT NULL` constraint violation on required attributes
  3. `UNIQUE` constraint violation on duplicate GSTIN/email
  4. `CHECK` constraint violation on negative prices/quantities
  5. Live demonstration of `ON DELETE CASCADE` and `ON DELETE SET NULL` behaviors

---

### 👥 Experiment 3: Employee–Department–Project DQL
- Schema: 5 Departments, 30 Employees, 8 Projects, and Employee-Project assignments with logged work hours.
- Queries:
  - **Selection**: Filter employees by salary threshold (`WHERE salary > 80000`) and hire date.
  - **Projection**: Clean column projections and formatted outputs.
  - **Aggregates**: Department and company-wide `COUNT`, `SUM`, `AVG`, `MAX`, `MIN`.
  - **Grouping**: `GROUP BY` department with `HAVING` filters (`AVG(salary) > 75000`).
  - **Conditional Logic**: `CASE` expressions classifying employees into salary bands (`High`, `Medium`, `Low`).
  - **Sorting**: Multi-column `ORDER BY` for budgets, salaries, and logged hours.

---

### 🔗 Experiment 4: Advanced Joins, Subqueries & `EXPLAIN`
- **Join Queries**:
  - `INNER JOIN`: Matching employees and departments.
  - `LEFT JOIN`: Preserving department records with no assigned staff.
  - `SELF JOIN`: Departmental coworker pairing.
  - `3-WAY JOIN`: Connecting employees, departments, and projects.
- **Subqueries & Set Operations**:
  - **Correlated Subquery**: Employees earning above their department's specific average.
  - **EXISTS / NOT EXISTS**: Identifying active vs unassigned staff.
  - **Simulated INTERSECT**: Employees satisfying dual criteria across relations.
  - **Simulated EXCEPT**: Employees belonging to a set but excluding another.
- **Query Optimizer Execution Plans**:
  - Analyzed each query using MySQL `EXPLAIN` to inspect join types (`ALL`, `ref`, `eq_ref`), row estimates, and index utilization.

---

### 👁️ Experiment 5: Views, Updatability & Recursive CTEs
- **Views**:
  - `Department_Salary_Summary`: Aggregate view with employee counts, total salary, and salary metrics.
  - `Employee_Hierarchy`: Self-joined view showing reporting manager names and department locations.
- **View Updatability**:
  - Demonstrated successful updates through simple single-table views (`Employee_Basic`).
  - Demonstrated rejection of updates on complex aggregate views (`Department_Salary_Summary` with Error 1288).
- **Recursive CTEs**:
  - Top-down traversal displaying the full reporting chain (`Lead -> Manager -> Subordinate`) with depth level.
  - Bottom-up traversal showing the upward management chain for a specific employee.

---

### ⚙️ Experiment 6: Stored Procedures, Triggers & Auditing
- **Stored Procedure**: `transfer_employee(p_emp_id, p_new_dept_id)`
  - Parameter validation for employee existence, target department existence, and duplicate department transfer.
  - Transaction handling with `START TRANSACTION`, `COMMIT`, and `ROLLBACK`.
  - Generic `SQLEXCEPTION` handler.
- **Salary Validation Triggers**:
  - `BEFORE INSERT` and `BEFORE UPDATE` triggers enforcing a minimum salary limit (`salary >= 15000`) and non-null values using `SIGNAL SQLSTATE '45000'`.
- **Audit Logging**:
  - `AFTER UPDATE` trigger recording old salary, new salary, employee ID, and timestamps into `Salary_Audit`.
  - Edge case testing: Salary unchanged updates are detected to avoid redundant audit rows.

---

## How to Execute

To run any experiment in MySQL:

```bash
# Log in to MySQL
mysql -u root -p

# Execute Experiment 1 (ER Model)
SOURCE Experiment-1.sql;

# Execute Experiment 2 (Relational Schema & Constraints)
SOURCE Experiment-2.sql;

# Execute Experiment 3 (Employee Management DQL)
SOURCE Experiment-3.sql;

# Execute Experiment 4 (Advanced Joins & EXPLAIN)
SOURCE Experiment-4.sql;

# Execute Experiment 5 (Views & Recursive CTEs)
SOURCE Experiment-5.sql;

# Execute Experiment 6 (Stored Procedures & Triggers)
SOURCE Experiment-6.sql;
```
