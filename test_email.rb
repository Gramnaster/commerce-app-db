require_relative 'config/environment'

# Create test user without triggering validations on associated records
user = User.new(email: 'test@example.com', password: 'Password123!')
user.skip_confirmation_notification!

# Skip the user_detail creation callback temporarily
User.skip_callback(:create, :after, :create_details)
user.save!
User.set_callback(:create, :after, :create_details)

# Generate token
token = user.confirmation_token || user.send(:set_confirmation_token)

# Generate email
mail = DeviseMailer.confirmation_instructions(user, token)
body = mail.body.encoded

# Output results
puts "=" * 80
puts "EMAIL SUBJECT: #{mail.subject}"
puts "=" * 80
puts body
puts "=" * 80

# Check for URL
if body.include?('confirmation_token=')
  url = body.scan(/http[^"'\s<]+confirmation_token=[^"'\s<]+/).first
  puts "✅ SUCCESS: Confirmation URL found"
  puts "   URL: #{url}"
  puts "   Button is clickable: #{body.include?('href=')}"
else
  puts "❌ FAILED: No confirmation URL in email"
end

# Cleanup
user.destroy
puts "=" * 80
