# Cloudinary configuration for Active Storage
# The CLOUDINARY_URL environment variable is automatically used by the gem
# Format: cloudinary://API_KEY:API_SECRET@CLOUD_NAME

require "cloudinary"

if ENV["CLOUDINARY_URL"].present?
  Cloudinary.config_from_url(ENV["CLOUDINARY_URL"])

  # Optional: Log the cloud name to verify configuration (don't log secrets!)
  Rails.logger.info "Cloudinary configured with cloud name: #{Cloudinary.config.cloud_name}" if Rails.env.development?
end
