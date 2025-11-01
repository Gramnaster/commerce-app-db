# Refactor Plan: UserCartOrders Address Structure

**Date:** November 2, 2025  
**Branch:** feat/complete-user-details  
**Status:** Planning Phase - NOT IMPLEMENTED YET

---

## 🎯 Objective

Change `user_cart_orders` table structure from using `user_address_id` (FK to join table) to using direct `address_id` and `user_id` foreign keys.

### Current Structure
```
user_cart_orders
  ├── user_address_id → user_addresses (join table)
  └── shopping_cart_id → shopping_carts → users

user_addresses (join table)
  ├── user_id → users
  └── address_id → addresses
```

### Proposed Structure
```
user_cart_orders
  ├── address_id → addresses (DIRECT)
  ├── user_id → users (DIRECT)
  └── shopping_cart_id → shopping_carts
```

---

## ✅ Benefits

1. **Simpler Queries:**
   - `@order.address` instead of `@order.user_address.address`
   - Fewer joins = better performance

2. **Clearer Ownership:**
   - Order directly knows which user placed it
   - Order directly knows delivery address

3. **Historical Integrity:**
   - If user deletes a saved address from user_addresses table, order history remains intact
   - Address data preserved for order records

4. **Consistency:**
   - Matches warehouse_orders pattern (already has direct user_id FK)

5. **Flexible Address Submission:**
   - Users can submit any address (saved or new)
   - Frontend handles saved address selection
   - Backend just stores the address reference

---

## 📋 Implementation Checklist

### Phase 1: Database Migration

- [ ] Create migration file: `db/migrate/YYYYMMDDHHMMSS_refactor_user_cart_orders_address_structure.rb`
- [ ] Add `address_id` column (nullable initially)
- [ ] Add `user_id` column (nullable initially)
- [ ] Migrate existing data from user_addresses
- [ ] Make columns NOT NULL
- [ ] Add indices on new columns
- [ ] Add foreign key constraints
- [ ] Remove old `user_address_id` column
- [ ] Test migration up/down

### Phase 2: Model Updates

**File: `app/models/user_cart_order.rb`**
- [ ] Remove: `belongs_to :user_address`
- [ ] Add: `belongs_to :address`
- [ ] Add: `belongs_to :user`
- [ ] Keep: All other associations unchanged

**File: `app/models/user.rb`**
- [ ] Add: `has_many :user_cart_orders, dependent: :destroy`

**File: `app/models/address.rb`**
- [ ] Add: `has_many :user_cart_orders, dependent: :restrict_with_error`
- [ ] Prevents deleting addresses used in orders

**File: `app/models/warehouse_order.rb`**
- [ ] NO CHANGES NEEDED (already has user_id)

### Phase 3: Controller Updates

**File: `app/controllers/api/v1/user_cart_orders_controller.rb`**

**Line 14-17 (index eager loading):**
```ruby
# CHANGE FROM:
includes({ user_address: :address })

# CHANGE TO:
includes(:address, :user)
```

**Line 67 (create action):**
```ruby
# CHANGE FROM:
user_address_id: user_cart_order_params[:user_address_id],

# CHANGE TO:
address_id: user_cart_order_params[:address_id],
user_id: current_user.id,
```

**Line 154 (set_user_cart_order eager loading):**
```ruby
# CHANGE FROM:
user_address: :address

# CHANGE TO:
:address, :user
```

**Line 158 (strong parameters):**
```ruby
# CHANGE FROM:
params.require(:user_cart_order).permit(:user_address_id, :is_paid, :cart_status, :social_program_id)

# CHANGE TO:
params.require(:user_cart_order).permit(:address_id, :is_paid, :cart_status, :social_program_id)
# Note: user_id NOT in params - comes from current_user
```

### Phase 4: Service Updates

**File: `app/services/assign_warehouse_to_order_service.rb`**

**Line 19:**
```ruby
# CHANGE FROM:
customer_address = @order.user_address.address

# CHANGE TO:
customer_address = @order.address
```

**Line 119:**
```ruby
# CHANGE FROM:
user: @order.shopping_cart.user

# CHANGE TO:
user: @order.user
```

### Phase 5: View Updates

**IMPORTANT:** Frontend JSON structure stays IDENTICAL - only internal Ruby code changes!

**File: `app/views/api/v1/user_cart_orders/show.json.props` (Lines 13-21)**
```ruby
# CHANGE FROM:
json.user_address do
  json.id @user_cart_order.user_address.id
  json.address do
    json.unit_no @user_cart_order.user_address.address.unit_no
    json.street_no @user_cart_order.user_address.address.street_no
    json.barangay @user_cart_order.user_address.address.barangay
    json.city @user_cart_order.user_address.address.city
    json.region @user_cart_order.user_address.address.region
    json.zipcode @user_cart_order.user_address.address.zipcode
  end
end

# CHANGE TO:
json.user_address do
  json.id @user_cart_order.address.id
  json.address do
    json.unit_no @user_cart_order.address.unit_no
    json.street_no @user_cart_order.address.street_no
    json.barangay @user_cart_order.address.barangay
    json.city @user_cart_order.address.city
    json.region @user_cart_order.address.region
    json.zipcode @user_cart_order.address.zipcode
  end
end
```

