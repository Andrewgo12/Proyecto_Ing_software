import { VALIDATION } from './constants';

export const validators = {
  email: (email) => {
    if (!email) return 'Email es requerido';
    if (!VALIDATION.EMAIL_REGEX.test(email)) return 'Email inválido';
    return null;
  },

  password: (password) => {
    if (!password) return 'Contraseña es requerida';
    if (password.length < VALIDATION.PASSWORD_MIN_LENGTH) {
      return `Contraseña debe tener al menos ${VALIDATION.PASSWORD_MIN_LENGTH} caracteres`;
    }
    return null;
  },

  required: (value, fieldName = 'Campo') => {
    if (!value || (typeof value === 'string' && value.trim() === '')) {
      return `${fieldName} es requerido`;
    }
    return null;
  },

  sku: (sku) => {
    if (!sku) return 'SKU es requerido';
    if (sku.length > VALIDATION.SKU_MAX_LENGTH) {
      return `SKU no puede exceder ${VALIDATION.SKU_MAX_LENGTH} caracteres`;
    }
    return null;
  },

  productName: (name) => {
    if (!name) return 'Nombre es requerido';
    if (name.length > VALIDATION.PRODUCT_NAME_MAX_LENGTH) {
      return `Nombre no puede exceder ${VALIDATION.PRODUCT_NAME_MAX_LENGTH} caracteres`;
    }
    return null;
  },

  positiveNumber: (value, fieldName = 'Valor') => {
    if (value === null || value === undefined || value === '') {
      return `${fieldName} es requerido`;
    }
    const num = parseFloat(value);
    if (isNaN(num) || num < 0) {
      return `${fieldName} debe ser un número positivo`;
    }
    return null;
  },

  quantity: (quantity) => {
    return validators.positiveNumber(quantity, 'Cantidad');
  },

  price: (price) => {
    return validators.positiveNumber(price, 'Precio');
  }
};

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