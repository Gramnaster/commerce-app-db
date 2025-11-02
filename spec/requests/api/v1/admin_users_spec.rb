require 'rails_helper'

RSpec.describe "Api::V1::AdminUsers", type: :request do
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

  let!(:warehouse_admin) do
    admin = AdminUser.new(
      email: 'warehouse@test.com',
      password: 'password123',
      password_confirmation: 'password123',
      admin_role: 'warehouse',
      confirmed_at: Time.current,
      skip_detail_validation: true
    )
    admin.save!(validate: false)
    admin.build_admin_detail(first_name: 'Warehouse', last_name: 'Admin', dob: Date.new(1990, 1, 1))
    admin.save!(validate: false)
    admin
  end

  let(:admin_token) do
    JWT.encode(
      { jti: admin_user.jti, sub: admin_user.id.to_s, scp: 'admin_user', aud: nil, iat: Time.now.to_i, exp: 1.day.from_now.to_i },
      ENV['DEVISE_JWT_SECRET_KEY'],
      'HS256'
    )
  end

  let(:warehouse_token) do
    JWT.encode(
      { jti: warehouse_admin.jti, sub: warehouse_admin.id.to_s, scp: 'admin_user', aud: nil, iat: Time.now.to_i, exp: 1.day.from_now.to_i },
      ENV['DEVISE_JWT_SECRET_KEY'],
      'HS256'
    )
  end

  describe 'GET /api/v1/admin_users' do
    it 'requires authentication' do
      get '/api/v1/admin_users.json'
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns admin users list for authenticated admin' do
      get '/api/v1/admin_users.json', headers: { 'Authorization' => "Bearer #{admin_token}" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET /api/v1/admin_users/:id' do
    it 'requires authentication' do
      get "/api/v1/admin_users/#{admin_user.id}.json"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows admin to view own profile' do
      get "/api/v1/admin_users/#{admin_user.id}.json", headers: { 'Authorization' => "Bearer #{admin_token}" }
      expect(response).to have_http_status(:ok)
    end

    it 'allows admin to view other admin profile' do
      get "/api/v1/admin_users/#{warehouse_admin.id}.json", headers: { 'Authorization' => "Bearer #{admin_token}" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'PATCH /api/v1/admin_users/:id' do
    it 'requires authentication' do
      patch "/api/v1/admin_users/#{admin_user.id}.json", params: { admin_user: { email: 'new@test.com' } }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /api/v1/admin_users/:id' do
    it 'requires authentication' do
      delete "/api/v1/admin_users/#{warehouse_admin.id}.json"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'allows management admin to delete other admins' do
      delete "/api/v1/admin_users/#{warehouse_admin.id}.json",
        headers: { 'Authorization' => "Bearer #{admin_token}" }

      expect(response).to have_http_status(:ok)
    end

    it 'denies warehouse admin from deleting users' do
      delete "/api/v1/admin_users/#{admin_user.id}.json",
        headers: { 'Authorization' => "Bearer #{warehouse_token}" }

      expect(response).to have_http_status(:forbidden)
    end
  end
end