**File: `app/views/api/v1/user_cart_orders/index.json.props` (Lines 15-23)**
```ruby
# Same pattern - replace:
order.user_address.address.unit_no → order.address.unit_no
order.user_address.address.street_no → order.address.street_no
# etc...
```

**File: `app/views/api/v1/receipts/show.json.props` (Lines 32-52)**
```ruby
# CHANGE FROM:
if @receipt.user_cart_order.user_address.present?
  json.user_address do
    json.id @receipt.user_cart_order.user_address.id
    if @receipt.user_cart_order.user_address.address.present?
      address = @receipt.user_cart_order.user_address.address
      # ... address fields
    end
  end
end

# CHANGE TO:
if @receipt.user_cart_order.address.present?
  json.user_address do
    json.id @receipt.user_cart_order.address.id
    address = @receipt.user_cart_order.address
    # ... address fields directly
  end
end
```

**File: `app/views/api/v1/admin/receipts/show.json.props` (Lines 32-52)**
- [ ] Same changes as regular receipts/show.json.props

**File: `app/views/api/v1/users/full_details.json.props` (Line 101)**
```ruby
# CHANGE FROM:
json.user_address_id cart_order.user_address_id

# CHANGE TO:
json.user_address_id cart_order.address_id
# Keep key name same for frontend compatibility
```

### Phase 6: Documentation Updates

**File: `README.md`**
- [ ] Update API examples showing `address_id` instead of `user_address_id`
- [ ] Update shopping cart workflow documentation
- [ ] Note: Frontend continues using saved addresses from user profile

---

## 🗄️ Migration Code

```ruby
class RefactorUserCartOrdersAddressStructure < ActiveRecord::Migration[8.1]
  def up
    # Add new columns (nullable first for data migration)
    add_column :user_cart_orders, :address_id, :bigint
    add_column :user_cart_orders, :user_id, :bigint
    
    # Migrate existing data
    # Copy address_id and user_id from user_addresses table
    execute <<-SQL
      UPDATE user_cart_orders
      SET 
        address_id = user_addresses.address_id,
        user_id = user_addresses.user_id
      FROM user_addresses
      WHERE user_cart_orders.user_address_id = user_addresses.id
    SQL
    
    # Verify all records were migrated
    unmigrated = execute("SELECT COUNT(*) FROM user_cart_orders WHERE address_id IS NULL OR user_id IS NULL").first
    if unmigrated["count"].to_i > 0
      raise "Migration failed: #{unmigrated['count']} orders could not be migrated"
    end
    
    # Make columns NOT NULL
    change_column_null :user_cart_orders, :address_id, false
    change_column_null :user_cart_orders, :user_id, false
    
    # Add indices for better query performance
    add_index :user_cart_orders, :address_id
    add_index :user_cart_orders, :user_id
    
    # Add foreign key constraints
    add_foreign_key :user_cart_orders, :addresses, column: :address_id
    add_foreign_key :user_cart_orders, :users, column: :user_id
    
    # Remove old column and its constraints
    remove_foreign_key :user_cart_orders, :user_addresses
    remove_index :user_cart_orders, :user_address_id
    remove_column :user_cart_orders, :user_address_id
  end
  
  def down
    # Rollback: restore original structure
    add_column :user_cart_orders, :user_address_id, :bigint
    
    # Try to restore user_address_id by finding matching user_addresses
    execute <<-SQL
      UPDATE user_cart_orders
      SET user_address_id = user_addresses.id
      FROM user_addresses
      WHERE user_cart_orders.user_id = user_addresses.user_id
        AND user_cart_orders.address_id = user_addresses.address_id
      LIMIT 1
    SQL
    
    # Make NOT NULL
    change_column_null :user_cart_orders, :user_address_id, false
    
    # Restore index and FK
    add_index :user_cart_orders, :user_address_id
    add_foreign_key :user_cart_orders, :user_addresses
    
    # Remove new columns
    remove_foreign_key :user_cart_orders, :addresses
    remove_foreign_key :user_cart_orders, :users
    remove_index :user_cart_orders, :address_id
    remove_index :user_cart_orders, :user_id
    remove_column :user_cart_orders, :address_id
    remove_column :user_cart_orders, :user_id
  end
end
```

---

## 🧪 Testing Plan

### Pre-Migration Tests
- [ ] Check existing order count: `UserCartOrder.count`
- [ ] Verify all orders have user_address_id: `UserCartOrder.where(user_address_id: nil).count` (should be 0)
- [ ] Check data integrity: `UserCartOrder.joins(:user_address).count` (should match total)

