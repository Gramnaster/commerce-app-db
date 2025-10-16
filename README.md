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