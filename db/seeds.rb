# frozen_string_literal: true

# =============================================================================
# Seeds — Rivage Case Study
# Portefeuille d'une agence de gestion locative fictive
# Données au 9 avril 2026
# =============================================================================

puts '==> Seeding database...'

# Helper pour créer des paiements mensuels
def create_monthly_payments(lease, months:, method: 'bank_transfer', partial: false, caf_tenant: nil)
  months.each do |month_date|
    if caf_tenant && caf_tenant.caf_amount_cents.present?
      # Paiement CAF séparé
      Payment.create!(
        lease: lease,
        date: month_date + 4.days,
        amount_cents: caf_tenant.caf_amount_cents,
        payment_type: 'rent',
        payment_method: 'caf'
      )

      tenant_part = lease.total_due_cents - caf_tenant.caf_amount_cents
      if partial
        # Le locataire ne paie pas sa part
      else
        Payment.create!(
          lease: lease,
          date: month_date + 7.days,
          amount_cents: tenant_part,
          payment_type: 'rent',
          payment_method: method
        )
      end
    else
      Payment.create!(
        lease: lease,
        date: month_date + rand(1..8).days,
        amount_cents: partial ? (lease.total_due_cents * 0.6).to_i : lease.total_due_cents,
        payment_type: 'rent',
        payment_method: method
      )
    end
  end
end

# =============================================================================
# 1. Marie Dupont — Cas simple, tout va bien
# =============================================================================
marie = Landlord.create!(
  nature: 'physical',
  first_name: 'Marie',
  last_name: 'Dupont',
  email: 'marie.dupont@email.com',
  phone: '06 12 34 56 78',
  payment_day: nil, # suit le défaut agence (le 10)
  management_fee_rate: nil # suit le défaut agence (7%)
)

prop_marie = Property.create!(
  landlord: marie,
  address: '45 rue de Rivoli',
  unit_number: 'Apt 3B',
  city: 'Paris',
  zip_code: '75001',
  nature: 'apartment',
  area_sqm: 55.0,
  rooms_count: 2
)

jean_martin = Tenant.create!(
  first_name: 'Jean',
  last_name: 'Martin',
  email: 'jean.martin@gmail.com',
  phone: '06 11 22 33 44'
)

lease_marie = Lease.create!(
  property: prop_marie,
  status: 'active',
  lease_type: 'residential_unfurnished',
  start_date: Date.new(2024, 9, 1),
  end_date: Date.new(2027, 8, 31),
  rent_amount_cents: 85_000,
  charges_amount_cents: 8_000,
  deposit_amount_cents: 85_000,
  balance_cents: 0
)

LeaseTenant.create!(lease: lease_marie, tenant: jean_martin, share: 100.0)

create_monthly_payments(lease_marie,
  months: [Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1)])

# =============================================================================
# 2. SCI Les Oliviers — Multi-biens, lot vacant, mix résidentiel/commercial
# =============================================================================
sci_oliviers = Landlord.create!(
  nature: 'company',
  first_name: 'Philippe',
  last_name: 'Bernard',
  company_name: 'SCI Les Oliviers',
  siret: '832 547 891 00012',
  email: 'contact@sci-oliviers.fr',
  phone: '06 98 76 54 32',
  payment_day: 15,
  management_fee_rate: 6.5
)

prop_oliviers_1 = Property.create!(
  landlord: sci_oliviers,
  address: '12 rue des Lilas',
  unit_number: 'Apt 1',
  city: 'Lyon',
  zip_code: '69003',
  nature: 'apartment',
  area_sqm: 70.0,
  rooms_count: 3
)

prop_oliviers_2 = Property.create!(
  landlord: sci_oliviers,
  address: '8 avenue Foch',
  unit_number: nil,
  city: 'Lyon',
  zip_code: '69006',
  nature: 'commercial',
  area_sqm: 120.0,
  rooms_count: nil
)

# LOT VACANT — pas de bail actif
prop_oliviers_3 = Property.create!(
  landlord: sci_oliviers,
  address: '12 rue des Lilas',
  unit_number: 'Apt 3',
  city: 'Lyon',
  zip_code: '69003',
  nature: 'apartment',
  area_sqm: 45.0,
  rooms_count: 2
)

sophie_durand = Tenant.create!(
  first_name: 'Sophie',
  last_name: 'Durand',
  email: 'sophie.durand@outlook.com',
  phone: '06 33 44 55 66'
)

