# Cas pratique — Développeur Fullstack

## Revue des versements propriétaires

**Durée : 1h à 1h15 (travail) + 30 à 45 min (restitution orale)**

---

## 1. Introduction à Rivage

Rivage est un logiciel de gestion locative axé sur la comptabilité, destiné aux agences immobilières. Notre plateforme permet aux gestionnaires et comptables de gérer l'intégralité du cycle de vie d'un bien en location : de l'entrée du locataire jusqu'à la restitution de son dépôt de garantie, en passant par l'encaissement des loyers, le paiement des charges et la rémunération des propriétaires.

Nos clients sont des agences immobilières (50 à 2 000 lots gérés). Leurs utilisateurs principaux sont les gestionnaires locatifs, les comptables d'agence et les directeurs d'agence.

---

## 2. Le contexte

Chaque mois, entre le 5 et le 10, la comptable mandant de l'agence passe en revue les versements propriétaires avant de déclencher les virements. Pour chaque propriétaire, elle peut **valider** le montant à verser, **bloquer** le versement avec un motif, ou **ajuster** (réduire, étaler).

L'agence gère 113 propriétaires. La majorité est en situation standard (loyer encaissé, honoraires déduits, virement). Une minorité présente des situations qui demandent arbitrage : impayé, paiement partiel, rejet SEPA, facture de travaux importante, versement désactivé, bail qui se termine, dépôt de garantie à restituer, propriétaire avec plusieurs mandats aux taux différents.

L'enjeu : aller vite sur les cas simples, prendre le temps sur les cas à risque, ne pas rater les pièges.

---

## 3. Le cycle financier — ce que tu dois savoir

### Formule de reversement

Chaque mois, pour chaque propriétaire, l'agence calcule le montant à reverser :

```
Reversement = Loyers encaissés ce mois-ci
            − Honoraires de gestion (5% à 10% HT, calculés par mandat)
            − Factures fournisseurs à déduire ce mois (travaux, plomberie, syndic)
            − Régularisations de charges à restituer au locataire
            − Dépôts de garantie à restituer (baux terminés)
```

Si le résultat est **négatif**, le propriétaire est **débiteur** : rien n'est versé, le déficit est reporté.

### Versement désactivé

Certains propriétaires ont leur `payment_enabled` à `false`. Ceux-là ne doivent **jamais** être versés tant que le motif n'est pas levé, quel que soit leur solde.

### Mandats multiples

Un propriétaire peut avoir signé **plusieurs mandats** de gestion à différentes époques, chacun avec son propre **taux d'honoraires** et son **jour de versement**. Chaque bien est rattaché à un mandat précis. Les honoraires doivent être calculés **mandat par mandat**, pas globalement.

### Contexte temporel du cas

- On est le **15 avril 2026**
- Les virements partiront le **20 avril 2026**
- Le mois à analyser (collecte des loyers) est **avril 2026** (le mois courant)
- Les rejets SEPA du mois apparaissent comme des paiements **négatifs** dans le mois courant — ils annulent l'encaissement correspondant

---

## 4. Ta mission

Construis un **flow de versement des propriétaires** qui permette à la comptable de :

- Avoir une **vue d'ensemble** des 113 propriétaires et identifier rapidement ceux qui demandent attention
- Accéder au **détail d'un propriétaire** (breakdown du calcul, historique, signaux à arbitrer)
- **Décider pour chacun** : valider le versement, bloquer avec motif, ajuster avec motif

L'API expose les ressources métier brutes (propriétaires, mandats, baux, paiements, factures). Pas de montant proposé, pas de classification préfabriquée — c'est toi qui construis la couche produit au-dessus.

Les actions sont mockées côté front, aucune mutation en base n'est requise.

---

## 5. Ce qui est déjà en place

### Application

