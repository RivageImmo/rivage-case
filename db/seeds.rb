# frozen_string_literal: true

# =============================================================================
# Seeds — Rivage Case Study
# Portefeuille d'une agence de gestion locative fictive
# Contexte : on est le 8 avril 2026. La run des reversements propriétaires
# du 10 avril concerne les loyers de mars 2026 encaissés.
# =============================================================================

puts '==> Seeding database...'

# =============================================================================
# Helpers
# =============================================================================

# Crée les paiements mensuels standards pour un bail donné.
# Chaque mois = loyer + charges encaissés, éventuellement scindés en CAF + part locataire.
def pay_monthly(lease, months:, method: 'bank_transfer', caf_tenant: nil, partial_ratio: nil)
  months.each do |month_date|
    if caf_tenant&.caf_amount_cents.present?
      Payment.create!(
        lease: lease,
        date: month_date + 4.days,
        amount_cents: caf_tenant.caf_amount_cents,
        payment_type: 'rent',
        payment_method: 'caf'
      )
      tenant_part = lease.total_due_cents - caf_tenant.caf_amount_cents
      amount = partial_ratio ? (tenant_part * partial_ratio).to_i : tenant_part
      next if partial_ratio == 0

      Payment.create!(
        lease: lease,
        date: month_date + 7.days,
        amount_cents: amount,
        payment_type: 'rent',
        payment_method: method
      )
    else
      amount = partial_ratio ? (lease.total_due_cents * partial_ratio).to_i : lease.total_due_cents
      next if partial_ratio == 0

      Payment.create!(
        lease: lease,
        date: month_date + rand(1..8).days,
        amount_cents: amount,
        payment_type: 'rent',
        payment_method: method
      )
    end
  end
end

JAN = Date.new(2026, 1, 1)
FEB = Date.new(2026, 2, 1)
MAR = Date.new(2026, 3, 1)
APR = Date.new(2026, 4, 1)

# =============================================================================
# 1. Marie Dupont — Cas simple, tout va bien
# Signal : aucun. Référence "propriétaire facile" pour la run.
# =============================================================================
marie = Landlord.create!(
  nature: 'physical', first_name: 'Marie', last_name: 'Dupont',
  email: 'marie.dupont@email.com', phone: '06 12 34 56 78',
  payment_day: nil, management_fee_rate: nil
)
prop_marie = Property.create!(
  landlord: marie, address: '45 rue de Rivoli', unit_number: 'Apt 3B',
  city: 'Paris', zip_code: '75001', nature: 'apartment',
  area_sqm: 55.0, rooms_count: 2
)
jean_martin = Tenant.create!(first_name: 'Jean', last_name: 'Martin',
  email: 'jean.martin@gmail.com', phone: '06 11 22 33 44')
lease_marie = Lease.create!(
  property: prop_marie, status: 'active', lease_type: 'residential_unfurnished',
  start_date: Date.new(2024, 9, 1), end_date: Date.new(2027, 8, 31),
  rent_amount_cents: 85_000, charges_amount_cents: 8_000,
  deposit_amount_cents: 85_000, balance_cents: 0
)
LeaseTenant.create!(lease: lease_marie, tenant: jean_martin, share: 100.0)
pay_monthly(lease_marie, months: [JAN, FEB, MAR, APR])

# =============================================================================
# 2. SCI Les Oliviers — Multi-biens, lot vacant, mix résidentiel/commercial
# Signaux : multi_property, vacancy, commercial_lease
# =============================================================================
sci_oliviers = Landlord.create!(
  nature: 'company', first_name: 'Philippe', last_name: 'Bernard',
  company_name: 'SCI Les Oliviers', siret: '832 547 891 00012',
  email: 'contact@sci-oliviers.fr', phone: '06 98 76 54 32',
  payment_day: 15, management_fee_rate: 6.5
)
prop_oliviers_1 = Property.create!(landlord: sci_oliviers, address: '12 rue des Lilas',
  unit_number: 'Apt 1', city: 'Lyon', zip_code: '69003', nature: 'apartment',
  area_sqm: 70.0, rooms_count: 3)
prop_oliviers_2 = Property.create!(landlord: sci_oliviers, address: '8 avenue Foch',
  unit_number: nil, city: 'Lyon', zip_code: '69006', nature: 'commercial',
  area_sqm: 120.0, rooms_count: nil)
prop_oliviers_3 = Property.create!(landlord: sci_oliviers, address: '12 rue des Lilas',
  unit_number: 'Apt 3', city: 'Lyon', zip_code: '69003', nature: 'apartment',
  area_sqm: 45.0, rooms_count: 2) # VACANT

sophie_durand = Tenant.create!(first_name: 'Sophie', last_name: 'Durand',
  email: 'sophie.durand@outlook.com', phone: '06 33 44 55 66')
lease_oliviers_1 = Lease.create!(property: prop_oliviers_1, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2023, 6, 1),
  end_date: Date.new(2026, 5, 31), rent_amount_cents: 75_000,
  charges_amount_cents: 6_000, deposit_amount_cents: 75_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_oliviers_1, tenant: sophie_durand, share: 100.0)
pay_monthly(lease_oliviers_1, months: [JAN, FEB, MAR, APR], method: 'sepa_debit')

boulangerie = Tenant.create!(first_name: 'Jacques', last_name: 'Martin',
  email: 'contact@boulangerie-martin.fr', phone: '04 78 00 11 22')
lease_oliviers_2 = Lease.create!(property: prop_oliviers_2, status: 'active',
  lease_type: 'commercial', start_date: Date.new(2022, 1, 1),
  end_date: Date.new(2031, 12, 31), rent_amount_cents: 180_000,
  charges_amount_cents: 20_000, deposit_amount_cents: 360_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_oliviers_2, tenant: boulangerie, share: 100.0)
pay_monthly(lease_oliviers_2, months: [JAN, FEB, MAR, APR])

ancien_locataire = Tenant.create!(first_name: 'Marc', last_name: 'Petit',
  email: 'marc.petit@free.fr', phone: '06 99 88 77 66')
Lease.create!(property: prop_oliviers_3, status: 'terminated',
  lease_type: 'residential_unfurnished', start_date: Date.new(2022, 3, 1),
  end_date: Date.new(2026, 3, 31), rent_amount_cents: 55_000,
  charges_amount_cents: 4_500, deposit_amount_cents: 55_000, balance_cents: 0
).tap { |l| LeaseTenant.create!(lease: l, tenant: ancien_locataire, share: 100.0) }

# =============================================================================
# 3. Lucas Moreau — Même adresse que SCI Les Oliviers (piège de confusion)
# Signaux : aucun de risque mais homonymie d'adresse avec #2
# =============================================================================
lucas = Landlord.create!(
  nature: 'physical', first_name: 'Lucas', last_name: 'Moreau',
  email: 'lucas.moreau@gmail.com', phone: '06 55 44 33 22',
  payment_day: nil, management_fee_rate: 8.0
)
prop_lucas_1 = Property.create!(landlord: lucas, address: '12 rue des Lilas',
  unit_number: 'Apt 2', city: 'Lyon', zip_code: '69003', nature: 'apartment',
  area_sqm: 60.0, rooms_count: 2)
