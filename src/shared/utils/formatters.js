import { format, parseISO, formatDistanceToNow } from 'date-fns';
import { es } from 'date-fns/locale';

// Date formatters
export const dateFormatters = {
  // Format date to DD/MM/YYYY
  short: (date) => {
    if (!date) return '';
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    return format(dateObj, 'dd/MM/yyyy', { locale: es });
  },

  // Format date to DD de MMMM de YYYY
  long: (date) => {
    if (!date) return '';
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    return format(dateObj, "dd 'de' MMMM 'de' yyyy", { locale: es });
  },

  // Format date with time
  withTime: (date) => {
    if (!date) return '';
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    return format(dateObj, 'dd/MM/yyyy HH:mm', { locale: es });
  },

  // Format time only
  timeOnly: (date) => {
    if (!date) return '';
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    return format(dateObj, 'HH:mm', { locale: es });
  },

  // Relative time (hace 2 horas)
  relative: (date) => {
    if (!date) return '';
    const dateObj = typeof date === 'string' ? parseISO(date) : date;
    return formatDistanceToNow(dateObj, { addSuffix: true, locale: es });
  }
};

// Number formatters
export const numberFormatters = {
  // Format currency (Colombian Peso)
  currency: (amount, currency = 'COP') => {
    if (amount === null || amount === undefined) return '$0';
    
    return new Intl.NumberFormat('es-CO', {
      style: 'currency',
      currency,
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
    }).format(amount);
  },

  // Format number with thousands separator
  number: (number, decimals = 0) => {
    if (number === null || number === undefined) return '0';
    
    return new Intl.NumberFormat('es-CO', {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    }).format(number);
  },

  // Format percentage
  percentage: (value, decimals = 1) => {
    if (value === null || value === undefined) return '0%';
    
    return new Intl.NumberFormat('es-CO', {
      style: 'percent',
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
    }).format(value / 100);
  },

  // Format file size
  fileSize: (bytes) => {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
};

// Text formatters
export const textFormatters = {
  // Capitalize first letter
  capitalize: (str) => {
    if (!str) return '';
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
  },

  // Title case
  titleCase: (str) => {
    if (!str) return '';
    return str.replace(/\w\S*/g, (txt) => 
      txt.charAt(0).toUpperCase() + txt.substr(1).toLowerCase()
    );
  },

  // Truncate text
  truncate: (text, maxLength = 50, suffix = '...') => {
    if (!text || text.length <= maxLength) return text;
    return text.substring(0, maxLength) + suffix;
  },

  // Format phone number
  phone: (phone) => {
    if (!phone) return '';
    const cleaned = phone.replace(/\D/g, '');
    
    if (cleaned.length === 10) {
      return cleaned.replace(/(\d{3})(\d{3})(\d{4})/, '($1) $2-$3');
    }
    
    return phone;
  },

  // Format SKU
  sku: (sku) => {
    if (!sku) return '';
    return sku.toString().toUpperCase().trim();
  },

  // Format email
  email: (email) => {
    if (!email) return '';
    return email.toString().toLowerCase().trim();
  }
};

// Status formatters
export const statusFormatters = {
  // Format stock status
  stockStatus: (quantity, minLevel, maxLevel) => {
    if (quantity === 0) {
      return { text: 'Agotado', color: 'red', class: 'bg-red-100 text-red-800' };
    }
    
    if (quantity <= minLevel) {
      return { text: 'Stock Bajo', color: 'yellow', class: 'bg-yellow-100 text-yellow-800' };
    }
    
    if (maxLevel && quantity >= maxLevel) {
      return { text: 'Sobrestock', color: 'blue', class: 'bg-blue-100 text-blue-800' };
    }
    
    return { text: 'Normal', color: 'green', class: 'bg-green-100 text-green-800' };
  },

  // Format movement type
  movementType: (type) => {
    const types = {
      'IN': { text: 'Entrada', color: 'green', icon: '↑' },
      'OUT': { text: 'Salida', color: 'red', icon: '↓' },
      'TRANSFER_IN': { text: 'Transferencia Entrada', color: 'blue', icon: '→' },
      'TRANSFER_OUT': { text: 'Transferencia Salida', color: 'orange', icon: '←' },
      'ADJUSTMENT': { text: 'Ajuste', color: 'purple', icon: '⚖' },
      'RETURN': { text: 'Devolución', color: 'gray', icon: '↩' }
    };
    
    return types[type] || { text: type, color: 'gray', icon: '?' };
  },

  // Format user role
  userRole: (role) => {
    const roles = {
      'admin': 'Administrador',
      'manager': 'Gerente',
      'warehouse': 'Almacén',
      'sales': 'Ventas',
      'viewer': 'Visualizador'
    };
    
    return roles[role] || role;
  }
};

// Array formatters
export const arrayFormatters = {
  // Join array with commas and 'y'
  list: (array, conjunction = 'y') => {
    if (!array || array.length === 0) return '';
    if (array.length === 1) return array[0];
    if (array.length === 2) return array.join(` ${conjunction} `);
    
    const last = array.pop();
    return array.join(', ') + ` ${conjunction} ${last}`;
  },

  // Format tags
  tags: (tags, maxVisible = 3) => {
    if (!tags || tags.length === 0) return [];
    
    const visible = tags.slice(0, maxVisible);
    const remaining = tags.length - maxVisible;
    
    if (remaining > 0) {
      visible.push(`+${remaining} más`);
    }
    
    return visible;
  }
};

// Utility formatters
export const utilityFormatters = {
  // Format search highlight
  highlight: (text, searchTerm) => {
    if (!searchTerm) return text;
    
    const regex = new RegExp(`(${searchTerm})`, 'gi');
    return text.replace(regex, '<mark>$1</mark>');
  },

  // Format initials
  initials: (firstName, lastName) => {
    const first = firstName ? firstName.charAt(0).toUpperCase() : '';
    const last = lastName ? lastName.charAt(0).toUpperCase() : '';
    return first + last;
  },

  // Format full name
  fullName: (firstName, lastName) => {
    const parts = [firstName, lastName].filter(Boolean);
    return parts.join(' ');
  }
};