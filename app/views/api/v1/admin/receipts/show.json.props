json.id @receipt.id
json.transaction_type @receipt.transaction_type
json.amount @receipt.amount.to_f
json.balance_before @receipt.balance_before.to_f
json.balance_after @receipt.balance_after.to_f
json.description @receipt.description
json.created_at @receipt.created_at
json.updated_at @receipt.updated_at

# User information
json.user do
  json.id @receipt.user.id
  json.email @receipt.user.email
  
  if @receipt.user.user_detail.present?
    json.first_name @receipt.user.user_detail.first_name
    json.last_name @receipt.user.user_detail.last_name
    json.full_name "#{@receipt.user.user_detail.first_name} #{@receipt.user.user_detail.last_name}"
  end
end

# Order information (if purchase)
if @receipt.user_cart_order.present?
  json.order do
    json.id @receipt.user_cart_order.id
    json.cart_status @receipt.user_cart_order.cart_status
    json.is_paid @receipt.user_cart_order.is_paid
    json.total_cost @receipt.user_cart_order.total_cost.to_f
    json.created_at @receipt.user_cart_order.created_at
    
    # Delivery address
    if @receipt.user_cart_order.user_address.present?
      json.delivery_address do
        json.id @receipt.user_cart_order.user_address.id
        
        if @receipt.user_cart_order.user_address.address.present?
          address = @receipt.user_cart_order.user_address.address
          json.unit_number address.unit_number
          json.street_number address.street_number
          json.address_line_1 address.address_line_1
          json.address_line_2 address.address_line_2
          json.city address.city
          json.region address.region
          json.postal_code address.postal_code
          
          if address.country.present?
            json.country do
              json.id address.country.id
              json.country_name address.country.country_name
            end
          end
        end
      end
    end
    
    # Order items
    json.items @receipt.user_cart_order.shopping_cart.shopping_cart_items do |item|
      json.id item.id
      json.qty item.qty
      json.subtotal (item.product.price.to_f * item.qty).round(2)
      
      json.product do
        json.id item.product.id
        json.product_name item.product.product_name
        json.description item.product.description
        json.price item.product.price.to_f
        json.sku item.product.sku
      end
    end
    
    json.items_count @receipt.user_cart_order.shopping_cart.shopping_cart_items.count
    json.total_quantity @receipt.user_cart_order.shopping_cart.shopping_cart_items.sum(:qty)
  end
else
  json.order nil
end
