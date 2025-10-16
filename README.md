# README

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

**Important**: Inventories can only be attached to warehouse-type company sites, not management-type sites.

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
- **Body**:
```json
{
  "inventory": {
    "company_site_id": 2,
    "product_id": 1,
    "sku": "SHOES-NKE-001",
    "qty_in_stock": 150
  }
}
```
- **Required Fields**: `company_site_id`, `product_id`, `sku`, `qty_in_stock`
- **Validation**: 
  - `sku` must be unique across all inventories
  - `qty_in_stock` must be an integer >= 0
  - `company_site_id` must reference a warehouse-type site (not management-type)

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