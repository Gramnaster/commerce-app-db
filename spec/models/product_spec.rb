require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'associations' do
    it 'belongs to product_category' do
      expect(Product.reflect_on_association(:product_category).macro).to eq(:belongs_to)
    end

    it 'belongs to producer' do
      expect(Product.reflect_on_association(:producer).macro).to eq(:belongs_to)
    end

    it 'has many shopping_cart_items' do
      expect(Product.reflect_on_association(:shopping_cart_items).macro).to eq(:has_many)
    end

    it 'has many inventories' do
      expect(Product.reflect_on_association(:inventories).macro).to eq(:has_many)
    end
  end

  describe 'validations' do
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

    it 'is valid with valid attributes' do
      product = Product.new(
        title: 'Test Product',
        price: 99.99,
        product_category: category,
        producer: producer
      )
      expect(product).to be_valid
    end

    it 'is not valid without a title' do
      product = Product.new(
        price: 99.99,
        product_category: category,
        producer: producer
      )
      expect(product).not_to be_valid
      expect(product.errors[:title]).to include("can't be blank")
    end

    it 'is not valid without a price' do
      product = Product.new(
        title: 'Test Product',
        product_category: category,
        producer: producer
      )
      expect(product).not_to be_valid
      expect(product.errors[:price]).to include("can't be blank")
    end

    it 'is not valid with negative price' do
      product = Product.new(
        title: 'Test Product',
        price: -10,
        product_category: category,
        producer: producer
      )
      expect(product).not_to be_valid
      expect(product.errors[:price]).to include("must be greater than or equal to 0")
    end
  end
end
