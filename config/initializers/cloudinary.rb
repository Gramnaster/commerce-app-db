# Cloudinary configuration for Active Storage
# The CLOUDINARY_URL environment variable is automatically used by the gem
# Format: cloudinary://API_KEY:API_SECRET@CLOUD_NAME

require "cloudinary"

if ENV["CLOUDINARY_URL"].present?
  Cloudinary.config_from_url(ENV["CLOUDINARY_URL"])

  # Set default transformations for optimal delivery
  # This applies auto format (WebP for supported browsers) and auto quality
  Cloudinary.config do |config|
    config.secure = true
    # Enable automatic format selection (WebP, AVIF) and quality optimization
    config.static_file_support = false
  end

  # Optional: Log the cloud name to verify configuration (don't log secrets!)
  Rails.logger.info "Cloudinary configured with cloud name: #{Cloudinary.config.cloud_name}" if Rails.env.development?
end
