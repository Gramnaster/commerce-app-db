
# README

## Table of Contents

- [API Documentation](#api-documentation)
  - [Product Categories](#product-categories-management-admin-only)
  - [Producers](#producers-management-admin-only)
  - [Promotions](#promotions-management-admin-only)
  - [Promotions Categories](#promotions-categories-join-table---management-admin-only)
  - [Products](#products-public-read-management-crud)
  - [User Payment Methods & Shopping Cart System](#user-payment-methods--shopping-cart-system)
    - [User Payment Methods](#user-payment-methods-user-only)
    - [Shopping Cart Items](#shopping-cart-items-user-only)
    - [User Cart Orders](#user-cart-orders-user-only)
    - [Order Approval & Fulfillment (Admin/Warehouse)](#order-approval--fulfillment-management-admin--warehouse)
  - [Transaction History (Receipts)](#transaction-history-receipts)
    - [User Receipts Endpoints](#user-receipts-endpoints)
    - [Admin Receipts Management](#admin-receipts-management-management-admin-only)
  - [Complete User Purchase Flow](#complete-user-purchase-flow)
  - [Test Credentials](#test-credentials)


This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
# commerce-app-db

## API Documentation

### Product Categories (Management Admin Only)

#### GET /api/v1/product_categories
List all product categories.
- **Auth Required**: Management Admin JWT token
- **Returns**: Array of all product categories with products count

#### GET /api/v1/product_categories/:id
Get a specific product category.
- **Auth Required**: Management Admin JWT token
- **Returns**: Single product category details

#### POST /api/v1/product_categories
Create a new product category.
- **Auth Required**: Management Admin JWT token
- **Body**:
```json
{
  "product_category": {
    "title": "electronics"
  }
}
```

#### PATCH /api/v1/product_categories/:id
Update a product category.
- **Auth Required**: Management Admin JWT token
- **Body**:
```json
{
  "product_category": {
    "title": "updated category name"
  }
}
```

#### DELETE /api/v1/product_categories/:id
Delete a product category.
- **Auth Required**: Management Admin JWT token
- **Returns**: `{"message": "Product category deleted successfully"}`
- **Note**: This will also delete all associated products (cascade delete)

---

### Producers (Management Admin Only)

#### GET /api/v1/producers
List all producers.
- **Auth Required**: Management Admin JWT token
- **Returns**: Array of all producers with address details and products count

#### GET /api/v1/producers/:id
Get a specific producer.
- **Auth Required**: Management Admin JWT token
- **Returns**: Single producer details with full address

#### POST /api/v1/producers
Create a new producer.
- **Auth Required**: Management Admin JWT token
- **Body (Option 1 - with existing address)**:
```json
{
  "producer": {
    "title": "Nike Inc.",
    "address_id": 5
  }
}
```
- **Body (Option 2 - create new address with producer)**:
```json
{
  "producer": {
    "title": "Nike Inc.",
    "address_attributes": {
      "unit_no": "100",
      "street_no": "Main Street",
      "address_line1": "Building A",
      "city": "New York",
      "region": "NY",
      "zipcode": "10001",
      "country_id": 1
    }
  }
}
```

#### PATCH /api/v1/producers/:id
Update a producer.
- **Auth Required**: Management Admin JWT token
- **Body (update title only)**:
```json
{
  "producer": {
    "title": "Updated Producer Name"
  }
}
```
- **Body (update with new address)**:
```json
{
  "producer": {
    "title": "Updated Producer Name",
    "address_id": 10
  }
}
```
- **Body (update address details)**:
```json
{
  "producer": {
    "address_attributes": {
      "id": 5,
      "city": "Los Angeles",
      "zipcode": "90001"
    }
  }
}
```

#### DELETE /api/v1/producers/:id
Delete a producer.
- **Auth Required**: Management Admin JWT token
- **Returns**: `{"message": "Producer deleted successfully"}`
- **Note**: This will also delete all associated products (cascade delete)

---

### Promotions (Management Admin Only)

#### GET /api/v1/promotions
List all promotions.
- **Auth Required**: Management Admin JWT token
- **Returns**: Array of all promotions with product categories and products count

#### GET /api/v1/promotions/:id
Get a specific promotion.
- **Auth Required**: Management Admin JWT token
- **Returns**: Single promotion with product categories and associated products

#### POST /api/v1/promotions
Create a new promotion.
- **Auth Required**: Management Admin JWT token
- **Body**:
```json
{
  "promotion": {
    "discount_amount": 15.50
  }
}
```
- **Note**: `discount_amount` must be greater than 0

#### PATCH /api/v1/promotions/:id
Update a promotion.
- **Auth Required**: Management Admin JWT token
- **Body**:
```json
{
  "promotion": {
    "discount_amount": 20.00
  }
}
```

#### DELETE /api/v1/promotions/:id
Delete a promotion.
- **Auth Required**: Management Admin JWT token
- **Returns**: `{"message": "Promotion deleted successfully"}`
- **Note**: Associated products will have their promotion_id set to NULL (nullify)

---

### Promotions Categories (Join Table - Management Admin Only)

Manage associations between promotions and product categories.

#### GET /api/v1/promotions_categories
List all promotion-category associations.
- **Auth Required**: Management Admin JWT token
- **Returns**: Array of all associations with promotion and product category details

#### GET /api/v1/promotions_categories/:id
Get a specific promotion-category association.
- **Auth Required**: Management Admin JWT token
- **Returns**: Single association with promotion and product category details

#### POST /api/v1/promotions_categories
Create a new promotion-category association.
- **Auth Required**: Management Admin JWT token
- **Body**:
```json
{
  "promotions_category": {
    "promotions_id": 1,
    "product_categories_id": 2
  }
}
```
- **Note**: The combination of `promotions_id` and `product_categories_id` must be unique

#### DELETE /api/v1/promotions_categories/:id
Delete a promotion-category association.
- **Auth Required**: Management Admin JWT token
- **Returns**: `{"message": "Promotion-category association deleted successfully"}`

---

### Products (Public Read, Management CRUD)

#### GET /api/v1/products
List all products.
- **Auth Required**: None (public access)
- **Returns**: Array of products with category, producer, and promotion details

**Example Response**:
```json
{
  "status": {
    "code": 200,
    "message": "Products retrieved successfully"
  },
  "data": [
    {
      "id": 1,
      "title": "Running Shoes",
      "description": "High-quality running shoes",
      "price": 99.99,
      "product_image_url": "https://example.com/shoes.jpg",
      "product_category": {
        "id": 1,
        "title": "Footwear"
      },
      "producer": {
        "id": 1,
        "title": "Nike Inc."
      },
      "promotion": {
        "id": 2,
        "discount_amount": 15.50
      },
      "created_at": "2025-01-14T10:00:00.000Z",
      "updated_at": "2025-01-14T10:00:00.000Z"
    }
  ]
}
```

#### GET /api/v1/products/:id
Get a specific product.
- **Auth Required**: None (public access)
- **Returns**: Single product with full details including producer address

**Example Response**:
```json
{
  "status": {
    "code": 200,
    "message": "Product retrieved successfully"
  },
  "data": {
    "id": 1,
    "title": "Running Shoes",
    "description": "High-quality running shoes",
    "price": 99.99,
    "product_image_url": "https://example.com/shoes.jpg",
    "product_category": {
      "id": 1,
      "title": "Footwear"
    },
    "producer": {
      "id": 1,
      "title": "Nike Inc.",
      "address": {
        "id": 5,
        "unit_no": "100",
        "street_no": "Main Street",
        "address_line1": "Building A",
        "address_line2": null,
        "city": "New York",
        "region": "NY",
        "zipcode": "10001",
        "country": {
          "id": 1,
          "country_name": "United States"
        }
      }
    },
    "promotion": {
      "id": 2,
      "discount_amount": 15.50
    },
    "created_at": "2025-01-14T10:00:00.000Z",
    "updated_at": "2025-01-14T10:00:00.000Z"
  }
}
```

#### POST /api/v1/products
Create a new product.
- **Auth Required**: Management Admin JWT token
- **Body**:
```json
{
  "product": {
    "title": "Running Shoes",
    "description": "High-quality running shoes",
    "price": 99.99,
    "product_category_id": 1,
    "producer_id": 1,
    "promotion_id": 2,
    "product_image_url": "https://example.com/shoes.jpg"
  }
}
```
- **Required Fields**: `title`, `price`, `product_category_id`, `producer_id`
- **Optional Fields**: `description`, `promotion_id`, `product_image_url`
- **Validation**: 
  - `title` must be present
  - `price` must be >= 0
  - `product_category_id` and `producer_id` must reference existing records
  - `promotion_id` is optional (nullable)

#### PATCH /api/v1/products/:id
Update a product.
- **Auth Required**: Management Admin JWT token
- **Body** (all fields optional for update):
```json
{
  "product": {
    "title": "Updated Product Name",
    "price": 149.99,
    "promotion_id": 3
  }
}
```

**Example - Remove promotion from product**:
```json
{
  "product": {
    "promotion_id": null
  }
}
```

#### DELETE /api/v1/products/:id
Delete a product.
- **Auth Required**: Management Admin JWT token
- **Returns**: `{"message": "Product deleted successfully"}`
- **Note**: This will also delete all associated shopping_cart_items and inventories (cascade delete)

---

### Inventories (Admin Only - Management & Warehouse)

**Important Notes**: 
- Inventories can only be attached to warehouse-type company sites, not management-type sites.
- **SKU is automatically generated** when creating an inventory. The system generates a 12-digit UPC-like code in the format: `SSSPPPPPPRRR` where:
  - `SSS` = 3-digit warehouse site ID
  - `PPPPPP` = 6-digit product ID
  - `RRR` = 3-digit random code for uniqueness
- Admins can optionally provide a custom SKU, but it's not required.

#### GET /api/v1/inventories
List all inventories.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Returns**: Array of inventories with company site and product details

**Example Response**:
```json
{
  "status": {
    "code": 200,
    "message": "Fetched all inventories successfully"
  },
  "data": [
    {
      "id": 1,
      "sku": "SHOES-NKE-001",
      "qty_in_stock": 150,
      "company_site": {
        "id": 2,
        "title": "JPB Warehouse A",
        "site_type": "warehouse"
      },
      "product": {
        "id": 1,
        "title": "Running Shoes",
        "price": "99.99"
      },
      "created_at": "2025-01-14T10:00:00.000Z",
      "updated_at": "2025-01-14T10:00:00.000Z"
    }
  ]
}
```

#### GET /api/v1/inventories/:id
Get a specific inventory.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Returns**: Single inventory with full company site address and product details

**Example Response**:
```json
{
  "status": {
    "code": 200,
    "message": "Inventory fetched successfully"
  },
  "data": {
    "id": 1,
    "sku": "SHOES-NKE-001",
    "qty_in_stock": 150,
    "company_site": {
      "id": 2,
      "title": "JPB Warehouse A",
      "site_type": "warehouse",
      "address": {
        "id": 10,
        "unit_no": "Building 5",
        "street_no": "123 Industrial Rd",
        "city": "Manila",
        "region": "NCR",
        "zipcode": "1000",
        "country": "Philippines"
      }
    },
    "product": {
      "id": 1,
      "title": "Running Shoes",
      "description": "High-quality running shoes",
      "price": "99.99",
      "product_image_url": "https://example.com/shoes.jpg",
      "product_category": {
        "id": 1,
        "title": "Footwear"
      },
      "producer": {
        "id": 1,
        "title": "Nike Inc."
      }
    },
    "created_at": "2025-01-14T10:00:00.000Z",
    "updated_at": "2025-01-14T10:00:00.000Z"
  }
}
```

#### POST /api/v1/inventories
Create a new inventory.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Body** (SKU is optional - will auto-generate if not provided):
```json
{
  "inventory": {
    "company_site_id": 2,
    "product_id": 1,
    "qty_in_stock": 150
  }
}
```
- **Body** (with custom SKU):
```json
{
  "inventory": {
    "company_site_id": 2,
    "product_id": 1,
    "sku": "CUSTOM-SKU-12345",
    "qty_in_stock": 150
  }
}
```
- **Required Fields**: `company_site_id`, `product_id`, `qty_in_stock`
- **Optional Fields**: `sku` (auto-generated if not provided)
- **Validation**: 
  - `sku` must be unique across all inventories (automatically ensured if auto-generated)
  - `qty_in_stock` must be an integer >= 0
  - `company_site_id` must reference a warehouse-type site (not management-type)

**Example Response with Auto-Generated SKU**:
```json
{
  "status": {
    "code": 200,
    "message": "Inventory fetched successfully"
  },
  "data": {
    "id": 1,
    "sku": "002000001439",
    "qty_in_stock": 150,
    "company_site": {
      "id": 2,
      "title": "JPB Warehouse A",
      "site_type": "warehouse"
    },
    "product": {
      "id": 1,
      "title": "Running Shoes",
      "price": "99.99"
    },
    "created_at": "2025-01-14T10:00:00.000Z",
    "updated_at": "2025-01-14T10:00:00.000Z"
  }
}
```

#### PATCH /api/v1/inventories/:id
Update an inventory.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Body** (all fields optional for update):
```json
{
  "inventory": {
    "qty_in_stock": 200,
    "sku": "SHOES-NKE-001-V2"
  }
}
```

#### DELETE /api/v1/inventories/:id
Delete an inventory.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Returns**: `{"message": "Inventory deleted successfully"}`
- **Note**: This will also delete all associated warehouse_orders (cascade delete)

---

### Admin Users

#### PATCH /api/v1/admin_users/:id
For updating an admin_user's details, role, and company site assignments:

```json
{
  "admin_user": {
    "admin_role": "management",
    "admin_detail_attributes": {
      "id": 4,
      "first_name": "Bien",
      "middle_name": "Sayson",
      "last_name": "Doe"
    },
    "admin_phones_attributes": [
      {
        "id": 1,
        "phone_no": "12345678",
        "phone_type": "mobile"
      }
    ],
    "admin_addresses_attributes": [
      {
        "id": 1,
        "is_default": true,
        "address_attributes": {
          "id": 5,
          "unit_no": "110",
          "street_no": "87 Cucumber St",
          "city": "Singapore",
          "zipcode": "1557330",
          "country_id": 20
        }
      }
    ],
    "admin_users_company_sites_attributes": [
      {
        "id": 1,
        "company_site_id": 2 // This updates existing
      },
      {
        "company_site_id": 3 // This adds a new company_site
      }
    ]
  }
}
```

**Notes:**
- To update an existing company site assignment: include the `id` of the join record
- To add a new company site assignment: omit the `id`, just provide `company_site_id`
- To remove a company site assignment: include `"_destroy": true` with the `id`

**Example - Remove a company site assignment:**
```json
{
  "admin_user": {
    "admin_users_company_sites_attributes": [
      {
        "id": 1,
        "_destroy": true
      }
    ]
  }
}
```

#### DELETE /api/v1/admin_users/:id
Soft delete (disable) an admin user when they leave the company:
- Sets `deleted_at` timestamp using `acts_as_paranoid`
- Admin can be restored later if needed
- Returns: `{"message": "Admin user disabled successfully"}`

---

## User Payment Methods & Shopping Cart System

### User Payment Methods (User Only)

Users have a payment method with a balance that can be used to purchase items. All payment operations require user authentication.

#### GET /api/v1/user_payment_methods/balance
Check current balance.
- **Auth Required**: User JWT token
- **Returns**: Current balance, user ID, and email

**Example Response**:
```json
{
  "balance": "900.0",
  "user_id": 18,
  "email": "test17@test.com"
}
```

#### POST /api/v1/user_payment_methods/deposit
Deposit funds into account.
- **Auth Required**: User JWT token
- **Body**:
```json
{
  "amount": 1000
}
```
- **Validation**: Amount must be greater than zero
- **Returns**: Confirmation with new balance

**Example Response**:
```json
{
  "message": "Deposit successful",
  "amount_deposited": 1000.0,
  "new_balance": "1000.0"
}
```

#### POST /api/v1/user_payment_methods/withdraw
Withdraw funds from account.
- **Auth Required**: User JWT token
- **Body**:
```json
{
  "amount": 100
}
```
- **Validation**: 
  - Amount must be greater than zero
  - Must have sufficient balance
- **Returns**: Confirmation with new balance or error if insufficient funds

**Example Response (Success)**:
```json
{
  "message": "Withdrawal successful",
  "amount_withdrawn": 100.0,
  "new_balance": "900.0"
}
```

**Example Response (Insufficient Funds)**:
```json
{
  "error": "Insufficient funds"
}
```

---

### Shopping Cart Items (User Only)

Users can add, view, update, and remove items from their shopping cart. Each user has their own cart created automatically on signup.

#### GET /api/v1/shopping_cart_items
View all items in your cart.
- **Auth Required**: User JWT token
- **Returns**: Array of cart items with product details and subtotals

**Example Response**:
```json
{
  "status": {
    "code": 200,
    "message": "Shopping cart items fetched successfully"
  },
  "data": [
    {
      "id": 3,
      "qty": "2.0",
      "product": {
        "id": 1,
        "title": "Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops",
        "price": "109.95",
        "product_image_url": "https://fakestoreapi.com/img/81fPKd-2AYL._AC_SL1500_t.png"
      },
      "subtotal": "219.9",
      "created_at": "2025-10-17T16:26:34.596Z",
      "updated_at": "2025-10-17T16:26:34.596Z"
    }
  ]
}
```

#### GET /api/v1/shopping_cart_items/:id
View a specific cart item.
- **Auth Required**: User JWT token
- **Returns**: Single cart item with full product details

#### POST /api/v1/shopping_cart_items
Add an item to your cart.
- **Auth Required**: User JWT token
- **Body**:
```json
{
  "shopping_cart_item": {
    "product_id": 1,
    "qty": 2
  }
}
```
- **Validation**:
  - `qty` must be greater than 0
  - Product must not already exist in cart
- **Returns**: Created cart item with product details

#### PATCH /api/v1/shopping_cart_items/:id
Update the quantity of a cart item.
- **Auth Required**: User JWT token
- **Body**:
```json
{
  "shopping_cart_item": {
    "qty": 5
  }
}
```
- **Validation**: `qty` must be greater than 0
- **Returns**: Updated cart item

#### DELETE /api/v1/shopping_cart_items/:id
Remove an item from your cart.
- **Auth Required**: User JWT token
- **Returns**: `{"message": "Item removed from cart successfully"}`

---

### User Cart Orders

Users submit their shopping cart as an order. The system automatically:
1. Calculates total cost from all cart items
2. Checks if user has sufficient balance
3. Deducts the cost from user's payment method
4. Creates the order with `is_paid: true` and `cart_status: pending`

Management admins can view and approve paid orders.

#### POST /api/v1/user_cart_orders (User Only)
Submit your shopping cart as an order.
- **Auth Required**: User JWT token
- **Body**:
```json
{
  "user_cart_order": {
    "user_address_id": 2
  }
}
```
- **Requirements**:
  - Cart must not be empty
  - User must have sufficient balance
- **Automatic Actions**:
  - Calculates total cost
  - Validates sufficient funds
  - Deducts payment from balance
  - Sets `is_paid: true`
  - Sets `cart_status: pending`

**Example Response (Success)**:
```json
{
  "status": {
    "code": 200,
    "message": "User cart order fetched successfully"
  },
  "data": {
    "id": 2,
    "total_cost": "286.8",
    "is_paid": true,
    "cart_status": "pending",
    "user_address": {
      "id": 2,
      "address": {
        "unit_no": "Unit 505",
        "street_no": "456 Commerce Ave",
        "city": "Manila",
        "region": "NCR",
        "zipcode": "1100"
      }
    },
    "items": [
      {
        "product_id": 1,
        "product_title": "Fjallraven - Foldsack No. 1 Backpack, Fits 15 Laptops",
        "qty": "2.0",
        "price": "109.95",
        "subtotal": "219.9"
      }
    ],
    "warehouse_orders_count": 0,
    "created_at": "2025-10-17T16:27:19.531Z",
    "updated_at": "2025-10-17T16:27:19.531Z"
  }
}
```

**Example Response (Insufficient Funds)**:
```json
{
  "error": "Insufficient funds",
  "required": "846.7",
  "current_balance": "613.2",
  "shortfall": "233.5"
}
```

**Note**: If payment fails due to insufficient funds, the cart items remain in the cart so the user can deposit more funds and try again later.

#### GET /api/v1/user_cart_orders (Management Only)
View all user orders.
- **Auth Required**: Management Admin JWT token
- **Returns**: Array of all orders with user address and item details

#### GET /api/v1/user_cart_orders/:id (Management Only)
View a specific order.
- **Auth Required**: Management Admin JWT token
- **Returns**: Full order details with items and delivery address

#### PATCH /api/v1/user_cart_orders/:id/approve (Management Only)
Approve a paid order.
- **Auth Required**: Management Admin JWT token
- **Requirement**: Order must have `is_paid: true`
- **Action**: Updates `cart_status` to "approved"
- **Returns**: Updated order details

**Example Request**:
```bash
curl -X PATCH http://localhost:3001/api/v1/user_cart_orders/2/approve \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

#### PATCH /api/v1/user_cart_orders/:id (Management Only)
Update order payment status or reject order.
- **Auth Required**: Management Admin JWT token
- **Body**:
```json
{
  "user_cart_order": {
    "is_paid": true,
    "cart_status": "rejected"
  }
}
```

---

### Warehouse Orders (Management & Warehouse Admin)

Management creates warehouse orders for approved user orders. Warehouse admins can view and update order status.

#### GET /api/v1/warehouse_orders
View all warehouse orders.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Returns**: Array of warehouse orders with inventory and site details

#### GET /api/v1/warehouse_orders/:id
View a specific warehouse order.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Returns**: Full order details including user and inventory information

#### POST /api/v1/warehouse_orders (Management Only)
Create a warehouse order.
- **Auth Required**: Management Admin JWT token
- **Body**:
```json
{
  "warehouse_order": {
    "company_site_id": 2,
    "inventory_id": 13,
    "user_id": 1,
    "user_cart_order_id": 2,
    "qty": 5,
    "product_status": "storage"
  }
}
```
- **Product Status Options**: `storage`, `progress`, `delivered`
- **Automatic Action**: Deducts quantity from inventory

#### PATCH /api/v1/warehouse_orders/:id
Update warehouse order status.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Body**:
```json
{
  "warehouse_order": {
    "product_status": "progress"
  }
}
```
- **Status Flow**: `storage` → `progress` → `delivered`

#### DELETE /api/v1/warehouse_orders/:id (Management Only)
Delete a warehouse order.
- **Auth Required**: Management Admin JWT token
- **Automatic Action**: Returns inventory quantity if status is `pending`
- **Returns**: `{"message": "Warehouse order deleted successfully"}`

---

## Transaction History (Receipts)

### Overview

The receipts system provides a complete audit trail of all financial transactions. Every deposit, withdrawal, and purchase creates a receipt record that tracks the amount, balance before/after the transaction, and associated details.

**Transaction Types:**
- **Deposit**: User adds funds to their account
- **Withdraw**: User removes funds from their account (manual or automatic payment)
- **Purchase**: Order completion record (automatically creates TWO receipts: one withdraw for payment, one purchase for order record)

**Key Features:**
- Balance tracking (before/after each transaction)
- Complete order details for purchases (items, delivery address, products)
- User filtering (users see only their own, admins see all)
- Admin management capabilities (view all, filter, delete)

---

### User Receipts Endpoints

#### GET /api/v1/receipts
View your transaction history.
- **Auth Required**: User JWT token
- **Optional Query Parameters**:
  - `transaction_type`: Filter by type (`deposit`, `withdraw`, or `purchase`)
- **Returns**: Array of receipts ordered by most recent first

**Example Request:**
```bash
curl -X GET http://localhost:3001/api/v1/receipts \
  -H "Authorization: Bearer YOUR_USER_TOKEN"
```

**Example Response:**
```json
[
  {
    "id": 4,
    "transaction_type": "purchase",
    "amount": 286.8,
    "balance_before": 666.5,
    "balance_after": 379.7,
    "description": "Purchase - Order #4",
    "created_at": "2025-10-17T17:08:11.715Z",
    "updated_at": "2025-10-17T17:08:11.715Z",
    "user": {
      "id": 18,
      "email": "test17@test.com",
      "first_name": "Bien",
      "last_name": "Doe"
    },
    "order": {
      "id": 4,
      "cart_status": "pending",
      "is_paid": true,
      "total_cost": 286.8,
      "items_count": 2,
      "total_quantity": "5.0"
    }
  },
  {
    "id": 3,
    "transaction_type": "withdraw",
    "amount": 286.8,
    "balance_before": 666.5,
    "balance_after": 379.7,
    "description": "Payment for Order #4",
    "created_at": "2025-10-17T17:08:11.711Z",
    "updated_at": "2025-10-17T17:08:11.711Z",
    "user": {
      "id": 18,
      "email": "test17@test.com",
      "first_name": "Bien",
      "last_name": "Doe"
    },
    "order": null
  }
]
```

**Filter by Type:**
```bash
curl -X GET "http://localhost:3001/api/v1/receipts?transaction_type=purchase" \
  -H "Authorization: Bearer YOUR_USER_TOKEN"
```

---

#### GET /api/v1/receipts/:id
View detailed information about a specific receipt.
- **Auth Required**: User JWT token
- **Authorization**: Users can only view their own receipts
- **Returns**: Complete receipt details including full order information for purchases

**Example Request:**
```bash
curl -X GET http://localhost:3001/api/v1/receipts/4 \
  -H "Authorization: Bearer YOUR_USER_TOKEN"
```

**Example Response (Purchase Receipt):**
```json
{
  "id": 4,
  "transaction_type": "purchase",
  "amount": 286.8,
  "balance_before": 666.5,
  "balance_after": 379.7,
  "description": "Purchase - Order #4",
  "created_at": "2025-10-17T17:08:11.715Z",
  "updated_at": "2025-10-17T17:08:11.715Z",
  "user": {
    "id": 18,
    "email": "test17@test.com",
    "first_name": "Bien",
    "last_name": "Doe",
    "full_name": "Bien Doe"
  },
  "order": {
    "id": 4,
    "cart_status": "pending",
    "is_paid": true,
    "total_cost": 286.8,
    "created_at": "2025-10-17T17:08:11.702Z",
    "delivery_address": {
      "id": 2,
      "unit_no": "Unit 505",
      "street_no": "456 Commerce Ave",
      "address_line1": null,
      "address_line2": null,
      "city": "Manila",
      "region": "NCR",
      "zipcode": "1100",
      "country": {
        "id": 1,
        "name": "Philippines",
        "code": "PH"
      }
    },
    "items": [
      {
        "id": 6,
        "qty": "2.0",
        "subtotal": "219.9",
        "product": {
          "id": 1,
          "title": "Fjallraven - Foldsack No. 1 Backpack",
          "description": "Your perfect pack for everyday use...",
          "price": 109.95
        }
      },
      {
        "id": 7,
        "qty": "3.0",
        "subtotal": "66.9",
        "product": {
          "id": 2,
          "title": "Mens Casual Premium Slim Fit T-Shirts",
          "description": "Slim-fitting style...",
          "price": 22.3
        }
      }
    ],
    "items_count": 2,
    "total_quantity": "5.0"
  }
}
```

---

### Admin Receipts Management (Management Admin Only)

#### GET /api/v1/admin/receipts
View all platform receipts with filtering and pagination.
- **Auth Required**: Management Admin JWT token
- **Optional Query Parameters**:
  - `user_id`: Filter by specific user
  - `transaction_type`: Filter by type (`deposit`, `withdraw`, or `purchase`)
  - `start_date`: Filter receipts from this date
  - `end_date`: Filter receipts to this date
  - `page`: Page number (default: 1)
  - `per_page`: Results per page (default: 20)
- **Returns**: Object with receipts array and pagination metadata

**Example Request:**
```bash
curl -X GET http://localhost:3001/api/v1/admin/receipts \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**Filter by User:**
```bash
curl -X GET "http://localhost:3001/api/v1/admin/receipts?user_id=18" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**Filter by Type:**
```bash
curl -X GET "http://localhost:3001/api/v1/admin/receipts?transaction_type=purchase" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**Pagination:**
```bash
curl -X GET "http://localhost:3001/api/v1/admin/receipts?per_page=20&page=2" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**Example Response:**
```json
{
  "receipts": [
    {
      "id": 4,
      "transaction_type": "purchase",
      "amount": 286.8,
      "balance_before": 666.5,
      "balance_after": 379.7,
      "description": "Purchase - Order #4",
      "created_at": "2025-10-17T17:08:11.715Z",
      "updated_at": "2025-10-17T17:08:11.715Z",
      "user": {
        "id": 18,
        "email": "test17@test.com",
        "first_name": "Bien",
        "last_name": "Doe"
      },
      "order": {
        "id": 4,
        "cart_status": "pending",
        "is_paid": true,
        "total_cost": 286.8,
        "items_count": 2,
        "total_quantity": "5.0"
      }
    }
  ],
  "pagination": {
    "total_count": 4,
    "current_page": 1,
    "per_page": 20,
    "total_pages": 1
  }
}
```

---

#### GET /api/v1/admin/receipts/:id
View detailed information about any receipt.
- **Auth Required**: Management Admin JWT token
- **Returns**: Complete receipt details (same structure as user show endpoint)

**Example Request:**
```bash
curl -X GET http://localhost:3001/api/v1/admin/receipts/4 \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

---

#### DELETE /api/v1/admin/receipts/:id
Delete a receipt record.
- **Auth Required**: Management Admin JWT token
- **Returns**: Success message
- **Note**: Use with caution - this is for correcting errors, not regular operation

**Example Request:**
```bash
curl -X DELETE http://localhost:3001/api/v1/admin/receipts/1 \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**Example Response:**
```json
{
  "message": "Receipt deleted successfully"
}
```

---

## Complete User Purchase Flow

### Step-by-Step Example

**1. User Login**
```bash
curl -X POST http://localhost:3001/api/v1/users/login \
  -H "Content-Type: application/json" \
  -d '{"user": {"email": "test17@test.com", "password": "test1234567"}}'
```

**2. Check Balance**
```bash
curl -X GET http://localhost:3001/api/v1/user_payment_methods/balance \
  -H "Authorization: Bearer YOUR_USER_TOKEN"
```

**3. Deposit Funds**
```bash
curl -X POST http://localhost:3001/api/v1/user_payment_methods/deposit \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount": 1000}'
```

**4. Add Items to Cart**
```bash
curl -X POST http://localhost:3001/api/v1/shopping_cart_items \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"shopping_cart_item": {"product_id": 1, "qty": 2}}'
```

**5. View Cart**
```bash
curl -X GET http://localhost:3001/api/v1/shopping_cart_items \
  -H "Authorization: Bearer YOUR_USER_TOKEN"
```

**6. Submit Order (Auto-Payment)**
```bash
curl -X POST http://localhost:3001/api/v1/user_cart_orders \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user_cart_order": {"user_address_id": 2}}'
```

**7. View Transaction History**
```bash
# View all receipts (deposit, withdraw, and purchase records)
curl -X GET http://localhost:3001/api/v1/receipts \
  -H "Authorization: Bearer YOUR_USER_TOKEN"

# View specific purchase receipt with full order details
curl -X GET http://localhost:3001/api/v1/receipts/4 \
  -H "Authorization: Bearer YOUR_USER_TOKEN"
```

**8. Management Approves Order**
```bash
curl -X PATCH http://localhost:3001/api/v1/user_cart_orders/2/approve \
  -H "Authorization: Bearer MANAGEMENT_TOKEN"
```

**9. Management Creates Warehouse Order**
```bash
curl -X POST http://localhost:3001/api/v1/warehouse_orders \
  -H "Authorization: Bearer MANAGEMENT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"warehouse_order": {"company_site_id": 2, "inventory_id": 13, "user_id": 18, "user_cart_order_id": 2, "qty": 2, "product_status": "storage"}}'
```

**10. Warehouse Updates Status**
```bash
curl -X PATCH http://localhost:3001/api/v1/warehouse_orders/1 \
  -H "Authorization: Bearer WAREHOUSE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"warehouse_order": {"product_status": "progress"}}'
```

---

## Test Credentials

### Regular User
```json
{
  "user": {
    "email": "test17@test.com",
    "password": "test1234567"
  }
}
```

### Management Admin
```json
{
  "admin_user": {
    "email": "admin@admin.com",
    "password": "admin123456"
  }
}
```

### Warehouse Admin
```json
{
  "admin_user": {
    "email": "warehouse@admin.com",
    "password": "warehouse123456"
  }
}
```