lease_oliviers_1 = Lease.create!(
  property: prop_oliviers_1,
  status: 'active',
  lease_type: 'residential_unfurnished',
  start_date: Date.new(2023, 6, 1),
  end_date: Date.new(2026, 5, 31),
  rent_amount_cents: 75_000,
  charges_amount_cents: 6_000,
  deposit_amount_cents: 75_000,
  balance_cents: 0
)
LeaseTenant.create!(lease: lease_oliviers_1, tenant: sophie_durand, share: 100.0)
create_monthly_payments(lease_oliviers_1,
  months: [Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1)],
  method: 'sepa_debit')

# Bail commercial — Boulangerie Martin
boulangerie_tenant = Tenant.create!(
  first_name: 'Jacques',
  last_name: 'Martin',
  email: 'contact@boulangerie-martin.fr',
  phone: '04 78 00 11 22'
)

lease_oliviers_2 = Lease.create!(
  property: prop_oliviers_2,
  status: 'active',
  lease_type: 'commercial',
  start_date: Date.new(2022, 1, 1),
  end_date: Date.new(2031, 12, 31),
  rent_amount_cents: 180_000,
  charges_amount_cents: 20_000,
  deposit_amount_cents: 360_000,
  balance_cents: 0
)
LeaseTenant.create!(lease: lease_oliviers_2, tenant: boulangerie_tenant, share: 100.0)
create_monthly_payments(lease_oliviers_2,
  months: [Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1)],
  method: 'bank_transfer')

# Ancien bail terminé sur le lot vacant (Apt 3)
ancien_locataire = Tenant.create!(
  first_name: 'Marc',
  last_name: 'Petit',
  email: 'marc.petit@free.fr',
  phone: '06 99 88 77 66'
)
lease_ancien = Lease.create!(
  property: prop_oliviers_3,
  status: 'terminated',
  lease_type: 'residential_unfurnished',
  start_date: Date.new(2022, 3, 1),
  end_date: Date.new(2026, 2, 28),
  rent_amount_cents: 55_000,
  charges_amount_cents: 4_500,
  deposit_amount_cents: 55_000,
  balance_cents: 0
)
LeaseTenant.create!(lease: lease_ancien, tenant: ancien_locataire, share: 100.0)

# =============================================================================
# 3. Lucas Moreau — Même adresse que SCI Les Oliviers (12 rue des Lilas)
# =============================================================================
lucas = Landlord.create!(
  nature: 'physical',
  first_name: 'Lucas',
  last_name: 'Moreau',
  email: 'lucas.moreau@gmail.com',
  phone: '06 55 44 33 22',
  payment_day: nil,
  management_fee_rate: 8.0
)

prop_lucas_1 = Property.create!(
  landlord: lucas,
  address: '12 rue des Lilas',
  unit_number: 'Apt 2',
  city: 'Lyon',
  zip_code: '69003',
  nature: 'apartment',
  area_sqm: 60.0,
  rooms_count: 2
)

prop_lucas_2 = Property.create!(
  landlord: lucas,
  address: '12 rue des Lilas',
  unit_number: 'Apt 4',
  city: 'Lyon',
  zip_code: '69003',
  nature: 'apartment',
  area_sqm: 35.0,
  rooms_count: 1
)

pierre_leroy = Tenant.create!(
  first_name: 'Pierre',
  last_name: 'Leroy',
  email: 'pierre.leroy@outlook.com',
  phone: '06 22 33 44 55'
)

emma_petit = Tenant.create!(
  first_name: 'Emma',
  last_name: 'Petit',
  email: 'emma.petit@gmail.com',
  phone: '06 44 55 66 77'
)

lease_lucas_1 = Lease.create!(
  property: prop_lucas_1,
  status: 'active',
  lease_type: 'residential_unfurnished',
  start_date: Date.new(2024, 1, 15),
  end_date: Date.new(2027, 1, 14),
  rent_amount_cents: 68_000,
  charges_amount_cents: 5_500,
  deposit_amount_cents: 68_000,
  balance_cents: 0
)
LeaseTenant.create!(lease: lease_lucas_1, tenant: pierre_leroy, share: 100.0)
create_monthly_payments(lease_lucas_1,
  months: [Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1)])