prop_lucas_2 = Property.create!(landlord: lucas, address: '12 rue des Lilas',
  unit_number: 'Apt 4', city: 'Lyon', zip_code: '69003', nature: 'apartment',
  area_sqm: 35.0, rooms_count: 1)
pierre_leroy = Tenant.create!(first_name: 'Pierre', last_name: 'Leroy',
  email: 'pierre.leroy@outlook.com', phone: '06 22 33 44 55')
emma_petit = Tenant.create!(first_name: 'Emma', last_name: 'Petit',
  email: 'emma.petit@gmail.com', phone: '06 44 55 66 77')
lease_lucas_1 = Lease.create!(property: prop_lucas_1, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2024, 1, 15),
  end_date: Date.new(2027, 1, 14), rent_amount_cents: 68_000,
  charges_amount_cents: 5_500, deposit_amount_cents: 68_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_lucas_1, tenant: pierre_leroy, share: 100.0)
pay_monthly(lease_lucas_1, months: [JAN, FEB, MAR, APR])

lease_lucas_2 = Lease.create!(property: prop_lucas_2, status: 'active',
  lease_type: 'residential_furnished', start_date: Date.new(2025, 9, 1),
  end_date: Date.new(2026, 8, 31), rent_amount_cents: 52_000,
  charges_amount_cents: 4_000, deposit_amount_cents: 52_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_lucas_2, tenant: emma_petit, share: 100.0)
pay_monthly(lease_lucas_2, months: [JAN, FEB, MAR, APR])

# =============================================================================
# 4. Isabelle Faure — Locataire en impayé depuis 3 mois, CAF paie seule
# Signaux : unpaid_balance, caf_only
# =============================================================================
isabelle = Landlord.create!(
  nature: 'physical', first_name: 'Isabelle', last_name: 'Faure',
  email: 'i.faure@orange.fr', phone: '06 77 88 99 00',
  payment_day: 10, management_fee_rate: nil
)
prop_isabelle = Property.create!(landlord: isabelle, address: '5 place Bellecour',
  unit_number: 'Apt 7A', city: 'Lyon', zip_code: '69002', nature: 'apartment',
  area_sqm: 80.0, rooms_count: 3)
karim = Tenant.create!(first_name: 'Karim', last_name: 'Benali',
  email: 'k.benali@gmail.com', phone: '06 88 77 66 55',
  caf_amount_cents: 25_000)
lease_isabelle = Lease.create!(property: prop_isabelle, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2023, 10, 1),
  end_date: Date.new(2026, 9, 30), rent_amount_cents: 105_000,
  charges_amount_cents: 10_000, deposit_amount_cents: 105_000,
  balance_cents: -230_000)
LeaseTenant.create!(lease: lease_isabelle, tenant: karim, share: 100.0)
# Janvier : CAF + petit bout locataire
Payment.create!(lease: lease_isabelle, date: Date.new(2026, 1, 5),
  amount_cents: 25_000, payment_type: 'rent', payment_method: 'caf')
Payment.create!(lease: lease_isabelle, date: Date.new(2026, 1, 15),
  amount_cents: 40_000, payment_type: 'rent', payment_method: 'bank_transfer')
# Février, Mars, Avril : seule la CAF paie (Karim n'a pas complété)
Payment.create!(lease: lease_isabelle, date: Date.new(2026, 2, 5),
  amount_cents: 25_000, payment_type: 'rent', payment_method: 'caf')
Payment.create!(lease: lease_isabelle, date: Date.new(2026, 3, 5),
  amount_cents: 25_000, payment_type: 'rent', payment_method: 'caf')
Payment.create!(lease: lease_isabelle, date: Date.new(2026, 4, 5),
  amount_cents: 25_000, payment_type: 'rent', payment_method: 'caf')

# =============================================================================
# 5. Pierre Garnier — Bail commercial + grosse facture travaux en attente
# Signaux : commercial_lease, heavy_invoice
# =============================================================================
garnier = Landlord.create!(
  nature: 'physical', first_name: 'Pierre', last_name: 'Garnier',
  email: 'p.garnier@wanadoo.fr', phone: '06 11 00 99 88',
  payment_day: nil, management_fee_rate: 5.0
)
prop_garnier = Property.create!(landlord: garnier, address: '22 rue de la République',
  unit_number: nil, city: 'Lyon', zip_code: '69002', nature: 'commercial',
  area_sqm: 200.0, rooms_count: nil)
restaurant = Tenant.create!(first_name: 'Antoine', last_name: 'Dubois',
  email: 'contact@le-comptoir.fr', phone: '04 78 22 33 44')
lease_garnier = Lease.create!(property: prop_garnier, status: 'active',
  lease_type: 'commercial', start_date: Date.new(2020, 4, 1),
  end_date: Date.new(2029, 3, 31), rent_amount_cents: 220_000,
  charges_amount_cents: 35_000, deposit_amount_cents: 440_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_garnier, tenant: restaurant, share: 100.0)
pay_monthly(lease_garnier, months: [JAN, FEB, MAR, APR])

Invoice.create!(landlord: garnier, property: prop_garnier,
  supplier_name: 'Artisan Duval SARL',
  description: 'Réfection complète de la toiture — urgence infiltrations',
  amount_cents: 850_000, status: 'pending', due_date: Date.new(2026, 4, 15))
Invoice.create!(landlord: garnier, property: prop_garnier,
  supplier_name: 'Plomberie Express',
  description: 'Remplacement robinetterie sanitaires',
  amount_cents: 34_500, status: 'paid', due_date: Date.new(2026, 2, 1),
  paid_date: Date.new(2026, 2, 5))

# =============================================================================
# 6. SCI Marais Invest — Propriétaire débiteur (factures > loyers)
# Signaux : debtor_carryover, multi_property, heavy_invoice
# =============================================================================
marais = Landlord.create!(
  nature: 'company', first_name: 'Anne-Sophie', last_name: 'Girard',
  company_name: 'SCI Marais Invest', siret: '901 234 567 00015',
  email: 'as.girard@maraisinvest.fr', phone: '06 33 22 11 00',
  payment_day: 20, management_fee_rate: 7.0
)
prop_marais_1 = Property.create!(landlord: marais, address: '15 rue du Temple',
  unit_number: 'Apt 2C', city: 'Paris', zip_code: '75004', nature: 'apartment',
  area_sqm: 40.0, rooms_count: 2)
prop_marais_2 = Property.create!(landlord: marais, address: '15 rue du Temple',
  unit_number: 'Apt 4A', city: 'Paris', zip_code: '75004', nature: 'apartment',
  area_sqm: 55.0, rooms_count: 3)
