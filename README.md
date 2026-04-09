# Rivage — Case pratique développeur

## Lancement rapide

```bash
docker compose up
```

L'application démarre sur **http://localhost:3000**.

Le premier lancement prend quelques minutes (installation des dépendances, création de la base de données).

## Sujet

Lis le fichier **[SUJET.md](SUJET.md)** pour les instructions complètes.

## Structure du projet

```
app/
├── controllers/
│   ├── api/                  # Endpoints JSON (landlords, leases, properties, invoices, stats)
│   └── pages_controller.rb   # Page principale
├── models/                    # Landlord, Property, Tenant, Lease, Payment, Invoice
├── views/layouts/             # Layout avec sidebar
└── frontend/
    ├── design_system/         # SCSS : couleurs, typographie, espacement, composants
    ├── react/
    │   ├── shared/
    │   │   ├── components/    # DataTable, Badge, CurrencyAmount, Button, Tabs, Icons
    │   │   └── hooks/         # useApi
    │   └── dashboard/
    │       └── App.tsx        # <-- TON FICHIER DE TRAVAIL
    └── entrypoints/
        └── application.tsx    # Point d'entrée React

resources/                     # Documentation métier (10 fichiers)
db/seeds.rb                    # Données de la base
```

## API disponibles

| Endpoint | Description |
|----------|-------------|
| `GET /api/stats` | KPIs globaux |
| `GET /api/landlords` | Liste des propriétaires |
| `GET /api/landlords/:id` | Détail d'un propriétaire |
| `GET /api/leases` | Liste des baux |
| `GET /api/leases/:id` | Détail d'un bail |
| `GET /api/properties` | Liste des biens |
| `GET /api/invoices` | Liste des factures |

## Composants disponibles

```tsx
import { DataTable, Badge, CurrencyAmount, Button, Tabs, Icons } from '~/react/shared/components';
import { useApi } from '~/react/shared/hooks/useApi';
```

## Hot reload

Les modifications dans les fichiers React sont reflétées immédiatement dans le navigateur.
