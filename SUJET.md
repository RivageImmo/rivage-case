# Cas pratique — Développeur Fullstack

## Revue des versements propriétaires

**Durée : 1h à 1h30 (travail) + 30 min (restitution orale)**

---

## 1. Introduction à Rivage

Rivage est un logiciel de gestion locative axé sur la comptabilité, destiné aux agences immobilières. Notre plateforme permet aux gestionnaires et comptables de gérer l'intégralité du cycle de vie d'un bien en location : de l'entrée du locataire jusqu'à la restitution de son dépôt de garantie, en passant par l'encaissement des loyers, le paiement des charges et la rémunération des propriétaires.

Nos clients sont des agences immobilières (50 à 2 000 lots gérés). Leurs utilisateurs principaux sont les gestionnaires locatifs, les comptables d'agence et les directeurs d'agence.

---

## 2. Le contexte

Chaque mois, entre le 5 et le 10, la comptable mandant de l'agence passe en revue les versements propriétaires avant de déclencher les virements. Pour chaque propriétaire, elle peut **valider** le montant à verser, **bloquer** le versement avec un motif, ou **ajuster** (réduire, étaler).

L'agence gère 113 propriétaires. La majorité est en situation standard. Une minorité présente des signaux qui demandent arbitrage : impayé, rejet SEPA, facture de travaux importante, versement désactivé, bail qui se termine, propriétaire débiteur, plusieurs mandats avec taux différents.

L'enjeu : aller vite sur les cas simples, prendre le temps sur les cas à risque, ne pas rater les pièges.

---

## 3. Le cycle financier — ce que tu dois savoir

**Chaque mois**, pour chaque propriétaire, l'agence calcule le montant à reverser :

```
Reversement = Loyers encaissés
            − Honoraires de gestion (5% à 10% HT, par mandat)
            − Factures fournisseurs (travaux, plomberie, syndic) à déduire ce mois
            − Régularisations de charges à restituer au locataire
            − Dépôts de garantie à restituer (baux terminés)
            − Report du solde débiteur des mois précédents
```

Si le résultat est **négatif**, le propriétaire est **débiteur** : rien n'est versé, le déficit est reporté.

Certains propriétaires ont leur **versement désactivé** (`payment_enabled: false`). Ceux-là ne doivent jamais être versés tant que le motif n'est pas levé.

**Mandats multiples.** Un propriétaire peut avoir signé plusieurs mandats de gestion à différentes époques, chacun avec son propre **taux d'honoraires** et son **jour de versement**. Chaque bien est rattaché à un mandat. Les honoraires se calculent mandat par mandat, pas globalement.

**Défaut agence.** Quand un mandat a `management_fee_rate` à `null`, on applique le taux agence (7%). Idem pour `payment_day` (le 10).

---

## 4. Ta mission

Construis l'interface que la comptable utilise chaque mois pour passer en revue les 113 propositions de versement et rendre une décision pour chacune.

**Tu dois construire toi-même** :
1. Le **calcul du net à verser** pour chaque propriétaire, à partir des briques brutes (encaissements par bail, factures, mandats avec leurs taux, DG à restituer).
2. L'**identification des situations à risque** — quels signaux tu remontes, avec quelle hiérarchie.
3. La **classification** des propositions — lesquelles demandent de l'attention, lesquelles peuvent être validées sans friction.
4. L'**UX de décision** : valider / bloquer avec motif / ajuster avec motif.

L'API te donne des **données brutes**, pas un verdict. Ton jugement produit, ta compréhension du cycle financier, et tes choix d'interface sont au cœur de l'évaluation.

Les actions (valider / bloquer / ajuster) sont mockées côté front — aucune mutation en base n'est requise.

---

## 5. Ce qui est déjà en place

### Application

- Application Rails + React avec PostgreSQL, dockerisée
- Design system complet (classes CSS utilitaires, composants SCSS)
- Composants React partagés (DataTable, Badge, CurrencyAmount, Button, Tabs, Icons)
- Hook `useApi` pour appeler les endpoints API
- Base de données seedée avec **113 propriétaires réalistes** (cas simples + cas avec signaux à arbitrer)

### Fichier à modifier

```
app/frontend/react/dashboard/App.tsx
```

### Endpoints API

**Endpoint principal — le cœur de ton travail :**

```
GET /api/payouts
```

Retourne les données brutes pour les 113 propriétaires : identité, mandats (avec taux et jour de versement), biens, baux, paiements encaissés du mois, paiements post-mois (pour détecter les rejets SEPA), factures fournisseurs, DG à restituer. **Aucun montant proposé, aucun verdict, aucune classification.** C'est à toi de construire la logique métier par-dessus.

**Endpoints complémentaires — pour enrichir un détail au clic si tu veux :**

```
GET /api/landlords/:id   — Détail d'un propriétaire
GET /api/leases/:id      — Historique complet d'un bail
```

**Endpoints secondaires — disponibles mais non indispensables :**

```
GET /api/stats           — KPIs globaux de l'agence
GET /api/landlords       — Liste des propriétaires avec stats agrégées
GET /api/leases          — Liste des baux
GET /api/properties      — Liste des biens
GET /api/invoices        — Liste des factures fournisseurs
```

### Documentation

Le dossier `resources/` contient 10 documents sur le métier de la gestion locative. **Tu n'es pas obligé de tout lire.** À toi de déterminer ce qui est utile.

---

