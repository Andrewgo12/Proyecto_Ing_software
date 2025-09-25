// API Endpoints
export const API_ENDPOINTS = {
  // Auth
  LOGIN: '/auth/login',
  LOGOUT: '/auth/logout',
  REFRESH: '/auth/refresh',
  PROFILE: '/auth/profile',
  REGISTER: '/auth/register',
  
  // Products
  PRODUCTS: '/products',
  PRODUCT_BY_ID: (id) => `/products/${id}`,
  PRODUCT_SEARCH: '/products/search',
  PRODUCT_STOCK: (id) => `/products/${id}/stock`,
  
  // Inventory
  STOCK: '/inventory/stock',
  LOW_STOCK: '/inventory/stock/low',
  MOVEMENTS: '/inventory/movements',
  ADJUST_STOCK: '/inventory/adjust',
  TRANSFER_STOCK: '/inventory/transfer',
  
  // Reports
  DASHBOARD_METRICS: '/reports/dashboard',
  INVENTORY_REPORT: '/reports/inventory',
  MOVEMENT_REPORT: '/reports/movements',
  VALUATION_REPORT: '/reports/valuation',
  PRODUCT_PERFORMANCE: '/reports/product-performance',
  STOCK_TRENDS: '/reports/stock-trends',
  
  // Categories
  CATEGORIES: '/categories',
  CATEGORY_BY_ID: (id) => `/categories/${id}`,
  
  // Locations
  LOCATIONS: '/locations',
  LOCATION_BY_ID: (id) => `/locations/${id}`,
  
  // Users
  USERS: '/users',
  USER_BY_ID: (id) => `/users/${id}`,
  
  // Suppliers
  SUPPLIERS: '/suppliers',
  SUPPLIER_BY_ID: (id) => `/suppliers/${id}`
};

// HTTP Status Codes
export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  NO_CONTENT: 204,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  UNPROCESSABLE_ENTITY: 422,
  INTERNAL_SERVER_ERROR: 500,
  SERVICE_UNAVAILABLE: 503
};

// Request timeouts (in milliseconds)
export const TIMEOUTS = {
  DEFAULT: 10000,
  UPLOAD: 30000,
  REPORT: 60000,
  LONG_RUNNING: 120000
};

// Pagination defaults
export const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_LIMIT: 10,
  MAX_LIMIT: 100,
  PAGE_SIZE_OPTIONS: [10, 25, 50, 100]
};

// Content types
export const CONTENT_TYPES = {
  JSON: 'application/json',
  FORM_DATA: 'multipart/form-data',
  URL_ENCODED: 'application/x-www-form-urlencoded',
  TEXT: 'text/plain',
  CSV: 'text/csv',
  EXCEL: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  PDF: 'application/pdf'
};