amina = Tenant.create!(first_name: 'Amina', last_name: 'Diallo',
  email: 'amina.diallo@gmail.com', phone: '06 44 33 22 11')
thomas_l = Tenant.create!(first_name: 'Thomas', last_name: 'Lefebvre',
  email: 'thomas.lefebvre@hotmail.fr', phone: '06 55 66 77 88')
lease_marais_1 = Lease.create!(property: prop_marais_1, status: 'active',
  lease_type: 'residential_furnished', start_date: Date.new(2025, 3, 1),
  end_date: Date.new(2027, 2, 28), rent_amount_cents: 98_000,
  charges_amount_cents: 8_500, deposit_amount_cents: 98_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_marais_1, tenant: amina, share: 100.0)
pay_monthly(lease_marais_1, months: [JAN, FEB, MAR, APR], method: 'sepa_debit')

lease_marais_2 = Lease.create!(property: prop_marais_2, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2024, 7, 1),
  end_date: Date.new(2027, 6, 30), rent_amount_cents: 115_000,
  charges_amount_cents: 9_500, deposit_amount_cents: 115_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_marais_2, tenant: thomas_l, share: 100.0)
pay_monthly(lease_marais_2, months: [JAN, FEB, MAR, APR])

Invoice.create!(landlord: marais, property: nil,
  supplier_name: 'BTP Rénovation Paris',
  description: 'Ravalement de façade — immeuble 15 rue du Temple',
  amount_cents: 1_200_000, status: 'paid', due_date: Date.new(2026, 1, 15),
  paid_date: Date.new(2026, 1, 20))
Invoice.create!(landlord: marais, property: prop_marais_1,
  supplier_name: 'Elec-Pro Services',
  description: 'Mise aux normes électriques — Apt 2C',
  amount_cents: 680_000, status: 'pending', due_date: Date.new(2026, 4, 30))
Invoice.create!(landlord: marais, property: nil,
  supplier_name: 'Chauffage Central SARL',
  description: 'Remplacement chaudière collective',
  amount_cents: 450_000, status: 'pending', due_date: Date.new(2026, 5, 15))

# =============================================================================
# 7. Jean-Marc Leroy — Bail qui expire dans 15 jours + DG à restituer
# Signaux : expiring_lease, deposit_to_refund
# =============================================================================
jm_leroy = Landlord.create!(
  nature: 'physical', first_name: 'Jean-Marc', last_name: 'Leroy',
  email: 'jm.leroy@gmail.com', phone: '06 22 11 00 99',
  payment_day: nil, management_fee_rate: nil
)
prop_leroy = Property.create!(landlord: jm_leroy, address: '3 rue Mercière',
  unit_number: 'Apt 5', city: 'Lyon', zip_code: '69002', nature: 'apartment',
  area_sqm: 65.0, rooms_count: 3)
fatou = Tenant.create!(first_name: 'Fatou', last_name: 'Sylla',
  email: 'fatou.sylla@yahoo.fr', phone: '06 99 88 77 66')
lease_leroy = Lease.create!(property: prop_leroy, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2023, 4, 25),
  end_date: Date.new(2026, 4, 24), rent_amount_cents: 72_000,
  charges_amount_cents: 6_000, deposit_amount_cents: 72_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_leroy, tenant: fatou, share: 100.0)
pay_monthly(lease_leroy, months: [JAN, FEB, MAR, APR], method: 'sepa_debit')

Invoice.create!(landlord: jm_leroy, property: prop_leroy,
  supplier_name: 'Plomberie Leroy',
  description: 'Réparation fuite salle de bain',
  amount_cents: 28_500, status: 'pending', due_date: Date.new(2026, 4, 20))

# =============================================================================
# 8. Catherine Blanc — Versement désactivé + co-location
# Signaux : payment_disabled (bloquant absolu)
# =============================================================================
catherine = Landlord.create!(
  nature: 'physical', first_name: 'Catherine', last_name: 'Blanc',
  email: 'c.blanc@me.com', phone: '06 00 11 22 33',
  payment_day: 5, management_fee_rate: 6.0,
  payment_enabled: false,
  payment_disabled_reason: "Travaux en cours — consigner les fonds jusqu'au terme des travaux"
)
prop_blanc = Property.create!(landlord: catherine, address: '7 quai de Saône',
  unit_number: 'Apt 8', city: 'Lyon', zip_code: '69001', nature: 'apartment',
  area_sqm: 90.0, rooms_count: 4)
julien = Tenant.create!(first_name: 'Julien', last_name: 'Roux',
  email: 'julien.roux@gmail.com', phone: '06 12 12 12 12')
clara = Tenant.create!(first_name: 'Clara', last_name: 'Morel',
  email: 'clara.morel@gmail.com', phone: '06 34 34 34 34')
lease_blanc = Lease.create!(property: prop_blanc, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2025, 1, 1),
  end_date: Date.new(2028, 12, 31), rent_amount_cents: 110_000,
  charges_amount_cents: 12_000, deposit_amount_cents: 110_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_blanc, tenant: julien, share: 50.0)
LeaseTenant.create!(lease: lease_blanc, tenant: clara, share: 50.0)
[JAN, FEB, MAR, APR].each do |month|
  Payment.create!(lease: lease_blanc, date: month + 2.days, amount_cents: 61_000,
    payment_type: 'rent', payment_method: 'bank_transfer')
  Payment.create!(lease: lease_blanc, date: month + 3.days, amount_cents: 61_000,
    payment_type: 'rent', payment_method: 'bank_transfer')
end
Invoice.create!(landlord: catherine, property: prop_blanc,
  supplier_name: 'Rénovation Saône SARL',
  description: 'Rénovation salle de bain + cuisine — en cours',
  amount_cents: 1_450_000, status: 'pending', due_date: Date.new(2026, 6, 1))

# =============================================================================
# 9. Laurent Petit — Multi-échéances (piège faux impayé)
# Locataire a payé 2 mois d'un coup en mars. Avril = 0 encaissé mais OK.
# Signaux : rent_partial (à tort si mal lu), multi_installment
# Risque : bloquer à tort en pensant que le locataire n'a pas payé mars
# =============================================================================
laurent = Landlord.create!(
  nature: 'physical', first_name: 'Laurent', last_name: 'Petit',
  email: 'l.petit@free.fr', phone: '06 12 34 98 76',
  payment_day: nil, management_fee_rate: 7.0
)
prop_laurent = Property.create!(landlord: laurent, address: '18 rue Saint-Jean',
  unit_number: 'Apt 2', city: 'Lyon', zip_code: '69005', nature: 'apartment',
  area_sqm: 50.0, rooms_count: 2)
valentin = Tenant.create!(first_name: 'Valentin', last_name: 'Roche',
  email: 'v.roche@gmail.com', phone: '06 32 32 32 32')
lease_laurent = Lease.create!(property: prop_laurent, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2024, 4, 1),
  end_date: Date.new(2027, 3, 31), rent_amount_cents: 78_000,
  charges_amount_cents: 7_000, deposit_amount_cents: 78_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_laurent, tenant: valentin, share: 100.0)