lease_lucas_2 = Lease.create!(
  property: prop_lucas_2,
  status: 'active',
  lease_type: 'residential_furnished',
  start_date: Date.new(2025, 9, 1),
  end_date: Date.new(2026, 8, 31),
  rent_amount_cents: 52_000,
  charges_amount_cents: 4_000,
  deposit_amount_cents: 52_000,
  balance_cents: 0
)
LeaseTenant.create!(lease: lease_lucas_2, tenant: emma_petit, share: 100.0)
create_monthly_payments(lease_lucas_2,
  months: [Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1)])

# =============================================================================
# 4. Isabelle Faure — Locataire en impayé depuis 3 mois
# =============================================================================
isabelle = Landlord.create!(
  nature: 'physical',
  first_name: 'Isabelle',
  last_name: 'Faure',
  email: 'i.faure@orange.fr',
  phone: '06 77 88 99 00',
  payment_day: 10,
  management_fee_rate: nil
)

prop_isabelle = Property.create!(
  landlord: isabelle,
  address: '5 place Bellecour',
  unit_number: 'Apt 7A',
  city: 'Lyon',
  zip_code: '69002',
  nature: 'apartment',
  area_sqm: 80.0,
  rooms_count: 3
)

karim = Tenant.create!(
  first_name: 'Karim',
  last_name: 'Benali',
  email: 'k.benali@gmail.com',
  phone: '06 88 77 66 55',
  caf_amount_cents: 25_000 # 250 EUR d'aide CAF
)

lease_isabelle = Lease.create!(
  property: prop_isabelle,
  status: 'active',
  lease_type: 'residential_unfurnished',
  start_date: Date.new(2023, 10, 1),
  end_date: Date.new(2026, 9, 30),
  rent_amount_cents: 105_000,
  charges_amount_cents: 10_000,
  deposit_amount_cents: 105_000,
  balance_cents: -230_000 # dette de 2300 EUR (jan: 50k manquant + fev/mar: 90k manquant chacun)
)
LeaseTenant.create!(lease: lease_isabelle, tenant: karim, share: 100.0)

# Janvier : seule la CAF a payé
Payment.create!(
  lease: lease_isabelle,
  date: Date.new(2026, 1, 5),
  amount_cents: 25_000,
  payment_type: 'rent',
  payment_method: 'caf'
)
# Le locataire a payé un petit bout en janvier
Payment.create!(
  lease: lease_isabelle,
  date: Date.new(2026, 1, 15),
  amount_cents: 40_000,
  payment_type: 'rent',
  payment_method: 'bank_transfer'
)
# Février : seule la CAF
Payment.create!(
  lease: lease_isabelle,
  date: Date.new(2026, 2, 5),
  amount_cents: 25_000,
  payment_type: 'rent',
  payment_method: 'caf'
)
# Mars : seule la CAF
Payment.create!(
  lease: lease_isabelle,
  date: Date.new(2026, 3, 5),
  amount_cents: 25_000,
  payment_type: 'rent',
  payment_method: 'caf'
)

# =============================================================================
# 5. Pierre Garnier — Bail commercial + grosse facture travaux
# =============================================================================
garnier = Landlord.create!(
  nature: 'physical',
  first_name: 'Pierre',
  last_name: 'Garnier',
  email: 'p.garnier@wanadoo.fr',
  phone: '06 11 00 99 88',
  payment_day: nil,
  management_fee_rate: 5.0
)

prop_garnier = Property.create!(
  landlord: garnier,
  address: '22 rue de la République',
  unit_number: nil,
  city: 'Lyon',
  zip_code: '69002',
  nature: 'commercial',
  area_sqm: 200.0,
  rooms_count: nil
)

restaurant_tenant = Tenant.create!(
  first_name: 'Antoine',
  last_name: 'Dubois',
  email: 'contact@le-comptoir.fr',
  phone: '04 78 22 33 44'
)

lease_garnier = Lease.create!(
  property: prop_garnier,
  status: 'active',
  lease_type: 'commercial',
  start_date: Date.new(2020, 4, 1),
  end_date: Date.new(2029, 3, 31),
  rent_amount_cents: 220_000,
  charges_amount_cents: 35_000,
  deposit_amount_cents: 440_000,
  balance_cents: 0
)
LeaseTenant.create!(lease: lease_garnier, tenant: restaurant_tenant, share: 100.0)
create_monthly_payments(lease_garnier,
  months: [Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1)])

