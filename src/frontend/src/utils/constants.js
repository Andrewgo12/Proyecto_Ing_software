// API Configuration
export const API_CONFIG = {
  BASE_URL: import.meta.env.VITE_API_URL || 'http://localhost:3001/api',
  TIMEOUT: 10000,
};

// User Roles
export const USER_ROLES = {
  ADMIN: 'admin',
  MANAGER: 'manager',
  WAREHOUSE: 'warehouse',
  SALES: 'sales',
  VIEWER: 'viewer',
};

// Movement Types
export const MOVEMENT_TYPES = {
  IN: 'IN',
  OUT: 'OUT',
  TRANSFER: 'TRANSFER',
  ADJUSTMENT: 'ADJUSTMENT',
};

// Stock Status
export const STOCK_STATUS = {
  NORMAL: 'normal',
  LOW: 'low',
  OUT: 'out',
  OVERSTOCK: 'overstock',
};

// Report Types
export const REPORT_TYPES = {
  INVENTORY: 'inventory',
  MOVEMENTS: 'movements',
  VALUATION: 'valuation',
};

// Pagination
export const PAGINATION = {
  DEFAULT_PAGE_SIZE: 10,
  PAGE_SIZE_OPTIONS: [10, 25, 50, 100],
};

// Date Formats
export const DATE_FORMATS = {
  DISPLAY: 'dd/MM/yyyy',
  API: 'yyyy-MM-dd',
  DATETIME: 'dd/MM/yyyy HH:mm',
};

// Status Colors
export const STATUS_COLORS = {
  success: 'bg-green-100 text-green-800',
  warning: 'bg-yellow-100 text-yellow-800',
  error: 'bg-red-100 text-red-800',
  info: 'bg-blue-100 text-blue-800',
};

// Local Storage Keys
export const STORAGE_KEYS = {
  ACCESS_TOKEN: 'accessToken',
  REFRESH_TOKEN: 'refreshToken',
  USER: 'user',
  THEME: 'theme',
};

// Validation Rules
export const VALIDATION = {
  EMAIL_REGEX: /^\S+@\S+$/i,
  PASSWORD_MIN_LENGTH: 6,
  SKU_MAX_LENGTH: 50,
  PRODUCT_NAME_MAX_LENGTH: 255,
};