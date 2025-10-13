json.array! @users do |user|
  json.id user.id
  json.email user.email
  json.first_name user.first_name
  json.middle_name user.middle_name
  json.last_name user.last_name
  json.date_of_birth user.date_of_birth
  json.mobile_no user.mobile_no
  json.address_line_01 user.address_line_01
  json.address_line_02 user.address_line_02
  json.city user.city
  json.zip_code user.zip_code
  json.country_id user.country_id
  json.user_status user.user_status
  json.user_role user.user_role
  json.created_at user.created_at
  json.updated_at user.updated_at
  json.confirmed_at user.confirmed_at

  # Country details if available
  if user.country
    json.country do
      json.id user.country.id
      json.name user.country.name
      json.code user.country.code
    end
  end

  # Wallet details for admin oversight
  if user.wallet
    json.wallet do
      json.id user.wallet.id
      json.balance user.wallet.balance
    end
  end
end