## 6. Le payload `/api/payouts`

```jsonc
{
  "period": {
    "reference_date": "2026-04-08",
    "scheduled_for": "2026-04-10",
    "collection_month": "2026-03",
    "collection_month_label": "Mars 2026"
  },
  "agency_defaults": {
    "management_fee_rate": 7.0,  // appliqué si mandate.management_fee_rate est null
    "payment_day": 10            // appliqué si mandate.payment_day est null
  },
  "landlords": [
    {
      "id": 113,
      "nature": "physical",
      "display_name": "Aline Courtin",
      "payment_enabled": true,
      "payment_disabled_reason": null,
      "mandate_started_at": "2021-03-15",
      "mandates": [
        { "id": 114, "reference": "MAND-2021-1000A",
          "management_fee_rate": "8.0", "payment_day": 10,
          "signed_at": "2021-03-15", "ended_at": null,
          "property_ids": [113] },
        { "id": 115, "reference": "MAND-2023-2000B",
          "management_fee_rate": "5.5", "payment_day": 5,
          "signed_at": "2023-06-15", "ended_at": null,
          "property_ids": [114] }
      ],
      "properties": [
        {
          "id": 113,
          "full_address": "85 rue Saint-Exupéry, Apt 11",
          "nature": "apartment",
          "mandate_id": 114,
          "leases": [
            {
              "id": 113,
              "status": "active",                      // active | terminated | upcoming
              "lease_type": "residential_unfurnished", // residential_unfurnished | residential_furnished | commercial
              "start_date": "2023-06-01",
              "end_date": "2026-04-28",
              "rent_amount_cents": 78000,
              "charges_amount_cents": 6240,
              "total_due_cents": 84240,
              "deposit_amount_cents": 78000,
              "balance_cents": 0,
              "tenants": [ { "id": 123, "display_name": "Sarah Martin",
                             "caf_amount_cents": null, "share": "100.0", ... } ],
              "payments_collection_month": [
                // Paiements datés dans le mois de collecte (mars 2026)
                { "date": "2026-03-05", "amount_cents": 84240,
                  "payment_type": "rent", "payment_method": "bank_transfer" }
              ],
              "payments_post_month": [
                // Paiements datés APRÈS le mois de collecte et avant reference_date.
                // Sert notamment à détecter les rejets SEPA (montants négatifs).
              ]
            }
          ]
        }
      ],
      "invoices": [
        { "id": 4, "supplier_name": "Artisan Duval SARL",
          "description": "Réfection toiture",
          "amount_cents": 850000, "status": "pending",
          "due_date": "2026-04-15", "paid_date": null,
          "property_id": 8, "property_address": "22 rue de la République" }
      ]
    }
  ]
}
```

### Ce que tu dois construire à partir de ces briques

- **Calcul du net** : loyers encaissés par bail (somme `payments_collection_month` du type `rent`) − honoraires par mandat − factures à déduire − régularisations (paiements `regularization` négatifs) − DG à restituer (baux `terminated`) − éventuel report débiteur des mois précédents.
- **Détection de situations** (non exhaustif, c'est à toi de décider lesquelles tu traites) : versement désactivé, impayé partiel, CAF seule, rejet SEPA (via `payments_post_month`), propriétaire débiteur, bail qui expire bientôt, DG à restituer, nouveau mandat, factures lourdes pendantes, multi-biens, bail commercial.
- **Classification** : quelles propositions regrouper, lesquelles isoler, dans quel ordre les présenter.
- **Interaction** : un flow de décision adapté à passer rapidement 113 cas.

---

## 7. Déroulement

| Phase | Durée | Description |
|-------|-------|-------------|
| Découverte | 15-20 min | Parcours la doc, explore `/api/payouts`, comprends le cycle financier |
| Construction | 45-60 min | Code ta solution dans `App.tsx` |
| Restitution | 30 min | Présentation de tes choix + démo en direct |

### Ce qu'on attend en restitution

- **Raisonnement produit.** Quel utilisateur tu as ciblé, pourquoi, ce que ton écran l'aide à faire.
- **Modélisation du calcul.** Explique comment tu calcules le net — notamment la gestion des mandats multiples.
- **Hiérarchie des signaux.** Ce que tu as choisi de remonter, dans quel ordre, avec quelle prominence visuelle — et ce que tu as délibérément masqué.
- **Démo en direct.** Tu passes la revue devant nous. Sur les cas à risque, on te demandera ta décision et pourquoi.
- **Limites.** Ce que tu n'as pas fait, ce que tu aurais fait avec plus de temps, les hypothèses que tu as prises.

---

## 8. Contraintes

1. L'interface est desktop uniquement.
2. Le design system et les composants sont fournis — utilise-les.
3. Tu peux ajouter de nouveaux endpoints API si nécessaire.
4. Tu peux créer de nouveaux composants React si nécessaire.
5. Les actions (valider / bloquer / ajuster) sont mockées côté front — aucune mutation en base requise.
6. **Le sujet est volontairement large.** On n'attend pas que tu traites chaque cas. On évalue ta capacité à prioriser, à modéliser le calcul correctement, et à livrer une expérience de décision cohérente.

---

## 9. Lancement

```bash
docker compose up
```

L'application est accessible sur `http://localhost:3000`. Les API sont accessibles directement dans le navigateur (ex : `http://localhost:3000/api/payouts`). Le hot-reload est actif sur `App.tsx`.

---

Bon courage !
