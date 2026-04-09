# Modèle de données — Application

L'application contient les modèles suivants. Les endpoints API retournent ces données en JSON.

---

## Landlord (Propriétaire)

| Champ | Type | Description |
|-------|------|-------------|
| id | integer | Identifiant unique |
| nature | string | `physical` (personne physique) ou `company` (SCI, SARL, etc.) |
| first_name | string | Prénom du représentant |
| last_name | string | Nom de famille |
| company_name | string | Raison sociale (si nature = company) |
| siret | string | Numéro SIRET (si nature = company) |
| email | string | Adresse email |
| phone | string | Téléphone |
| payment_day | integer (nullable) | Jour de versement préféré (null = défaut agence : le 10) |
| management_fee_rate | decimal (nullable) | Taux d'honoraires négocié (null = défaut agence : 7%) |
| payment_enabled | boolean | Versement actif ou désactivé |
| payment_disabled_reason | string (nullable) | Motif de désactivation du versement |

## Property (Bien / Lot)

| Champ | Type | Description |
|-------|------|-------------|
| id | integer | Identifiant unique |
| landlord_id | integer | Propriétaire du bien |
| address | string | Adresse |
| unit_number | string (nullable) | Numéro d'appartement ou de lot |
| city | string | Ville |
| zip_code | string | Code postal |
| nature | string | `apartment`, `house`, `commercial`, `parking` |
| area_sqm | decimal | Surface en m² |
| rooms_count | integer (nullable) | Nombre de pièces |

## Tenant (Locataire)

| Champ | Type | Description |
|-------|------|-------------|
| id | integer | Identifiant unique |
| first_name | string | Prénom |
| last_name | string | Nom |
| email | string | Adresse email |
| phone | string | Téléphone |
| caf_amount_cents | integer (nullable) | Montant CAF mensuel en centimes (si bénéficiaire) |

## Lease (Bail)

| Champ | Type | Description |
|-------|------|-------------|
| id | integer | Identifiant unique |
| property_id | integer | Bien concerné |
| status | string | `active`, `terminated`, `upcoming` |
| lease_type | string | `residential_unfurnished`, `residential_furnished`, `commercial` |
| start_date | date | Date de début |
| end_date | date (nullable) | Date de fin |
| rent_amount_cents | integer | Loyer mensuel en centimes |
| charges_amount_cents | integer | Charges mensuelles en centimes |
| deposit_amount_cents | integer | Dépôt de garantie en centimes |
| balance_cents | integer | Solde du locataire en centimes (négatif = dette) |

Un bail est lié à ses locataires via la table `lease_tenants` (pour gérer la co-location).

## Payment (Paiement)

| Champ | Type | Description |
|-------|------|-------------|
| id | integer | Identifiant unique |
| lease_id | integer | Bail concerné |
| date | date | Date du paiement |
| amount_cents | integer | Montant en centimes |
| payment_type | string | `rent`, `deposit`, `regularization` |
| payment_method | string | `bank_transfer`, `sepa_debit`, `check`, `caf` |

## Invoice (Facture fournisseur)

| Champ | Type | Description |
|-------|------|-------------|
| id | integer | Identifiant unique |
| landlord_id | integer | Propriétaire concerné |
| property_id | integer (nullable) | Bien concerné (null = facture globale immeuble) |
| supplier_name | string | Nom du fournisseur |
| description | string | Description des travaux/services |
| amount_cents | integer | Montant en centimes |
| status | string | `pending` ou `paid` |
| due_date | date | Date d'échéance |
| paid_date | date (nullable) | Date de paiement effectif |

---

## Endpoints API

```
GET /api/stats           — KPIs globaux
GET /api/landlords       — Liste des propriétaires (avec stats agrégées)
GET /api/landlords/:id   — Détail d'un propriétaire (biens, baux, paiements, factures)
GET /api/leases          — Liste des baux
GET /api/leases/:id      — Détail d'un bail (avec historique de paiements)
GET /api/properties      — Liste des biens
GET /api/invoices        — Liste des factures
```

Tous les montants sont en **centimes** (ex : 85000 = 850,00 EUR).
