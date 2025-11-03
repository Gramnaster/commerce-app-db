require 'rails_helper'

RSpec.describe "Api::V1::Products", type: :request do
  describe 'GET /api/v1/products' do
    it 'returns a successful response' do
      get '/api/v1/products.json'
      expect(response).to have_http_status(:ok)
    end

    it 'returns JSON content type' do
      get '/api/v1/products.json'
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET /api/v1/products/:id' do
    let(:country) { Country.create!(name: 'Test Country', code: 'TC') }
    let(:address) do
      Address.create!(
        unit_no: '1A',
        street_no: '123',
        barangay: 'Test Barangay',
        city: 'Test City',
        region: 'Test Region',
        zipcode: '1234',
        country: country
      )
    end
    let(:category) { ProductCategory.create!(title: 'Test Category') }
    let(:producer) { Producer.create!(title: 'Test Producer', address: address) }
    let(:product) do
      Product.create!(
        title: 'Test Product',
        price: 99.99,
        product_category: category,
        producer: producer
      )
    end

    it 'returns a successful response' do
      get "/api/v1/products/#{product.id}.json"
      expect(response).to have_http_status(:ok)
    end

    it 'returns the product data' do
      get "/api/v1/products/#{product.id}.json"
      json_response = JSON.parse(response.body)
      expect(json_response['data']['title']).to eq('Test Product')
    end
  end
end
