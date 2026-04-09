import React from 'react';

type Variant = 'success' | 'danger' | 'warning' | 'info' | 'neutral';

interface BadgeProps {
  variant: Variant;
  children: React.ReactNode;
  dot?: boolean;
}

export function Badge({ variant, children, dot = true }: BadgeProps) {
  return (
    <span className={`badge badge--${variant}`}>
      {dot && <span className="badge__dot" />}
      {children}
    </span>
  );
}
