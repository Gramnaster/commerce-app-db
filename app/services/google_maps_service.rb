class GoogleMapsService
  BASE_URL = "https://maps.googleapis.com/maps/api/".freeze

  def initialize
    @api_key = ENV["GOOGLE_MAPS_API_KEY"]
    raise "Google Maps API key not found. Please set GOOGLE_MAPS_API_KEY in .env" unless @api_key
  end

  # Geocode an address string to get lat/lng coordinates
  # Returns: { lat:, lng:, formatted_address:, location_type: } or nil
  def geocode_address(address_string)
    response = conn.get("geocode/json") do |req|
      req.params["address"] = address_string
      req.params["key"] = @api_key
    end

    handle_response(response, "geocode") do |body|
      return nil if body["results"].empty?

      result = body["results"].first
      location = result["geometry"]["location"]

      {
        lat: location["lat"],
        lng: location["lng"],
        formatted_address: result["formatted_address"],
        location_type: result["geometry"]["location_type"]
      }
    end
  end

  # Calculate distances from multiple origins to a single destination
  # origins: Array of {lat:, lng:} hashes
  # destination: String address OR {lat:, lng:} hash
  # Returns: Array of distance data for each origin
  def distance_matrix(origins, destination)
    origin_strings = origins.map { |loc| "#{loc[:lat]},#{loc[:lng]}" }.join("|")

    destination_string = if destination.is_a?(Hash)
      "#{destination[:lat]},#{destination[:lng]}"
    else
      destination.to_s
    end

    response = conn.get("distancematrix/json") do |req|
      req.params["origins"] = origin_strings
      req.params["destinations"] = destination_string
      req.params["key"] = @api_key
      req.params["units"] = "metric"
    end

    handle_response(response, "distance matrix") do |body|
      body["rows"]
    end
  end

  private

  def conn
    @conn ||= Faraday.new(url: BASE_URL) do |f|
      f.request :url_encoded
      f.response :json, content_type: /\bjson$/
      f.adapter Faraday.default_adapter
      f.options.timeout = 10
      f.options.open_timeout = 5
    end
  end

  def handle_response(response, api_name)
    unless response.success?
      Rails.logger.error("Google Maps #{api_name} HTTP Error: #{response.status}")
      return nil
    end

    body = response.body

    unless body.is_a?(Hash)
      Rails.logger.error("Google Maps #{api_name} Invalid Response: Not JSON")
      return nil
    end

    case body["status"]
    when "OK"
      yield(body)
    when "ZERO_RESULTS"
      Rails.logger.warn("Google Maps #{api_name}: No results found")
      nil
    else
      error_msg = body["error_message"] || body["status"]
      Rails.logger.error("Google Maps #{api_name} API Error: #{error_msg}")
      nil
    end
  rescue Faraday::TimeoutError => e
    Rails.logger.error("Google Maps #{api_name} Timeout: #{e.message}")
    nil
  rescue Faraday::Error => e
    Rails.logger.error("Google Maps #{api_name} Network Error: #{e.message}")
    nil
  end
end
