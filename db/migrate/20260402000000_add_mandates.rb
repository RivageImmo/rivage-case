# frozen_string_literal: true

# Un propriétaire peut signer plusieurs mandats de gestion à différentes époques,
# avec des conditions (taux d'honoraires, jour de versement) différentes par mandat.
# Chaque bien est rattaché à un mandat et hérite donc de ses conditions.
class AddMandates < ActiveRecord::Migration[8.0]
  def change
    create_table :mandates do |t|
      t.references :landlord, null: false, foreign_key: true
      t.string :reference, null: false # ex: "MAND-2024-001"
      t.decimal :management_fee_rate, precision: 5, scale: 2
      t.integer :payment_day
      t.date :signed_at, null: false
      t.date :ended_at
      t.timestamps
    end

    add_reference :properties, :mandate, foreign_key: true
  end
end
