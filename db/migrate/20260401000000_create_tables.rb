# frozen_string_literal: true

class CreateTables < ActiveRecord::Migration[8.0]
  def change
    create_table :landlords do |t|
      t.string :nature, null: false
      t.string :first_name
      t.string :last_name, null: false
      t.string :company_name
      t.string :siret
      t.string :email
      t.string :phone
      t.integer :payment_day
      t.decimal :management_fee_rate, precision: 5, scale: 2
      t.boolean :payment_enabled, default: true, null: false
      t.string :payment_disabled_reason
      t.timestamps
    end

    create_table :properties do |t|
      t.references :landlord, null: false, foreign_key: true
      t.string :address, null: false
      t.string :unit_number
      t.string :city, null: false
      t.string :zip_code, null: false
      t.string :nature, null: false
      t.decimal :area_sqm, precision: 8, scale: 2
      t.integer :rooms_count
      t.timestamps
    end

    create_table :tenants do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.integer :caf_amount_cents
      t.timestamps
    end

    create_table :leases do |t|
      t.references :property, null: false, foreign_key: true
      t.string :status, null: false, default: 'active'
      t.string :lease_type, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.integer :rent_amount_cents, null: false
      t.integer :charges_amount_cents, null: false, default: 0
      t.integer :deposit_amount_cents, null: false, default: 0
      t.integer :balance_cents, null: false, default: 0
      t.timestamps
    end

    create_table :lease_tenants do |t|
      t.references :lease, null: false, foreign_key: true
      t.references :tenant, null: false, foreign_key: true
      t.decimal :share, precision: 5, scale: 2, default: 100.0
      t.timestamps
    end

    create_table :payments do |t|
      t.references :lease, null: false, foreign_key: true
      t.date :date, null: false
      t.integer :amount_cents, null: false
      t.string :payment_type, null: false
      t.string :payment_method, null: false
      t.timestamps
    end

    create_table :invoices do |t|
      t.references :landlord, null: false, foreign_key: true
      t.references :property, foreign_key: true
      t.string :supplier_name, null: false
      t.string :description, null: false
      t.integer :amount_cents, null: false
      t.string :status, null: false, default: 'pending'
      t.date :due_date, null: false
      t.date :paid_date
      t.timestamps
    end

    add_index :leases, :status
    add_index :leases, :end_date
    add_index :payments, :date
    add_index :invoices, :status
  end
end
