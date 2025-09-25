import { Loader2 } from 'lucide-react';
import { clsx } from 'clsx';

const LoadingSpinner = ({ size = 'md', className = '' }) => {
  const sizeClasses = {
    sm: 'w-4 h-4',
    md: 'w-6 h-6',
    lg: 'w-8 h-8',
    xl: 'w-12 h-12'
  };

  return (
    <Loader2 
      className={clsx(
        'animate-spin text-blue-600',
        sizeClasses[size],
        className
      )} 
    />
  );
};

export default LoadingSpinner;