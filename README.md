
# README

## Table of Contents

- [API Documentation](#api-documentation)
  - [Pagination](#pagination)
  - [Users](#users-public-registration--authentication)
    - [User Registration](#user-registration)
    - [User Authentication](#user-authentication)
    - [User Profile Management](#user-profile-management)
  - [Admin Users](#admin-users-management--warehouse)
    - [Admin Authentication](#admin-authentication)
    - [Admin User Management](#admin-user-management)
  - [User Management](#user-management-management-admin-only)
  - [Product Categories](#product-categories-management-admin-only)
  - [Producers](#producers-management-admin-only)
  - [Promotions](#promotions-management-admin-only)
    - [How Product Promotions Are Displayed](#how-product-promotions-are-displayed)
  - [Promotions Categories](#promotions-categories-join-table---management-admin-only)
  - [Products](#products-public-read-management-crud)
  - [Inventories](#inventories-admin-only---management--warehouse)
  - [User Payment Methods & Shopping Cart System](#user-payment-methods--shopping-cart-system)
    - [User Payment Methods](#user-payment-methods-user-only)
    - [Shopping Cart Items](#shopping-cart-items-user-only)
    - [User Cart Orders](#user-cart-orders-user-only)
    - [Warehouse Auto-Assignment](#warehouse-auto-assignment)
    - [Warehouse Orders](#warehouse-orders-management--warehouse-admin)
  - [Transaction History (Receipts)](#transaction-history-receipts)
    - [User Receipts Endpoints](#user-receipts-endpoints)
    - [Admin Receipts Management](#admin-receipts-management-management-admin-only)
  - [Social Programs & Donation Tracking](#social-programs--donation-tracking)
    - [Social Programs](#social-programs)
    - [Donation Tracking (Social Program Receipts)](#donation-tracking-social-program-receipts)
  - [Complete User Purchase Flow](#complete-user-purchase-flow)
  - [Test Credentials](#test-credentials)

---

## Recent Changes

### November 2025: Receipts Response Structure Update

**Breaking Change:** Receipt items are now returned via `warehouse_orders` instead of `shopping_cart_items`:

**What Changed:**
- **Old structure:** `receipt.order.shopping_cart.shopping_cart_items` (empty after order creation)
- **New structure:** `receipt.order.warehouse_orders` (persists order history)

**Why This Changed:**
- `shopping_cart_items` are cleared after order creation to prevent old items appearing in active cart
- `warehouse_orders` are created during order processing and persist as the historical record
- This provides accurate order history and warehouse assignment tracking

**Frontend Migration Required:**
```javascript
// OLD (now returns empty array)
receipt.order.shopping_cart.shopping_cart_items.forEach(item => {
  const product = item.product;
  const qty = item.qty;
});

// NEW (correct approach)
receipt.order.warehouse_orders.forEach(order => {
  const product = order.inventory.product;
  const qty = order.qty;
  const warehouse = order.company_site;
  const status = order.product_status; // e.g., "on_delivery", "storage"
});
```

**Response Changes:**
- `items_count`: Now counts `warehouse_orders` instead of `shopping_cart_items`
- `total_quantity`: Now sums from `warehouse_orders`
- Each item now includes warehouse assignment and delivery status
- Product access via: `warehouse_order.inventory.product`

---

### November 2025: User Cart Orders Refactoring

**Breaking Change:** The `user_cart_orders` endpoint parameter has changed:

- **Old:** `user_address_id` (referenced join table)
- **New:** `address_id` (direct reference to addresses table)

**What Changed:**
- Orders now directly reference the `addresses` table instead of going through the `user_addresses` join table
- Simplifies queries: `@order.address` instead of `@order.user_address.address`
- Better performance (fewer joins)
- Preserves order history even if user removes address from saved addresses

**Migration:**
- All existing orders automatically migrated to new structure
- Response JSON structure unchanged (frontend compatible)
- User ID now stored directly on order (not inferred from shopping cart)

**New API Usage:**
```json
POST /api/v1/user_cart_orders
{
  "user_cart_order": {
    "address_id": 20,  // Changed from user_address_id
    "social_program_id": 1
  }
}
```

For detailed refactoring documentation, see [REFACTOR_USER_CART_ORDERS_PLAN.md](REFACTOR_USER_CART_ORDERS_PLAN.md)

---


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

### Pagination

Most endpoints that return lists of items support pagination to improve performance and reduce response sizes. 

#### Paginated Endpoints

The following endpoints support pagination:

**Public/User Accessible:**
- Products (GET /api/v1/products) - Default: 20 per page
- Product Categories (GET /api/v1/product_categories) - Default: 20 per page
- Producers (GET /api/v1/producers) - Default: 20 per page
- Countries (GET /api/v1/countries) - Default: 50 per page
- Shopping Cart Items (GET /api/v1/shopping_cart_items) - Default: 20 per page
- Receipts (GET /api/v1/receipts) - Default: 20 per page (user's own receipts)

**Admin Only:**
- Admin Users (GET /api/v1/admin_users) - Default: 20 per page
- Users (GET /api/v1/users) - Default: 20 per page (management only)
- Inventories (GET /api/v1/inventories) - Default: 50 per page
- Promotions (GET /api/v1/promotions) - Default: 20 per page
- Promotion Categories (GET /api/v1/promotions_categories) - Default: 20 per page
- Company Sites (GET /api/v1/company_sites) - Default: 20 per page
- Warehouse Orders (GET /api/v1/warehouse_orders) - Default: 30 per page
- Warehouse Orders by User - Most Recent (GET /api/v1/warehouse_orders/:user_id/most_recent) - Default: 30 per page
- Warehouse Orders by User - Pending (GET /api/v1/warehouse_orders/:user_id/pending) - Default: 30 per page
- User Cart Orders (GET /api/v1/user_cart_orders) - Default: 30 per page
- Admin Receipts (GET /api/v1/admin/receipts) - Default: 20 per page

#### Pagination Parameters

**Query Parameters:**
- `page` (integer, optional): Page number to retrieve (default: 1)
- `per_page` (integer, optional): Number of items per page (default: varies by endpoint, max: 100)

**Example Request:**
```bash
GET /api/v1/products?page=2&per_page=10
```

**Response Format:**
```json
{
  "status": {
    "code": 200,
    "message": "Fetched all products successfully"
  },
  "pagination": {
    "current_page": 2,
    "per_page": 10,
    "total_entries": 20,
    "total_pages": 2,
    "next_page": null,
    "previous_page": 1
  },
  "data": [
    ...
  ]
}
```

**Pagination Metadata:**
- `current_page`: The current page number
- `per_page`: Number of items per page
- `total_entries`: Total number of items across all pages
- `total_pages`: Total number of pages available
- `next_page`: Next page number (null if on last page)
- `previous_page`: Previous page number (null if on first page)

**Maximum Limit:** The `per_page` parameter is capped at 100 items to prevent performance issues.

---

### Users (Public Registration & Authentication)

Regular users can self-register, manage their profiles, and shop in the system. User accounts require email confirmation before login. All authenticated user endpoints use the `Authorization: Bearer <token>` header with the `user` scope.

---

### User Registration

#### POST /api/v1/users/signup
Create a new user account. Only basic information is required for registration.
- **Auth Required**: None

**Minimal Registration (Recommended for Frontend):**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "user_detail_attributes": {
      "first_name": "Alice",
      "last_name": "Johnson",
      "dob": "1995-03-10"
    }
  }
}
```

**Required Fields**:
- `email`, `password`, `password_confirmation`
- `user_detail_attributes`: `first_name`, `last_name`, `dob`

**Optional Fields** (can be added later via PATCH):
- `user_detail_attributes.middle_name`
- `phones_attributes`: Array of phone objects
- `user_addresses_attributes`: Array of address objects
- `user_payment_methods_attributes`: Array of payment method objects

**Example Response:**
```json
{
  "status": {
    "code": 201,
    "message": "Signed up successfully."
  },
  "data": {
    "id": 15,
    "email": "user@example.com",
    "jti": "5117f677-1bec-4e8b-b842-93c18e2efd02"
  }
}
```

**Error Responses:**

*Email Already Exists (422):*
```json
{
  "status": {
    "message": "User registration failed",
    "errors": ["Email has already been taken"],
    "code": "email_already_exists",
    "field": "email"
  }
}
```

*Invalid Password (422):*
```json
{
  "status": {
    "message": "User registration failed",
    "errors": ["Password is too short (minimum is 6 characters)"],
    "code": "invalid_password",
    "field": "password"
  }
}
```

*Password Mismatch (422):*
```json
{
  "status": {
    "message": "User registration failed",
    "errors": ["Password confirmation doesn't match Password"],
    "code": "password_mismatch",
    "field": "password_confirmation"
  }
}
```

*Multiple Errors (422):*
```json
{
  "status": {
    "message": "User registration failed",
    "errors": [
      "Email has already been taken",
      "Password is too short (minimum is 6 characters)"
    ],
    "code": "email_already_exists",
    "field": "email"
  }
}
```

**Error Codes:**
- `email_already_exists` - Email is already registered
- `invalid_password` - Password doesn't meet requirements
- `password_mismatch` - Password confirmation doesn't match

**What Gets Auto-Created:**
- `user_detail`: Created with provided first_name, last_name, dob
- `user_payment_method`: Auto-created with balance=0.0 and payment_type=null
- `shopping_cart`: Auto-created empty shopping cart
- `phones`: Empty array (can be added later)
- `user_addresses`: Empty array (can be added later)

**Note**: A confirmation email is sent asynchronously. The user must confirm their email before logging in.

<details>
<summary><b>Advanced: Full Registration with Nested Attributes</b></summary>

You can optionally include phones, addresses, and payment methods during registration:

```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "user_detail_attributes": {
      "first_name": "John",
      "middle_name": "M",
      "last_name": "Doe",
      "dob": "1990-01-15"
    },
    "phones_attributes": [
      {
        "phone_no": "+639171234567",
        "phone_type": "mobile"
      }
    ],
    "user_addresses_attributes": [
      {
        "is_default": true,
        "address_attributes": {
          "unit_no": "123",
          "street_no": "456",
          "address_line1": "Main Street",
          "address_line2": "Subdivision",
          "barangay": "Barangay 1",
          "city": "Manila",
          "region": "NCR",
          "zipcode": "1000",
          "country_id": 1
        }
      }
    ],
    "user_payment_methods_attributes": [
      {
        "balance": 5000.00,
        "payment_type": "e_wallet"
      }
    ]
  }
}
```

**Phone Types**: `mobile`, `home`, `work`  
**Payment Types**: `e_wallet`, `credit_card`, `debit_card`, `cash`
</details>

#### GET /api/v1/users/confirmation?confirmation_token=TOKEN
Confirm user email address.
- **Auth Required**: None
- **Query Parameters**: `confirmation_token` (received via email)

**Example Response (Success):**
```json
{
  "status": {
    "code": 200,
    "message": "Email successfully confirmed."
  },
  "data": {
    "id": 14,
    "email": "user@example.com",
    "confirmed": true
  }
}
```

**Example Response (Already Confirmed):**
```json
{
  "status": {
    "message": "Invalid confirmation token."
  },
  "errors": [
    "Email was already confirmed, please try signing in"
  ]
}
```

---

### User Authentication

#### POST /api/v1/users/login
User login (requires confirmed email).
- **Auth Required**: None
- **Body**:
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Logged in successfully."
  },
  "data": {
    "id": 14,
    "email": "user@example.com",
    "jti": "ba991969-1624-44ec-8a4b-a501faa49db6"
  }
}
```

**Note**: JWT token is returned in the `Authorization` response header as `Bearer <token>`

#### DELETE /api/v1/users/logout
User logout (revokes JWT token).
- **Auth Required**: User JWT token
- **Returns**: `{"message": "Logged out successfully"}`

---

### User Profile Management

#### GET /api/v1/users/:id
Retrieve user profile with all nested data.
- **Auth Required**: User JWT token (users can only view their own profile)
- **Returns**: Complete user object including `user_detail`, `phones`, `user_addresses`, and `user_payment_methods`

**Example Response (Minimal Registration):**
```json
{
  "status": {
    "code": 200,
    "message": "User was retrieved successfully."
  },
  "data": {
    "id": 15,
    "email": "user@example.com",
    "is_verified": false,
    "confirmed_at": "2025-10-28T15:52:36.657Z",
    "created_at": "2025-10-28T15:51:57.822Z",
    "updated_at": "2025-10-28T15:52:36.658Z",
    "user_detail": {
      "id": 14,
      "first_name": "Alice",
      "middle_name": null,
      "last_name": "Johnson",
      "dob": "1995-03-10"
    },
    "phones": [],
    "user_addresses": [],
    "user_payment_methods": [
      {
        "id": 12,
        "balance": "0.0",
        "payment_type": null
      }
    ]
  }
}
```

<details>
<summary><b>Example Response (Full Registration with All Nested Data)</b></summary>

```json
{
  "status": {
    "code": 200,
    "message": "User was retrieved successfully."
  },
  "data": {
    "id": 14,
    "email": "user@example.com",
    "is_verified": false,
    "confirmed_at": "2025-10-28T15:47:17.724Z",
    "created_at": "2025-10-28T15:46:28.302Z",
    "updated_at": "2025-10-28T15:47:17.725Z",
    "user_detail": {
      "id": 13,
      "first_name": "John",
      "middle_name": "M",
      "last_name": "Doe",
      "dob": "1990-01-15"
    },
    "phones": [
      {
        "id": 1,
        "phone_no": "+639171234567",
        "phone_type": "mobile"
      }
    ],
    "user_addresses": [
      {
        "id": 2,
        "is_default": true,
        "address": {
          "id": 18,
          "unit_no": "123",
          "street_no": "456",
          "address_line1": "Main Street",
          "address_line2": "Subdivision",
          "barangay": "Barangay 1",
          "city": "Manila",
          "region": "NCR",
          "zipcode": "1000",
          "country_id": 1
        }
      }
    ],
    "user_payment_methods": [
      {
        "id": 10,
        "balance": "5000.0",
        "payment_type": "e_wallet"
      }
    ]
  }
}
```
</details>

#### PATCH /api/v1/users/:id
Update user profile and nested attributes.
- **Auth Required**: User JWT token (users can only update their own profile)
- **Body**: Same structure as registration, but all fields are optional. Include `id` for existing nested records.

**Example - Update User Detail and Add New Phone:**
```json
{
  "user": {
    "user_detail_attributes": {
      "id": 13,
      "first_name": "Jane",
      "middle_name": "Marie",
      "last_name": "Smith",
      "dob": "1992-05-20"
    },
    "phones_attributes": [
      {
        "id": 1,
        "phone_no": "+639171234567",
        "phone_type": "mobile"
      },
      {
        "phone_no": "+639281234567",
        "phone_type": "home"
      }
    ]
  }
}
```

**Example - Delete a Nested Record:**
```json
{
  "user": {
    "phones_attributes": [
      {
        "id": 2,
        "_destroy": true
      }
    ]
  }
}
```

**Example - Update Address with New Barangay:**
```json
{
  "user": {
    "user_addresses_attributes": [
      {
        "id": 2,
        "is_default": false,
        "address_attributes": {
          "id": 18,
          "unit_no": "999",
          "street_no": "888",
          "address_line1": "Updated Street",
          "address_line2": "New Subdivision",
          "barangay": "Barangay 5",
          "city": "Quezon City",
          "region": "NCR",
          "zipcode": "1100",
          "country_id": 1
        }
      }
    ]
  }
}
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "User updated successfully"
  },
  "data": {
    "id": 14,
    "email": "user@example.com",
    "is_verified": false,
    "created_at": "2025-10-28T15:46:28.302Z",
    "updated_at": "2025-10-28T15:47:17.725Z",
    "user_detail": {
      "id": 13,
      "first_name": "Jane",
      "middle_name": "Marie",
      "last_name": "Smith",
      "dob": "1992-05-20"
    },
    "phones": [...],
    "user_addresses": [...],
    "user_payment_methods": [...]
  }
}
```

#### DELETE /api/v1/users/:id
Delete user account and all associated data.
- **Auth Required**: User JWT token (users can only delete their own account)
- **Returns**: `{"message": "User deleted successfully"}`

**Note**: This permanently deletes the user and all nested records (detail, phones, addresses, payment methods, shopping cart, orders, receipts).

---

### Admin Users (Management & Warehouse)

The system has two types of admin users:
- **Management**: Full access - can view/manage all admin users, products, orders, and system resources
- **Warehouse**: Limited access - can view/update warehouse orders and their own profile only

Admin users require JWT authentication with `admin_user` scope. All admin endpoints use the `Authorization: Bearer <token>` header.

---

### Admin Authentication

#### POST /api/v1/admin_users/login
Admin user login (Management or Warehouse).
- **Auth Required**: None
- **Body**:
```json
{
  "admin_user": {
    "email": "admin@admin.com",
    "password": "admin123456"
  }
}
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Logged in successfully.",
    "data": {
      "admin_user": {
        "id": 1,
        "email": "admin@admin.com",
        "admin_role": "management"
      }
    }
  }
}
```
- **Note**: JWT token is returned in the `Authorization` response header as `Bearer <token>`

#### DELETE /api/v1/admin_users/logout
Admin user logout.
- **Auth Required**: Admin JWT token
- **Returns**: `{"message": "Logged out successfully"}`

#### POST /api/v1/admin_users/signup
Create a new admin user account (self-registration).
- **Auth Required**: None
- **Body**:
```json
{
  "admin_user": {
    "email": "newadmin@company.com",
    "password": "password123",
    "password_confirmation": "password123",
    "admin_role": "warehouse",
    "admin_detail_attributes": {
      "first_name": "John",
      "middle_name": "Paul",
      "last_name": "Doe",
      "dob": "1990-05-15"
    }
  }
}
```
- **Admin Roles**: `management` or `warehouse`
- **Required Fields**: `email`, `password`, `password_confirmation`, `admin_role`, and `admin_detail_attributes` (with `first_name`, `last_name`, and `dob`)
- **Note**: Account requires email confirmation before login

**Example Response:**
```json
{
  "status": {
    "code": 201,
    "message": "Signed up successfully."
  },
  "data": {
    "id": 6,
    "email": "newadmin@company.com",
    "admin_role": "warehouse"
  }
}
```

---

### Admin User Management

#### GET /api/v1/admin_users
List all admin users (Management Only).
- **Auth Required**: Management Admin JWT token
- **Returns**: Array of all admin users with details, phones, addresses, and company sites

**Example Response:**
```json
{
  "admin_users": {
    "1": {
      "id": 1,
      "email": "admin@admin.com",
      "admin_role": "management",
      "confirmed_at": "2025-01-16T10:00:00.000Z",
      "created_at": "2025-01-16T10:00:00.000Z",
      "updated_at": "2025-01-16T10:00:00.000Z",
      "admin_detail": {
        "first_name": "Admin",
        "middle_name": null,
        "last_name": "User",
        "dob": "1990-01-01"
      },
      "admin_phones": [
        {
          "id": 1,
          "phone_no": "+1234567890",
          "phone_type": "mobile"
        }
      ],
      "admin_addresses": [
        {
          "id": 1,
          "is_default": true,
          "address": {
            "id": 1,
            "unit_no": "Suite 100",
            "street_no": "123",
            "address_line1": "Main Street",
            "address_line2": null,
            "city": "New York",
            "region": "NY",
            "zipcode": "10001",
            "country_id": 1
          }
        }
      ],
      "company_sites": [
        {
          "id": 1,
          "title": "JPB Headquarters",
          "site_type": "headquarters"
        }
      ]
    }
  }
}
```

#### GET /api/v1/admin_users/:id
Get a specific admin user.
- **Auth Required**: Admin JWT token
- **Authorization**:
  - **Management**: Can view any admin user
  - **Warehouse**: Can only view their own profile
- **Returns**: Full admin user details including personal info, phones, addresses, and company sites

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Admin user was retrieved successfully."
  },
  "data": {
    "id": 1,
    "email": "admin@admin.com",
    "admin_role": "management",
    "created_at": "2025-01-16T10:00:00.000Z",
    "updated_at": "2025-01-16T10:00:00.000Z",
    "admin_detail": {
      "id": 1,
      "first_name": "Admin",
      "middle_name": null,
      "last_name": "User",
      "dob": "1990-01-01"
    },
    "admin_phones": [
      {
        "id": 1,
        "phone_no": "+1234567890",
        "phone_type": "mobile"
      }
    ],
    "admin_addresses": [
      {
        "id": 1,
        "is_default": true,
        "address": {
          "id": 1,
          "unit_no": "Suite 100",
          "street_no": "123",
          "address_line1": "Main Street",
          "address_line2": null,
          "city": "New York",
          "region": "NY",
          "zipcode": "10001",
          "country_id": 1
        }
      }
    ],
    "company_sites": [
      {
        "id": 1,
        "title": "JPB Headquarters",
        "site_type": "headquarters",
        "address": {
          "city": "New York",
          "region": "NY"
        }
      }
    ]
  }
}
```

#### PATCH /api/v1/admin_users/:id
Update an admin user.
- **Auth Required**: Admin JWT token
- **Authorization**:
  - **Management**: Can update any admin user
  - **Warehouse**: Can only update their own profile
- **Body** (update personal details):
```json
{
  "admin_user": {
    "admin_detail_attributes": {
      "id": 1,
      "first_name": "John",
      "middle_name": "Paul",
      "last_name": "Doe",
      "dob": "1985-05-15"
    }
  }
}
```

**Body** (add/update phone):
```json
{
  "admin_user": {
    "admin_phones_attributes": [
      {
        "id": 1,
        "phone_no": "+1987654321",
        "phone_type": "work"
      }
    ]
  }
}
```

**Body** (add/update address):
```json
{
  "admin_user": {
    "admin_addresses_attributes": [
      {
        "is_default": true,
        "address_attributes": {
          "unit_no": "Apt 5B",
          "street_no": "456",
          "address_line1": "Oak Avenue",
          "address_line2": null,
          "city": "Los Angeles",
          "region": "CA",
          "zipcode": "90001",
          "country_id": 1
        }
      }
    ]
  }
}
```

**Body** (delete phone - set `_destroy: true`):
```json
{
  "admin_user": {
    "admin_phones_attributes": [
      {
        "id": 1,
        "_destroy": true
      }
    ]
  }
}
```

**Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Admin user updated successfully"
  },
  "data": {
    "id": 1,
    "email": "admin@admin.com",
    "admin_role": "management",
    "admin_detail": {
      "first_name": "John",
      "last_name": "Doe"
    }
  }
}
```

#### DELETE /api/v1/admin_users/:id
Soft delete an admin user (disable account).
- **Auth Required**: Management Admin JWT token
- **Returns**: `{"message": "Admin user disabled successfully"}`
- **Note**: This performs a soft delete (sets `deleted_at` timestamp). The admin user account is disabled but data is preserved. Used when an admin leaves the company.

---

### User Management (Management Admin Only)

Management admins have access to comprehensive user data endpoints for system oversight and customer support.

#### GET /api/v1/users
List all regular users in the system.
- **Auth Required**: Management Admin JWT token
- **Supports**: Pagination (default: 20 per page)
- **Returns**: Array of all users with basic information

#### GET /api/v1/users/:id/full_details
Get complete user details including all transactions, orders, and warehouse shipments.
- **Auth Required**: Management Admin JWT token
- **Returns**: Comprehensive user data including:
  - User profile information (email, verification status)
  - User detail (name, date of birth)
  - Phone numbers
  - User addresses with full address details and country
  - Payment methods with current balance
  - All receipts (deposits, withdrawals, purchases, donations)
  - All cart orders with:
    - Order total cost, status, and payment status
    - Social program information (if donation was made)
    - Warehouse orders (inventory ID, quantity, product status)

**Example Request:**
```bash
curl -X GET http://localhost:3003/api/v1/users/24/full_details \
  -H "Authorization: Bearer MANAGEMENT_ADMIN_TOKEN"
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "User full details retrieved successfully."
  },
  "data": {
    "id": 24,
    "email": "user@example.com",
    "is_verified": true,
    "confirmed_at": "2025-10-28T15:52:36.657Z",
    "created_at": "2025-10-28T15:51:57.822Z",
    "updated_at": "2025-10-28T15:52:36.658Z",
    "user_detail": {
      "id": 14,
      "first_name": "John",
      "middle_name": "M",
      "last_name": "Doe",
      "dob": "1990-01-15"
    },
    "phones": [
      {
        "id": 1,
        "phone_no": "+639171234567",
        "phone_type": "mobile"
      }
    ],
    "user_addresses": [
      {
        "id": 7,
        "is_default": true,
        "address": {
          "id": 18,
          "unit_no": "123",
          "street_no": "456",
          "address_line1": "Main Street",
          "address_line2": "Subdivision",
          "barangay": "Barangay 1",
          "city": "Manila",
          "region": "NCR",
          "zipcode": "1000",
          "country_id": 1,
          "country": "Philippines"
        }
      }
    ],
    "user_payment_methods": [
      {
        "id": 12,
        "balance": "3226.01",
        "payment_type": "e_wallet"
      }
    ],
    "receipts": [
      {
        "id": 45,
        "transaction_type": "purchase",
        "amount": "1773.99",
        "balance_before": "5000.0",
        "balance_after": "3226.01",
        "description": "Purchase - Order #8",
        "user_cart_order_id": 8,
        "created_at": "2025-11-01T10:31:24.000Z"
      },
      {
        "id": 46,
        "transaction_type": "withdraw",
        "amount": "1773.99",
        "balance_before": "5000.0",
        "balance_after": "3226.01",
        "description": "Payment for Order #8",
        "user_cart_order_id": null,
        "created_at": "2025-11-01T10:31:24.000Z"
      },
      {
        "id": 47,
        "transaction_type": "donation",
        "amount": "141.92",
        "balance_before": "3226.01",
        "balance_after": "3226.01",
        "description": "Donation to Community Food Program (8% of Order #8)",
        "user_cart_order_id": 8,
        "created_at": "2025-11-01T10:31:24.000Z",
        "social_programs": [
          {
            "id": 1,
            "title": "Community Food Program",
            "description": "Providing meals to families in need"
          }
        ]
      }
    ],
    "user_cart_orders": [
      {
        "id": 8,
        "total_cost": "1773.99",
        "is_paid": true,
        "cart_status": "approved",
        "user_address_id": 20,  // Note: JSON key unchanged for frontend compatibility, but now references address_id directly
        "social_program_id": 1,
        "created_at": "2025-11-01T10:31:24.000Z",
        "updated_at": "2025-11-01T10:31:24.000Z",
        "social_program": {
          "id": 1,
          "title": "Community Food Program",
          "description": "Providing meals to families in need"
        },
        "warehouse_orders": [
          {
            "id": 9,
            "inventory_id": 47,
            "company_site_id": 2,
            "qty": 2,
            "product_status": "storage",
            "created_at": "2025-11-01T10:31:24.000Z",
            "updated_at": "2025-11-01T10:31:24.000Z"
          },
          {
            "id": 10,
            "inventory_id": 52,
            "company_site_id": 2,
            "qty": 3,
            "product_status": "storage",
            "created_at": "2025-11-01T10:31:24.000Z",
            "updated_at": "2025-11-01T10:31:24.000Z"
          },
          {
            "id": 11,
            "inventory_id": 57,
            "company_site_id": 2,
            "qty": 1,
            "product_status": "storage",
            "created_at": "2025-11-01T10:31:24.000Z",
            "updated_at": "2025-11-01T10:31:24.000Z"
          }
        ]
      }
    ]
  }
}
```

**Use Cases:**
- Customer support: View complete customer history and order status
- Order fulfillment: Access all warehouse orders for a specific user
- Financial tracking: Review all user transactions including donations
- Issue resolution: Investigate user complaints with full context
- Analytics: Analyze user purchasing patterns and social program participation

---

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

**Overview:**
Promotions use **percentage-based discounts** (1-100%). When applied to products or categories, the discount percentage is calculated from the original price.

**How it works:**
- Direct product promotions take precedence over category promotions
- All products in a promoted category automatically receive the discount
- Final price = Original price × (1 - discount_percentage / 100)

**Example:**
- 60% discount on $100 product = $40 final price (saves $60)
- 30% discount on $50 product = $35 final price (saves $15)

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
    "discount_amount": 60
  }
}
```
- **Note**: `discount_amount` must be between 1 and 100 (percentage)
- **Example**: `60` = 60% discount

**Example Request:**
```bash
curl -X POST http://localhost:3001/api/v1/promotions \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"promotion":{"discount_amount":60}}'
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Promotion fetched successfully"
  },
  "data": {
    "id": 7,
    "discount_amount": "60.0",
    "products_count": 0,
    "product_categories": [],
    "products": []
  }
}
```

#### PATCH /api/v1/promotions/:id
Update a promotion.
- **Auth Required**: Management Admin JWT token
- **Body**:
```json
{
  "promotion": {
    "discount_amount": 30
  }
}
```
- **Note**: `discount_amount` must be between 1 and 100 (percentage)

#### DELETE /api/v1/promotions/:id
Delete a promotion.
- **Auth Required**: Management Admin JWT token
- **Returns**: `{"message": "Promotion deleted successfully"}`
- **Note**: Associated products will have their promotion_id set to NULL (nullify)

---

### How Product Promotions Are Displayed

When a product has a promotion (either direct or via category), the API automatically calculates and returns discount information:

**Product Response Fields:**
- `price` - Original price
- `final_price` - Price after discount applied
- `discount_percentage` - The percentage discount (0-100)
- `discount_amount_dollars` - Dollar amount saved
- `promotion` - Promotion object with details

**Example Product with 60% Promotion:**
```json
{
  "data": {
    "id": 1,
    "title": "Fjallraven Backpack",
    "price": "109.95",
    "final_price": "43.98",
    "discount_percentage": "60.0",
    "discount_amount_dollars": "65.97",
    "promotion": {
      "id": 7,
      "discount_amount": "60.0"
    }
  }
}
```

**Example Product with Category Promotion (30% off Jewelery):**
```json
{
  "data": {
    "id": 5,
    "title": "Gold Plated Necklace",
    "price": "695.0",
    "final_price": "486.5",
    "discount_percentage": "30.0",
    "discount_amount_dollars": "208.5",
    "product_category": {
      "id": 3,
      "title": "jewelery"
    }
  }
}
```

**Shopping Cart with Promotions:**
Shopping cart items automatically display discounted prices. The `subtotal` is calculated using `final_price` not original `price`.

```json
{
  "data": [
    {
      "id": 101,
      "product_id": 1,
      "qty": 2,
      "subtotal": "87.96",
      "product": {
        "title": "Fjallraven Backpack",
        "price": "109.95",
        "final_price": "43.98",
        "discount_percentage": "60.0",
        "discount_amount_dollars": "65.97"
      }
    }
  ]
}
```

**Order Processing:**
When a user creates an order, the `total_cost` is calculated using `final_price` (with promotions applied), not the original price.

---

### Promotions Categories (Join Table - Management Admin Only)

Manage associations between promotions and product categories. When a promotion is linked to a category, **all products** in that category automatically receive the discount.

**Use Case:** Apply a site-wide "30% off all Jewelery" promotion without updating individual products.

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
List all products with pagination support.
- **Auth Required**: None (public access)
- **Pagination**: Yes (default: 20 per page, max: 100)
- **Query Parameters**: 
  - `page` (optional): Page number
  - `per_page` (optional): Items per page
- **Returns**: Paginated array of products with category, producer, and promotion details

**Example Request with Pagination**:
```bash
GET /api/v1/products?page=1&per_page=10
```

**Example Response**:
```json
{
  "status": {
    "code": 200,
    "message": "Products retrieved successfully"
  },
  "pagination": {
    "current_page": 1,
    "per_page": 10,
    "total_entries": 20,
    "total_pages": 2,
    "next_page": 2,
    "previous_page": null
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
Create a new product with either image upload or URL.
- **Auth Required**: Management Admin JWT token

**Method 1: Image File Upload (multipart/form-data)**
```bash
curl -X POST http://localhost:3001/api/v1/products \
  -H "Authorization: Bearer <token>" \
  -F "product[title]=Running Shoes" \
  -F "product[description]=High-quality running shoes" \
  -F "product[price]=99.99" \
  -F "product[product_category_id]=1" \
  -F "product[producer_id]=1" \
  -F "product[promotion_id]=2" \
  -F "product[product_image]=@/path/to/image.jpg"
```

**Method 2: Image URL (application/json)**
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

**React-Vite Frontend Example (File Upload)**

The backend automatically handles Cloudinary upload - you just send the file to the endpoint!

```javascript
// Component: CreateProductForm.jsx
import { useState } from 'react';

const CreateProductForm = () => {
  const [imageFile, setImageFile] = useState(null);
  const [imagePreview, setImagePreview] = useState(null);
  const [loading, setLoading] = useState(false);

  // Handle file selection
  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImageFile(file);
      // Create preview URL
      setImagePreview(URL.createObjectURL(file));
    }
  };

  // Submit form with image
  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);

    try {
      // Create FormData object
      const formData = new FormData();
      formData.append('product[title]', e.target.title.value);
      formData.append('product[description]', e.target.description.value);
      formData.append('product[price]', e.target.price.value);
      formData.append('product[product_category_id]', e.target.category.value);
      formData.append('product[producer_id]', e.target.producer.value);
      
      // Add image file if selected
      if (imageFile) {
        formData.append('product[product_image]', imageFile);
      }

      // Send to your Rails API
      const response = await fetch('http://localhost:3001/api/v1/products', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
          // NOTE: Do NOT set 'Content-Type' header - browser sets it automatically with boundary
        },
        body: formData
      });

      const data = await response.json();
      
      if (response.ok) {
        console.log('Product created:', data);
        console.log('Image URL from Cloudinary:', data.data.product_image_url);
        // The product_image_url will be a Cloudinary URL in production:
        // https://res.cloudinary.com/dftqk1gfb/image/upload/v1234567890/xyz123.jpg
      } else {
        console.error('Error:', data.errors);
      }
    } catch (error) {
      console.error('Upload failed:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input type="text" name="title" placeholder="Product Title" required />
      <textarea name="description" placeholder="Description" />
      <input type="number" name="price" step="0.01" placeholder="Price" required />
      <select name="category" required>
        <option value="1">Men's Clothing</option>
        {/* Add other categories */}
      </select>
      <select name="producer" required>
        <option value="1">Producer 1</option>
        {/* Add other producers */}
      </select>
      
      {/* File input for image */}
      <div>
        <label>Product Image:</label>
        <input 
          type="file" 
          accept="image/*" 
          onChange={handleFileChange}
        />
        {imagePreview && (
          <img src={imagePreview} alt="Preview" style={{width: '200px'}} />
        )}
      </div>

      <button type="submit" disabled={loading}>
        {loading ? 'Uploading...' : 'Create Product'}
      </button>
    </form>
  );
};

export default CreateProductForm;
```

**Key Points:**
- ✅ **Endpoint**: `POST http://localhost:3001/api/v1/products` (same as before!)
- ✅ **Content-Type**: Browser automatically sets `multipart/form-data` with boundary
- ✅ **Cloudinary Upload**: Happens automatically in the backend - you don't need to do anything special!
- ✅ **Response**: You get back a Cloudinary URL in `product_image_url`

**What Happens Behind the Scenes:**
1. Your React app sends the file to Rails API
2. Rails Active Storage receives the file
3. Active Storage checks `config.active_storage.service` → sees `:cloudinary`
4. Active Storage automatically uploads to your Cloudinary account
5. Cloudinary returns a permanent URL
6. Rails saves the product with Cloudinary reference
7. Your React app receives the Cloudinary URL in the response

**Production vs Development URLs:**
- **Development (local storage)**: `/rails/active_storage/blobs/redirect/...`
- **Production (Cloudinary)**: `https://res.cloudinary.com/dftqk1gfb/image/upload/...`


- **Required Fields**: `title`, `price`, `product_category_id`, `producer_id`
- **Optional Fields**: `description`, `promotion_id`, `product_image` (file), `product_image_url` (string)
- **Image Priority**: Uploaded `product_image` takes precedence over `product_image_url`
- **Validation**: 
  - `title` must be present
  - `price` must be >= 0
  - `product_category_id` and `producer_id` must reference existing records
  - `promotion_id` is optional (nullable)

**Example Response**:
```json
{
  "status": {
    "code": 200,
    "message": "Product created successfully"
  },
  "data": {
    "id": 21,
    "title": "Running Shoes",
    "description": "High-quality running shoes",
    "price": "99.99",
    "final_price": "99.99",
    "discount_percentage": 0,
    "discount_amount_dollars": "0.0",
    "product_image_url": "/rails/active_storage/blobs/redirect/...",
    "product_category": {
      "id": 1,
      "title": "men's clothing"
    },
    "producer": {
      "id": 1,
      "title": "Nestle Inc.",
      "address": {
        "id": 1,
        "unit_no": "2020",
        "street_no": "26th Ave",
        "barangay": "Unknown",
        "city": "Taguig",
        "zipcode": "1244",
        "country": "Philippines"
      }
    },
    "promotion": null,
    "created_at": "2025-10-29T05:42:23.720Z",
    "updated_at": "2025-10-29T05:42:23.761Z"
  }
}
```

#### PATCH /api/v1/products/:id
Update a product with optional image upload or URL.
- **Auth Required**: Management Admin JWT token

**Method 1: Update with Image File (multipart/form-data)**
```bash
curl -X PATCH http://localhost:3001/api/v1/products/:id \
  -H "Authorization: Bearer <token>" \
  -F "product[title]=Updated Product Name" \
  -F "product[price]=149.99" \
  -F "product[product_image]=@/path/to/new-image.jpg"
```

**Method 2: Update with Image URL (application/json)**
```json
{
  "product": {
    "title": "Updated Product Name",
    "price": 149.99,
    "product_image_url": "https://example.com/new-image.jpg"
  }
}
```

**React-Vite Frontend Example (Update with File)**

```javascript
// Component: UpdateProductForm.jsx
const UpdateProductForm = ({ productId, currentProduct }) => {
  const [newImage, setNewImage] = useState(null);
  const [imagePreview, setImagePreview] = useState(currentProduct.product_image_url);

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setNewImage(file);
      setImagePreview(URL.createObjectURL(file));
    }
  };

  const handleUpdate = async (e) => {
    e.preventDefault();
    
    const formData = new FormData();
    formData.append('product[title]', e.target.title.value);
    formData.append('product[price]', e.target.price.value);
    
    // Only add image if a new one was selected
    if (newImage) {
      formData.append('product[product_image]', newImage);
    }

    const response = await fetch(`http://localhost:3001/api/v1/products/${productId}`, {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('adminToken')}`
      },
      body: formData
    });

    const data = await response.json();
    if (response.ok) {
      console.log('Product updated!');
      console.log('New image URL:', data.data.product_image_url);
    }
  };

  return (
    <form onSubmit={handleUpdate}>
      <input 
        type="text" 
        name="title" 
        defaultValue={currentProduct.title} 
      />
      <input 
        type="number" 
        name="price" 
        step="0.01" 
        defaultValue={currentProduct.price} 
      />
      
      <div>
        <label>Change Image:</label>
        <input type="file" accept="image/*" onChange={handleFileChange} />
        {imagePreview && (
          <img src={imagePreview} alt="Preview" style={{width: '200px'}} />
        )}
      </div>

      <button type="submit">Update Product</button>
    </form>
  );
};
```

**Updating Image Behavior:**
- If you upload a new file → Old Cloudinary image is replaced
- If you don't upload a file → Existing image stays unchanged
- Backend handles Cloudinary upload automatically

**React-Vite: Displaying Product Images**

```javascript
// Component: ProductCard.jsx
const ProductCard = ({ product }) => {
  return (
    <div className="product-card">
      <img 
        src={product.product_image_url} 
        alt={product.title}
        onError={(e) => {
          // Fallback image if Cloudinary URL fails
          e.target.src = '/placeholder-image.png';
        }}
      />
      <h3>{product.title}</h3>
      <p>${product.price}</p>
    </div>
  );
};

// The product_image_url automatically works with:
// - Local development: /rails/active_storage/blobs/redirect/...
// - Production: https://res.cloudinary.com/dftqk1gfb/image/upload/...
```

**React-Vite: Fetching Products**

```javascript
// Hook: useProducts.js
import { useState, useEffect } from 'react';

export const useProducts = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        const response = await fetch('http://localhost:3001/api/v1/products');
        const data = await response.json();
        setProducts(data.data); // Array of products
      } catch (error) {
        console.error('Error fetching products:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, []);

  return { products, loading };
};

// Usage in component:
const ProductList = () => {
  const { products, loading } = useProducts();

  if (loading) return <div>Loading...</div>;

  return (
    <div className="product-grid">
      {products.map(product => (
        <ProductCard key={product.id} product={product} />
      ))}
    </div>
  );
};
```

**Example - Remove promotion from product**:
```json
{
  "product": {
    "promotion_id": null
  }
}
```

**Note**: When updating a product with an uploaded `product_image`, it will replace any existing uploaded image. The `product_image_url` field is ignored if an uploaded image is attached.

#### DELETE /api/v1/products/:id/delete_image
Delete only the uploaded image attachment from a product (keeps the product).
- **Auth Required**: Management Admin JWT token
- **Note**: This only removes uploaded images (Active Storage attachments). If the product has a `product_image_url`, it will remain and be used after deletion.

**Example Request**:
```bash
curl -X DELETE http://localhost:3001/api/v1/products/:id/delete_image \
  -H "Authorization: Bearer <token>"
```

**Example Response (Success)**:
```json
{
  "message": "Product image deleted successfully",
  "product": {
    "id": 21,
    "title": "Running Shoes",
    "product_image_url": "https://example.com/fallback.jpg"
  }
}
```

**Example Response (No Image Attached)**:
```json
{
  "error": "No image attached to this product"
}
```

#### DELETE /api/v1/products/:id
Delete a product entirely.
- **Auth Required**: Management Admin JWT token
- **Returns**: `{"message": "Product deleted successfully"}`
- **Note**: This will delete the product, its uploaded image (if any), and all associated shopping_cart_items and inventories (cascade delete)

---

### Product Images - Important Notes

**Image Priority System**:
1. If a product has an uploaded image attachment (`product_image`), it will be used
2. If no uploaded image exists, the `product_image_url` field will be used
3. If neither exists, `product_image_url` will be `null`

**Supported Operations**:
- **Create with file upload**: Use `multipart/form-data` with `product[product_image]`
- **Create with URL**: Use `application/json` with `product[product_image_url]`
- **Update image file**: Upload new file with `multipart/form-data` (replaces existing)
- **Update image URL**: Use `application/json` with `product[product_image_url]` (only used if no uploaded image exists)
- **Delete uploaded image**: Use `DELETE /api/v1/products/:id/delete_image` (fallback to URL if present)
- **Delete product**: Removes product and all associated data including images

**Backend Storage**:
- **Development**: Local disk storage (`Rails.root/storage`)
- **Production**: Cloudinary cloud storage (persistent across deployments)
- Uploaded images are stored using Rails Active Storage with Cloudinary service
- Image URLs are returned in all product responses with absolute paths
- Images are delivered via Cloudinary's CDN for fast global delivery

**Cloudinary Configuration** (Production):
- Cloud storage ensures images persist across Render deployments
- Automatically configured via `CLOUDINARY_URL` environment variable
- Free tier: 25GB storage, 25GB bandwidth/month
- To deploy: Set `CLOUDINARY_URL` in Render environment variables
- Format: `cloudinary://API_KEY:API_SECRET@CLOUD_NAME`

---

### Frontend Integration Summary

**The Magic: You Don't Need Cloudinary SDK in React!**

Your React-Vite frontend doesn't need any Cloudinary libraries. Just use standard `fetch` with `FormData`:

```javascript
// ✅ This is all you need!
const formData = new FormData();
formData.append('product[product_image]', imageFile);

fetch('http://localhost:3001/api/v1/products', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}` },
  body: formData
});

// Rails Active Storage + Cloudinary handle the rest automatically!
```

**The Complete Flow:**

1. **Create Product (React)**
   ```javascript
   // User selects file → Upload to Rails → Rails uploads to Cloudinary → Done!
   <input type="file" onChange={(e) => setImageFile(e.target.files[0])} />
   ```

2. **Display Products (React)**
   ```javascript
   // Just use the product_image_url from the API response
   <img src={product.product_image_url} alt={product.title} />
   ```

3. **Update Product (React)**
   ```javascript
   // Upload new file → Rails replaces old Cloudinary image → Done!
   formData.append('product[product_image]', newImageFile);
   ```

4. **Delete Image (React)**
   ```javascript
   // Delete only the image, keep the product
   fetch(`/api/v1/products/${id}/delete_image`, { method: 'DELETE' });
   ```

**Important: Content-Type Header**
```javascript
// ❌ DON'T do this when uploading files:
headers: {
  'Content-Type': 'multipart/form-data',  // Wrong! Browser needs to set boundary
  'Authorization': `Bearer ${token}`
}

// ✅ DO this instead:
headers: {
  'Authorization': `Bearer ${token}`  // Only auth header, browser handles Content-Type
}
```

**Environment Differences:**

| Environment | Image URL Format | Storage Location |
|-------------|-----------------|------------------|
| **Development** | `/rails/active_storage/blobs/redirect/...` | Local disk (`storage/`) |
| **Production** | `https://res.cloudinary.com/dftqk1gfb/image/upload/...` | Cloudinary cloud |

Both work seamlessly with `<img src={product.product_image_url} />` in React!

---

### Cloudinary Image Transformations

**No Backend Code Required!** Cloudinary handles image transformations on-the-fly via URL parameters. Simply modify the image URL in your React frontend to get different versions of the same image.

#### Basic Transformation Syntax

Cloudinary URLs follow this pattern:
```
https://res.cloudinary.com/{cloud_name}/image/upload/{transformations}/{version}/{public_id}.{format}
```

Transformations are inserted between `/upload/` and the version/filename.

#### Common Transformations

**Resize (Width)**
```javascript
// Original from API
const originalUrl = product.product_image_url;
// "https://res.cloudinary.com/dftqk1gfb/image/upload/v123/product.jpg"

// Resize to 300px width, maintain aspect ratio
const resizedUrl = originalUrl.replace('/upload/', '/upload/w_300/');
// "https://res.cloudinary.com/dftqk1gfb/image/upload/w_300/v123/product.jpg"
```

**Crop to Square Thumbnail**
```javascript
// 200x200 square, crop to fill, focus on center
const thumbnailUrl = originalUrl.replace('/upload/', '/upload/w_200,h_200,c_fill/');
// "https://res.cloudinary.com/dftqk1gfb/image/upload/w_200,h_200,c_fill/v123/product.jpg"
```

**Crop with Gravity (Smart Crop)**
```javascript
// 400x300, crop to fill, focus on faces or center
const smartCropUrl = originalUrl.replace('/upload/', '/upload/w_400,h_300,c_fill,g_auto/');
// "https://res.cloudinary.com/dftqk1gfb/image/upload/w_400,h_300,c_fill,g_auto/v123/product.jpg"
```

**Quality Optimization**
```javascript
// Auto quality (balances quality vs file size)
const optimizedUrl = originalUrl.replace('/upload/', '/upload/q_auto/');
// "https://res.cloudinary.com/dftqk1gfb/image/upload/q_auto/v123/product.jpg"
```

**Format Conversion**
```javascript
// Convert to WebP format
const webpUrl = originalUrl.replace('/upload/', '/upload/f_auto/');
// Cloudinary automatically serves WebP to browsers that support it
```

**Combine Multiple Transformations**
```javascript
// 500px wide, auto quality, auto format
const transformedUrl = originalUrl.replace('/upload/', '/upload/w_500,q_auto,f_auto/');
// "https://res.cloudinary.com/dftqk1gfb/image/upload/w_500,q_auto,f_auto/v123/product.jpg"
```

#### React Component Examples

**Responsive Product Card**
```javascript
const ProductCard = ({ product }) => {
  const getImageUrl = (transformations = '') => {
    if (!product.product_image_url) return '/placeholder.png';
    return product.product_image_url.replace('/upload/', `/upload/${transformations}/`);
  };

  return (
    <div className="product-card">
      {/* Thumbnail - 300x300 square */}
      <img 
        src={getImageUrl('w_300,h_300,c_fill,q_auto,f_auto')}
        alt={product.title}
        loading="lazy"
      />
      <h3>{product.title}</h3>
      <p>${product.price}</p>
    </div>
  );
};
```

**Product Detail with Zoom**
```javascript
const ProductDetail = ({ product }) => {
  const [imageSize, setImageSize] = useState('medium');
  
  const getImageUrl = (size) => {
    if (!product.product_image_url) return '/placeholder.png';
    
    const sizes = {
      thumbnail: 'w_150,h_150,c_fill',
      medium: 'w_500,h_500,c_fit',
      large: 'w_1000,h_1000,c_fit',
      zoom: 'w_2000,h_2000,c_fit'
    };
    
    return product.product_image_url.replace(
      '/upload/', 
      `/upload/${sizes[size]},q_auto,f_auto/`
    );
  };

  return (
    <div className="product-detail">
      <img 
        src={getImageUrl(imageSize)}
        alt={product.title}
        onClick={() => setImageSize(imageSize === 'medium' ? 'large' : 'medium')}
      />
      
      <div className="thumbnails">
        {['thumbnail', 'medium', 'large'].map(size => (
          <img 
            key={size}
            src={getImageUrl('thumbnail')}
            onClick={() => setImageSize(size)}
          />
        ))}
      </div>
    </div>
  );
};
```

**Utility Function for Transformations**
```javascript
// utils/cloudinaryTransform.js
export const transformCloudinaryUrl = (url, transformations) => {
  if (!url || !url.includes('cloudinary.com')) {
    return url; // Return as-is if not a Cloudinary URL
  }
  
  return url.replace('/upload/', `/upload/${transformations}/`);
};

// Usage in components:
import { transformCloudinaryUrl } from '@/utils/cloudinaryTransform';

const thumbnailUrl = transformCloudinaryUrl(
  product.product_image_url, 
  'w_300,h_300,c_fill,q_auto,f_auto'
);
```

#### Transformation Parameters Reference

| Parameter | Description | Example |
|-----------|-------------|---------|
| `w_X` | Width in pixels | `w_300` |
| `h_X` | Height in pixels | `h_200` |
| `c_X` | Crop mode | `c_fill`, `c_fit`, `c_scale`, `c_thumb` |
| `g_X` | Gravity/focus | `g_auto`, `g_face`, `g_center` |
| `q_X` | Quality | `q_auto`, `q_80` (1-100) |
| `f_X` | Format | `f_auto`, `f_webp`, `f_jpg` |
| `r_X` | Radius/rounded corners | `r_10`, `r_max` (circle) |
| `e_X` | Effects | `e_grayscale`, `e_sepia`, `e_blur:300` |
| `b_X` | Background color | `b_white`, `b_rgb:ff0000` |

#### Crop Modes Explained

- **`c_fill`**: Resize and crop to fill dimensions exactly (may crop image)
- **`c_fit`**: Resize to fit within dimensions (maintains aspect ratio, no cropping)
- **`c_scale`**: Scale to exact dimensions (may distort)
- **`c_thumb`**: Generate thumbnail with smart cropping
- **`c_pad`**: Resize and add padding to fit exact dimensions

#### Best Practices

**1. Always Use Auto Quality and Format**
```javascript
// ✅ Good - Let Cloudinary optimize
'w_500,q_auto,f_auto'

// ❌ Bad - Fixed quality/format
'w_500,q_100,f_jpg'
```

**2. Use Lazy Loading**
```javascript
<img 
  src={transformedUrl} 
  loading="lazy"  // Browser native lazy loading
  alt={product.title}
/>
```

**3. Provide Multiple Sizes for Responsive Images**
```javascript
<img 
  src={transformCloudinaryUrl(url, 'w_800,q_auto,f_auto')}
  srcSet={`
    ${transformCloudinaryUrl(url, 'w_400,q_auto,f_auto')} 400w,
    ${transformCloudinaryUrl(url, 'w_800,q_auto,f_auto')} 800w,
    ${transformCloudinaryUrl(url, 'w_1200,q_auto,f_auto')} 1200w
  `}
  sizes="(max-width: 640px) 400px, (max-width: 1024px) 800px, 1200px"
  alt={product.title}
/>
```

**4. Cache Transformations**
```javascript
// Cache transformed URLs to avoid recalculating
const cachedThumbnail = useMemo(
  () => transformCloudinaryUrl(product.product_image_url, 'w_300,h_300,c_fill,q_auto,f_auto'),
  [product.product_image_url]
);
```

#### Free Tier Limits

Your Cloudinary free tier includes:
- ✅ **25,000 transformations/month** (plenty for most apps!)
- ✅ **Unlimited cached transformations** (first transformation is cached)
- ✅ **25GB bandwidth/month**

**Note**: The first time a transformation is requested, Cloudinary creates it. Subsequent requests use the cached version (doesn't count against transformation limit).

#### Advanced: Named Transformations (Optional)

For frequently used transformations, you can create named presets in the Cloudinary dashboard:

1. Go to Cloudinary Console → Settings → Upload
2. Create a preset: `product_thumbnail` = `w_300,h_300,c_fill,q_auto,f_auto`
3. Use in URL: `t_product_thumbnail`

```javascript
// Instead of:
const url = originalUrl.replace('/upload/', '/upload/w_300,h_300,c_fill,q_auto,f_auto/');

// Use named transformation:
const url = originalUrl.replace('/upload/', '/upload/t_product_thumbnail/');
```

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
List all inventories with pagination support.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Pagination**: Yes (default: 50 per page, max: 100)
- **Query Parameters**: 
  - `page` (optional): Page number
  - `per_page` (optional): Items per page
- **Returns**: Paginated array of inventories with company site and product details

**Example Request with Pagination**:
```bash
GET /api/v1/inventories?page=1&per_page=20
```

**Example Response**:
```json
{
  "status": {
    "code": 200,
    "message": "Fetched all inventories successfully"
  },
  "pagination": {
    "current_page": 1,
    "per_page": 20,
    "total_entries": 60,
    "total_pages": 3,
    "next_page": 2,
    "previous_page": null
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
Create a new inventory or add to existing inventory.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Behavior**: 
  - If an inventory for the same `product_id` and `company_site_id` already exists, the `qty_in_stock` will be **added** to the existing inventory
  - If no matching inventory exists, a new inventory record is created
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
- **Optional Fields**: `sku` (auto-generated if not provided, ignored if inventory exists)
- **Validation**: 
  - `sku` must be unique across all inventories (automatically ensured if auto-generated)
  - `qty_in_stock` must be an integer >= 0
  - `company_site_id` must reference a warehouse-type site (not management-type)

**Example Response with Auto-Generated SKU (New Inventory)**:
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

**Example Response (Adding to Existing Inventory)**:
If an inventory with `product_id: 1` and `company_site_id: 2` already exists with `qty_in_stock: 150`, 
and you POST with `qty_in_stock: 100`, the result will be:
```json
{
  "status": {
    "code": 200,
    "message": "Inventory fetched successfully"
  },
  "data": {
    "id": 1,
    "sku": "002000001439",
    "qty_in_stock": 250,
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
    "updated_at": "2025-01-14T15:32:46.274Z"
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
        "phone_no": "+639171234567",
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
4. Creates the order with `is_paid: true` and `cart_status: approved`
5. **Auto-assigns products to nearest warehouses** (see [Warehouse Auto-Assignment](#warehouse-auto-assignment))
6. Creates warehouse orders automatically

Management admins can view and monitor orders.

#### POST /api/v1/user_cart_orders (User Only)
Submit your shopping cart as an order.
- **Auth Required**: User JWT token
- **Body**:
```json
{
  "user_cart_order": {
    "address_id": 20,
    "social_program_id": 1  // Optional: specify social program for 8% donation
  }
}
```
- **Requirements**:
  - Cart must not be empty
  - User must have sufficient balance
  - Address must exist (FK constraint enforced)
- **Automatic Actions**:
  - Calculates total cost
  - Validates sufficient funds
  - Deducts payment from balance
  - Sets `is_paid: true`
  - Sets `cart_status: approved` (auto-approved)
  - Creates receipt for purchase
  - **Geocodes customer address** (if not already geocoded)
  - **Calculates distances to all warehouses**
  - **Assigns each product to nearest warehouse with stock**
  - **Creates warehouse orders automatically**
  - **Deducts inventory quantities**
  - **Creates 8% donation receipt** (if `social_program_id` provided)
  - **Links donation to social program** via SocialProgramReceipt
  - **Clears shopping cart items** (cart becomes empty after successful order)

**Important**: After a successful order, all shopping cart items are automatically deleted. This ensures your cart is empty for the next purchase and prevents old items from reappearing.

**Note**: Changed from `user_address_id` to `address_id` (November 2025). Orders now directly reference addresses table, not the user_addresses join table. This simplifies queries and preserves order history even if user removes address from saved addresses.

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
    "cart_status": "approved",
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
    "warehouse_orders_count": 2,
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

#### GET /api/v1/user_cart_orders/warehouse/:warehouse_id (Management Only)
View orders for a specific warehouse.
- **Auth Required**: Management Admin JWT token
- **Path Parameter**: `warehouse_id` - The company_site ID (warehouse)
- **Returns**: Array of orders that have items fulfilled by this warehouse
- **Note**: An order may appear if it has ANY items from this warehouse (even if other items come from different warehouses)

**Example Request:**
```bash
curl -X GET http://localhost:3001/api/v1/user_cart_orders/warehouse/5 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

**Use Case:** Warehouse admins can see all orders they need to fulfill.

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

## Warehouse Auto-Assignment

### Overview

The system automatically assigns products to the nearest available warehouse when a user creates an order. This ensures optimal delivery times and efficient inventory management.

**Key Features:**
- **Automatic Geocoding**: Customer addresses are geocoded using Google Maps Geocoding API
- **Distance Calculation**: Uses Google Maps Distance Matrix API to calculate distances from customer to all warehouses
- **Smart Assignment**: Each product is assigned to the nearest warehouse with sufficient stock
- **Inventory Management**: Automatically deducts quantities from assigned warehouse inventories
- **Fallback Logic**: If distance calculation fails, assigns to warehouse with most stock

### How It Works

1. **User Places Order**: Customer submits cart with delivery address
2. **Address Geocoding**: System geocodes the delivery address to get latitude/longitude
3. **Distance Calculation**: Calls Google Maps Distance Matrix API with:
   - Origins: All warehouse addresses (pre-geocoded and stored in database)
   - Destination: Customer address
4. **Warehouse Selection**: For each product in the cart:
   - Finds all warehouses with sufficient stock
   - Selects the warehouse with shortest distance
   - Creates warehouse order
   - Deducts inventory quantity
5. **Order Completion**: Returns approved order with warehouse_orders_count

### API Integration

**Google Maps APIs Used:**
- **Geocoding API**: One-time geocoding of warehouse addresses (stored in database)
- **Distance Matrix API**: Real-time distance calculation for each order
- **API Key**: Configured in environment variable `GOOGLE_MAPS_API_KEY`

### Database Schema

**Addresses Table** (geolocation fields):
```ruby
t.decimal :latitude, precision: 10, scale: 8
t.decimal :longitude, precision: 11, scale: 8
t.datetime :geocoded_at
t.string :geocode_source  # 'google_maps' or 'manual'
```

### Example Workflow

**Scenario**: Customer in Dagupan, Pangasinan orders 1 Backpack + 1 Jacket

1. **Order Created**: POST /api/v1/user_cart_orders with address in Dagupan
2. **Geocoding**: Address geocoded → `15.9757° N, 120.5707° E`
3. **Distance Calculation**:
   - JPB Warehouse A (Tarlac): 85 km
   - JPB Warehouse B (Malolos): 145 km
   - JPB Warehouse C (Antipolo): 320 km
4. **Assignment**:
   - Both products assigned to **JPB Warehouse A** (nearest with stock)
   - 2 warehouse orders created automatically
   - Inventory deducted from Warehouse A
5. **Result**: Order approved with `warehouse_orders_count: 2`

### Performance & Reliability

- **Caching**: Warehouse coordinates stored in database (no repeated geocoding)
- **Fallback**: If API fails, assigns to warehouse with most stock
- **Error Handling**: Partial failures logged, order still completes
- **N+1 Prevention**: Eager loading for products and inventories

---

### Warehouse Orders (Management & Warehouse Admin)

Warehouse orders are **automatically created** when users place orders. The system assigns each product to the nearest warehouse with sufficient stock using Google Maps distance calculation.

Management creates manual warehouse orders only for special cases. Warehouse admins can view and update order status.

#### GET /api/v1/warehouse_orders
View all warehouse orders.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Returns**: Array of warehouse orders with inventory and site details
- **Pagination**: Default 30 per page

**Example Request:**
```bash
curl -X GET "http://localhost:3003/api/v1/warehouse_orders?per_page=50" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

#### GET /api/v1/warehouse_orders/:user_id/most_recent
View most recent warehouse orders for a specific user.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Returns**: Array of user's warehouse orders ordered by most recent first
- **Pagination**: Default 30 per page

**Example Request:**
```bash
curl -X GET "http://localhost:3003/api/v1/warehouse_orders/20/most_recent" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Warehouse orders fetched successfully"
  },
  "pagination": {
    "current_page": 1,
    "per_page": 30,
    "total_entries": 6,
    "total_pages": 1,
    "next_page": null,
    "previous_page": null
  },
  "data": [
    {
      "id": 8,
      "qty": 1,
      "product_status": "storage",
      "company_site": {
        "id": 4,
        "title": "JPB Warehouse C",
        "site_type": "warehouse"
      },
      "inventory": {
        "id": 46,
        "sku": "001001004972",
        "product_id": 4
      },
      "user_cart_order_id": 6,
      "created_at": "2025-10-30T15:41:33.269Z",
      "updated_at": "2025-10-30T15:41:33.269Z"
    }
  ]
}
```

#### GET /api/v1/warehouse_orders/:user_id/pending
View pending warehouse orders for a specific user.
- **Auth Required**: Management or Warehouse Admin JWT token
- **Returns**: Array of user's warehouse orders with status `storage` or `progress` (excludes `delivered`)
- **Pagination**: Default 30 per page
- **Use Case**: Track orders that haven't been delivered yet

**Example Request:**
```bash
curl -X GET "http://localhost:3003/api/v1/warehouse_orders/20/pending" \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Warehouse orders fetched successfully"
  },
  "pagination": {
    "current_page": 1,
    "per_page": 30,
    "total_entries": 5,
    "total_pages": 1
  },
  "data": [
    {
      "id": 8,
      "qty": 1,
      "product_status": "storage",
      "company_site": {
        "id": 4,
        "title": "JPB Warehouse C",
        "site_type": "warehouse"
      },
      "inventory": {
        "id": 46,
        "sku": "001001004972",
        "product_id": 4
      },
      "user_cart_order_id": 6,
      "created_at": "2025-10-30T15:41:33.269Z",
      "updated_at": "2025-10-30T15:41:33.269Z"
    }
  ]
}
```

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
- **Donation**: Automatic 8% donation to social program (created when order includes `social_program_id`, does not affect user balance)

**Key Features:**
- Balance tracking (before/after each transaction)
- Complete order details for purchases (items, delivery address, products)
- Automatic donation tracking for social programs (8% of order total)
- User filtering (users see only their own, admins see all)
- Admin management capabilities (view all, filter, delete)

---

### User Receipts Endpoints

#### GET /api/v1/receipts
View your transaction history.
- **Auth Required**: User JWT token
- **Optional Query Parameters**:
  - `transaction_type`: Filter by type (`deposit`, `withdraw`, `purchase`, or `donation`)
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
        "id": 1,
        "qty": "2.0",
        "subtotal": "219.9",
        "warehouse": {
          "id": 4,
          "title": "JPB Warehouse C"
        },
        "product_status": "on_delivery",
        "product": {
          "id": 1,
          "title": "Fjallraven - Foldsack No. 1 Backpack",
          "description": "Your perfect pack for everyday use...",
          "price": 109.95,
          "image": "https://fakestoreapi.com/img/backpack.jpg",
          "product_images": [
            {
              "id": 1,
              "url": "https://fakestoreapi.com/img/backpack.jpg"
            }
          ]
        }
      },
      {
        "id": 2,
        "qty": "3.0",
        "subtotal": "66.9",
        "warehouse": {
          "id": 4,
          "title": "JPB Warehouse C"
        },
        "product_status": "storage",
        "product": {
          "id": 2,
          "title": "Mens Casual Premium Slim Fit T-Shirts",
          "description": "Slim-fitting style...",
          "price": 22.3,
          "image": null,
          "product_images": []
        }
      }
    ],
    "items_count": 2,
    "total_quantity": "5.0"
  }
}
```

---

#### GET /api/v1/receipts/latest
Get the most recent receipt for the authenticated user. Perfect for redirecting after checkout!
- **Auth Required**: User JWT token OR Management Admin JWT token
- **Authorization**: 
  - Users can only view their own latest receipt
  - Management admins must provide `user_id` parameter
- **Returns**: Same format as GET /api/v1/receipts/:id
- **Error**: Returns 404 if user has no receipts

**Example Request (User):**
```bash
curl -X GET http://localhost:3001/api/v1/receipts/latest \
  -H "Authorization: Bearer YOUR_USER_TOKEN"
```

**Example Request (Admin):**
```bash
curl -X GET "http://localhost:3001/api/v1/receipts/latest?user_id=5" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

**Example Response:**
Same response format as `GET /api/v1/receipts/:id` (see above)

**Use Case:**
```javascript
// After successful checkout, redirect to latest receipt
const response = await fetch('/api/v1/receipts/latest', {
  headers: { 'Authorization': `Bearer ${userToken}` }
});
const receipt = await response.json();
window.location.href = `/transactions/${receipt.id}`;
```

---

**Delivery Orders Tracking:**

The `delivery_orders` array shows the warehouse fulfillment status for purchase receipts. When you place an order, products may be fulfilled from multiple warehouses. Each delivery order represents a batch of items coming from a single warehouse.

- **company_site**: The warehouse fulfilling this part of your order
- **status**: Current delivery status for this batch
  - `storage`: Items are being prepared at the warehouse
  - `progress`: Items are out for delivery
  - `delivered`: Items have been delivered
- **delivered_at**: Timestamp of the last status update for this delivery batch
  - `storage`: Items are being prepared at the warehouse
  - `progress`: Items are out for delivery
  - `delivered`: Items have been delivered

**Status Logic:** The delivery status only changes when ALL items from that warehouse reach the same status. For example, if a warehouse is shipping 3 items to you, the status remains "storage" until all 3 items move to "progress", then stays "progress" until all 3 are "delivered".

**Multiple Warehouses:** If your order contains items from 2 different warehouses, you'll see 2 delivery orders - one for each warehouse. This allows you to track each shipment independently.

---

### Admin Receipts Management (Management Admin Only)

#### GET /api/v1/admin/receipts
View all platform receipts with filtering and pagination.
- **Auth Required**: Management Admin JWT token
- **Optional Query Parameters**:
  - `user_id`: Filter by specific user
  - `transaction_type`: Filter by type (`deposit`, `withdraw`, `purchase`, or `donation`)
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

## Social Programs & Donation Tracking

### Overview

Social Programs track community support initiatives where 8% of each order's total cost is automatically donated. The system maintains a join table (`social_program_receipts`) that links receipts to social programs, providing a complete audit trail of all donations.

**Key Features:**
- Manage multiple social programs with descriptions and addresses
- Track which receipts contributed to which programs
- Full CRUD operations for programs and donation tracking
- Complete donation history with user and order details
- **Automatic donation creation**: When a UserCartOrder is created with a `social_program_id`, the system automatically:
  - Calculates 8% of the order's total cost
  - Creates a Receipt with `transaction_type: "donation"`
  - Links the receipt to the social program via SocialProgramReceipt
  - Does not affect user's balance (tracking only)

**Automatic Donation Flow:**
1. User creates order with `social_program_id` parameter
2. Order processes normally (payment deducted, warehouse assignment, etc.)
3. After order creation, `after_create` callback triggers
4. System creates donation receipt: `amount = total_cost * 0.08`
5. Receipt description: `"8% donation to [Program Name] from Order #[ID]"`
6. SocialProgramReceipt join record created automatically
7. Donation is tracked but doesn't fail order if tracking fails

---

### Social Programs

#### GET /api/v1/social_programs
List all available social programs.
- **Auth Required**: None (public endpoint)
- **Pagination**: Default 10 per page
- **Returns**: Array of social programs with addresses

**Example Request:**
```bash
curl -X GET http://localhost:3003/api/v1/social_programs
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Social programs fetched successfully"
  },
  "pagination": {
    "total_count": 2,
    "current_page": 1,
    "per_page": 10,
    "total_pages": 1
  },
  "data": [
    {
      "id": 1,
      "title": "Community Food Program",
      "description": "Monthly food distribution for 100+ families",
      "address": {
        "id": 1,
        "unit_no": "2020",
        "street_no": "26th Ave",
        "barangay": "Unknown",
        "city": "Taguig",
        "zipcode": "1244",
        "country": "Philippines"
      },
      "created_at": "2025-10-30T16:21:05.321Z",
      "updated_at": "2025-10-30T16:23:15.123Z"
    }
  ]
}
```

---

#### GET /api/v1/social_programs/:id
View detailed information about a specific social program.
- **Auth Required**: None (public endpoint)

**Example Request:**
```bash
curl -X GET http://localhost:3003/api/v1/social_programs/1
```

---

#### POST /api/v1/social_programs
Create a new social program.
- **Auth Required**: Admin JWT token (recommended)
- **Required Fields**:
  - `title`: Program name
  - `description`: Program details
  - `address_id`: Location reference

**Example Request:**
```bash
curl -X POST http://localhost:3003/api/v1/social_programs \
  -H "Content-Type: application/json" \
  -d '{
    "social_program": {
      "title": "Education Support Program",
      "description": "School supplies for underprivileged students",
      "address_id": 1
    }
  }'
```

---

#### PATCH /api/v1/social_programs/:id
Update an existing social program.
- **Auth Required**: Admin JWT token (recommended)

**Example Request:**
```bash
curl -X PATCH http://localhost:3003/api/v1/social_programs/1 \
  -H "Content-Type: application/json" \
  -d '{
    "social_program": {
      "description": "Updated: Weekly food distribution for families in need"
    }
  }'
```

---

#### DELETE /api/v1/social_programs/:id
Delete a social program.
- **Auth Required**: Admin JWT token (recommended)
- **Note**: Will also delete associated donation tracking records

**Example Request:**
```bash
curl -X DELETE http://localhost:3003/api/v1/social_programs/1
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Social program deleted successfully"
  }
}
```

---

### Donation Tracking (Social Program Receipts)

The join table tracks which receipts (representing 8% donations from orders) are allocated to which social programs.

#### GET /api/v1/social_program_receipts
View all donation tracking records.
- **Auth Required**: None (public endpoint)
- **Pagination**: Default 20 per page
- **Returns**: Complete details including social program info, receipt details, user info, and order details

**Example Request:**
```bash
curl -X GET http://localhost:3003/api/v1/social_program_receipts
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Fetched all social programs-receipts associations successfully"
  },
  "pagination": {
    "total_count": 1,
    "current_page": 1,
    "per_page": 20,
    "total_pages": 1
  },
  "data": [
    {
      "id": 1,
      "social_program": {
        "id": 1,
        "title": "Community Food Program",
        "description": "Monthly food distribution for 100+ families",
        "address": {
          "id": 1,
          "city": "Taguig",
          "country": "Philippines"
        }
      },
      "receipt": {
        "id": 1,
        "transaction_type": "deposit",
        "amount": 500.0,
        "balance_before": 0.0,
        "balance_after": 500.0,
        "description": "Deposit to account",
        "created_at": "2025-10-22T07:18:01.841Z",
        "user": {
          "id": 3,
          "email": "finaltest@example.com",
          "first_name": "Final",
          "last_name": "Test"
        },
        "order": null
      },
      "created_at": "2025-10-30T16:23:41.089Z"
    }
  ]
}
```

---

#### GET /api/v1/social_program_receipts/:id
View a specific donation tracking record with full details.
- **Auth Required**: None (public endpoint)

**Example Request:**
```bash
curl -X GET http://localhost:3003/api/v1/social_program_receipts/1
```

---

#### POST /api/v1/social_program_receipts
Create a donation tracking record (link a receipt to a social program).
- **Auth Required**: Admin JWT token (recommended)
- **Required Fields**:
  - `social_program_id`: The program receiving the donation
  - `receipt_id`: The receipt representing the donation (typically 8% of order total)

**Example Request:**
```bash
curl -X POST http://localhost:3003/api/v1/social_program_receipts \
  -H "Content-Type: application/json" \
  -d '{
    "social_program_receipt": {
      "social_program_id": 1,
      "receipt_id": 5
    }
  }'
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Social programs-receipts association fetched successfully"
  },
  "data": {
    "id": 2,
    "social_program": { ... },
    "receipt": { ... },
    "created_at": "2025-10-30T16:25:00.000Z"
  }
}
```

---

#### DELETE /api/v1/social_program_receipts/:id
Remove a donation tracking record (unlink a receipt from a social program).
- **Auth Required**: Admin JWT token (recommended)
- **Use Case**: Correcting allocation errors

**Example Request:**
```bash
curl -X DELETE http://localhost:3003/api/v1/social_program_receipts/1
```

**Example Response:**
```json
{
  "status": {
    "code": 200,
    "message": "Social program receipt association deleted successfully"
  }
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
  -d '{"user_cart_order": {"address_id": 20}}'
```

**Optional: Submit Order with Social Program Donation**
```bash
# Include social_program_id to automatically donate 8% to a social program
curl -X POST http://localhost:3001/api/v1/user_cart_orders \
  -H "Authorization: Bearer YOUR_USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "user_cart_order": {
      "address_id": 20,
      "social_program_id": 1
    }
  }'
# This automatically creates a donation receipt (8% of order total)
# and links it to the social program via SocialProgramReceipt
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

---

## Deployment Guide

### Deploying to Render with Cloudinary

This application uses **Cloudinary** for persistent image storage in production. This is critical because Render's basic plans use ephemeral storage (files are deleted on every deployment/restart).

#### Prerequisites
1. **Render Account**: Sign up at [render.com](https://render.com)
2. **Cloudinary Account**: Sign up at [cloudinary.com](https://cloudinary.com) (Free tier: 25GB storage, 25GB bandwidth/month)
3. **PostgreSQL Database**: Create a PostgreSQL database on Render

#### Step 1: Set Up Cloudinary
1. Create a free Cloudinary account
2. Go to Dashboard → Account Details
3. Copy your `CLOUDINARY_URL` (format: `cloudinary://API_KEY:API_SECRET@CLOUD_NAME`)

#### Step 2: Configure Render Environment Variables
In your Render service settings, add the following environment variables:

```bash
# Database (automatically set by Render when you attach PostgreSQL)
DATABASE_URL=<your-postgres-url>

# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=<your-master-key>
DEVISE_JWT_SECRET_KEY=<your-jwt-secret>

# Cloudinary (CRITICAL for image storage)
CLOUDINARY_URL=cloudinary://API_KEY:API_SECRET@CLOUD_NAME

# Email (Gmail SMTP)
GMAIL_USERNAME=<your-gmail>
GMAIL_APP_PASSWORD=<your-app-password>

# Optional: Stock API
FINNHUB_API_KEY=<your-key>
```

#### Step 3: Deploy Configuration

**Build Command:**
```bash
bundle install && rails db:migrate && rails db:seed
```

**Start Command:**
```bash
bundle exec puma -C config/puma.rb
```

#### How Image Storage Works

**Development (Local):**
- Images stored in `Rails.root/storage` directory
- Uses Active Storage with `:local` service
- Perfect for testing, but data is on your machine

**Production (Render + Cloudinary):**
- Images uploaded to Cloudinary cloud storage
- Uses Active Storage with `:cloudinary` service
- **Images persist across deployments** (no data loss!)
- Delivered via Cloudinary's global CDN
- Automatic image optimization and transformations

#### Verification After Deployment

1. **Test image upload:**
```bash
curl -X POST https://your-app.onrender.com/api/v1/products \
  -H "Authorization: Bearer <admin-token>" \
  -F "product[title]=Test Product" \
  -F "product[price]=19.99" \
  -F "product[product_category_id]=1" \
  -F "product[producer_id]=1" \
  -F "product[product_image]=@/path/to/image.jpg"
```

2. **Check image URL in response** - Should start with `https://res.cloudinary.com/...`

3. **Verify persistence** - Redeploy your app, images should still be accessible

#### Why Cloudinary?
- ✅ **Persistent Storage**: Images survive deployments and restarts
- ✅ **CDN Delivery**: Fast image loading worldwide
- ✅ **Free Tier**: 25GB storage is plenty for most projects
- ✅ **Image Transformations**: Automatic resizing, format conversion, optimization
- ✅ **Zero Infrastructure**: No need to manage S3 buckets or servers
- ✅ **Active Storage Compatible**: Drop-in replacement for local storage

#### Troubleshooting

**Images not uploading?**
- Check `CLOUDINARY_URL` is set correctly in Render environment variables
- Verify the URL format: `cloudinary://API_KEY:API_SECRET@CLOUD_NAME`
- Check Render logs for Cloudinary authentication errors

**Images loading slowly?**
- Cloudinary delivers via CDN, should be fast globally
- Check your Cloudinary bandwidth usage in dashboard

**Need more storage?**
- Cloudinary free tier: 25GB storage, 25GB bandwidth/month
- Paid plans start at $89/month for 85GB storage (rarely needed for small apps)
- Alternative: AWS S3 (~$0.023/GB/month, cheaper for large storage)

---