- Application Rails + React avec PostgreSQL, dockerisée
- Design system complet (classes CSS utilitaires, composants SCSS)
- Composants React partagés (DataTable, Badge, CurrencyAmount, Button, Tabs, Icons)
- Hook `useApi` pour appeler les endpoints API
- Base de données seedée avec **113 propriétaires réalistes** (cas simples + cas à risque)

### Fichier à modifier

```
app/frontend/react/dashboard/App.tsx
```

### Endpoints API

**Endpoint principal** — contient tout ce dont tu as besoin pour la revue :

```
GET /api/landlords        — Liste des propriétaires, chacun avec ses mandats, biens,
                            baux actifs, paiements du mois et post-mois, factures.
GET /api/landlords/:id    — Même forme pour un propriétaire unique
```

**Endpoints complémentaires** — utiles si tu veux filtrer, zoomer, ou enrichir :

```
GET /api/mandates?landlord_id=X   — Mandats d'un propriétaire (ou tous)
GET /api/leases                   — Liste des baux
GET /api/leases/:id               — Détail d'un bail (historique complet des paiements)
GET /api/properties               — Liste des biens
GET /api/invoices                 — Liste des factures fournisseurs
GET /api/stats                    — KPIs globaux de l'agence (vue macro)
```

### Documentation

Le dossier `resources/` contient 10 documents sur le métier de la gestion locative. **Tu n'es pas obligé de tout lire.** À toi de déterminer ce qui est utile.

---

## 6. Exemple de payload `/api/landlords`

```jsonc
{
  "id": 113,
  "nature": "physical",
  "display_name": "Aline Courtin",
  "email": "aline.courtin@email.com",
  "phone": "06 ...",
  "payment_enabled": true,
  "payment_disabled_reason": null,
  "mandate_started_at": "2021-03-15",   // premier mandat signé avec l'agence

  "mandates": [
    {
      "id": 114,
      "reference": "MAND-2021-1000A",
      "management_fee_rate": "8.0",      // string decimal, null = défaut agence (7%)
      "payment_day": 10,                 // null = défaut agence (10)
      "signed_at": "2021-03-15",
      "ended_at": null,                  // null = mandat toujours actif
      "property_ids": [113]
    },
    { "id": 115, "reference": "MAND-2023-2000B", "management_fee_rate": "5.5",
      "payment_day": 5, "signed_at": "2023-06-15", "ended_at": null,
      "property_ids": [114] }
  ],

  "properties": [
    {
      "id": 113,
      "full_address": "85 rue Saint-Exupéry, Apt 11",
      "nature": "apartment",             // apartment | house | commercial | parking
      "mandate_id": 114,                 // mandat qui régit ce bien
      "leases": [
        {
          "id": 113,
          "status": "active",            // active | terminated | upcoming
          "lease_type": "residential_unfurnished",
          "start_date": "2023-06-01",
          "end_date": "2026-04-28",
          "rent_amount_cents": 78000,
          "charges_amount_cents": 6240,
          "total_due_cents": 84240,
          "deposit_amount_cents": 78000,
          "balance_cents": 0,

          "tenants": [
            { "id": 123, "display_name": "Sarah Martin",
              // null = pas d'aide CAF. Non-null = la CAF verse ce montant
              // directement à l'agence chaque mois (paiement dissocié du locataire).
              "caf_amount_cents": null,
              "share": "100.0", ... }
          ],

          // Paiements datés dans mars 2026 (le mois de collecte)
          "payments_collection_month": [
            { "date": "2026-03-05", "amount_cents": 84240,
              "payment_type": "rent",    // rent | deposit | regularization
              "payment_method": "bank_transfer" }  // bank_transfer | sepa_debit | check | caf
          ],

          // Paiements datés entre le 1er avril et aujourd'hui (8 avril).
          // Utile pour détecter les rejets SEPA (montants négatifs).
          "payments_post_month": []
        }
      ]
    }
  ],

  "invoices": [
    { "id": 4, "supplier_name": "Artisan Duval SARL",
      "description": "Réfection toiture",
      "amount_cents": 850000,
      "status": "pending",               // pending | paid
      "due_date": "2026-04-15",
      "paid_date": null,
      "property_id": 8,
      "property_address": "22 rue de la République" }
  ]
}
```