### Post-Migration Tests
- [ ] Verify migration success: `UserCartOrder.where(address_id: nil).count` (should be 0)
- [ ] Verify user_id populated: `UserCartOrder.where(user_id: nil).count` (should be 0)
- [ ] Verify old column removed: Check schema

### Functionality Tests
1. **Create Order:**
   ```bash
   POST /api/v1/user_cart_orders
   Body: { "user_cart_order": { "address_id": 1, "social_program_id": null } }
   Expected: Success, order created with correct address and user
   ```

2. **View Order (User):**
   ```bash
   GET /api/v1/user_cart_orders/:id (as management)
   Expected: JSON shows user_address block with correct data
   ```

3. **View Receipt:**
   ```bash
   GET /api/v1/receipts/:id
   Expected: order.user_address shows correct delivery address
   ```

4. **Warehouse Assignment:**
   - [ ] Create order, verify AssignWarehouseToOrderService calculates distances correctly
   - [ ] Check warehouse_orders created with correct user_id

5. **Query Performance:**
   - [ ] Check for N+1 queries (Bullet gem)
   - [ ] Verify eager loading works: `includes(:address, :user)`

6. **Edge Cases:**
   - [ ] Try creating order with non-existent address_id (should fail with FK error)
   - [ ] Try deleting address used in order (should fail with FK constraint)
   - [ ] Verify pagination still works
   - [ ] Verify filtering/searching still works

---

## ⚠️ Important Notes

### Address Validation Decision
**NO VALIDATION NEEDED** - Users can submit any address_id:
- It's their money and their shipping address
- They control what address to use
- Frontend shows their saved addresses for convenience
- Backend just stores the reference via FK constraint
- FK constraint ensures address exists in database

### Frontend Impact
**ZERO CHANGES REQUIRED:**
- API endpoint stays: `POST /api/v1/user_cart_orders`
- Parameter changes from `user_address_id` to `address_id`
- Frontend form update: minimal change
- Response JSON structure: **IDENTICAL**

### Security Considerations
- User authentication: still via JWT (current_user)
- Order ownership: enforced by setting user_id from current_user
- Address existence: enforced by FK constraint
- No additional validation needed per user request

### Rollback Plan
- Migration has `down` method to reverse changes
- Keep backup before running migration
- Test rollback in development first

---

## 📊 Current Data Status

**As of November 2, 2025:**
- UserCartOrder count: ~8-11 records (test data)
- Test user ID 24 has orders referencing user_address_id 7
- User address 7 has FK constraint preventing deletion (used by order #8)

**Migration will:**
- Copy user_address_id 7 → Get address_id and user_id from user_addresses table
- Store those directly in user_cart_orders
- After migration, user can delete user_address record without affecting order history

---

## 🚀 Deployment Steps

1. **Development:**
   - [ ] Create and run migration
   - [ ] Update all code files
   - [ ] Run test suite
   - [ ] Manual testing with Postman/curl

2. **Staging (if applicable):**
   - [ ] Deploy and test
   - [ ] Verify data migration
   - [ ] Run smoke tests

3. **Production:**
   - [ ] Backup database
   - [ ] Run migration during low-traffic period
   - [ ] Monitor for errors
   - [ ] Verify functionality

---

## 📝 Files to Modify Summary

### Must Change (10 files):
1. New migration file
2. `app/models/user_cart_order.rb`
3. `app/models/user.rb`
4. `app/models/address.rb`
5. `app/controllers/api/v1/user_cart_orders_controller.rb`
6. `app/services/assign_warehouse_to_order_service.rb`
7. `app/views/api/v1/user_cart_orders/show.json.props`
8. `app/views/api/v1/user_cart_orders/index.json.props`
9. `app/views/api/v1/receipts/show.json.props`
10. `app/views/api/v1/admin/receipts/show.json.props`

### Optional:
11. `app/views/api/v1/users/full_details.json.props` (minor change)
12. `README.md` (documentation)

### No Changes Needed:
- `app/models/warehouse_order.rb` (already has user_id)
- `app/models/shopping_cart.rb`
- `app/controllers/api/v1/shopping_cart_items_controller.rb`
- Test files (will update after implementation)

---

## ❓ Questions Resolved

**Q: Should we validate that users can only use their own addresses?**  
**A:** NO - Users can submit any address. It's their money and shipping address. Frontend provides convenience of saved addresses, but backend just stores whatever address_id they submit (with FK validation only).

**Q: What about address deletion?**  
**A:** With new structure, FK constraint on user_cart_orders.address_id prevents deleting addresses table records used in orders. Users can still delete from user_addresses (saved addresses) without affecting order history.

**Q: Frontend changes needed?**  
**A:** Minimal - change parameter name from `user_address_id` to `address_id` in POST request. Response JSON stays identical.

---

**Status:** Ready for implementation  
**Next Step:** Review this plan, then proceed with Phase 1 (migration creation)
