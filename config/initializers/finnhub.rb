require "finnhub_ruby"

class FinnhubClient
  def self.client
    @client ||= new
  end

  def initialize
    @api_keys = ENV["FINNHUB_API_KEY"].split(",")
    @current_index = 0
    configure_client
  end

  def configure_client
    FinnhubRuby.configure do |config|
      config.api_key["api_key"] = @api_keys[@current_index]
      p "Using another Finnhub API key"
    end
    @client = FinnhubRuby::DefaultApi.new
  end

  def rotate_key!
    @current_index = (@current_index + 1) % @api_keys.length
    configure_client
  end

  # Wrap any Finnhub API call with this method
  def self.try_request(&block)
    client.try_request(&block)
  end

  def try_request
    retries = 0
    begin
      yield @client
    rescue StandardError => e
      # Handle rate limit, timeout, and API errors
      if e.message.include?("429") || e.message.include?("rate limit") ||
         e.message.include?("timeout") || e.message.include?("408")
        if retries < @api_keys.length - 1
          puts "API key hit rate limit or timeout, rotating key..."
          rotate_key!
          retries += 1
          retry
        else
          raise "All Finnhub API keys exhausted due to rate limiting or timeout."
        end
      else
        raise
      end
    end
  end
end