# Janvier, Février : normal
Payment.create!(lease: lease_laurent, date: Date.new(2026, 1, 6), amount_cents: 85_000,
  payment_type: 'rent', payment_method: 'bank_transfer')
Payment.create!(lease: lease_laurent, date: Date.new(2026, 2, 5), amount_cents: 85_000,
  payment_type: 'rent', payment_method: 'bank_transfer')
# Mars : paie 2 mois d'un coup (mars + avril anticipé)
Payment.create!(lease: lease_laurent, date: Date.new(2026, 3, 4), amount_cents: 170_000,
  payment_type: 'rent', payment_method: 'bank_transfer')
# Avril : rien (normal — déjà payé en mars)

# =============================================================================
# 10. Bruno Moreau — Paiement partiel avril (60%)
# Signaux : rent_partial
# =============================================================================
bruno = Landlord.create!(
  nature: 'physical', first_name: 'Bruno', last_name: 'Moreau',
  email: 'b.moreau@sfr.fr', phone: '06 44 55 66 77',
  payment_day: nil, management_fee_rate: nil
)
prop_bruno = Property.create!(landlord: bruno, address: '9 rue Pasteur',
  unit_number: 'Apt 4', city: 'Villeurbanne', zip_code: '69100', nature: 'apartment',
  area_sqm: 45.0, rooms_count: 2)
celine = Tenant.create!(first_name: 'Céline', last_name: 'Marchand',
  email: 'c.marchand@gmail.com', phone: '06 77 77 77 77')
lease_bruno = Lease.create!(property: prop_bruno, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2025, 6, 1),
  end_date: Date.new(2028, 5, 31), rent_amount_cents: 62_000,
  charges_amount_cents: 5_000, deposit_amount_cents: 62_000, balance_cents: -26_800)
LeaseTenant.create!(lease: lease_bruno, tenant: celine, share: 100.0)
pay_monthly(lease_bruno, months: [JAN, FEB, MAR])
# Avril : 60% seulement
Payment.create!(lease: lease_bruno, date: Date.new(2026, 4, 8),
  amount_cents: 40_200, payment_type: 'rent', payment_method: 'bank_transfer')

# =============================================================================
# 11. Maxime Berger — Rejet SEPA sur le loyer d'avril
# Modélisation : paiement SEPA positif + contrepartie négative, les deux dans avril.
# La somme des paiements SEPA du mois = 0, l'encaissement est en réalité nul.
# =============================================================================
maxime = Landlord.create!(
  nature: 'physical', first_name: 'Maxime', last_name: 'Berger',
  email: 'm.berger@yahoo.fr', phone: '06 88 99 00 11',
  payment_day: nil, management_fee_rate: 7.5
)
prop_maxime = Property.create!(landlord: maxime, address: '42 cours Lafayette',
  unit_number: 'Apt 6', city: 'Lyon', zip_code: '69003', nature: 'apartment',
  area_sqm: 58.0, rooms_count: 2)
nadia = Tenant.create!(first_name: 'Nadia', last_name: 'Haddad',
  email: 'n.haddad@gmail.com', phone: '06 88 99 11 22')
lease_maxime = Lease.create!(property: prop_maxime, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2024, 10, 1),
  end_date: Date.new(2027, 9, 30), rent_amount_cents: 70_000,
  charges_amount_cents: 6_500, deposit_amount_cents: 70_000, balance_cents: -76_500)
LeaseTenant.create!(lease: lease_maxime, tenant: nadia, share: 100.0)
pay_monthly(lease_maxime, months: [JAN, FEB, MAR], method: 'sepa_debit')
# Avril : SEPA prélevé le 5, rejet le 10 (la contrepartie annule l'encaissement)
Payment.create!(lease: lease_maxime, date: Date.new(2026, 4, 5),
  amount_cents: 76_500, payment_type: 'rent', payment_method: 'sepa_debit')
Payment.create!(lease: lease_maxime, date: Date.new(2026, 4, 10),
  amount_cents: -76_500, payment_type: 'rent', payment_method: 'sepa_debit')

# =============================================================================
# 12. Étienne Roy — Régularisation de charges à rembourser au locataire
# Locataire a trop versé en provisions de charges sur 2025 (320 EUR à rembourser).
# Signal : regularization_pending
# =============================================================================
etienne = Landlord.create!(
  nature: 'physical', first_name: 'Étienne', last_name: 'Roy',
  email: 'e.roy@orange.fr', phone: '06 11 22 33 99',
  payment_day: nil, management_fee_rate: 6.5
)
prop_etienne = Property.create!(landlord: etienne, address: '33 avenue Jean Jaurès',
  unit_number: 'Apt 11', city: 'Lyon', zip_code: '69007', nature: 'apartment',
  area_sqm: 62.0, rooms_count: 3)
alain = Tenant.create!(first_name: 'Alain', last_name: 'Gauthier',
  email: 'a.gauthier@gmail.com', phone: '06 55 66 77 99')
lease_etienne = Lease.create!(property: prop_etienne, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2022, 9, 1),
  end_date: Date.new(2028, 8, 31), rent_amount_cents: 68_000,
  charges_amount_cents: 7_500, deposit_amount_cents: 68_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_etienne, tenant: alain, share: 100.0)
pay_monthly(lease_etienne, months: [JAN, FEB, MAR, APR])
# Régularisation : locataire a trop payé en provisions 2025 → remboursement de 32 000 centimes
Payment.create!(lease: lease_etienne, date: Date.new(2026, 4, 12),
  amount_cents: -32_000, payment_type: 'regularization', payment_method: 'bank_transfer')

# =============================================================================
# 13. Sylvie Caron — Bail terminé le 10 avril, DG à restituer ce mois-ci
# Signaux : deposit_to_refund, new_vacancy
# =============================================================================
sylvie = Landlord.create!(
  nature: 'physical', first_name: 'Sylvie', last_name: 'Caron',
  email: 's.caron@laposte.net', phone: '06 77 88 22 33'
)
prop_sylvie = Property.create!(landlord: sylvie, address: '6 rue Victor Hugo',
  unit_number: 'Apt 1', city: 'Villeurbanne', zip_code: '69100', nature: 'apartment',
  area_sqm: 48.0, rooms_count: 2)
# Ancien bail terminé le 10 avril (tout récent)
sortant = Tenant.create!(first_name: 'Hélène', last_name: 'Marty',
  email: 'h.marty@free.fr', phone: '06 44 99 22 88')
lease_sylvie_old = Lease.create!(property: prop_sylvie, status: 'terminated',
  lease_type: 'residential_unfurnished', start_date: Date.new(2022, 4, 1),
  end_date: Date.new(2026, 4, 10), rent_amount_cents: 60_000,
  charges_amount_cents: 5_000, deposit_amount_cents: 60_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_sylvie_old, tenant: sortant, share: 100.0)
