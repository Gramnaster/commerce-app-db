class AssignWarehouseToOrderService
  def initialize(user_cart_order)
    @order = user_cart_order
    @gmaps_service = GoogleMapsService.new
    @errors = []
  end

  def call
    begin
      # Get cart items
      cart_items = @order.shopping_cart.shopping_cart_items.includes(:product)

      if cart_items.empty?
        @errors << "No items in cart"
        return failure_result
      end

      # Get customer address
      customer_address = @order.user_address.address
      customer_address_string = customer_address.full_address

      Rails.logger.info("[WarehouseAssignment] Processing order ##{@order.id} with #{cart_items.count} items")
      Rails.logger.info("[WarehouseAssignment] Customer address: #{customer_address_string}")

      # Get active warehouses with coordinates
      warehouses = CompanySite.where(site_type: "warehouse")
                              .joins(:address)
                              .where.not(addresses: { latitude: nil })
                              .includes(:address, :inventories)

      if warehouses.empty?
        @errors << "No geocoded warehouses available"
        return failure_result
      end

      # Build warehouse coordinates for Distance Matrix API
      warehouse_coords = warehouses.map do |wh|
        { lat: wh.address.latitude.to_f, lng: wh.address.longitude.to_f }
      end

      # Calculate distances from all warehouses to customer
      distance_data = @gmaps_service.distance_matrix(warehouse_coords, customer_address_string)

      unless distance_data
        @errors << "Distance calculation failed"
        return fallback_assignment(cart_items, warehouses)
      end

      # Process each cart item
      cart_items.each do |item|
        assign_warehouse_for_item(item, warehouses, distance_data)
      end

      if @errors.empty?
        Rails.logger.info("[WarehouseAssignment] Successfully assigned #{cart_items.count} items")
        success_result
      else
        Rails.logger.warn("[WarehouseAssignment] Completed with errors: #{@errors.join(', ')}")
        partial_success_result
      end

    rescue => e
      Rails.logger.error("[WarehouseAssignment] Exception: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      @errors << "System error: #{e.message}"
      failure_result
    end
  end

  private

  def assign_warehouse_for_item(item, warehouses, distance_data)
    product = item.product
    required_qty = item.qty.to_i

    Rails.logger.info("[WarehouseAssignment] Assigning product ##{product.id} (#{product.title}) - Qty: #{required_qty}")

    # Find inventories for this product with sufficient stock - eager load product to avoid N+1
    available_inventories = Inventory.includes(:product)
                                    .where(product: product)
                                    .where("qty_in_stock >= ?", required_qty)
                                    .where(company_site_id: warehouses.pluck(:id))

    if available_inventories.empty?
      @errors << "No inventory available for product: #{product.title}"
      Rails.logger.warn("[WarehouseAssignment] No inventory for product ##{product.id}")
      return
    end

    # Find nearest warehouse with stock
    selected_warehouse = nil
    selected_inventory = nil
    min_distance = Float::INFINITY

    available_inventories.each do |inventory|
      warehouse = warehouses.find { |wh| wh.id == inventory.company_site_id }
      next unless warehouse

      warehouse_index = warehouses.index(warehouse)
      distance_element = distance_data[warehouse_index]["elements"].first

      if distance_element["status"] == "OK"
        distance_meters = distance_element["distance"]["value"]

        if distance_meters < min_distance
          min_distance = distance_meters
          selected_warehouse = warehouse
          selected_inventory = inventory
        end
      end
    end

    unless selected_warehouse
      @errors << "Could not find reachable warehouse for product: #{product.title}"
      return
    end

    # Create warehouse order
    warehouse_order = WarehouseOrder.create!(
      company_site: selected_warehouse,
      inventory: selected_inventory,
      user: @order.shopping_cart.user,
      user_cart_order: @order,
      qty: required_qty.to_i,
      product_status: "storage"
    )

    # Deduct inventory
    selected_inventory.qty_in_stock -= required_qty.to_i
    selected_inventory.save!

    Rails.logger.info("[WarehouseAssignment] Assigned to #{selected_warehouse.title} - Distance: #{min_distance}m")
    Rails.logger.info("[WarehouseAssignment] Created WarehouseOrder ##{warehouse_order.id}")
  end

  def fallback_assignment(cart_items, warehouses)
    Rails.logger.warn("[WarehouseAssignment] Using fallback assignment (no distance data)")

    cart_items.each do |item|
      product = item.product
      required_qty = item.qty.to_i

      inventory = Inventory.includes(:product)
                          .where(product: product)
                          .where("qty_in_stock >= ?", required_qty)
                          .where(company_site_id: warehouses.pluck(:id))
                          .order(qty_in_stock: :desc)
                          .first

      if inventory
        _warehouse_order = WarehouseOrder.create!(
          company_site: inventory.company_site,
          inventory: inventory,
          user: @order.shopping_cart.user,
          user_cart_order: @order,
          qty: required_qty.to_i,
          product_status: "storage"
        )

        inventory.qty_in_stock -= required_qty.to_i
        inventory.save!

        Rails.logger.info("[WarehouseAssignment] Fallback assigned product ##{product.id} to #{inventory.company_site.title}")
      else
        @errors << "No inventory for product: #{product.title}"
      end
    end

    partial_success_result
  end

  def success_result
    {
      success: true,
      errors: [],
      warehouse_orders_count: @order.warehouse_orders.count
    }
  end

  def partial_success_result
    {
      success: true,
      errors: @errors,
      warehouse_orders_count: @order.warehouse_orders.count
    }
  end

  def failure_result
    {
      success: false,
      errors: @errors,
      warehouse_orders_count: 0
    }
  end
end
