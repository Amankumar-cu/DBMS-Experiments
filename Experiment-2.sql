-- ============================================================================
-- DBMS LAB EXPERIMENT 2
-- ============================================================================
-- AIM:
-- Convert the ER diagram into a relational schema. Write complete MySQL
-- CREATE TABLE statements with primary keys, foreign keys, NOT NULL, UNIQUE,
-- ON DELETE CASCADE and SET NULL constraints. Insert sample data and demonstrate
-- referential integrity violations.
-- ============================================================================

-- Step 1: Database Setup
DROP DATABASE IF EXISTS IndianEcommerceDB;
CREATE DATABASE IndianEcommerceDB;
USE IndianEcommerceDB;

-- ============================================================================
-- 1. RELATIONAL SCHEMA DEFINITION (DDL WITH CONSTRAINTS)
-- ============================================================================

-- Table 1: Category (Supports self-referencing hierarchy with ON DELETE SET NULL)
CREATE TABLE Category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_category_id INT NULL,
    CONSTRAINT fk_category_parent 
        FOREIGN KEY (parent_category_id) 
        REFERENCES Category(category_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE
);

-- Table 2: Seller (Strong entity with unique Indian GSTIN)
CREATE TABLE Seller (
    seller_id INT AUTO_INCREMENT PRIMARY KEY,
    company_name VARCHAR(150) NOT NULL,
    gstin VARCHAR(15) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone VARCHAR(15) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    rating DECIMAL(2,1) DEFAULT 4.0 CHECK (rating BETWEEN 1.0 AND 5.0)
);

