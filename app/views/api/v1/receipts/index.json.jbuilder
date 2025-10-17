json.array! @receipts do |receipt|
  json.id receipt.id
  json.transaction_type receipt.transaction_type
  json.amount receipt.amount.to_f
  json.balance_before receipt.balance_before.to_f
  json.balance_after receipt.balance_after.to_f
  json.description receipt.description
  json.created_at receipt.created_at
  json.updated_at receipt.updated_at

  # User information
  json.user do
    json.id receipt.user.id
    json.email receipt.user.email
    json.first_name receipt.user.user_detail&.first_name
    json.last_name receipt.user.user_detail&.last_name
  end

  # Order information (if purchase)
  if receipt.user_cart_order.present?
    json.order do
      json.id receipt.user_cart_order.id
      json.cart_status receipt.user_cart_order.cart_status
      json.is_paid receipt.user_cart_order.is_paid
      json.total_cost receipt.user_cart_order.total_cost.to_f

      # Order items summary
      json.items_count receipt.user_cart_order.shopping_cart.shopping_cart_items.count
      json.total_quantity receipt.user_cart_order.shopping_cart.shopping_cart_items.sum(:qty)
    end
  else
    json.order nil
  end
end
