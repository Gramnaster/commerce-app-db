# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_13_074159) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "phone_type", ["mobile", "home", "work"]

  create_table "addresses", force: :cascade do |t|
    t.string "unit_no", null: false
    t.string "street_no", null: false
    t.string "address_line1"
    t.string "address_line2"
    t.string "city", null: false
    t.string "region"
    t.string "zipcode", null: false
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_addresses_on_country_id"
  end

  create_table "countries", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "phones", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "phone_no", null: false
    t.enum "phone_type", default: "mobile", null: false, enum_type: "phone_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["phone_type"], name: "index_phones_on_phone_type"
    t.index ["user_id"], name: "index_phones_on_user_id"
  end

  create_table "user_addresses", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "address_id", null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_user_addresses_on_address_id"
    t.index ["user_id"], name: "index_user_addresses_on_user_id"
  end

  create_table "user_details", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "first_name", null: false
    t.string "middle_name"
    t.string "last_name", null: false
    t.date "dob", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_details_on_user_id"
  end

  create_table "user_payment_methods", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "balance", precision: 15, scale: 2, default: "0.0", null: false
    t.string "payment_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_payment_methods_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "addresses", "countries"
  add_foreign_key "phones", "users"
  add_foreign_key "user_addresses", "addresses"
  add_foreign_key "user_addresses", "users"
  add_foreign_key "user_details", "users"
  add_foreign_key "user_payment_methods", "users"
end
