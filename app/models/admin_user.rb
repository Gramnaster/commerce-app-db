class AdminUser < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  # Soft delete support - admin can be disabled when they leave the company
  acts_as_paranoid

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :timeoutable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_one :admin_detail, dependent: :destroy
  has_many :admin_phones, dependent: :destroy
  has_many :admin_addresses, dependent: :destroy
  has_many :addresses, through: :admin_addresses
  has_many :admin_users_company_sites, dependent: :destroy
  has_many :company_sites, through: :admin_users_company_sites

  # Enum for admin_role
  enum :admin_role, { management: "management", warehouse: "warehouse" }

  # Nested attributes
  accepts_nested_attributes_for :admin_detail, allow_destroy: true

  accepts_nested_attributes_for :admin_phones, allow_destroy: true, reject_if: :all_blank

  accepts_nested_attributes_for :admin_addresses, allow_destroy: true, reject_if: :all_blank

  accepts_nested_attributes_for :admin_users_company_sites, allow_destroy: true, reject_if: :all_blank

  # Attribute to skip validation during seeding
  attr_accessor :skip_detail_validation

  # Validation: admin_detail must be present (skip during seeding)
  validates :admin_detail, presence: true, unless: :skip_detail_validation
end
