require 'rails_helper'

RSpec.describe "Api::V1::Users", type: :request do
  # Use let! to ensure these are created once before tests run
  let!(:admin_user) do
    admin = AdminUser.new(
      email: 'test_admin@test.com',
      password: 'password123',
      password_confirmation: 'password123',
      admin_role: 'management',
      confirmed_at: Time.current,
      skip_detail_validation: true
    )
    admin.save!(validate: false)
    admin.build_admin_detail(first_name: 'Admin', last_name: 'User', dob: Date.new(1990, 1, 1))
    admin.save!(validate: false)
    admin
  end

  let!(:user) do
    u = User.new(
      email: 'test_user@test.com',
      password: 'password123',
      password_confirmation: 'password123',
      confirmed_at: Time.current
    )
    u.define_singleton_method(:create_details) { } # Skip after_create callback
    u.save!(validate: false)
    u.build_user_detail(first_name: 'Test', last_name: 'User', dob: Date.new(1990, 1, 1))
    u.save!(validate: false)
    u.user_payment_methods.create!(balance: 0.00)
    u.build_shopping_cart
    u.save!(validate: false)
    u
  end

  let(:admin_token) do
    JWT.encode(
      { jti: admin_user.jti, sub: admin_user.id.to_s, scp: 'admin_user', aud: nil, iat: Time.now.to_i, exp: 1.day.from_now.to_i },
      ENV['DEVISE_JWT_SECRET_KEY'],
      'HS256'
    )
  end

  let(:user_token) do
    JWT.encode(
      { jti: user.jti, sub: user.id.to_s, scp: 'user', aud: nil, iat: Time.now.to_i, exp: 1.day.from_now.to_i },
      ENV['DEVISE_JWT_SECRET_KEY'],
      'HS256'
    )
  end

  describe 'GET /api/v1/users' do
    it 'requires authentication' do
      get '/api/v1/users.json'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns users list for admin' do
      get '/api/v1/users.json', headers: { 'Authorization' => "Bearer #{admin_token}" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
    end

    it 'denies access for regular user' do
      get '/api/v1/users.json', headers: { 'Authorization' => "Bearer #{user_token}" }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/v1/users/:id' do
    it 'requires authentication' do
      get "/api/v1/users/#{user.id}.json"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows user to view own profile' do
      get "/api/v1/users/#{user.id}.json", headers: { 'Authorization' => "Bearer #{user_token}" }
      expect(response).to have_http_status(:ok)
    end

    it 'allows admin to view any user profile' do
      get "/api/v1/users/#{user.id}.json", headers: { 'Authorization' => "Bearer #{admin_token}" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /api/v1/users/:id' do
    it 'requires authentication' do
      patch "/api/v1/users/#{user.id}.json", params: { user: { email: 'new@test.com' } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/users/:id' do
    it 'requires authentication' do
      delete "/api/v1/users/#{user.id}.json"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
