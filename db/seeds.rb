# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

require 'finnhub_ruby'
require 'net/http'
require 'json'

# Seeds the Countries table
puts "Seeding country data from Finnhub..."
ActiveRecord::Base.transaction do
  begin
    countries_data = nil
    FinnhubClient.try_request do |client|
      countries_data = client.country
    end

    puts "Populating countries table"
    countries_data.each do |country_data|
      country_code = country_data['code2']
      Country.find_or_create_by!(code: country_code) do |country|
        country.name = country_data['country']
        puts "Seeded country: #{country.name} (#{country.code})"
      end
    end
    puts "Countries table populated successfully."

  rescue StandardError => e
    if e.class.to_s == 'FinnhubRuby::ApiError'
      puts "Finnhub API Error: #{e.message}. Rolling back country creations."
    else
      puts "Failed to fetch country data. Aborting seed. Error: #{e.message}"
    end
    raise ActiveRecord::Rollback

  rescue => e
    puts "Error: #{e.message}"
    raise ActiveRecord::Rollback
  end
end

# Seeds the Producers table
puts "Seeding Producers table..."
addresses = [
  { unit_no: "2020", street_no: "26th Ave", city: "Taguig", zipcode: "1244", country_id: "102" },
  { unit_no: "0110", street_no: "9th Roxas", city: "Quezon", zipcode: "1499", country_id: "102" },
  { unit_no: "1430", street_no: "8th Cucumber", city: "Metro Manila", zipcode: "1011", country_id: "102" },
  { unit_no: "310", street_no: "15th Centre", city: "Cavite", zipcode: "1802", country_id: "102" }
]

address_records = addresses.map do |attrs|
  Address.find_or_create_by!(attrs)
end

producers = [
  { title: "Nestle Inc.", address: address_records[0] },
  { title: "Amazonia LLC", address: address_records[1] },
  { title: "Appollonia Inc.", address: address_records[2] },
  { title: "Johnsons & Johnsons", address: address_records[3] }
]

producers.each do |attrs|
  Producer.find_or_create_by!(title: attrs[:title], address: attrs[:address])
end

# Seeds the Categories table
puts "Seeding Categories table..."
[ "men's clothing", "women's clothing", "jewelery", "electronics" ].each do |cat_title|
  ProductCategory.find_or_create_by!(title: cat_title)
end

# Seeds the Products table
puts "Seeding product data from fakeproducts..."

ActiveRecord::Base.transaction do
  begin
    # API-Wrapper Project
    puts "Populating products table"
    url = URI.parse('https://fakestoreapi.com/products')
    response = Net::HTTP.get(url)
    products = JSON.parse(response)

    # Get a producer to assign to products
    producer = Producer.first
    unless producer
      puts "No producers found. Please seed producers first."
      raise ActiveRecord::Rollback
    end

    products.each do |product_data|
      # Find or create category
      category = ProductCategory.find_or_create_by!(title: product_data['category'])

      # Create product
      Product.find_or_create_by!(title: product_data['title']) do |product|
        product.product_category = category
        product.producer = producer
        product.description = product_data['description']
        product.price = product_data['price']
        product.product_image_url = product_data['image']
      end
      puts "Seeded product: #{product_data['title']}"
    end

    puts "Products table seeded successfully"
  rescue StandardError => e
    puts "Failed to seed products. Error: #{e.message}"
    raise ActiveRecord::Rollback
  end
end

# Seeds the Company Sites for development
puts "Seeding Company Sites table..."
ph_country = Country.find_by(code: "PH")
sg_country = Country.find_by(code: "SG")
company_addresses = [
  { unit_no: "110", street_no: "87 Cucumber St", city: "Singapore", zipcode: "1557330", country_id: sg_country.id  },
  { unit_no: "332", street_no: "9th Roxas", city: "Tarlac", zipcode: "5650", country_id: ph_country.id  },
  { unit_no: "090", street_no: "8th Linkway", city: "Malolos", zipcode: "8110", country_id: ph_country.id  },
  { unit_no: "3101-A", street_no: "99th Ave", city: "Antipolo", zipcode: "6602", country_id: ph_country.id  }
]

company_site_records = company_addresses.map do |attrs|
  Address.find_or_create_by!(attrs)
end

company_site = [
  { title: "JPB Management - HQ", address: company_site_records[0], site_type: "management" },
  { title: "JPB Warehouse A", address: company_site_records[1], site_type: "warehouse" },
  { title: "JPB Warehouse B", address: company_site_records[2], site_type: "warehouse" },
  { title: "JPB Warehouse C", address: company_site_records[3], site_type: "warehouse" }
]

company_site.each do |attrs|
  CompanySite.find_or_create_by!(title: attrs[:title]) do |site|
    site.address = attrs[:address]
    site.site_type = attrs[:site_type]
  end
end

# Seeds the Admin User for development
puts "Seeding Admin Users for development..."

admin_email = ENV['ADMIN_EMAIL']
admin_password = ENV['ADMIN_PASSWORD']

warehouse_email = ENV['WAREHOUSE_EMAIL']
warehouse_password = ENV['WAREHOUSE_PASSWORD']

ActiveRecord::Base.transaction do
  begin
    # Management Admin
    management_admin = AdminUser.find_or_create_by!(email: admin_email) do |admin|
      admin.password = admin_password
      admin.password_confirmation = admin_password
      admin.admin_role = 'management'
      admin.skip_detail_build = true  # Skip auto-building during seed
    end

    unless management_admin.admin_detail
      management_admin.create_admin_detail!(
        first_name: 'Admin',
        last_name: 'User',
        dob: Date.new(1990, 1, 1)
      )
    end

    AdminAddress.find_or_create_by!(
      admin_user: management_admin,
      address: company_site_records.first,
      is_default: true
    )

    AdminUsersCompanySite.find_or_create_by!(
      admin_user: management_admin,
      company_site: CompanySite.find_by(title: company_site.first[:title])
    )

    # Warehouse Admin
    warehouse_admin = AdminUser.find_or_create_by!(email: warehouse_email) do |admin|
      admin.password = warehouse_password
      admin.password_confirmation = warehouse_password
      admin.admin_role = 'warehouse'
      admin.skip_detail_build = true  # Skip auto-building during seed
    end

    unless warehouse_admin.admin_detail
      warehouse_admin.create_admin_detail!(
        first_name: 'Warehouse',
        last_name: 'Admin',
        dob: Date.new(1995, 1, 1)
      )
    end

    AdminAddress.find_or_create_by!(
      admin_user: warehouse_admin,
      address: company_site_records.second,
      is_default: true
    )

    AdminUsersCompanySite.find_or_create_by!(
      admin_user: warehouse_admin,
      company_site: CompanySite.find_by(title: company_site.second[:title])
    )

    puts "Admin users seeded successfully."
  rescue StandardError => e
    puts "Failed to seed admin users. Error: #{e.message}"
    raise ActiveRecord::Rollback
  end
end