-- Table 3: Customer (Strong entity with composite name and unique email)
CREATE TABLE Customer (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table 4: Customer_Phone (Resolves multi-valued phone numbers attribute, ON DELETE CASCADE)
CREATE TABLE Customer_Phone (
    customer_id INT NOT NULL,
    phone_number VARCHAR(15) NOT NULL,
    phone_type VARCHAR(20) DEFAULT 'Mobile',
    PRIMARY KEY (customer_id, phone_number),
    CONSTRAINT fk_custphone_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES Customer(customer_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Table 5: Address (Dependent entity on Customer, ON DELETE CASCADE)
CREATE TABLE Address (
    address_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    house_flat_no VARCHAR(50) NOT NULL,
    street VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    pincode CHAR(6) NOT NULL,
    address_type VARCHAR(20) DEFAULT 'Home',
    is_default BOOLEAN DEFAULT FALSE,
    CONSTRAINT fk_address_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES Customer(customer_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Table 6: Product (Superclass entity with ON DELETE SET NULL on category, ON DELETE CASCADE on seller)
CREATE TABLE Product (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    base_price DECIMAL(10,2) NOT NULL CHECK (base_price >= 0.00),
    stock_quantity INT NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    seller_id INT NOT NULL,
    category_id INT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_seller 
        FOREIGN KEY (seller_id) 
        REFERENCES Seller(seller_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_product_category 
        FOREIGN KEY (category_id) 
        REFERENCES Category(category_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE
);

-- Table 7: Product_Electronics (Specialization subclass table, ON DELETE CASCADE)
CREATE TABLE Product_Electronics (
    product_id INT PRIMARY KEY,
    brand VARCHAR(50) NOT NULL,
    model_number VARCHAR(50) NOT NULL,
    warranty_months INT NOT NULL DEFAULT 12 CHECK (warranty_months >= 0),
    power_wattage INT NULL,
    CONSTRAINT fk_elec_product 
        FOREIGN KEY (product_id) 
        REFERENCES Product(product_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Table 8: Product_Clothing (Specialization subclass table, ON DELETE CASCADE)
CREATE TABLE Product_Clothing (
    product_id INT PRIMARY KEY,
    apparel_size VARCHAR(10) NOT NULL,
    color VARCHAR(30) NOT NULL,
    fabric_type VARCHAR(50) NOT NULL,
    target_gender VARCHAR(20) NOT NULL CHECK (target_gender IN ('Men', 'Women', 'Unisex', 'Kids')),
    CONSTRAINT fk_cloth_product 
        FOREIGN KEY (product_id) 
        REFERENCES Product(product_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Table 9: Orders (Customer purchase, address ON DELETE SET NULL to preserve order history)
CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    delivery_address_id INT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00 CHECK (total_amount >= 0.00),
    order_status VARCHAR(30) NOT NULL DEFAULT 'PLACED' 
        CHECK (order_status IN ('PLACED', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED')),
    CONSTRAINT fk_order_customer 
        FOREIGN KEY (customer_id) 
        REFERENCES Customer(customer_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_order_address 
        FOREIGN KEY (delivery_address_id) 
        REFERENCES Address(address_id) 
        ON DELETE SET NULL 
        ON UPDATE CASCADE
);

-- Table 10: OrderItem (Weak Entity: composite PK with item_number, ON DELETE CASCADE)
CREATE TABLE OrderItem (
    order_id INT NOT NULL,
    item_number INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price >= 0.00),
    PRIMARY KEY (order_id, item_number),
    CONSTRAINT fk_item_order 
        FOREIGN KEY (order_id) 
        REFERENCES Orders(order_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE,
    CONSTRAINT fk_item_product 
        FOREIGN KEY (product_id) 
        REFERENCES Product(product_id) 
        ON DELETE RESTRICT 
        ON UPDATE CASCADE
);

-- Table 11: Payment (Dependent entity with ON DELETE CASCADE)
CREATE TABLE Payment (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    payment_method VARCHAR(30) NOT NULL 
        CHECK (payment_method IN ('UPI', 'CREDIT_CARD', 'DEBIT_CARD', 'NET_BANKING', 'COD')),
    transaction_ref VARCHAR(100) NOT NULL UNIQUE,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0.00),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' 
        CHECK (payment_status IN ('PENDING', 'SUCCESS', 'FAILED', 'REFUNDED')),
    paid_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_order 
        FOREIGN KEY (order_id) 
        REFERENCES Orders(order_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- Table 12: Delivery (Fulfillment entity with ON DELETE CASCADE)
CREATE TABLE Delivery (
    delivery_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL UNIQUE,
    courier_partner VARCHAR(50) NOT NULL,
    tracking_awb VARCHAR(50) NOT NULL UNIQUE,
    delivery_status VARCHAR(30) NOT NULL DEFAULT 'DISPATCHED' 
        CHECK (delivery_status IN ('DISPATCHED', 'IN_TRANSIT', 'OUT_FOR_DELIVERY', 'DELIVERED', 'RETURNED')),
    estimated_delivery DATE NOT NULL,
    actual_delivery DATE NULL,
    CONSTRAINT fk_delivery_order 
        FOREIGN KEY (order_id) 
        REFERENCES Orders(order_id) 
        ON DELETE CASCADE 
        ON UPDATE CASCADE
);

-- ============================================================================
-- 2. SAMPLE DATA INSERTION (REALISTIC INDIAN E-COMMERCE CONTEXT)
-- ============================================================================

-- Categories
INSERT INTO Category (category_id, category_name, description, parent_category_id) VALUES
(1, 'Electronics', 'Gadgets and electronic equipment', NULL),
(2, 'Fashion', 'Apparel and accessories', NULL),
(3, 'Smartphones & Audio', 'Mobile phones and audio gear', 1),
(4, 'Men Clothing', 'Shirts, jeans, and formal wear', 2);

-- Sellers
INSERT INTO Seller (seller_id, company_name, gstin, email, phone, city, state, rating) VALUES
(1, 'Cloudtail India Pvt Ltd', '29AABCC1234D1Z1', 'seller1@cloudtail.in', '9811223344', 'Bengaluru', 'Karnataka', 4.8),
(2, 'RetailNet India LLP', '27AABCR5678E1Z4', 'contact@retailnet.co.in', '9822334455', 'Mumbai', 'Maharashtra', 4.5),
(3, 'SuperComNet Traders', '07AABCS9012F1Z8', 'info@supercomnet.in', '9833445566', 'New Delhi', 'Delhi', 4.3);

-- Customers
INSERT INTO Customer (customer_id, first_name, last_name, email) VALUES
(1, 'Aman', 'Kumar', 'aman.kumar@example.com'),
(2, 'Priya', 'Sharma', 'priya.sharma@example.com'),
(3, 'Rahul', 'Verma', 'rahul.verma@example.com');

-- Multi-valued phones
INSERT INTO Customer_Phone (customer_id, phone_number, phone_type) VALUES
(1, '+91-9876543210', 'Primary'),
(1, '+91-9876543211', 'Alternate'),
(2, '+91-9123456780', 'Primary'),
(3, '+91-9988776655', 'Primary');

-- Customer Addresses
INSERT INTO Address (address_id, customer_id, house_flat_no, street, city, state, pincode, address_type, is_default) VALUES
(1, 1, 'Flat 402, Sunshine Apts', 'Koramangala 4th Block', 'Bengaluru', 'Karnataka', '560034', 'Home', TRUE),
(2, 2, 'B-12, Sector 62', 'Electronic City Road', 'Noida', 'Uttar Pradesh', '201301', 'Work', TRUE),
(3, 3, 'House 88, Bandra West', 'Hill Road', 'Mumbai', 'Maharashtra', '400050', 'Home', TRUE);

-- Products
INSERT INTO Product (product_id, title, base_price, stock_quantity, seller_id, category_id) VALUES
(101, 'boAt Rockerz 450 Bluetooth Headphone', 1499.00, 50, 1, 3),
(102, 'Samsung Galaxy S24 5G (128GB)', 74999.00, 20, 2, 3),
(103, 'Peter England Slim Fit Cotton Formal Shirt', 1299.00, 100, 3, 4);

-- Product Subclasses (Specialization)
INSERT INTO Product_Electronics (product_id, brand, model_number, warranty_months, power_wattage) VALUES
(101, 'boAt', 'Rockerz 450', 12, 5),
(102, 'Samsung', 'SM-S921B', 24, 25);

INSERT INTO Product_Clothing (product_id, apparel_size, color, fabric_type, target_gender) VALUES
(103, 'L', 'Sky Blue', '100% Cotton', 'Men');

-- Orders
INSERT INTO Orders (order_id, customer_id, delivery_address_id, total_amount, order_status) VALUES
(1001, 1, 1, 1499.00, 'CONFIRMED'),
(1002, 2, 2, 74999.00, 'SHIPPED');

-- Order Items (Weak Entity with composite key)
INSERT INTO OrderItem (order_id, item_number, product_id, quantity, unit_price) VALUES
(1001, 1, 101, 1, 1499.00),
(1002, 1, 102, 1, 74999.00);

-- Payments
INSERT INTO Payment (order_id, payment_method, transaction_ref, amount, payment_status) VALUES
(1001, 'UPI', 'UPI/20261029/987654321', 1499.00, 'SUCCESS'),
(1002, 'CREDIT_CARD', 'HDFC_PG_882910398', 74999.00, 'SUCCESS');

-- Delivery
INSERT INTO Delivery (order_id, courier_partner, tracking_awb, delivery_status, estimated_delivery) VALUES
(1002, 'Delhivery', 'DEL123456789IN', 'IN_TRANSIT', '2026-11-02');

-- ============================================================================
-- 3. REFERENTIAL INTEGRITY VIOLATION DEMONSTRATIONS
-- ============================================================================

-- DEMONSTRATION 1: Foreign Key Violation on INSERT
-- Attempting to place an order for non-existent customer_id = 999
-- EXPECTED: Fails with Error 1452 (Cannot add or update a child row: a foreign key constraint fails)
-- UNCOMMENT TO TEST:
-- INSERT INTO Orders (order_id, customer_id, delivery_address_id, total_amount, order_status)
-- VALUES (1003, 999, 1, 2500.00, 'PLACED');

-- DEMONSTRATION 2: NOT NULL Constraint Violation
-- Attempting to insert a product without a required title or base_price
-- EXPECTED: Fails with Error 1048 (Column 'title' cannot be null)
-- UNCOMMENT TO TEST:
-- INSERT INTO Product (title, base_price, stock_quantity, seller_id, category_id)
-- VALUES (NULL, 999.00, 10, 1, 1);

-- DEMONSTRATION 3: UNIQUE Constraint Violation
-- Attempting to register another seller with an already existing GSTIN
-- EXPECTED: Fails with Error 1062 (Duplicate entry '29AABCC1234D1Z1' for key 'gstin')
-- UNCOMMENT TO TEST:
-- INSERT INTO Seller (company_name, gstin, email, phone, city, state)
-- VALUES ('Duplicate Seller Ltd', '29AABCC1234D1Z1', 'seller_dup@test.in', '9999999999', 'Pune', 'Maharashtra');

-- DEMONSTRATION 4: CHECK Constraint Violation
-- Attempting to insert a product with negative base_price
-- EXPECTED: Fails with Error 3819 (Check constraint 'product_chk_1' is violated)
-- UNCOMMENT TO TEST:
-- INSERT INTO Product (title, base_price, stock_quantity, seller_id, category_id)
-- VALUES ('Faulty Pricing Item', -500.00, 10, 1, 1);

-- DEMONSTRATION 5: Testing ON DELETE CASCADE
-- When an Order is deleted, its associated OrderItems and Payments are automatically deleted.
SELECT 'Before deleting Order 1001:' AS Status;
SELECT * FROM Orders WHERE order_id = 1001;
SELECT * FROM OrderItem WHERE order_id = 1001;
SELECT * FROM Payment WHERE order_id = 1001;

DELETE FROM Orders WHERE order_id = 1001;

SELECT 'After deleting Order 1001 (Cascade effect demonstrated):' AS Status;
SELECT * FROM Orders WHERE order_id = 1001;
SELECT * FROM OrderItem WHERE order_id = 1001; -- Result is empty (Cascaded!)
SELECT * FROM Payment WHERE order_id = 1001;   -- Result is empty (Cascaded!)

-- DEMONSTRATION 6: Testing ON DELETE SET NULL
-- When Category 4 (Men Clothing) is deleted, Product 103 has category_id updated to NULL.
SELECT 'Before deleting Category 4:' AS Status;
SELECT product_id, title, category_id FROM Product WHERE product_id = 103;

DELETE FROM Category WHERE category_id = 4;

SELECT 'After deleting Category 4 (SET NULL effect demonstrated):' AS Status;
SELECT product_id, title, category_id FROM Product WHERE product_id = 103; -- category_id is now NULL!
