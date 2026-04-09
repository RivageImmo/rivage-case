import React from 'react';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
}

export function Button({
  variant = 'primary',
  size = 'md',
  className = '',
  children,
  ...props
}: ButtonProps) {
  const sizeClass = size !== 'md' ? `btn--${size}` : '';
  return (
    <button className={`btn btn--${variant} ${sizeClass} ${className}`.trim()} {...props}>
      {children}
    </button>
  );
}
