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

ActiveRecord::Schema[8.1].define(version: 2026_04_03_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "invoices", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.date "due_date", null: false
    t.bigint "landlord_id", null: false
    t.date "paid_date"
    t.bigint "property_id"
    t.string "status", default: "pending", null: false
    t.string "supplier_name", null: false
    t.datetime "updated_at", null: false
    t.index ["landlord_id"], name: "index_invoices_on_landlord_id"
    t.index ["property_id"], name: "index_invoices_on_property_id"
    t.index ["status"], name: "index_invoices_on_status"
  end

  create_table "landlords", force: :cascade do |t|
    t.string "company_name"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name", null: false
    t.decimal "management_fee_rate", precision: 5, scale: 2
    t.string "nature", null: false
    t.integer "payment_day"
    t.string "payment_disabled_reason"
    t.boolean "payment_enabled", default: true, null: false
    t.string "phone"
    t.string "siret"
    t.datetime "updated_at", null: false
  end

  create_table "lease_tenants", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "lease_id", null: false
    t.decimal "share", precision: 5, scale: 2, default: "100.0"
    t.bigint "tenant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["lease_id"], name: "index_lease_tenants_on_lease_id"
    t.index ["tenant_id"], name: "index_lease_tenants_on_tenant_id"
  end

  create_table "leases", force: :cascade do |t|
    t.integer "balance_cents", default: 0, null: false
    t.integer "charges_amount_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "deposit_amount_cents", default: 0, null: false
    t.date "end_date"
    t.string "lease_type", null: false
    t.bigint "property_id", null: false
    t.integer "rent_amount_cents", null: false
    t.date "start_date", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["end_date"], name: "index_leases_on_end_date"
    t.index ["property_id"], name: "index_leases_on_property_id"
    t.index ["status"], name: "index_leases_on_status"
  end

  create_table "mandates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "ended_at"
    t.bigint "landlord_id", null: false
    t.decimal "management_fee_rate", precision: 5, scale: 2, default: "7.0", null: false
    t.integer "payment_day", default: 10, null: false
    t.string "reference", null: false
    t.date "signed_at", null: false
    t.datetime "updated_at", null: false
    t.index ["landlord_id"], name: "index_mandates_on_landlord_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.bigint "lease_id", null: false
    t.string "payment_method", null: false
    t.string "payment_type", null: false
    t.datetime "updated_at", null: false
    t.index ["date"], name: "index_payments_on_date"
    t.index ["lease_id"], name: "index_payments_on_lease_id"
  end

  create_table "properties", force: :cascade do |t|
    t.string "address", null: false
    t.decimal "area_sqm", precision: 8, scale: 2
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.bigint "landlord_id", null: false
    t.bigint "mandate_id"
    t.string "nature", null: false
    t.integer "rooms_count"
    t.string "unit_number"
    t.datetime "updated_at", null: false
    t.string "zip_code", null: false
    t.index ["landlord_id"], name: "index_properties_on_landlord_id"
    t.index ["mandate_id"], name: "index_properties_on_mandate_id"
  end

  create_table "tenants", force: :cascade do |t|
    t.integer "caf_amount_cents"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
  end

  add_foreign_key "invoices", "landlords"
  add_foreign_key "invoices", "properties"
  add_foreign_key "lease_tenants", "leases"
  add_foreign_key "lease_tenants", "tenants"
  add_foreign_key "leases", "properties"
  add_foreign_key "mandates", "landlords"
  add_foreign_key "payments", "leases"
  add_foreign_key "properties", "landlords"
  add_foreign_key "properties", "mandates"
end
