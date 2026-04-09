import React from 'react';

/**
 * =============================================================================
 * TODO — C'est ici que tu construis ton tableau de bord.
 *
 * Tu as a disposition :
 *
 * Composants (import depuis '~/react/shared/components') :
 *   - DataTable, Column  — tableau de donnees generique
 *   - Badge              — badge de statut (success, danger, warning, info, neutral)
 *   - CurrencyAmount     — affichage formate d'un montant en centimes
 *   - Button             — bouton (primary, secondary, danger, ghost)
 *   - Tabs, Tab          — navigation par onglets
 *   - Icons              — icones (lucide-react) : Home, Building2, Users, AlertTriangle, etc.
 *
 * Hook (import depuis '~/react/shared/hooks/useApi') :
 *   - useApi<T>(path)    — { data, loading, error } pour appeler les endpoints API
 *
 * Endpoints API disponibles :
 *   GET /api/stats           — KPIs globaux (taux d'occupation, impayes, etc.)
 *   GET /api/landlords       — Liste des proprietaires avec stats agregees
 *   GET /api/landlords/:id   — Detail d'un proprietaire (biens, baux, paiements, factures)
 *   GET /api/leases          — Liste de tous les baux avec statut et balance
 *   GET /api/leases/:id      — Detail d'un bail avec historique de paiements
 *   GET /api/properties      — Liste des biens avec info d'occupation
 *   GET /api/invoices        — Liste des factures fournisseurs
 *
 * Classes CSS du design system :
 *   Layout:     .page-header, .stats-grid, .stat-card, .card, .alert-banner
 *   Table:      .data-table (utilise le composant DataTable)
 *   Badge:      .badge .badge--success/danger/warning/info/neutral
 *   Boutons:    .btn .btn--primary/secondary/danger/ghost .btn--sm/lg
 *   Tabs:       .tabs .tabs__tab .tabs__tab--active
 *   Spacing:    .m-{0..24}, .p-{0..24}, .gap-{0..24}, .mx-auto, etc.
 *   Flex:       .d-flex, .align-items-center, .justify-content-between, .gap-3, etc.
 *   Typography: .font-size-{10..32}, .font-weight-{300..700}
 *   Colors:     .color-{grey/primary/success/danger/warning}-{shade}, .bg-{color}-{shade}
 *
 * =============================================================================
 */

export default function DashboardApp() {
  return (
    <div>
      <div className="page-header">
        <h1 className="page-header__title">Tableau de bord</h1>
        <p className="page-header__subtitle">TODO — Construis ta solution ici</p>
      </div>

      <div className="card">
        <div className="card__body" style={{ textAlign: 'center', padding: '4rem 2rem' }}>
          <p className="font-size-16 color-grey-400 mb-4">
            Ouvre ce fichier pour commencer
          </p>
          <code className="font-size-14 color-primary-600 bg-primary-25 p-2 radius-6">
            app/frontend/react/dashboard/App.tsx
          </code>
        </div>
      </div>
    </div>
  );
}
