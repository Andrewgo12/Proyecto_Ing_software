// Common validation patterns
export const VALIDATION_PATTERNS = {
  EMAIL: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
  PHONE: /^[\+]?[1-9][\d]{0,15}$/,
  SKU: /^[A-Z0-9\-_]{3,20}$/i,
  BARCODE: /^[0-9]{8,13}$/,
  CURRENCY: /^\d+(\.\d{1,2})?$/,
  POSITIVE_NUMBER: /^[1-9]\d*$/,
  DECIMAL: /^\d+(\.\d+)?$/
};

// Validation functions
export const validators = {
  // Required field validation
  required: (value, fieldName = 'Field') => {
    if (value === null || value === undefined || value === '') {
      return `${fieldName} is required`;
    }
    return null;
  },

  // Email validation
  email: (email) => {
    if (!email) return 'Email is required';
    if (!VALIDATION_PATTERNS.EMAIL.test(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  },

  // Password validation
  password: (password, minLength = 6) => {
    if (!password) return 'Password is required';
    if (password.length < minLength) {
      return `Password must be at least ${minLength} characters long`;
    }
    return null;
  },

  // SKU validation
  sku: (sku) => {
    if (!sku) return 'SKU is required';
    if (!VALIDATION_PATTERNS.SKU.test(sku)) {
      return 'SKU must contain only letters, numbers, hyphens, and underscores';
    }
    return null;
  },

  // Positive number validation
  positiveNumber: (value, fieldName = 'Value') => {
    if (value === null || value === undefined || value === '') {
      return `${fieldName} is required`;
    }
    const num = parseFloat(value);
    if (isNaN(num) || num <= 0) {
      return `${fieldName} must be a positive number`;
    }
    return null;
  },

  // Non-negative number validation
  nonNegativeNumber: (value, fieldName = 'Value') => {
    if (value === null || value === undefined || value === '') {
      return `${fieldName} is required`;
    }
    const num = parseFloat(value);
    if (isNaN(num) || num < 0) {
      return `${fieldName} must be a non-negative number`;
    }
    return null;
  },

  // String length validation
  stringLength: (value, minLength, maxLength, fieldName = 'Field') => {
    if (!value) return `${fieldName} is required`;
    if (value.length < minLength) {
      return `${fieldName} must be at least ${minLength} characters long`;
    }
    if (maxLength && value.length > maxLength) {
      return `${fieldName} must not exceed ${maxLength} characters`;
    }
    return null;
  },

  // Phone validation
  phone: (phone) => {
    if (!phone) return 'Phone number is required';
    if (!VALIDATION_PATTERNS.PHONE.test(phone)) {
      return 'Please enter a valid phone number';
    }
    return null;
  },

  // Barcode validation
  barcode: (barcode) => {
    if (!barcode) return null; // Optional field
    if (!VALIDATION_PATTERNS.BARCODE.test(barcode)) {
      return 'Barcode must be 8-13 digits';
    }
    return null;
  },

  // Date validation
  date: (date, fieldName = 'Date') => {
    if (!date) return `${fieldName} is required`;
    const dateObj = new Date(date);
    if (isNaN(dateObj.getTime())) {
      return `Please enter a valid ${fieldName.toLowerCase()}`;
    }
    return null;
  },

  // Future date validation
  futureDate: (date, fieldName = 'Date') => {
    const dateError = validators.date(date, fieldName);
    if (dateError) return dateError;
    
    const dateObj = new Date(date);
    const now = new Date();
    if (dateObj <= now) {
      return `${fieldName} must be in the future`;
    }
    return null;
  },

  // Past date validation
  pastDate: (date, fieldName = 'Date') => {
    const dateError = validators.date(date, fieldName);
    if (dateError) return dateError;
    
    const dateObj = new Date(date);
    const now = new Date();
    if (dateObj >= now) {
      return `${fieldName} must be in the past`;
    }
    return null;
  }
};

// Form validation helper
export const validateForm = (data, rules) => {
  const errors = {};
  
  Object.keys(rules).forEach(field => {
    const rule = rules[field];
    const value = data[field];
    
    if (typeof rule === 'function') {
      const error = rule(value);
      if (error) errors[field] = error;
    } else if (Array.isArray(rule)) {
      for (const validator of rule) {
        const error = validator(value);
        if (error) {
          errors[field] = error;
          break;
        }
      }
    }
  });
  
  return {
    isValid: Object.keys(errors).length === 0,
    errors
  };
};

// Sanitization functions
export const sanitizers = {
  // Remove HTML tags
  stripHtml: (str) => {
    if (!str) return '';
    return str.replace(/<[^>]*>/g, '');
  },

  // Trim whitespace
  trim: (str) => {
    if (!str) return '';
    return str.toString().trim();
  },

  // Normalize SKU
  normalizeSku: (sku) => {
    if (!sku) return '';
    return sku.toString().toUpperCase().trim();
  },

  // Normalize email
  normalizeEmail: (email) => {
    if (!email) return '';
    return email.toString().toLowerCase().trim();
  },

  // Remove non-numeric characters
  numbersOnly: (str) => {
    if (!str) return '';
    return str.toString().replace(/[^0-9]/g, '');
  },

  // Format currency
  formatCurrency: (value) => {
    if (!value) return '0';
    const num = parseFloat(value);
    return isNaN(num) ? '0' : num.toFixed(2);
  }
};