# Grosse facture travaux
Invoice.create!(
  landlord: garnier,
  property: prop_garnier,
  supplier_name: 'Artisan Duval SARL',
  description: 'Réfection complète de la toiture — urgence infiltrations',
  amount_cents: 850_000,
  status: 'pending',
  due_date: Date.new(2026, 4, 15)
)

# Petite facture payée
Invoice.create!(
  landlord: garnier,
  property: prop_garnier,
  supplier_name: 'Plomberie Express',
  description: 'Remplacement robinetterie sanitaires',
  amount_cents: 34_500,
  status: 'paid',
  due_date: Date.new(2026, 2, 1),
  paid_date: Date.new(2026, 2, 5)
)

# =============================================================================
# 6. SCI Marais Invest — Propriétaire débiteur (factures > loyers)
# =============================================================================
marais = Landlord.create!(
  nature: 'company',
  first_name: 'Anne-Sophie',
  last_name: 'Girard',
  company_name: 'SCI Marais Invest',
  siret: '901 234 567 00015',
  email: 'as.girard@maraisinvest.fr',
  phone: '06 33 22 11 00',
  payment_day: 20,
  management_fee_rate: 7.0
)

prop_marais_1 = Property.create!(
  landlord: marais,
  address: '15 rue du Temple',
  unit_number: 'Apt 2C',
  city: 'Paris',
  zip_code: '75004',
  nature: 'apartment',
  area_sqm: 40.0,
  rooms_count: 2
)

prop_marais_2 = Property.create!(
  landlord: marais,
  address: '15 rue du Temple',
  unit_number: 'Apt 4A',
  city: 'Paris',
  zip_code: '75004',
  nature: 'apartment',
  area_sqm: 55.0,
  rooms_count: 3
)

amina = Tenant.create!(
  first_name: 'Amina',
  last_name: 'Diallo',
  email: 'amina.diallo@gmail.com',
  phone: '06 44 33 22 11'
)

thomas_l = Tenant.create!(
  first_name: 'Thomas',
  last_name: 'Lefebvre',
  email: 'thomas.lefebvre@hotmail.fr',
  phone: '06 55 66 77 88'
)

lease_marais_1 = Lease.create!(
  property: prop_marais_1,
  status: 'active',
  lease_type: 'residential_furnished',
  start_date: Date.new(2025, 3, 1),
  end_date: Date.new(2027, 2, 28),
  rent_amount_cents: 98_000,
  charges_amount_cents: 8_500,
  deposit_amount_cents: 98_000,
  balance_cents: 0
)
LeaseTenant.create!(lease: lease_marais_1, tenant: amina, share: 100.0)
create_monthly_payments(lease_marais_1,
  months: [Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1)],
  method: 'sepa_debit')

lease_marais_2 = Lease.create!(
  property: prop_marais_2,
  status: 'active',
  lease_type: 'residential_unfurnished',
  start_date: Date.new(2024, 7, 1),
  end_date: Date.new(2027, 6, 30),
  rent_amount_cents: 115_000,
  charges_amount_cents: 9_500,
  deposit_amount_cents: 115_000,
  balance_cents: 0
)
LeaseTenant.create!(lease: lease_marais_2, tenant: thomas_l, share: 100.0)
create_monthly_payments(lease_marais_2,
  months: [Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1)])

# Lourdes factures de travaux — rendent le propriétaire débiteur
Invoice.create!(
  landlord: marais,
  property: nil,
  supplier_name: 'BTP Rénovation Paris',
  description: 'Ravalement de façade — immeuble 15 rue du Temple',
  amount_cents: 1_200_000,
  status: 'paid',
  due_date: Date.new(2026, 1, 15),
  paid_date: Date.new(2026, 1, 20)
)

Invoice.create!(
  landlord: marais,
  property: prop_marais_1,
  supplier_name: 'Elec-Pro Services',
  description: 'Mise aux normes électriques — Apt 2C',
  amount_cents: 680_000,
  status: 'pending',
  due_date: Date.new(2026, 4, 30)
)

Invoice.create!(
  landlord: marais,
  property: nil,
  supplier_name: 'Chauffage Central SARL',
  description: 'Remplacement chaudière collective',
  amount_cents: 450_000,
  status: 'pending',
  due_date: Date.new(2026, 5, 15)
)

# =============================================================================
# 7. Jean-Marc Leroy — Bail qui expire dans 15 jours + dépôt à restituer
# =============================================================================
jm_leroy = Landlord.create!(
  nature: 'physical',
  first_name: 'Jean-Marc',
  last_name: 'Leroy',
  email: 'jm.leroy@gmail.com',
  phone: '06 22 11 00 99',
  payment_day: nil,
  management_fee_rate: nil
)