pay_monthly(lease_sylvie_old, months: [JAN, FEB, MAR])
# Paiement avril proratisé (10 jours) avant la fin du bail
Payment.create!(lease: lease_sylvie_old, date: Date.new(2026, 4, 3),
  amount_cents: 21_670, payment_type: 'rent', payment_method: 'bank_transfer')
# DG à restituer : enregistré comme un "paiement" de type deposit négatif (sortie de trésorerie)
# Note : la convention seeds est que le DG restitué apparaîtra en déduction côté PayoutRun

# =============================================================================
# 14. SCI Horizon — Nouveau mandat, démarre le 1er avril, premier versement
# Signal : new_landlord (mandat récent < 30 jours)
# =============================================================================
horizon = Landlord.create!(
  nature: 'company', first_name: 'Pascal', last_name: 'Dubois',
  company_name: 'SCI Horizon', siret: '123 456 789 00023',
  email: 'p.dubois@sci-horizon.fr', phone: '06 55 22 33 44',
  payment_day: 10, management_fee_rate: 7.0,
  created_at: Date.new(2026, 3, 28)
)
prop_horizon = Property.create!(landlord: horizon, address: '11 rue Garibaldi',
  unit_number: 'Apt 3', city: 'Lyon', zip_code: '69006', nature: 'apartment',
  area_sqm: 72.0, rooms_count: 3)
mathieu = Tenant.create!(first_name: 'Mathieu', last_name: 'Blanchard',
  email: 'm.blanchard@gmail.com', phone: '06 99 11 22 33')
lease_horizon = Lease.create!(property: prop_horizon, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2024, 9, 1),
  end_date: Date.new(2027, 8, 31), rent_amount_cents: 82_000,
  charges_amount_cents: 7_500, deposit_amount_cents: 82_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_horizon, tenant: mathieu, share: 100.0)
# Mandat démarre le 28 mars : premier versement à faire en avril
Payment.create!(lease: lease_horizon, date: Date.new(2026, 4, 6),
  amount_cents: 89_500, payment_type: 'rent', payment_method: 'bank_transfer')

# =============================================================================
# 15. Jacques Perrin — Déficit reporté de mars (propriétaire débiteur résorbé)
# Mars : grosse facture payée en plus du loyer courant → solde négatif reporté.
# En avril, le loyer doit résorber le déficit avant tout versement.
# Signal : debtor_carryover
# =============================================================================
jacques = Landlord.create!(
  nature: 'physical', first_name: 'Jacques', last_name: 'Perrin',
  email: 'j.perrin@wanadoo.fr', phone: '06 12 00 11 22',
  payment_day: nil, management_fee_rate: 7.0
)
prop_jacques = Property.create!(landlord: jacques, address: '24 rue Royale',
  unit_number: 'Apt 9', city: 'Lyon', zip_code: '69001', nature: 'apartment',
  area_sqm: 55.0, rooms_count: 2)
oriane = Tenant.create!(first_name: 'Oriane', last_name: 'Dupuis',
  email: 'o.dupuis@gmail.com', phone: '06 11 99 88 77')
lease_jacques = Lease.create!(property: prop_jacques, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2023, 5, 1),
  end_date: Date.new(2026, 4, 30), rent_amount_cents: 64_000,
  charges_amount_cents: 5_500, deposit_amount_cents: 64_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_jacques, tenant: oriane, share: 100.0)
pay_monthly(lease_jacques, months: [JAN, FEB, MAR, APR])
# Grosse facture de mars déjà payée → carryover négatif à résorber en avril
Invoice.create!(landlord: jacques, property: prop_jacques,
  supplier_name: 'Toitures Beaujolais',
  description: 'Reprise d\'étanchéité toiture',
  amount_cents: 115_000, status: 'paid', due_date: Date.new(2026, 3, 10),
  paid_date: Date.new(2026, 3, 18))

# =============================================================================
# 16. Aurélie Lemoine — Bail vient de démarrer (entrée locataire début avril)
# Premier loyer + DG encaissés → encaissement plus gros que d'habitude.
# Signaux : new_lease, unusual_inflow
# =============================================================================
aurelie = Landlord.create!(
  nature: 'physical', first_name: 'Aurélie', last_name: 'Lemoine',
  email: 'a.lemoine@gmail.com', phone: '06 77 00 44 55',
  payment_day: nil, management_fee_rate: 8.0
)
prop_aurelie = Property.create!(landlord: aurelie, address: '14 rue des Capucins',
  unit_number: 'Apt 2', city: 'Lyon', zip_code: '69001', nature: 'apartment',
  area_sqm: 40.0, rooms_count: 2)
leo = Tenant.create!(first_name: 'Léo', last_name: 'Fabre',
  email: 'l.fabre@gmail.com', phone: '06 22 88 11 44')
lease_aurelie = Lease.create!(property: prop_aurelie, status: 'active',
  lease_type: 'residential_furnished', start_date: Date.new(2026, 4, 5),
  end_date: Date.new(2027, 4, 4), rent_amount_cents: 68_000,
  charges_amount_cents: 5_000, deposit_amount_cents: 136_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_aurelie, tenant: leo, share: 100.0)
# Entrée : DG + prorata d'avril (26 jours / 30)
Payment.create!(lease: lease_aurelie, date: Date.new(2026, 4, 5),
  amount_cents: 136_000, payment_type: 'deposit', payment_method: 'bank_transfer')
Payment.create!(lease: lease_aurelie, date: Date.new(2026, 4, 5),
  amount_cents: 63_270, payment_type: 'rent', payment_method: 'bank_transfer')

# =============================================================================
# 17. Vincent Aubert — Bail upcoming, DG déjà encaissé en avril
# Bail signé démarre le 1er juin. DG arrivé en avril → encaissement sans loyer récurrent.
# Signal : upcoming_lease, deposit_received
# =============================================================================
vincent = Landlord.create!(
  nature: 'physical', first_name: 'Vincent', last_name: 'Aubert',
  email: 'v.aubert@free.fr', phone: '06 34 11 22 99',
  payment_day: nil, management_fee_rate: nil
)
prop_vincent = Property.create!(landlord: vincent, address: '28 rue de Bonnel',
  unit_number: 'Apt 5', city: 'Lyon', zip_code: '69003', nature: 'apartment',
  area_sqm: 52.0, rooms_count: 2)
lea_nguyen = Tenant.create!(first_name: 'Léa', last_name: 'Nguyen',
  email: 'l.nguyen@gmail.com', phone: '06 99 88 00 11')
lease_vincent = Lease.create!(property: prop_vincent, status: 'upcoming',
  lease_type: 'residential_unfurnished', start_date: Date.new(2026, 6, 1),
  end_date: Date.new(2029, 5, 31), rent_amount_cents: 72_000,
  charges_amount_cents: 6_000, deposit_amount_cents: 72_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_vincent, tenant: lea_nguyen, share: 100.0)
