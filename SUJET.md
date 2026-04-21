# Cas pratique — Développeur Fullstack

## La run des versements propriétaires

**Durée : 1h à 1h30 (travail) + 30 min (restitution orale)**

---

## 1. Introduction à Rivage

Rivage est un logiciel de gestion locative axé sur la comptabilité, destiné aux agences immobilières. Notre plateforme permet aux gestionnaires et comptables de gérer l'intégralité du cycle de vie d'un bien en location : de l'entrée du locataire jusqu'à la restitution de son dépôt de garantie, en passant par l'encaissement des loyers, le paiement des charges et la rémunération des propriétaires.

Nos clients sont des agences immobilières (50 à 2 000 lots gérés). Leurs utilisateurs principaux sont les gestionnaires locatifs, les comptables d'agence et les directeurs d'agence.

---

## 2. Le moment

> **Mercredi 8 avril 2026, 9h30.** Nathalie, comptable mandant, arrive. Dans 48h, Rivage déclenche la run mensuelle des **versements aux propriétaires** — chaque propriétaire reçoit le net de ses loyers de mars, déductions faites. La run concerne 23 propriétaires.
>
> Son job aujourd'hui : passer en revue chaque proposition de versement et décider, pour chacune, **Valider**, **Bloquer** (avec motif), ou **Ajuster** (nouveau montant + motif). Une fois validée la run, les virements partent automatiquement le 10.
>
> **Le coût d'une erreur est asymétrique :**
> - Un versement qui part alors qu'il ne fallait pas → l'agence a avancé de l'argent qu'elle doit récupérer manuellement chez le propriétaire. Typiquement plusieurs jours de mails et de recouvrement.
> - Un versement bloqué à tort → un propriétaire furieux au téléphone le 11, satisfaction en chute, parfois résiliation du mandat.
>
> Nathalie ne peut pas "tout regarder en détail". Elle doit aller vite sur les cas simples, lentement sur les cas à risque, et détecter elle-même les pièges.

---

## 3. Le cycle financier — ce que tu dois savoir

**Chaque mois**, pour chaque propriétaire, l'agence calcule le montant à reverser :

```
Reversement = Loyers encaissés
            − Honoraires de gestion (5% à 10% HT)
            − Factures fournisseurs (travaux, plomberie, syndic)
            − Prime GLI (assurance impayés)
            − Régularisations de charges à restituer au locataire
            − Dépôts de garantie à restituer (baux terminés)
            − Report du solde débiteur des mois précédents
```

Si le résultat est **négatif**, le propriétaire est **débiteur** : rien n'est versé, le déficit est reporté.

Certains propriétaires ont leur **versement désactivé** (travaux en cours, fonds consignés). Ceux-là ne doivent jamais être versés tant que le motif n'est pas levé.

Le reversement peut aussi être **ajusté** : on retient une partie pour provisionner des travaux à venir, on étale une grosse facture sur plusieurs mois, on verse un acompte. C'est une décision qui appartient à Nathalie.

---

## 4. Ta mission

Construis **la UI que Nathalie utilisera le 8 de chaque mois** pour passer en revue les 23 propositions de versement de la run et rendre une décision pour chacune.