prop_leroy = Property.create!(
  landlord: jm_leroy,
  address: '3 rue Mercière',
  unit_number: 'Apt 5',
  city: 'Lyon',
  zip_code: '69002',
  nature: 'apartment',
  area_sqm: 65.0,
  rooms_count: 3
)

fatou = Tenant.create!(
  first_name: 'Fatou',
  last_name: 'Sylla',
  email: 'fatou.sylla@yahoo.fr',
  phone: '06 99 88 77 66'
)

lease_leroy = Lease.create!(
  property: prop_leroy,
  status: 'active',
  lease_type: 'residential_unfurnished',
  start_date: Date.new(2023, 4, 25),
  end_date: Date.new(2026, 4, 24),
  rent_amount_cents: 72_000,
  charges_amount_cents: 6_000,
  deposit_amount_cents: 72_000,
  balance_cents: 0
)
LeaseTenant.create!(lease: lease_leroy, tenant: fatou, share: 100.0)
create_monthly_payments(lease_leroy,
  months: [Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1)],
  method: 'sepa_debit')

Invoice.create!(
  landlord: jm_leroy,
  property: prop_leroy,
  supplier_name: 'Plomberie Leroy',
  description: 'Réparation fuite salle de bain',
  amount_cents: 28_500,
  status: 'pending',
  due_date: Date.new(2026, 4, 20)
)

# =============================================================================
# 8. Catherine Blanc — Versement désactivé + co-location
# =============================================================================
catherine = Landlord.create!(
  nature: 'physical',
  first_name: 'Catherine',
  last_name: 'Blanc',
  email: 'c.blanc@me.com',
  phone: '06 00 11 22 33',
  payment_day: 5,
  management_fee_rate: 6.0,
  payment_enabled: false,
  payment_disabled_reason: 'Travaux en cours — consigner les fonds jusqu\'au terme des travaux'
)

prop_blanc = Property.create!(
  landlord: catherine,
  address: '7 quai de Saône',
  unit_number: 'Apt 8',
  city: 'Lyon',
  zip_code: '69001',
  nature: 'apartment',
  area_sqm: 90.0,
  rooms_count: 4
)

julien = Tenant.create!(
  first_name: 'Julien',
  last_name: 'Roux',
  email: 'julien.roux@gmail.com',
  phone: '06 12 12 12 12'
)

clara = Tenant.create!(
  first_name: 'Clara',
  last_name: 'Morel',
  email: 'clara.morel@gmail.com',
  phone: '06 34 34 34 34'
)

lease_blanc = Lease.create!(
  property: prop_blanc,
  status: 'active',
  lease_type: 'residential_unfurnished',
  start_date: Date.new(2025, 1, 1),
  end_date: Date.new(2028, 12, 31),
  rent_amount_cents: 110_000,
  charges_amount_cents: 12_000,
  deposit_amount_cents: 110_000,
  balance_cents: 0
)
LeaseTenant.create!(lease: lease_blanc, tenant: julien, share: 50.0)
LeaseTenant.create!(lease: lease_blanc, tenant: clara, share: 50.0)

# Chaque co-locataire paie sa moitié
[Date.new(2026, 1, 1), Date.new(2026, 2, 1), Date.new(2026, 3, 1)].each do |month|
  Payment.create!(
    lease: lease_blanc,
    date: month + 2.days,
    amount_cents: 61_000, # moitié du loyer+charges
    payment_type: 'rent',
    payment_method: 'bank_transfer'
  )
  Payment.create!(
    lease: lease_blanc,
    date: month + 3.days,
    amount_cents: 61_000,
    payment_type: 'rent',
    payment_method: 'bank_transfer'
  )
end

# Facture travaux en cours pour Catherine
Invoice.create!(
  landlord: catherine,
  property: prop_blanc,
  supplier_name: 'Rénovation Saône SARL',
  description: 'Rénovation salle de bain + cuisine — en cours',
  amount_cents: 1_450_000,
  status: 'pending',
  due_date: Date.new(2026, 6, 1)
)

puts "==> Seeded: #{Landlord.count} landlords, #{Property.count} properties, #{Tenant.count} tenants, #{Lease.count} leases, #{Payment.count} payments, #{Invoice.count} invoices"