Payment.create!(lease: lease_vincent, date: Date.new(2026, 4, 12),
  amount_cents: 72_000, payment_type: 'deposit', payment_method: 'bank_transfer')

# =============================================================================
# 18. Nadège Thibault — Prime GLI active (déduite mensuellement)
# Signal : gli_fee (2.5% du loyer annuel, prélevé mensuellement)
# Convention seeds : encodé comme une facture mensuelle récurrente "Prime GLI".
# =============================================================================
nadege = Landlord.create!(
  nature: 'physical', first_name: 'Nadège', last_name: 'Thibault',
  email: 'n.thibault@orange.fr', phone: '06 00 99 88 77',
  payment_day: nil, management_fee_rate: 7.0
)
prop_nadege = Property.create!(landlord: nadege, address: '19 quai Claude Bernard',
  unit_number: 'Apt 7', city: 'Lyon', zip_code: '69007', nature: 'apartment',
  area_sqm: 66.0, rooms_count: 3)
samir = Tenant.create!(first_name: 'Samir', last_name: 'Belkacem',
  email: 's.belkacem@gmail.com', phone: '06 55 44 88 99')
lease_nadege = Lease.create!(property: prop_nadege, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2024, 5, 1),
  end_date: Date.new(2027, 4, 30), rent_amount_cents: 88_000,
  charges_amount_cents: 7_000, deposit_amount_cents: 88_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_nadege, tenant: samir, share: 100.0)
pay_monthly(lease_nadege, months: [JAN, FEB, MAR, APR], method: 'sepa_debit')
Invoice.create!(landlord: nadege, property: prop_nadege,
  supplier_name: 'GLI — Assurance Loyers Impayés',
  description: 'Prime GLI mars 2026 (2.5% annuel)',
  amount_cents: 2_200, status: 'pending', due_date: Date.new(2026, 4, 10))

# =============================================================================
# 19. SCI Tournesol — Multi-biens, tout OK (test de scale visuel)
# 4 biens, 4 baux actifs, aucune anomalie.
# Signaux : multi_property seul (aucun risque)
# =============================================================================
tournesol = Landlord.create!(
  nature: 'company', first_name: 'Hélène', last_name: 'Roux',
  company_name: 'SCI Tournesol', siret: '555 666 777 00012',
  email: 'contact@sci-tournesol.fr', phone: '06 78 78 78 78',
  payment_day: 12, management_fee_rate: 6.0
)
4.times do |i|
  prop = Property.create!(landlord: tournesol, address: "#{20 + i} rue des Charmilles",
    unit_number: "Apt #{i + 1}", city: 'Lyon', zip_code: '69004', nature: 'apartment',
    area_sqm: [45.0, 55.0, 65.0, 72.0][i], rooms_count: [2, 2, 3, 3][i])
  tenant = Tenant.create!(first_name: "Locataire#{i + 1}", last_name: 'Tournesol',
    email: "loc#{i + 1}@tournesol.fr", phone: "06 77 77 77 0#{i}")
  lease = Lease.create!(property: prop, status: 'active',
    lease_type: 'residential_unfurnished',
    start_date: Date.new(2024 - (i % 2), 6, 1), end_date: Date.new(2027 + (i % 2), 5, 31),
    rent_amount_cents: [62_000, 70_000, 82_000, 92_000][i],
    charges_amount_cents: [5_000, 6_000, 7_500, 8_500][i],
    deposit_amount_cents: [62_000, 70_000, 82_000, 92_000][i], balance_cents: 0)
  LeaseTenant.create!(lease: lease, tenant: tenant, share: 100.0)
  pay_monthly(lease, months: [JAN, FEB, MAR, APR], method: i.even? ? 'sepa_debit' : 'bank_transfer')
end

# =============================================================================
# 20. SCI Atlas — Mix gros commercial + 2 résidentiels
# Signal : multi_property, commercial_lease
# =============================================================================
atlas = Landlord.create!(
  nature: 'company', first_name: 'Marthe', last_name: 'Valois',
  company_name: 'SCI Atlas', siret: '789 012 345 00034',
  email: 'contact@sci-atlas.fr', phone: '06 15 15 15 15',
  payment_day: 18, management_fee_rate: 6.5
)
prop_atlas_1 = Property.create!(landlord: atlas, address: '50 rue Président Édouard Herriot',
  unit_number: nil, city: 'Lyon', zip_code: '69002', nature: 'commercial',
  area_sqm: 180.0, rooms_count: nil)
prop_atlas_2 = Property.create!(landlord: atlas, address: '27 rue Duquesne',
  unit_number: 'Apt 3', city: 'Lyon', zip_code: '69006', nature: 'apartment',
  area_sqm: 78.0, rooms_count: 4)
prop_atlas_3 = Property.create!(landlord: atlas, address: '27 rue Duquesne',
  unit_number: 'Apt 5', city: 'Lyon', zip_code: '69006', nature: 'apartment',
  area_sqm: 62.0, rooms_count: 3)
librairie_tenant = Tenant.create!(first_name: 'Florence', last_name: 'Levasseur',
  email: 'contact@librairie-atlas.fr', phone: '04 78 55 66 77')
locres_1 = Tenant.create!(first_name: 'Hugo', last_name: 'Martel',
  email: 'h.martel@gmail.com', phone: '06 21 21 21 21')
locres_2 = Tenant.create!(first_name: 'Camille', last_name: 'Garnier',
  email: 'c.garnier@gmail.com', phone: '06 32 32 32 32')
lease_atlas_1 = Lease.create!(property: prop_atlas_1, status: 'active',
  lease_type: 'commercial', start_date: Date.new(2021, 6, 1),
  end_date: Date.new(2030, 5, 31), rent_amount_cents: 210_000,
  charges_amount_cents: 28_000, deposit_amount_cents: 420_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_atlas_1, tenant: librairie_tenant, share: 100.0)
pay_monthly(lease_atlas_1, months: [JAN, FEB, MAR, APR])
lease_atlas_2 = Lease.create!(property: prop_atlas_2, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2023, 10, 1),
  end_date: Date.new(2026, 9, 30), rent_amount_cents: 95_000,
  charges_amount_cents: 8_000, deposit_amount_cents: 95_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_atlas_2, tenant: locres_1, share: 100.0)
pay_monthly(lease_atlas_2, months: [JAN, FEB, MAR, APR])
lease_atlas_3 = Lease.create!(property: prop_atlas_3, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2025, 1, 1),
  end_date: Date.new(2028, 12, 31), rent_amount_cents: 78_000,
  charges_amount_cents: 6_500, deposit_amount_cents: 78_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_atlas_3, tenant: locres_2, share: 100.0)
pay_monthly(lease_atlas_3, months: [JAN, FEB, MAR, APR], method: 'sepa_debit')

