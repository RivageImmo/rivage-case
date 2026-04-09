import React from 'react';
import { createRoot } from 'react-dom/client';
import '~/design_system/main.scss';
import DashboardApp from '~/react/dashboard/App';

document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('dashboard-app');
  if (container) {
    const root = createRoot(container);
    root.render(
      <React.StrictMode>
        <DashboardApp />
      </React.StrictMode>
    );
  }
});
