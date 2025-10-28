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

ActiveRecord::Schema[8.1].define(version: 2025_10_28_155747) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "admin_role", ["management", "warehouse"]
  create_enum "cart_status", ["rejected", "pending", "approved"]
  create_enum "phone_type", ["mobile", "home", "work"]
  create_enum "product_status", ["storage", "progress", "delivered"]
  create_enum "site_type", ["management", "warehouse"]

  create_table "addresses", force: :cascade do |t|
    t.string "address_line1"
    t.string "address_line2"
    t.string "barangay", null: false
    t.string "city", null: false
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.string "region"
    t.string "street_no", null: false
    t.string "unit_no", null: false
    t.datetime "updated_at", null: false
    t.string "zipcode", null: false
    t.index ["country_id"], name: "index_addresses_on_country_id"
  end

  create_table "admin_addresses", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.bigint "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_admin_addresses_on_address_id"
    t.index ["admin_user_id"], name: "index_admin_addresses_on_admin_user_id"
  end

  create_table "admin_details", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.date "dob", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "middle_name"
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_admin_details_on_admin_user_id"
  end

  create_table "admin_phones", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.integer "phone_no", null: false
    t.enum "phone_type", default: "mobile", null: false, enum_type: "phone_type"
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_admin_phones_on_admin_user_id"
    t.index ["phone_type"], name: "index_admin_phones_on_phone_type"
  end

  create_table "admin_users", force: :cascade do |t|
    t.enum "admin_role", default: "management", null: false, enum_type: "admin_role"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "jti"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["admin_role"], name: "index_admin_users_on_admin_role"
    t.index ["confirmation_token"], name: "index_admin_users_on_confirmation_token", unique: true
    t.index ["deleted_at"], name: "index_admin_users_on_deleted_at"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["jti"], name: "index_admin_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true
  end

  create_table "admin_users_company_sites", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.bigint "company_site_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id"], name: "index_admin_users_company_sites_on_admin_user_id"
    t.index ["company_site_id"], name: "index_admin_users_company_sites_on_company_site_id"
  end

  create_table "company_sites", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.datetime "created_at", null: false
    t.enum "site_type", default: "warehouse", null: false, enum_type: "site_type"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_company_sites_on_address_id"
    t.index ["site_type"], name: "index_company_sites_on_site_type"
    t.index ["title"], name: "index_company_sites_on_title", unique: true
  end

  create_table "countries", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "inventories", force: :cascade do |t|
    t.bigint "company_site_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.integer "qty_in_stock"
    t.string "sku", null: false
    t.datetime "updated_at", null: false
    t.index ["company_site_id"], name: "index_inventories_on_company_site_id"
    t.index ["product_id"], name: "index_inventories_on_product_id"
    t.index ["sku"], name: "index_inventories_on_sku", unique: true
  end

  create_table "phones", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "phone_no", default: "", null: false
    t.enum "phone_type", default: "mobile", null: false, enum_type: "phone_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["phone_type"], name: "index_phones_on_phone_type"
    t.index ["user_id"], name: "index_phones_on_user_id"
  end

  create_table "producers", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["address_id"], name: "index_producers_on_address_id"
  end

  create_table "product_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.decimal "price", precision: 15, scale: 2
    t.bigint "producer_id", null: false
    t.bigint "product_category_id", null: false
    t.string "product_image_url"
    t.bigint "promotion_id"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["producer_id"], name: "index_products_on_producer_id"
    t.index ["product_category_id"], name: "index_products_on_product_category_id"
    t.index ["promotion_id"], name: "index_products_on_promotion_id"
  end

  create_table "promotions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.decimal "discount_amount", precision: 15, scale: 2
    t.datetime "updated_at", null: false
  end

  create_table "promotions_categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_categories_id", null: false
    t.bigint "promotions_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_categories_id"], name: "index_promotions_categories_on_product_categories_id"
    t.index ["promotions_id"], name: "index_promotions_categories_on_promotions_id"
  end

  create_table "receipts", force: :cascade do |t|
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.decimal "balance_after", precision: 15, scale: 2, null: false
    t.decimal "balance_before", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "transaction_type", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_cart_order_id"
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_receipts_on_created_at"
    t.index ["transaction_type"], name: "index_receipts_on_transaction_type"
    t.index ["user_cart_order_id"], name: "index_receipts_on_user_cart_order_id"
    t.index ["user_id"], name: "index_receipts_on_user_id"
  end

  create_table "shopping_cart_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.decimal "qty", default: "0.0", null: false
    t.bigint "shopping_cart_id", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_shopping_cart_items_on_product_id"
    t.index ["shopping_cart_id"], name: "index_shopping_cart_items_on_shopping_cart_id"
  end

  create_table "shopping_carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_shopping_carts_on_user_id"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["key_hash", "byte_size"], name: "index_solid_cache_entries_on_key_hash_and_byte_size"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "user_addresses", force: :cascade do |t|
    t.bigint "address_id", null: false
    t.datetime "created_at", null: false
    t.boolean "is_default", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["address_id"], name: "index_user_addresses_on_address_id"
    t.index ["user_id"], name: "index_user_addresses_on_user_id"
  end

  create_table "user_cart_orders", force: :cascade do |t|
    t.enum "cart_status", default: "pending", null: false, enum_type: "cart_status"
    t.datetime "created_at", null: false
    t.boolean "is_paid", default: false, null: false
    t.bigint "shopping_cart_id", null: false
    t.decimal "total_cost", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_address_id", null: false
    t.index ["cart_status"], name: "index_user_cart_orders_on_cart_status"
    t.index ["shopping_cart_id"], name: "index_user_cart_orders_on_shopping_cart_id"
    t.index ["user_address_id"], name: "index_user_cart_orders_on_user_address_id"
  end

  create_table "user_details", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "dob", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "middle_name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_details_on_user_id"
  end

  create_table "user_payment_methods", force: :cascade do |t|
    t.decimal "balance", precision: 15, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.string "payment_type"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_user_payment_methods_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.boolean "is_verified", default: false
    t.string "jti"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "warehouse_orders", force: :cascade do |t|
    t.bigint "company_site_id", null: false
    t.datetime "created_at", null: false
    t.bigint "inventory_id", null: false
    t.enum "product_status", null: false, enum_type: "product_status"
    t.integer "qty"
    t.datetime "updated_at", null: false
    t.bigint "user_cart_order_id", null: false
    t.bigint "user_id", null: false
    t.index ["company_site_id"], name: "index_warehouse_orders_on_company_site_id"
    t.index ["inventory_id"], name: "index_warehouse_orders_on_inventory_id"
    t.index ["user_cart_order_id"], name: "index_warehouse_orders_on_user_cart_order_id"
    t.index ["user_id"], name: "index_warehouse_orders_on_user_id"
  end

  add_foreign_key "addresses", "countries"
  add_foreign_key "admin_addresses", "addresses"
  add_foreign_key "admin_addresses", "admin_users"
  add_foreign_key "admin_details", "admin_users"
  add_foreign_key "admin_phones", "admin_users"
  add_foreign_key "admin_users_company_sites", "admin_users"
  add_foreign_key "admin_users_company_sites", "company_sites"
  add_foreign_key "company_sites", "addresses"
  add_foreign_key "inventories", "company_sites"
  add_foreign_key "inventories", "products"
  add_foreign_key "phones", "users"
  add_foreign_key "producers", "addresses"
  add_foreign_key "products", "producers"
  add_foreign_key "products", "product_categories"
  add_foreign_key "products", "promotions"
  add_foreign_key "promotions_categories", "product_categories", column: "product_categories_id"
  add_foreign_key "promotions_categories", "promotions", column: "promotions_id"
  add_foreign_key "receipts", "user_cart_orders"
  add_foreign_key "receipts", "users"
  add_foreign_key "shopping_cart_items", "products"
  add_foreign_key "shopping_cart_items", "shopping_carts"
  add_foreign_key "shopping_carts", "users"
  add_foreign_key "user_addresses", "addresses"
  add_foreign_key "user_addresses", "users"
  add_foreign_key "user_cart_orders", "shopping_carts"
  add_foreign_key "user_cart_orders", "user_addresses"
  add_foreign_key "user_details", "users"
  add_foreign_key "user_payment_methods", "users"
  add_foreign_key "warehouse_orders", "company_sites"
  add_foreign_key "warehouse_orders", "inventories"
  add_foreign_key "warehouse_orders", "user_cart_orders"
  add_foreign_key "warehouse_orders", "users"
end