# =============================================================================
# 21. Xavier Dumas — Cas simple supplémentaire (volume de run)
# =============================================================================
xavier = Landlord.create!(
  nature: 'physical', first_name: 'Xavier', last_name: 'Dumas',
  email: 'x.dumas@gmail.com', phone: '06 47 47 47 47',
  payment_day: nil, management_fee_rate: nil
)
prop_xavier = Property.create!(landlord: xavier, address: '8 rue des Remparts',
  unit_number: 'Apt 4', city: 'Lyon', zip_code: '69002', nature: 'apartment',
  area_sqm: 52.0, rooms_count: 2)
manon = Tenant.create!(first_name: 'Manon', last_name: 'Rivière',
  email: 'm.riviere@gmail.com', phone: '06 19 19 19 19')
lease_xavier = Lease.create!(property: prop_xavier, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2024, 7, 1),
  end_date: Date.new(2027, 6, 30), rent_amount_cents: 74_000,
  charges_amount_cents: 6_000, deposit_amount_cents: 74_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_xavier, tenant: manon, share: 100.0)
pay_monthly(lease_xavier, months: [JAN, FEB, MAR, APR], method: 'sepa_debit')

# =============================================================================
# 22. Clémence Richard — Cas simple supplémentaire
# =============================================================================
clemence = Landlord.create!(
  nature: 'physical', first_name: 'Clémence', last_name: 'Richard',
  email: 'c.richard@outlook.fr', phone: '06 52 52 52 52',
  payment_day: nil, management_fee_rate: 7.5
)
prop_clemence = Property.create!(landlord: clemence, address: '3 rue de la Charité',
  unit_number: 'Apt 6', city: 'Lyon', zip_code: '69002', nature: 'apartment',
  area_sqm: 48.0, rooms_count: 2)
damien = Tenant.create!(first_name: 'Damien', last_name: 'Chevalier',
  email: 'd.chevalier@gmail.com', phone: '06 28 28 28 28')
lease_clemence = Lease.create!(property: prop_clemence, status: 'active',
  lease_type: 'residential_furnished', start_date: Date.new(2025, 10, 1),
  end_date: Date.new(2026, 9, 30), rent_amount_cents: 66_000,
  charges_amount_cents: 5_500, deposit_amount_cents: 132_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_clemence, tenant: damien, share: 100.0)
pay_monthly(lease_clemence, months: [JAN, FEB, MAR, APR])

# =============================================================================
# 23. Rachid Ziani — Cas simple supplémentaire
# =============================================================================
rachid = Landlord.create!(
  nature: 'physical', first_name: 'Rachid', last_name: 'Ziani',
  email: 'r.ziani@gmail.com', phone: '06 63 63 63 63',
  payment_day: nil, management_fee_rate: nil
)
prop_rachid = Property.create!(landlord: rachid, address: '56 rue Vendôme',
  unit_number: 'Apt 2', city: 'Lyon', zip_code: '69006', nature: 'apartment',
  area_sqm: 61.0, rooms_count: 3)
sarah = Tenant.create!(first_name: 'Sarah', last_name: 'Boucher',
  email: 's.boucher@gmail.com', phone: '06 71 71 71 71')
lease_rachid = Lease.create!(property: prop_rachid, status: 'active',
  lease_type: 'residential_unfurnished', start_date: Date.new(2023, 3, 1),
  end_date: Date.new(2026, 2, 28), rent_amount_cents: 79_000,
  charges_amount_cents: 6_500, deposit_amount_cents: 79_000, balance_cents: 0)
LeaseTenant.create!(lease: lease_rachid, tenant: sarah, share: 100.0)
pay_monthly(lease_rachid, months: [JAN, FEB, MAR, APR], method: 'sepa_debit')
# Note : le bail est renouvelé tacitement (end_date dépassé mais status active)

# =============================================================================
# Volume — 80 propriétaires "normaux" supplémentaires
# Tous en situation standard : 1 bien, 1 bail actif, paiement régulier.
# Objectif : donner à la run une volumétrie réaliste (~100 propriétaires).
# Aucun signal de risque — le candidat doit pouvoir les traiter vite.
# =============================================================================

FIRST_NAMES_M = %w[Antoine Benoît Cédric David Éric Fabrice Gilles Hervé Ismaël
                   Julien Kevin Laurent Mickaël Nicolas Olivier Paul Quentin
                   Rémi Stéphane Thierry Yann Florian Baptiste Loïc Théo].freeze
FIRST_NAMES_F = %w[Agnès Brigitte Céline Delphine Émilie Florence Gabrielle
                   Hélène Ingrid Juliette Karine Laure Monique Nathalie Odile
                   Patricia Rachel Sandrine Virginie Zoé Léa Inès Pauline Chloé].freeze
LAST_NAMES = %w[Bernard Rousseau Laurent Moreau Simon Michel Dubois Martin
                Durand Lefebvre Leroy Roux Vincent Fournier Morel Girard André
                Mercier Blanc Guerin Boyer Garnier Chevalier Francois Legrand
                Gauthier Garcia Nicolas Perrin Morin Mathieu Clement Gautier
                Dumas Lopez Meunier Riviere Pierre Noel Brun].freeze
CITIES = [
  ['Lyon', '69001'], ['Lyon', '69002'], ['Lyon', '69003'], ['Lyon', '69004'],
  ['Lyon', '69005'], ['Lyon', '69006'], ['Lyon', '69007'], ['Lyon', '69008'],
  ['Villeurbanne', '69100'], ['Caluire-et-Cuire', '69300'],
  ['Paris', '75001'], ['Paris', '75003'], ['Paris', '75011'], ['Paris', '75015'],
  ['Bron', '69500'], ['Saint-Priest', '69800'], ['Oullins', '69600']
].freeze
STREETS = ['rue de la République', 'avenue Jean Jaurès', 'rue Victor Hugo',
           'rue Pasteur', 'avenue Foch', 'rue Garibaldi', 'cours Gambetta',
           'place de la Liberté', 'rue du Commerce', 'avenue Leclerc',
           'rue des Alliés', 'rue Molière', 'rue Voltaire', 'rue Diderot',
           'quai Perrache', 'rue Saint-Exupéry', 'avenue de Saxe', 'rue Servient'].freeze

srand(42) # reproductibilité des seeds de volume

