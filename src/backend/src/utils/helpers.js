const crypto = require('crypto');

const helpers = {
  // Generate unique SKU
  generateSKU: (prefix = 'PROD', length = 6) => {
    const timestamp = Date.now().toString().slice(-4);
    const random = Math.random().toString(36).substring(2, length - 2).toUpperCase();
    return `${prefix}-${timestamp}${random}`;
  },

  // Format currency
  formatCurrency: (amount, currency = 'COP') => {
    return new Intl.NumberFormat('es-CO', {
      style: 'currency',
      currency,
      minimumFractionDigits: 0
    }).format(amount);
  },

  // Generate hash
  generateHash: (data) => {
    return crypto.createHash('sha256').update(data).digest('hex');
  },

  // Paginate results
  paginate: (query, page = 1, limit = 10) => {
    const offset = (page - 1) * limit;
    return {
      ...query,
      limit: parseInt(limit),
      offset: parseInt(offset)
    };
  },

  // Calculate pagination info
  getPaginationInfo: (total, page, limit) => {
    return {
      page: parseInt(page),
      limit: parseInt(limit),
      total: parseInt(total),
      pages: Math.ceil(total / limit),
      hasNext: page < Math.ceil(total / limit),
      hasPrev: page > 1
    };
  },

  // Sanitize string
  sanitizeString: (str) => {
    if (!str) return '';
    return str.toString().trim().replace(/[<>]/g, '');
  },

  // Generate reference number
  generateReference: (prefix = 'REF') => {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substring(2, 8).toUpperCase();
    return `${prefix}-${timestamp}-${random}`;
  },

  // Calculate percentage
  calculatePercentage: (value, total) => {
    if (total === 0) return 0;
    return Math.round((value / total) * 100 * 100) / 100;
  },

  // Deep clone object
  deepClone: (obj) => {
    return JSON.parse(JSON.stringify(obj));
  },

  // Remove null/undefined values
  removeEmpty: (obj) => {
    return Object.fromEntries(
      Object.entries(obj).filter(([_, v]) => v != null && v !== '')
    );
  },

  // Delay execution
  delay: (ms) => {
    return new Promise(resolve => setTimeout(resolve, ms));
  },

  // Retry function
  retry: async (fn, maxAttempts = 3, delayMs = 1000) => {
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } catch (error) {
        if (attempt === maxAttempts) throw error;
        await helpers.delay(delayMs * attempt);
      }
    }
  },

  // Validate email
  isValidEmail: (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  },

  // Generate random string
  randomString: (length = 8) => {
    return crypto.randomBytes(length).toString('hex').substring(0, length);
  }
};

module.exports = helpers;