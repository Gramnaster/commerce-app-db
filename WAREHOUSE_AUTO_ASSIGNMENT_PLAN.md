# Warehouse Auto-Assignment Implementation Plan

## Goal
Automatically create Warehouse Orders when a User_Cart_Order is created from the frontend. The system will:
1. Assign each product to the warehouse that has inventory AND is nearest to the shipping address
2. Use Google Maps API for geocoding warehouse addresses and calculating distances
3. Create warehouse orders automatically without manual intervention

---

## Current System Analysis

### Existing Models & Relationships
```
UserCartOrder
  - belongs_to :shopping_cart
  - belongs_to :user_address
  - has_many :warehouse_orders
  - Fields: total_cost, is_paid, cart_status (pending/approved/rejected)

WarehouseOrder  
  - belongs_to :company_site (warehouse)
  - belongs_to :inventory
  - belongs_to :user
  - belongs_to :user_cart_order
  - Fields: qty, product_status (storage/progress/delivered)

CompanySite
  - belongs_to :address
  - has_many :inventories
  - has_many :warehouse_orders
  - Fields: title, site_type (warehouse/management)
  - NO latitude/longitude fields yet ❌

Address
  - belongs_to :country
  - Fields: unit_no, street_no, barangay, city, zipcode, country_id
  - NO latitude/longitude fields yet ❌

Inventory
  - belongs_to :company_site (must be warehouse type)
  - belongs_to :product
  - Fields: sku, qty_in_stock
  
ShoppingCart -> ShoppingCartItem -> Product
```

### Current Warehouse Data (from seeds.rb)
```ruby
# 3 Warehouses (all in Philippines):
JPB Warehouse A: 332, 9th Roxas, San Vicente, Tarlac, 5650, PH
JPB Warehouse B: 090, 8th Linkway, Dakila, Malolos, 8110, PH  
JPB Warehouse C: 3101-A, 99th Ave, San Roque, Antipolo, 6602, PH

# 1 Management Site (Singapore):
JPB Management - HQ: 110, 87 Cucumber St, Geylang, Singapore, 1557330, SG
```

### Current User Cart Order Flow
1. User submits cart via `POST /api/v1/user_cart_orders/create`
2. System validates cart, checks balance, deducts payment
3. Creates `UserCartOrder` with status "pending"
4. Creates `Receipt` for purchase
5. **NO warehouse orders created yet** ❌

---

## Implementation Plan

### Phase 1: Database Schema Updates

#### 1.1 Add Geolocation Fields to Addresses Table
**Migration: `add_geolocation_to_addresses`**
```ruby
# Add columns:
- latitude: decimal(10, 8)   # e.g., 14.5995124 (Philippines)
- longitude: decimal(11, 8)   # e.g., 120.9842195
- geocoded_at: datetime       # timestamp of last geocoding
- geocode_source: string      # 'google_maps' or 'manual'
```

**Why**: Store precise coordinates for both warehouse addresses AND customer shipping addresses

#### 1.2 Update CompanySite Model
**Add fields:**
```ruby
- is_active: boolean (default: true)  # For enabling/disabling warehouses
```

---

### Phase 2: Google Maps Service Setup

#### 2.1 Add Faraday Gem
**Decision: Using Faraday (Not Raw Net::HTTP)**

**Rationale:**
- ✅ Production-ready with automatic timeout handling
- ✅ Cleaner, more maintainable code (5-10 lines vs 30+)
- ✅ Easier testing and mocking
- ✅ Built-in error handling and retries
- ✅ Consistent with modern Rails best practices
- ✅ Minimal overhead (~100KB gem)
- ✅ Future-proof (easy to add caching, retries, circuit breakers)

**Update Gemfile:**
```ruby
gem 'faraday'           # HTTP client
gem 'faraday-net_http'  # Default adapter
```

#### 2.2 Environment Variables
**Already Added to `.env`:**
```bash
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

#### 2.3 Create GoogleMapsService
**File: `app/services/google_maps_service.rb`**

**APIs Used:**
1. **Geocoding API** - One-time geocoding of warehouse addresses
   - Endpoint: `https://maps.googleapis.com/maps/api/geocode/json`
   - Purpose: Get precise lat/lng for 3 warehouses, store in DB
   - Cost: ~$5 per 1000 requests (only need 3 requests total)

2. **Distance Matrix API** - Calculate distances for each order
   - Endpoint: `https://maps.googleapis.com/maps/api/distancematrix/json`
   - Purpose: Compare all warehouses to customer address in one call
   - Cost: $5 per 1000 requests (1 request per order)
   - Note: Marked "legacy" but fully supported, perfect for this use case

**Methods needed:**
- `geocode_address(address_string)` → returns `{lat:, lng:, formatted_address:, location_type:}`
- `distance_matrix(origins_array, destination)` → returns distance data with meters/duration

**Hybrid Approach (Cost-Optimized):**
- Warehouses: Geocode once → store lat/lng → reuse forever (3 API calls total)
- Customer address: Pass address string to Distance Matrix API (1 API call per order)
- Distance Matrix implicitly geocodes customer address while calculating distances