**L'objectif de Nathalie :**
1. Aller vite sur les cas simples ("tout va bien, je valide").
2. Repérer les cas qui demandent réflexion ("il y a un signal qui m'inquiète").
3. Ne pas rater les pièges (une donnée qui a l'air normale mais cache un problème).
4. Justifier chaque blocage ou ajustement avec un motif communicable.

**Contraintes :**
- Tous les cas tiennent dans un seul flow, pas d'autre page à ouvrir pour prendre une décision.
- Chaque décision (valider / bloquer / ajuster) doit être traçable : pourquoi, par qui, quand.
- Les actions sont mockées côté front (aucune mutation en base n'est nécessaire) — tu simules l'enregistrement.
- Si une info n'est pas dans le payload principal, tu peux fouiller les autres endpoints pour enrichir.

**Ton prototype doit permettre de démontrer en live, pendant la restitution, le passage de la run en 5 minutes chrono.**

---

## 5. Ce qui est déjà en place

### Application

- Application Rails + React avec PostgreSQL, dockerisée
- Design system complet (classes CSS utilitaires, composants SCSS)
- Composants React partagés (DataTable, Badge, CurrencyAmount, Button, Tabs, Icons)
- Hook `useApi` pour appeler les endpoints API
- Base de données seedée avec **23 propriétaires réalistes** (cas simples + cas piégés)

### Fichier à modifier

```
app/frontend/react/dashboard/App.tsx
```

### Endpoint principal (à utiliser en premier)

```
GET /api/payout-runs/current
```

Retourne la run du mois prête à être passée en revue : pour chaque propriétaire, un objet `payout` avec son net proposé, le breakdown détaillé, les signaux métier (tags), et les actions disponibles. **Les calculs financiers sont déjà faits** — ton job est la UX de décision, pas le calcul.

### Endpoints complémentaires (pour enrichir si besoin)

```
GET /api/stats           — KPIs globaux
GET /api/landlords       — Liste des propriétaires avec stats agrégées
GET /api/landlords/:id   — Détail d'un propriétaire (biens, baux, paiements, factures)
GET /api/leases          — Liste des baux
GET /api/leases/:id      — Détail d'un bail avec historique de paiements
GET /api/properties      — Liste des biens
GET /api/invoices        — Liste des factures fournisseurs
```

### Documentation

Le dossier `resources/` contient 10 documents sur le métier de la gestion locative. **Tu n'es pas obligé de tout lire.** À toi de déterminer ce qui est utile.

---

## 6. Le payload `/api/payout-runs/current`

```jsonc
{
  "run": {
    "id": "run-2026-04-10",
    "scheduled_for": "2026-04-10",
    "reference_date": "2026-04-08",
    "collection_month": "2026-03",
    "collection_month_label": "Mars 2026",
    "totals": {
      "proposed_count": 23,
      "ready_count": 12,
      "at_risk_count": 9,
      "blocked_count": 1,
      "debtor_count": 1,
      "proposed_amount_cents": 18520000
    }
  },
  "payouts": [
    {
      "id": "payout-42",
      "landlord": {
        "id": 42,
        "nature": "physical",
        "display_name": "Isabelle Faure",
        "email": "...", "phone": "...",
        "payment_day": 10,
        "management_fee_rate": 7.0,
        "payment_enabled": true,
        "payment_disabled_reason": null,
        "is_company": false,
        "mandate_started_at": "2023-10-01",
        "properties_count": 1,
        "active_leases_count": 1
      },
      "period": { "month": "2026-03", "label": "Mars 2026" },
      "proposed_status": "at_risk",  // ready | at_risk | debtor | blocked
      "proposed_amount_cents": 23250,
      "previous_amount_cents": 23250,
      "amount_delta_cents": 0,
      "breakdown": {
        "rent_collected_cents": 25000,
        "deposit_inflow_cents": 0,
        "regularization_cents": 0,
        "fees_cents": -1750,
        "invoices_cents": 0,
        "deposit_refund_cents": 0,
        "carryover_cents": 0
      },
      "components": [
        { "type": "rent", "label": "Loyer encaissé — 5 place Bellecour, Apt 7A",
          "amount_cents": 25000, "expected_cents": 115000, "note": "Encaissement partiel",
          "lease_id": 4 },
        { "type": "fees", "label": "Honoraires de gestion (7%)", "amount_cents": -1750 }
      ],
      "signals": ["unpaid_balance", "caf_only"],
      "suggested_block_reason": null,
      "actions": ["validate", "block", "adjust"]
    }
  ]
}
```

### Les signaux possibles (`signals[]`)

| Signal                  | Sens                                                                 |
| ----------------------- | -------------------------------------------------------------------- |
| `payment_disabled`      | Le versement est désactivé (motif dans `suggested_block_reason`)     |
| `unpaid_balance`        | Au moins un bail a un solde locataire négatif                        |
| `caf_only`              | Le mois de collecte n'a reçu que des paiements CAF (locataire absent)|
| `sepa_rejected`         | Un prélèvement SEPA a été rejeté (le montant encaissé est annulé)    |
| `rent_partial`          | Encaissement inférieur au loyer attendu                              |
| `multi_installment`     | Le mois précédent a été surperçu, le mois courant est vide           |
| `heavy_invoice`         | Une facture fournisseur ≥ 5 000 EUR est pendante                     |
| `debtor_carryover`      | Un déficit du mois précédent est reporté                             |
| `deposit_to_refund`     | Un dépôt de garantie doit être restitué (bail terminé)               |
| `regularization_pending`| Une régularisation de charges est à restituer au locataire           |
| `expiring_lease`        | Au moins un bail se termine dans les 30 jours                        |
| `commercial_lease`      | Au moins un bail est commercial                                      |
| `multi_property`        | Le propriétaire a plusieurs biens                                    |
| `vacancy`               | Au moins un bien est vacant                                          |
| `new_landlord`          | Mandat démarré il y a moins de 30 jours                              |
| `new_lease`             | Bail démarré dans le mois de collecte                                |
| `upcoming_lease`        | Un bail non encore actif a déjà encaissé (DG, 1er loyer)             |

---

## 7. Déroulement

| Phase | Durée | Description |
|-------|-------|-------------|
| Découverte | 15-20 min | Parcours la doc, explore `/api/payout-runs/current` et les autres endpoints, comprends le cycle financier |
| Construction | 45-60 min | Code ta solution dans `App.tsx` |
| **Restitution** | **30 min** | **Présente tes choix et fais la run en direct devant nous** |

### Ce qu'on attend en restitution

- **Ton raisonnement produit.** Qui est Nathalie, qu'est-ce qui la rend efficace, qu'est-ce qui la ralentit, comment ton écran l'aide.
- **Ta hiérarchie des signaux.** Tu ne peux pas tout remonter au même niveau. Défends les choix de ce qui est gros, ce qui est petit, ce qui est caché, ce qui est explicite.
- **La démo en live.** Tu passes les 23 versements devant nous. On chronomètre. Sur les cas piégés, on te demandera "tu fais quoi, pourquoi ?".
- **Tes limites.** Ce que tu n'as pas eu le temps de faire, ce que tu aurais fait avec plus de temps, les hypothèses que tu as prises.

---

## 8. Contraintes

1. L'interface est desktop uniquement.
2. Le design system et les composants sont fournis — utilise-les.
3. Tu peux ajouter de nouveaux endpoints API si nécessaire (dans `app/controllers/api/`), mais le payload `/api/payout-runs/current` doit suffire pour l'essentiel.
4. Tu peux créer de nouveaux composants React si nécessaire.
5. Les actions (valider/bloquer/ajuster) sont mockées côté front — aucune mutation en base requise.
6. **Le sujet est volontairement large.** On n'attend pas que tu traites chaque détail. On évaluera ta capacité à prioriser les signaux, à penser comme Nathalie, et à livrer une expérience de décision fluide.

---

## 9. Lancement

```bash
docker compose up
```

L'application est accessible sur `http://localhost:3000`. Les API sont accessibles directement dans le navigateur (ex : `http://localhost:3000/api/payout-runs/current`). Le hot-reload est actif sur `App.tsx`.

---

Bon courage !
