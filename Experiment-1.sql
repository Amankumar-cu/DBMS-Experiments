-- ============================================================================
-- DBMS LAB EXPERIMENT 1
-- ============================================================================
-- AIM:
-- Design an ER diagram for an Indian e-commerce platform with entities:
-- Customer, Product, Order, OrderItem, Seller, Category, Payment, Delivery, Address.
-- Specify primary keys, composite and multi-valued attributes, weak entities,
-- specialization of Product, and participation constraints.
-- ============================================================================

/*
===============================================================================
                       1. CONCEPTUAL ER MODEL DESIGN
===============================================================================

1. ENTITIES AND ATTRIBUTES:
-------------------------------------------------------------------------------
a) Customer (Strong Entity):
   - customer_id        : Primary Key (PK)
   - name               : Composite Attribute (first_name, last_name)
   - email              : Candidate Key / Unique Attribute
   - phone_numbers      : Multi-Valued Attribute {primary_phone, alternate_phone}
   - registered_at      : Simple Attribute (Timestamp)

b) Address (Weak / Dependent Entity):
   - Identifying Entity : Customer
   - address_id         : Primary Key (or Discriminator with customer_id)
   - address_details    : Composite Attribute (house_flat_no, street_road, landmark, city, state, pincode)
   - address_type       : Simple Attribute (Home, Work, Other)
   - is_default         : Boolean Attribute

c) Seller (Strong Entity):
   - seller_id          : Primary Key (PK)
   - company_name       : Simple Attribute
   - gstin              : Candidate Key (Unique Indian GST Number, e.g., 22AAAAA0000A1Z5)
   - email              : Unique Attribute
   - phone              : Simple Attribute
   - pickup_pincode     : Simple Attribute
   - rating             : Derived / Dynamic Attribute

d) Category (Strong Entity):
   - category_id        : Primary Key (PK)
   - category_name      : Unique Attribute (e.g., Mobiles, Fashion, Home & Kitchen)
   - parent_category_id : Self-referencing FK for sub-categories

e) Product (Superclass Entity - Specialization/Generalization):
   - product_id         : Primary Key (PK)
   - product_title      : Simple Attribute
   - description        : Simple Attribute
   - base_price         : Simple Attribute (in INR)
   - stock_quantity     : Simple Attribute
   - seller_id          : Foreign Key (Supplied by Seller)
   - category_id        : Foreign Key (Belongs to Category)

   * SPECIALIZATION OF PRODUCT (Disjoint & Total):
     i. Product_Electronics (Subclass):
        - warranty_period_months : Simple Attribute (e.g., 12, 24)
        - brand                  : Simple Attribute (e.g., boAt, Noise, Samsung)
        - model_number           : Simple Attribute
        - power_consumption_watt : Simple Attribute

     ii. Product_Clothing (Subclass):
        - apparel_size           : Simple Attribute (e.g., S, M, L, XL, XXL)
        - color                  : Simple Attribute
        - fabric_type            : Simple Attribute (e.g., Cotton, Silk, Polyester)
        - target_gender          : Simple Attribute (Men, Women, Unisex, Kids)

     iii. Product_Grocery (Subclass):
        - expiry_date            : Simple Attribute
        - is_vegetarian          : Boolean Attribute (Green dot compliance in India)
        - fssai_license_number   : Simple Attribute (Indian Food Safety Regulatory ID)

f) Order (Strong Entity with identifying relation to OrderItem):
   - order_id           : Primary Key (PK)
   - order_date         : Simple Attribute (Timestamp)
   - total_amount       : Derived Attribute (SUM of items + taxes - discounts)
   - order_status       : Simple Attribute (PLACED, CONFIRMED, SHIPPED, DELIVERED, CANCELLED)
   - customer_id        : Foreign Key referencing Customer
   - delivery_address_id: Foreign Key referencing Address

g) OrderItem (WEAK ENTITY):
   - Identifying Owner  : Order
   - Identifying Rel.   : Order_Contains_Item
   - Partial Key (Disc.): item_number (1, 2, 3... within an order)
   - Primary Key        : Composite (order_id, item_number)
   - product_id         : Foreign Key referencing Product
   - quantity           : Simple Attribute (> 0)
   - unit_selling_price : Simple Attribute (Price locked at order time)
   - subtotal           : Derived Attribute (quantity * unit_selling_price)

h) Payment (Strong / Dependent Entity):
   - payment_id         : Primary Key (PK)
   - order_id           : Foreign Key referencing Order (1-to-1 or 1-to-N on retry)
   - payment_method     : Simple Attribute (UPI, CREDIT_CARD, DEBIT_CARD, NET_BANKING, COD)
   - transaction_ref    : Unique Attribute (e.g., UPI UTR / Gateway Ref)
   - payment_status     : Simple Attribute (PENDING, SUCCESS, FAILED, REFUNDED)
   - payment_timestamp  : Simple Attribute

i) Delivery (Strong / Dependent Entity):
   - delivery_id        : Primary Key (PK)
   - order_id           : Foreign Key referencing Order (1-to-1)
   - courier_partner    : Simple Attribute (Delhivery, BlueDart, Ekart, IndiaPost, Shadowfax)
   - tracking_awb       : Unique Attribute (Air Waybill Number)
   - delivery_status    : Simple Attribute (PICKED_UP, IN_TRANSIT, OUT_FOR_DELIVERY, DELIVERED)
   - dispatch_date      : Simple Attribute
   - estimated_delivery : Simple Attribute
   - actual_delivery    : Simple Attribute (NULL until delivered)

-------------------------------------------------------------------------------
2. STRUCTURAL CONSTRAINTS (CARDINALITY & PARTICIPATION):
-------------------------------------------------------------------------------
1. Customer --- Places ---> Order
   - Cardinality: 1 : N (One customer can place many orders)
   - Participation:
     * Customer: Partial (A customer can register without placing an order immediately)
     * Order: Total (An order must belong to exactly one customer)

2. Customer --- Has ---> Address
   - Cardinality: 1 : N (One customer can save multiple addresses)
   - Participation:
     * Customer: Partial (Can be newly registered)
     * Address: Total (An address must belong to a customer)

3. Order === Includes ===> OrderItem (Weak Entity Relationship)
   - Cardinality: 1 : N (One order contains at least one order item)
   - Participation:
     * Order: Total (An order cannot exist without items)
     * OrderItem: Total (Existence-dependent on Order; Double rectangle & double diamond)

4. Product --- Ordered_In ---> OrderItem
   - Cardinality: 1 : N (A product can appear across multiple order items)
   - Participation:
     * Product: Partial (A product may not have been ordered yet)
     * OrderItem: Total (Each line item must point to a valid product)

5. Seller --- Sells ---> Product
   - Cardinality: 1 : N (A seller lists multiple products)
   - Participation:
     * Seller: Partial
     * Product: Total (Every listed product must have a registered seller)

6. Category --- Classifies ---> Product
   - Cardinality: 1 : N (A category groups multiple products)
   - Participation:
     * Category: Partial
     * Product: Total (Every product must belong to a category)

7. Order --- Settled_Via ---> Payment
   - Cardinality: 1 : 1 (or 1 : N for retry attempts)
   - Participation:
     * Order: Total (Every confirmed order must initiate payment)
     * Payment: Total (Every payment transaction is linked to an order)

8. Order --- Dispatched_Via ---> Delivery
   - Cardinality: 1 : 1
   - Participation:
     * Order: Partial (Initially placed; becomes total upon fulfillment)
     * Delivery: Total (Delivery record is tied to an order)

-------------------------------------------------------------------------------
3. MERMAID ER DIAGRAM SPECIFICATION:
-------------------------------------------------------------------------------
```mermaid
erDiagram
    CUSTOMER ||--o{ ADDRESS : "has"
    CUSTOMER ||--o{ ORDER : "places"
    CUSTOMER ||--|{ CUSTOMER_PHONE : "owns"
    SELLER ||--o{ PRODUCT : "supplies"
    CATEGORY ||--o{ PRODUCT : "categorizes"
    ORDER ||--|{ ORDER_ITEM : "contains (identifying)"
    PRODUCT ||--o{ ORDER_ITEM : "is ordered in"
    ORDER ||--|| PAYMENT : "paid with"
    ORDER ||--|| DELIVERY : "shipped via"
    PRODUCT ||--|| PRODUCT_ELECTRONICS : "specialized as (ISA)"
    PRODUCT ||--|| PRODUCT_CLOTHING : "specialized as (ISA)"

    CUSTOMER {
        int customer_id PK
        string first_name
        string last_name
        string email UK
        datetime registered_at
    }

    CUSTOMER_PHONE {
        int customer_id FK
        string phone_number PK
    }

    ADDRESS {
        int address_id PK
        int customer_id FK
        string street
        string city
        string state
        string pincode
    }

    SELLER {
        int seller_id PK
        string company_name
        string gstin UK
        string email UK
    }

    CATEGORY {
        int category_id PK
        string category_name UK
        int parent_category_id FK
    }

    PRODUCT {
        int product_id PK
        string title
        decimal base_price
        int stock_quantity
        int seller_id FK
        int category_id FK
    }

    ORDER {
        int order_id PK
        datetime order_date
        decimal total_amount
        string order_status
        int customer_id FK
        int delivery_address_id FK
    }

    ORDER_ITEM {
        int order_id PK,FK
        int item_number PK
        int product_id FK
        int quantity
        decimal unit_price
    }

    PAYMENT {
        int payment_id PK
        int order_id FK
        string payment_method
        string transaction_ref UK
        decimal amount
        string payment_status
    }

    DELIVERY {
        int delivery_id PK
        int order_id FK
        string courier_partner
        string tracking_awb UK
        string delivery_status
    }
```
===============================================================================
*/