---

### Phase 3: One-Time Warehouse Geocoding

#### 3.1 Rake Task for Initial Geocoding
**File: `lib/tasks/geocode_warehouses.rake`**

**Purpose:**
- Geocode all 3 warehouse addresses once
- Store precise lat/lng in addresses table
- Can be run manually or in deployment

**Command:** `rails geocode:warehouses`

#### 3.2 Update seeds.rb (Optional)
- Add geocoding after warehouse address creation
- Only for fresh database setups

---

### Phase 4: Warehouse Assignment Service

#### 4.1 Create AssignWarehouseToOrderService
**File: `app/services/assign_warehouse_to_order_service.rb`**

**Input:** `user_cart_order` object
**Output:** Creates `WarehouseOrder` records

**Logic Flow:**
```
1. Get all items from user_cart_order.shopping_cart.shopping_cart_items
2. Get customer address from user_cart_order.user_address.address
3. Build customer address string (for geocoding)

4. For each cart item:
   a. Find product
   b. Query inventories that have this product with qty >= item.qty
   c. Get warehouse locations (lat/lng from address table)
   
   d. Call GoogleMapsService.distance_matrix(warehouse_coords, customer_address)
   
   e. Select warehouse with:
      - Sufficient inventory (qty_in_stock >= item.qty)
      - Shortest distance to customer
      
   f. Create WarehouseOrder:
      - company_site_id: selected_warehouse.id
      - inventory_id: selected_inventory.id
      - user_id: customer.id
      - user_cart_order_id: order.id
      - qty: item.qty
      - product_status: 'storage'
      
   g. Deduct inventory: inventory.qty_in_stock -= item.qty

5. Handle edge cases:
   - No warehouse has sufficient stock → split order OR mark as 'pending_stock'
   - Geocoding fails → fallback to first available warehouse
   - Distance API fails → use simple SQL query (no distance optimization)
```

---

### Phase 5: Update User Cart Orders Controller

#### 5.1 Modify `create` Action
**File: `app/controllers/api/v1/user_cart_orders_controller.rb`**

**After successful order creation:**
```ruby
# Existing code creates UserCartOrder...

if @user_cart_order.save
  # Existing: Deduct payment, create receipt
  
  # NEW: Auto-assign warehouses
  assignment_service = AssignWarehouseToOrderService.new(@user_cart_order)
  assignment_result = assignment_service.call
  
  if assignment_result[:success]
    render :show, status: :created
  else
    # Log error but don't fail the order
    # Admin can manually assign later
    Rails.logger.error("Warehouse assignment failed: #{assignment_result[:errors]}")
    render :show, status: :created
  end
end
```

---

### Phase 6: Testing Strategy

#### 6.1 Unit Tests (RSpec)
**Test files:**
- `spec/services/google_maps_service_spec.rb`
- `spec/services/assign_warehouse_to_order_service_spec.rb`

**Test cases:**
- GoogleMapsService returns valid coordinates
- Distance matrix calculates correctly
- Service handles API failures gracefully

#### 6.2 Integration Tests
**Test scenarios:**
1. User creates order → warehouses auto-assigned
2. Multiple products → multiple warehouse orders created
3. Product split across warehouses if needed
4. Insufficient inventory handling

#### 6.3 Manual API Testing
**Test with provided credentials:**
```json
Admin: {"admin_user": {"email": "admin@admin.com", "password": "admin123456"}}
User:  {"user": {"email": "test1@test.com", "password": "bienbien"}}
```

**Test flow:**
1. Login as user
2. Add products to cart
3. Submit cart order via POST /api/v1/user_cart_orders
4. Verify warehouse_orders created
5. Check via GET /api/v1/warehouse_orders (as admin)

---

## Edge Cases & Considerations

### 1. Insufficient Inventory
**Problem:** No single warehouse has enough stock
**Solutions:**
- **Split Order**: Create multiple warehouse orders from different warehouses
- **Partial Fulfillment**: Fulfill what's available, mark rest as backorder
- **Reject Order**: Mark as 'pending_stock', notify customer

### 2. API Failures
**Problem:** Google Maps API down or quota exceeded
**Fallback:**
- Use simple round-robin assignment
- Assign to warehouse with most stock
- Log error for manual review

### 3. Multiple Products
**Problem:** Products may be in different warehouses
**Solution:**
- Create one WarehouseOrder per product per warehouse
- Customer gets shipments from multiple locations

### 4. Geocoding Accuracy
**Problem:** Ambiguous addresses
**Solution:**
- Store `location_type` from Google (ROOFTOP vs APPROXIMATE)
- Validate address before accepting order
- Show formatted_address to user for confirmation

### 5. Cost Optimization
**Problem:** Google Maps API costs money
**Strategy:**
- Geocode warehouses once, store forever
- Only geocode customer address once per order
- Cache distance calculations for common routes
- Use metric units (meters) not imperial

---

## Sequence of Implementation

