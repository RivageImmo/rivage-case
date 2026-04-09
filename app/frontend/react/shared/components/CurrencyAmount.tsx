import React from 'react';

interface CurrencyAmountProps {
  cents: number;
  colored?: boolean;
  className?: string;
}

export function CurrencyAmount({ cents, colored = false, className = '' }: CurrencyAmountProps) {
  const amount = cents / 100;
  const formatted = new Intl.NumberFormat('fr-FR', {
    style: 'currency',
    currency: 'EUR',
  }).format(amount);

  let colorClass = '';
  if (colored) {
    if (cents > 0) colorClass = 'color-success-600';
    else if (cents < 0) colorClass = 'color-danger-600';
  }

  return <span className={`${colorClass} ${className}`.trim()}>{formatted}</span>;
}