-- ============================================================================
-- VERIFICATION DDL: METADATA & ER MODEL REGISTRATION SCHEMA
-- ============================================================================
CREATE DATABASE IF NOT EXISTS IndianEcommerce_ER_Model;
USE IndianEcommerce_ER_Model;

-- Metadata table documenting the ER design components
CREATE TABLE IF NOT EXISTS ER_Entity_Dictionary (
    entity_name VARCHAR(50) PRIMARY KEY,
    entity_type VARCHAR(30) NOT NULL, -- Strong, Weak, Subclass
    primary_key VARCHAR(100) NOT NULL,
    identifying_owner VARCHAR(50) DEFAULT NULL,
    description TEXT NOT NULL
);

INSERT INTO ER_Entity_Dictionary (entity_name, entity_type, primary_key, identifying_owner, description) VALUES
('Customer', 'Strong', 'customer_id', NULL, 'Stores registered Indian shoppers with composite name, email, and multi-valued phones.'),
('Address', 'Weak / Dependent', 'address_id (FK customer_id)', 'Customer', 'Stores delivery and billing addresses in India with pincode, state, and street.'),
('Seller', 'Strong', 'seller_id', NULL, 'Indian registered marketplace sellers with verified GSTIN numbers.'),
('Category', 'Strong', 'category_id', NULL, 'Hierarchical catalog categories (Electronics, Fashion, Grocery).'),
('Product', 'Strong (Superclass)', 'product_id', NULL, 'Base catalog items with pricing, inventory, seller, and category links.'),
('Product_Electronics', 'Subclass (Specialization)', 'product_id', 'Product', 'Electronics specialization: warranty, brand, model, power specs.'),
('Product_Clothing', 'Subclass (Specialization)', 'product_id', 'Product', 'Apparel specialization: size, color, fabric, target gender.'),
('Order', 'Strong', 'order_id', NULL, 'Customer purchase transactions referencing customer and delivery address.'),
('OrderItem', 'Weak Entity', 'order_id, item_number', 'Order', 'Line items inside an order. Existence-dependent on Order with ON DELETE CASCADE.'),
('Payment', 'Dependent Entity', 'payment_id', 'Order', 'Payment records (UPI, Cards, NetBanking, COD) with unique gateway reference.'),
('Delivery', 'Dependent Entity', 'delivery_id', 'Order', 'Logistics fulfillment via Indian courier partners (Delhivery, BlueDart, Ekart).')
ON DUPLICATE KEY UPDATE description = VALUES(description);

-- Display the ER Entity Dictionary
SELECT 
    entity_name AS `Entity Name`,
    entity_type AS `Entity Type`,
    primary_key AS `Primary Key / Discriminator`,
    IFNULL(identifying_owner, 'N/A') AS `Identifying Parent`,
    description AS `Design Specification`
FROM ER_Entity_Dictionary
ORDER BY entity_name;
