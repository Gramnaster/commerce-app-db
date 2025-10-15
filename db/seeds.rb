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
        puts "  -> Created country: #{country.name} (#{country.code})"
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
addresses = [
  { unit_no: "2020", street_no: "26th Ave", city: "Taguig", zipcode: "1244", country: "102" },
  { unit_no: "0110", street_no: "9th Roxas", city: "Quezon", zipcode: "1499", country: "102" },
  { unit_no: "1430", street_no: "8th Cucumber", city: "Metro Manila", zipcode: "1011", country: "102" },
  { unit_no: "310", street_no: "15th Centre", city: "Cavite", zipcode: "1802", country: "102" }
]

# Seeds the Categories table
[ "men's clothing", "women's clothing", "jewelery", "electronics" ].each do |cat_title|
  ProductCategory.find_or_create_by!(title: cat_title)
end

# Seeds the Products table
puts "Seeding product data from fakeproducts..."

# ActiveRecord::Base.transaction do
#   begin
#     # API-Wrapper Project
#     puts "Populating products table"
#     url = URI.parse('https://fakestoreapi.com/products')
#     response = Net::HTTP.get(url)
#     products = JSON.parse(response)

#     products.each do |product_data|
#       # Find or create category
#       category = ProductCategory.find_or_create_by!(title: product_data['category'])

#       # Create product
#       Product.find_or_create_by!(title: product_data['title']) do |product|
#         product.product_category = category
#         product.description = product_data['description']
#         product.price = product_data['price']
#         product.product_image_url = product_data['image']
#       end
#       puts "Seeded product: #{product_data['title']}"
#     end

#     puts "Products table seeded successfully"
#   rescue StandardError => e
#     puts "Failed to seed products. Error: #{e.message}"
#     raise ActiveRecord::Rollback
#   end
# end
