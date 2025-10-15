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