### Step 1: Dependencies & Environment (15 min)
- [x] Add GOOGLE_MAPS_API_KEY to .env
- [ ] Add faraday gem to Gemfile
- [ ] Run bundle install
- [ ] Verify API key works with test request

### Step 2: Database (30 min)
- [ ] Create migration for lat/lng fields on addresses
- [ ] Run migration
- [ ] Update Address model with validations
- [ ] Add geocoded? helper method

### Step 3: Google Maps Service (1 hour)
- [ ] Create app/services/ directory
- [ ] Create GoogleMapsService class with Faraday
- [ ] Implement geocode_address method
- [ ] Implement distance_matrix method
- [ ] Add comprehensive error handling
- [ ] Test manually with Rails console

### Step 4: Geocode Warehouses (30 min)
- [ ] Create rake task (lib/tasks/geocode_warehouses.rake)
- [ ] Run task to geocode 3 warehouse addresses
- [ ] Verify coordinates stored in database
- [ ] Document coordinates for reference

### Step 5: Assignment Service (2 hours)
- [ ] Create AssignWarehouseToOrderService
- [ ] Implement warehouse selection logic
- [ ] Handle inventory queries and stock checking
- [ ] Implement inventory deduction
- [ ] Add fallback for API failures
- [ ] Handle edge cases (no stock, split orders)

### Step 6: Controller Integration (30 min)
- [ ] Update user_cart_orders#create
- [ ] Add service call after order creation
- [ ] Add error handling (don't fail order if assignment fails)
- [ ] Log assignment results

### Step 7: Testing (1-2 hours)
- [ ] Write GoogleMapsService specs
- [ ] Write AssignWarehouseToOrderService specs
- [ ] Manual API testing with provided credentials:
  - Admin: admin@admin.com / admin123456
  - User: test1@test.com / bienbien
- [ ] Test complete flow: cart → order → warehouse assignment
- [ ] Verify warehouse_orders created correctly
- [ ] Test edge cases

### Step 8: Documentation (30 min)
- [ ] Update WAREHOUSE_AUTO_ASSIGNMENT_PLAN.md with results
- [ ] Document what worked and what didn't
- [ ] Add troubleshooting section
- [ ] Update README if needed

---

## Files to Create/Modify

### New Files
```
app/services/google_maps_service.rb
app/services/assign_warehouse_to_order_service.rb
lib/tasks/geocode_warehouses.rake
db/migrate/XXXXXX_add_geolocation_to_addresses.rb
spec/services/google_maps_service_spec.rb
spec/services/assign_warehouse_to_order_service_spec.rb
```

### Files to Modify
```
app/controllers/api/v1/user_cart_orders_controller.rb
app/models/address.rb (add validations)
app/models/company_site.rb (add scopes for active warehouses)
Gemfile (add faraday)
.env (add GOOGLE_MAPS_API_KEY)
db/seeds.rb (optional: add geocoding)
```

---

## Success Criteria

### Must Have
✅ Warehouse orders automatically created when user submits cart
✅ Nearest warehouse selected based on distance
✅ Inventory automatically deducted
✅ System works for all 3 warehouse locations
✅ Customer address geocoded correctly

### Nice to Have
⭐ Split orders across warehouses if needed
⭐ Admin dashboard shows warehouse assignments
⭐ Email notifications to warehouse staff
⭐ Estimated delivery time based on distance

---

## Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Google API quota exceeded | High | Implement fallback assignment |
| Inaccurate geocoding | Medium | Validate addresses, use formatted_address |
| Service performance slow | Medium | Cache coordinates, optimize queries |
| Database schema change breaks existing data | High | Test migration on copy first |
| Distance calculation wrong | High | Test with known coordinates, verify results |

---

## Next Steps

**Before coding:**
1. ✅ Review this plan with team
2. ✅ Confirm Google Maps API key is available and has quota
3. ✅ Backup database before schema changes
4. ✅ Set up test environment

**Start implementation with:**
- Database migration (lowest risk, highest value)
- Then Google Maps service (can test independently)
- Then assignment logic (builds on previous steps)

---

## Questions to Resolve

1. **What happens if customer address is outside Philippines?**
   - Current warehouses are all PH-based
   - Reject order? Show warning? Calculate international shipping?

2. **Should we validate address before order submission?**
   - Add address validation endpoint?
   - Geocode and show formatted address to user?

3. **How to handle timezone for delivery estimates?**
   - All timestamps in UTC?
   - Convert to local timezone?

4. **Should warehouse assignment be editable by admin?**
   - Allow manual reassignment?
   - Cancel and recreate warehouse orders?

---

**Document Version:** 2.0  
**Created:** 2025-10-30  
**Updated:** 2025-10-30  
**Branch:** feat/google-maps  
**Status:** Ready for Implementation

**Key Decisions:**
- ✅ Using Faraday (not raw Net::HTTP) for production readiness
- ✅ Using Distance Matrix API (legacy but perfect for multi-origin comparison)
- ✅ Using Geocoding API for one-time warehouse coordinate lookup
- ✅ Hybrid approach: stored warehouse coords + on-the-fly customer geocoding
- ✅ Google Maps API Key added to .env