def seed_normal_property(landlord, i)
  city, zip = CITIES.sample
  street = STREETS.sample
  rent = [48_000, 55_000, 62_000, 68_000, 72_000, 78_000, 85_000, 92_000, 105_000].sample
  charges = (rent * 0.08).to_i
  deposit = rent
  lease_type = ['residential_unfurnished', 'residential_unfurnished', 'residential_unfurnished',
                'residential_furnished'].sample
  start_date = Date.new([2022, 2023, 2023, 2024].sample, [1, 3, 6, 9].sample, [1, 15].sample)
  end_date = Date.new(2027 + rand(3), [4, 7, 10].sample, [14, 28].sample)
  area = [32.0, 38.0, 45.0, 52.0, 58.0, 65.0, 72.0, 80.0, 90.0].sample
  rooms = [1, 2, 2, 3, 3, 4].sample

  property = Property.create!(
    landlord: landlord,
    address: "#{rand(1..180)} #{street}",
    unit_number: rand(10) < 7 ? "Apt #{rand(1..15)}" : nil,
    city: city, zip_code: zip, nature: 'apartment',
    area_sqm: area, rooms_count: rooms
  )
  tenant = Tenant.create!(
    first_name: [FIRST_NAMES_M, FIRST_NAMES_F].sample[(i * 7) % 24],
    last_name: LAST_NAMES[(i * 5) % LAST_NAMES.size],
    email: "locataire#{i + 100}#{rand(1000)}@email.com",
    phone: "06 #{rand(10..99)} #{rand(10..99)} #{rand(10..99)} #{rand(10..99)}"
  )
  lease = Lease.create!(
    property: property, status: 'active', lease_type: lease_type,
    start_date: start_date, end_date: end_date,
    rent_amount_cents: rent, charges_amount_cents: charges,
    deposit_amount_cents: deposit, balance_cents: 0
  )
  LeaseTenant.create!(lease: lease, tenant: tenant, share: 100.0)
  method = ['bank_transfer', 'bank_transfer', 'sepa_debit'].sample
  pay_monthly(lease, months: [JAN, FEB, MAR, APR], method: method)
  property
end

80.times do |i|
  fn = [FIRST_NAMES_M, FIRST_NAMES_F].sample
  first = fn[i % fn.size]
  last = LAST_NAMES[(i * 3) % LAST_NAMES.size]
  email_handle = "#{first.downcase.tr('éèêàâîïôù', 'eeaaiiou')}.#{last.downcase}"

  landlord = Landlord.create!(
    nature: 'physical',
    first_name: first,
    last_name: last,
    email: "#{email_handle}#{i}@email.com",
    phone: "06 #{rand(10..99)} #{rand(10..99)} #{rand(10..99)} #{rand(10..99)}",
    payment_day: [nil, nil, nil, 5, 10, 15, 20].sample,
    management_fee_rate: [nil, nil, 6.0, 6.5, 7.0, 7.5, 8.0].sample
  )
  seed_normal_property(landlord, i)
end

# =============================================================================
# Volume — 10 propriétaires multi-mandats (2 biens, 2 mandats différents)
# Chaque mandat a son propre taux d'honoraires et jour de versement.
# Le candidat doit calculer les honoraires par mandat, pas globalement.
# =============================================================================
MULTI_MANDATE_CASES = [
  { first: 'Aline', last: 'Courtin', fees_a: 8.0, fees_b: 5.5, day_a: 10, day_b: 5 },
  { first: 'Bertrand', last: 'Mallet', fees_a: 7.5, fees_b: 6.0, day_a: nil, day_b: 15 },
  { first: 'Caroline', last: 'Dardel', fees_a: 7.0, fees_b: 5.0, day_a: 10, day_b: 20 },
  { first: 'Damien', last: 'Fiquet', fees_a: 8.0, fees_b: 6.5, day_a: 15, day_b: 15 },
  { first: 'Élodie', last: 'Ganier', fees_a: 7.5, fees_b: 6.0, day_a: nil, day_b: 10 },
  { first: 'François', last: 'Hilaire', fees_a: 8.0, fees_b: 7.0, day_a: 5, day_b: 20 },
  { first: 'Géraldine', last: 'Joubert', fees_a: 6.5, fees_b: 5.5, day_a: 10, day_b: 10 },
  { first: 'Henri', last: 'Kaminski', fees_a: 7.5, fees_b: 5.0, day_a: 15, day_b: 5 },
  { first: 'Isabelle', last: 'Lenoir', fees_a: 8.0, fees_b: 6.0, day_a: nil, day_b: 15 },
  { first: 'Jérôme', last: 'Marceau', fees_a: 7.0, fees_b: 5.5, day_a: 20, day_b: 10 }
].freeze

MULTI_MANDATE_CASES.each_with_index do |config, idx|
  landlord = Landlord.create!(
    nature: 'physical', first_name: config[:first], last_name: config[:last],
    email: "#{config[:first].downcase.tr('éèêàâîïôùç', 'eeaaiioua')}.#{config[:last].downcase}@email.com",
    phone: "06 #{rand(10..99)} #{rand(10..99)} #{rand(10..99)} #{rand(10..99)}",
    payment_day: nil,
    management_fee_rate: nil # lu via les mandats, pas via le landlord
  )

  mandate_a = Mandate.create!(
    landlord: landlord, reference: "MAND-#{2021 + (idx % 3)}-#{1000 + idx}A",
    management_fee_rate: config[:fees_a], payment_day: config[:day_a] || 10,
    signed_at: Date.new(2021 + (idx % 3), [1, 3, 6, 9].sample, 15)
  )
  mandate_b = Mandate.create!(
    landlord: landlord, reference: "MAND-#{2023 + (idx % 2)}-#{2000 + idx}B",
    management_fee_rate: config[:fees_b], payment_day: config[:day_b] || 10,
    signed_at: Date.new(2023 + (idx % 2), [1, 3, 6, 9].sample, 15)
  )

  prop_a = seed_normal_property(landlord, 200 + idx)
  prop_b = seed_normal_property(landlord, 300 + idx)
  prop_a.update!(mandate: mandate_a)
  prop_b.update!(mandate: mandate_b)
end

# =============================================================================
# Post-traitement
#  (1) mandat par défaut pour chaque propriétaire qui n'en a pas encore
#      — il reprend les conditions stockées sur le Landlord
#  (2) les propriétés sans mandat sont attachées au mandat par défaut
#  (3) normalisation des dates d'onboarding (SCI Horizon = mandat récent)
# =============================================================================

Landlord.includes(:mandates, :properties).find_each do |landlord|
  if landlord.mandates.empty?
    mandate = Mandate.create!(
      landlord: landlord,
      reference: "MAND-#{landlord.id.to_s.rjust(4, '0')}",
      management_fee_rate: landlord.management_fee_rate || 7.0,
      payment_day: landlord.payment_day || 10,
      signed_at: landlord.created_at.to_date
    )
    landlord.properties.where(mandate_id: nil).update_all(mandate_id: mandate.id)
  else
    # Propriétés qui seraient restées orphelines : on les attache au mandat le plus ancien
    default_mandate = landlord.mandates.order(:signed_at).first
    landlord.properties.where(mandate_id: nil).update_all(mandate_id: default_mandate.id)
  end
end

Landlord.where("company_name != 'SCI Horizon' OR company_name IS NULL").update_all(
  created_at: Date.new(2024, 1, 15),
  updated_at: Date.new(2024, 1, 15)
)

puts "==> Seeded: #{Landlord.count} propriétaires, #{Mandate.count} mandats, " \
     "#{Property.count} biens, #{Tenant.count} locataires, #{Lease.count} baux, " \
     "#{Payment.count} paiements, #{Invoice.count} factures"