### Ce que tu dois construire à partir de ces briques

**Calcul du net à verser**
- Somme des `payments_collection_month` de type `rent` par bail = loyers encaissés
- Honoraires = loyers encaissés × taux **du mandat** rattaché au bien (avec fallback 7% si `null`)
- Déductions : factures à retenir ce mois, régularisations de charges (montants négatifs en `payment_type: regularization`), dépôts de garantie à restituer (bail `terminated`)

**Détection des situations** (liste non exhaustive — à toi de décider lesquelles tu traites et comment tu les hiérarchises)
- Versement désactivé (`payment_enabled: false`)
- Impayé ou paiement partiel (`payments_collection_month` < `total_due_cents`)
- CAF seule (seul paiement = `payment_method: caf`, locataire n'a pas complété)
- Rejet SEPA (paiement négatif dans `payments_post_month`)
- Propriétaire débiteur (net calculé négatif)
- Bail qui expire bientôt (`end_date` proche)
- Dépôt de garantie à restituer (bail `terminated` récent)
- Mandat récent (`mandate_started_at` récent)
- Factures lourdes pendantes
- Propriétaire multi-biens, multi-mandats, bail commercial

**Classification et priorisation**
Quelles propositions regrouper, lesquelles isoler, dans quel ordre les présenter. À toi de justifier.

**Interaction**
Un flow de décision adapté à passer rapidement 113 cas. Les actions (valider / bloquer / ajuster) nécessitent toutes un enregistrement traçable (motif pour bloquer/ajuster).

---

## 7. Déroulement

| Phase | Durée | Description |
|-------|-------|-------------|
| Découverte | 15-20 min | Parcours la doc métier, explore `/api/landlords`, comprends le cycle financier |
| Construction | 45-55 min | Code ta solution dans `App.tsx` |
| Restitution | 30-45 min | Présentation de tes choix + démo en direct |

Le sujet est volontairement large. On ne s'attend pas à ce que tu traites tous les cas — on évalue ta capacité à choisir ce qui compte en priorité. Un MVP focalisé (calcul juste + cas à risque bien remontés) vaut mieux qu'une implémentation qui survole tout.

### Ce qu'on attend en restitution

- **Raisonnement produit.** Quel utilisateur tu as ciblé, pourquoi, ce que ton écran l'aide à faire.
- **Modélisation du calcul.** Comment tu calcules le net — notamment la gestion des mandats multiples.
- **Hiérarchie des signaux.** Ce que tu as choisi de remonter, dans quel ordre, avec quelle prominence — et ce que tu as délibérément masqué.
- **Démo en direct.** Tu passes la revue devant nous. Sur les cas à risque, on te demandera ta décision et pourquoi.
- **Limites.** Ce que tu n'as pas fait, ce que tu aurais fait avec plus de temps.

---

## 8. Contraintes

1. L'interface est desktop uniquement.
2. Utilise le design system et les composants fournis.
3. Tu peux créer de nouveaux composants React si nécessaire, et de nouveaux endpoints API si tu en ressens le besoin (mais `/api/landlords` devrait suffire).
4. Les actions (valider / bloquer / ajuster) sont mockées côté front — aucune mutation en base requise.
5. Le sujet est volontairement large. On n'attend pas que tu traites chaque cas. On évalue ta capacité à prioriser, à modéliser le calcul correctement, et à livrer une expérience de décision cohérente.

---

## 9. Lancement

```bash
docker compose up
```

L'application est accessible sur `http://localhost:3000`. Les API sont accessibles directement dans le navigateur (ex : `http://localhost:3000/api/landlords`). Le hot-reload est actif sur `App.tsx`.

---

Bon courage !
