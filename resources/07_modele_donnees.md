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
| payment_enabled | boolean | Versement actif ou désactivé (drapeau global au propriétaire) |
| payment_disabled_reason | string (nullable) | Motif de désactivation du versement |
| payment_day | integer (nullable) | **Déprécié** — utilise `mandate.payment_day` |
| management_fee_rate | decimal (nullable) | **Déprécié** — utilise `mandate.management_fee_rate` |

## Mandate (Mandat de gestion)

Un propriétaire signe un ou plusieurs mandats de gestion avec l'agence. Chaque mandat porte ses propres conditions commerciales (taux d'honoraires, jour de versement). Les biens sont rattachés à un mandat spécifique.

| Champ | Type | Description |
|-------|------|-------------|
| id | integer | Identifiant unique |
| landlord_id | integer | Propriétaire du mandat |
| reference | string | Référence interne (ex : `MAND-2024-001`) |
| management_fee_rate | decimal | Taux d'honoraires du mandat (défaut agence : 7%) |
| payment_day | integer | Jour de versement du mandat (défaut agence : le 10) |
| signed_at | date | Date de signature |
| ended_at | date (nullable) | Date de résiliation si applicable |

## Property (Bien / Lot)

| Champ | Type | Description |
|-------|------|-------------|
| id | integer | Identifiant unique |
| landlord_id | integer | Propriétaire du bien |
| mandate_id | integer (nullable) | Mandat de gestion qui régit ce bien (taux d'honoraires, jour de versement) |
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
GET /api/landlords                 — Liste des propriétaires avec mandats, biens, baux actifs
                                     (paiements du mois + post-mois), factures. Vue la plus
                                     complète pour construire la revue mensuelle des versements.
GET /api/landlords/:id             — Même forme pour un propriétaire unique
GET /api/mandates?landlord_id=X    — Mandats d'un propriétaire (ou tous)
GET /api/leases                    — Liste des baux
GET /api/leases/:id                — Détail d'un bail avec historique complet des paiements
GET /api/properties                — Liste des biens
GET /api/invoices                  — Liste des factures fournisseurs
GET /api/stats                     — KPIs globaux de l'agence (vue macro)
```

Le détail du payload `/api/landlords` (mandats, propriétés, baux, paiements collectés, paiements post-mois, factures) est documenté dans `SUJET.md` section 6. **Aucun calcul n'est préfait** — le candidat doit construire lui-même le net à verser, la détection des signaux et la classification.

**Défauts agence** : si `mandate.management_fee_rate` est `null`, appliquer 7%. Si `mandate.payment_day` est `null`, appliquer le 10.

**Contexte temporel du cas** : on est le **8 avril 2026**. Les virements partent le **10 avril**. Le mois de collecte à analyser est **mars 2026**. Les paiements datés après le 31 mars (ex : rejets SEPA) sont exposés via `payments_post_month` sur chaque bail.

Tous les montants sont en **centimes** (ex : 85000 = 850,00 EUR).

---

## Champs calculés par l'API

L'API retourne plusieurs champs calculés qui ne sont pas directement stockés en base de données. Ces champs sont construits à la volée par les contrôleurs ou les méthodes de modèle.

### Sur Landlord (via le contrôleur)

| Champ calculé | Type | Description |
|---------------|------|-------------|
| `display_name` | string | Si `nature = company` : retourne `company_name`. Si `nature = physical` : retourne `"first_name last_name"`. |
| `properties_count` | integer | Nombre total de biens du propriétaire. |
| `active_leases_count` | integer | Nombre de baux actifs (status = `active`). |
| `vacant_properties_count` | integer | Nombre de biens sans bail actif. |

**Note** : l'API n'expose pas d'agrégats financiers (somme des loyers, solde, factures pendantes) au niveau `Landlord`. Ces calculs sont à la charge du candidat — il doit les faire lui-même à partir des briques `leases[]`, `invoices[]` et `mandates[]` retournées par `/api/landlords`.

### Sur Property (via le contrôleur)

| Champ calculé | Type | Description |
|---------------|------|-------------|
| `full_address` | string | Concaténation de `address` et `unit_number` (séparés par une virgule). Ex : `"45 rue de Rivoli, Apt 3B"`. |
| `vacant` | boolean | `true` si le bien n'a aucun bail actif. |

### Sur Lease (via le contrôleur et le modèle)

| Champ calculé | Type | Description |
|---------------|------|-------------|
| `total_due_cents` | integer | `rent_amount_cents + charges_amount_cents` — montant total dû mensuellement (en centimes). |
| `expires_soon` | boolean | `true` si le bail est actif, possède une `end_date`, et que celle-ci est dans les 30 prochains jours. |

### Sur Tenant (via le modèle)

| Champ calculé | Type | Description |
|---------------|------|-------------|
| `display_name` | string | `"first_name last_name"`. |
| `share` | decimal | Part du locataire dans le bail (provient de la table de liaison `lease_tenants`). Ex : `"100.0"` pour un locataire unique. |

### Sur Invoice (via le contrôleur)

| Champ calculé | Type | Description |
|---------------|------|-------------|
| `property_address` | string (nullable) | Adresse complète du bien lié à la facture (`full_address` du Property). `null` si la facture n'est pas liée à un bien spécifique. |

---

## Exemples de réponses API

### GET /api/landlords — Liste des propriétaires

Retourne un tableau JSON. Chaque élément contient les données du propriétaire avec des statistiques agrégées. Voici 2 éléments représentatifs (sur 103 au total) :

```json
[
  {
    "id": 9,
    "nature": "physical",
    "display_name": "Marie Dupont",
    "company_name": null,
    "email": "marie.dupont@email.com",
    "phone": "06 12 34 56 78",
    "payment_enabled": true,
    "payment_disabled_reason": null,
    "properties_count": 1,
    "active_leases_count": 1,
    "vacant_properties_count": 0
  },
  {
    "id": 10,
    "nature": "company",
    "display_name": "SCI Les Oliviers",
    "company_name": "SCI Les Oliviers",
    "email": "contact@sci-oliviers.fr",
    "phone": "06 98 76 54 32",
    "payment_enabled": true,
    "payment_disabled_reason": null,
    "properties_count": 3,
    "active_leases_count": 2,
    "vacant_properties_count": 1
  }
]
```

### GET /api/landlords/:id — Détail d'un propriétaire

Retourne l'objet propriétaire enrichi avec la liste de ses biens (et leurs baux actifs avec locataires et paiements récents) et ses factures fournisseur.

```json
{
  "id": 9,
  "nature": "physical",
  "display_name": "Marie Dupont",
  "company_name": null,
  "email": "marie.dupont@email.com",
  "phone": "06 12 34 56 78",
  "payment_enabled": true,
  "payment_disabled_reason": null,
  "properties_count": 1,
  "active_leases_count": 1,
  "vacant_properties_count": 0,
  "siret": null,
  "properties": [
    {
      "id": 13,
      "address": "45 rue de Rivoli",
      "unit_number": "Apt 3B",
      "full_address": "45 rue de Rivoli, Apt 3B",
      "city": "Paris",
      "zip_code": "75001",
      "nature": "apartment",
      "area_sqm": "55.0",
      "rooms_count": 2,
      "vacant": false,
      "lease": {
        "id": 13,
        "status": "active",
        "lease_type": "residential_unfurnished",
        "start_date": "2024-09-01",
        "end_date": "2027-08-31",
        "rent_amount_cents": 85000,
        "charges_amount_cents": 8000,
        "deposit_amount_cents": 85000,
        "total_due_cents": 93000,
        "balance_cents": 0,
        "expires_soon": false,
        "tenants": [
          {
            "id": 14,
            "display_name": "Jean Martin",
            "email": "jean.martin@gmail.com",
            "phone": "06 11 22 33 44",
            "caf_amount_cents": null,
            "share": "100.0"
          }
        ],
        "recent_payments": [
          {
            "id": 40,
            "date": "2026-03-03",
            "amount_cents": 93000,
            "payment_type": "rent",
            "payment_method": "bank_transfer"
          },
          {
            "id": 39,
            "date": "2026-02-05",
            "amount_cents": 93000,
            "payment_type": "rent",
            "payment_method": "bank_transfer"
          },
          {
            "id": 38,
            "date": "2026-01-08",
            "amount_cents": 93000,
            "payment_type": "rent",
            "payment_method": "bank_transfer"
          }
        ]
      }
    }
  ],
  "invoices": []
}
```

### GET /api/stats — KPIs globaux

Retourne un objet unique avec les indicateurs clés de performance de l'agence.

```json
{
  "landlords_count": 103,
  "properties_count": 112,
  "active_leases_count": 109,
  "vacant_properties_count": 3,
  "occupancy_rate": 97.3,
  "total_monthly_rent_cents": 8102000,
  "total_monthly_charges_cents": 700000,
  "total_balance_cents": -333300,
  "unpaid_leases_count": 3,
  "total_unpaid_cents": 333300,
  "expiring_leases_count": 3,
  "pending_invoices_count": 5,
  "pending_invoices_total_cents": 3208500,
  "disabled_payments_count": 1
}
```

**Détail des champs stats :**

| Champ | Type | Description |
|-------|------|-------------|
| `landlords_count` | integer | Nombre total de propriétaires. |
| `properties_count` | integer | Nombre total de biens gérés. |
| `active_leases_count` | integer | Nombre de baux actifs. |
| `vacant_properties_count` | integer | Nombre de biens sans bail actif. |
| `occupancy_rate` | float | Taux d'occupation en pourcentage (arrondi à 1 décimale). Formule : `(biens occupés / biens totaux) * 100`. |
| `total_monthly_rent_cents` | integer | Somme des loyers mensuels des baux actifs (en centimes). |
| `total_monthly_charges_cents` | integer | Somme des charges mensuelles des baux actifs (en centimes). |
| `total_balance_cents` | integer | Solde global tous baux actifs confondus (en centimes). Négatif = impayés. |
| `unpaid_leases_count` | integer | Nombre de baux avec un solde négatif (impayés). |
| `total_unpaid_cents` | integer | Montant total des impayés en valeur absolue (en centimes). |
| `expiring_leases_count` | integer | Nombre de baux actifs dont la date de fin est dans les 30 prochains jours. |
| `pending_invoices_count` | integer | Nombre de factures fournisseur en attente de paiement. |
| `pending_invoices_total_cents` | integer | Montant total des factures en attente (en centimes). |
| `disabled_payments_count` | integer | Nombre de propriétaires dont les versements sont désactivés (`payment_enabled = false`). |
