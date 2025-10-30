namespace :geocode do
  desc "Geocode all warehouse addresses using Google Maps API"
  task warehouses: :environment do
    puts "Starting warehouse geocoding..."
    puts "=" * 50

    service = GoogleMapsService.new
    warehouses = CompanySite.where(site_type: "warehouse").includes(:address)

    if warehouses.empty?
      puts "No warehouses found!"
      exit
    end

    warehouses.each do |warehouse|
      address = warehouse.address
      puts "\nProcessing: #{warehouse.title}"
      puts "Address: #{address.full_address}"

      if address.geocoded?
        puts "  Already geocoded: (#{address.latitude}, #{address.longitude})"
        next
      end

      result = service.geocode_address(address.full_address)

      if result
        address.update!(
          latitude: result[:lat],
          longitude: result[:lng],
          geocoded_at: Time.current,
          geocode_source: "google_maps"
        )
        puts "  ✓ Geocoded: (#{result[:lat]}, #{result[:lng]})"
        puts "  Location Type: #{result[:location_type]}"
        puts "  Formatted: #{result[:formatted_address]}"
      else
        puts "  ✗ Failed to geocode"
      end

      # Rate limiting: sleep to avoid hitting API limits
      sleep(0.5)
    end

    puts "\n" + "=" * 50
    puts "Geocoding complete!"

    # Summary
    geocoded_count = CompanySite.where(site_type: "warehouse")
                                .joins(:address)
                                .where.not(addresses: { latitude: nil })
                                .count

    puts "Warehouses geocoded: #{geocoded_count}/#{warehouses.count}"
  end
end
