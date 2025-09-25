// Application configuration
export const APP_CONFIG = {
  NAME: 'Inventario PYMES',
  VERSION: '1.0.0',
  DESCRIPTION: 'Sistema de gestión de inventario para pequeñas y medianas empresas',
  AUTHOR: 'Inventario PYMES Team',
  SUPPORT_EMAIL: 'soporte@inventariopymes.com',
  WEBSITE: 'https://inventariopymes.com'
};

// Environment types
export const ENVIRONMENTS = {
  DEVELOPMENT: 'development',
  STAGING: 'staging',
  PRODUCTION: 'production',
  TEST: 'test'
};

// Supported languages
export const LANGUAGES = {
  ES: 'es',
  EN: 'en',
  PT: 'pt'
};

// Date and time formats
export const DATE_FORMATS = {
  SHORT: 'DD/MM/YYYY',
  LONG: 'DD [de] MMMM [de] YYYY',
  WITH_TIME: 'DD/MM/YYYY HH:mm',
  TIME_ONLY: 'HH:mm',
  ISO: 'YYYY-MM-DD',
  MONTH_YEAR: 'MM/YYYY'
};

// Currency settings
export const CURRENCY = {
  DEFAULT: 'COP',
  SYMBOL: '$',
  DECIMAL_PLACES: 0,
  THOUSANDS_SEPARATOR: ',',
  DECIMAL_SEPARATOR: '.'
};

// File upload limits
export const FILE_LIMITS = {
  MAX_SIZE: 5 * 1024 * 1024, // 5MB
  ALLOWED_TYPES: ['image/jpeg', 'image/png', 'image/gif', 'application/pdf'],
  MAX_FILES: 10
};

// Cache settings
export const CACHE = {
  DEFAULT_TTL: 3600, // 1 hour
  LONG_TTL: 86400, // 24 hours
  SHORT_TTL: 300, // 5 minutes
  KEYS: {
    USER_PROFILE: 'user_profile',
    DASHBOARD_METRICS: 'dashboard_metrics',
    PRODUCT_LIST: 'product_list',
    STOCK_LEVELS: 'stock_levels'
  }
};

// Notification settings
export const NOTIFICATIONS = {
  TYPES: {
    INFO: 'info',
    SUCCESS: 'success',
    WARNING: 'warning',
    ERROR: 'error'
  },
  DURATION: {
    SHORT: 3000,
    MEDIUM: 5000,
    LONG: 8000,
    PERSISTENT: 0
  }
};

// Theme settings
export const THEME = {
  COLORS: {
    PRIMARY: '#2196F3',
    SECONDARY: '#FFC107',
    SUCCESS: '#4CAF50',
    WARNING: '#FF9800',
    ERROR: '#F44336',
    INFO: '#2196F3',
    LIGHT: '#F5F5F5',
    DARK: '#212121'
  },
  BREAKPOINTS: {
    XS: 0,
    SM: 576,
    MD: 768,
    LG: 992,
    XL: 1200
  }
};

// Feature flags
export const FEATURES = {
  BARCODE_SCANNER: true,
  MULTI_LOCATION: true,
  ADVANCED_REPORTS: true,
  MOBILE_APP: true,
  NOTIFICATIONS: true,
  BULK_OPERATIONS: true,
  API_INTEGRATIONS: true
};

// System limits
export const LIMITS = {
  MAX_PRODUCTS: 10000,
  MAX_LOCATIONS: 50,
  MAX_USERS: 100,
  MAX_CATEGORIES: 500,
  MAX_SUPPLIERS: 200,
  BULK_OPERATION_SIZE: 1000
};