// User roles
export const USER_ROLES = {
  ADMIN: 'admin',
  MANAGER: 'manager',
  WAREHOUSE: 'warehouse',
  SALES: 'sales',
  VIEWER: 'viewer'
};

// User permissions
export const USER_PERMISSIONS = {
  // Products
  CREATE_PRODUCT: 'create_product',
  UPDATE_PRODUCT: 'update_product',
  DELETE_PRODUCT: 'delete_product',
  VIEW_PRODUCT: 'view_product',
  
  // Inventory
  CREATE_MOVEMENT: 'create_movement',
  ADJUST_STOCK: 'adjust_stock',
  TRANSFER_STOCK: 'transfer_stock',
  VIEW_STOCK: 'view_stock',
  
  // Reports
  GENERATE_REPORTS: 'generate_reports',
  VIEW_ANALYTICS: 'view_analytics',
  EXPORT_DATA: 'export_data',
  
  // Users
  MANAGE_USERS: 'manage_users',
  VIEW_USERS: 'view_users',
  
  // System
  SYSTEM_CONFIG: 'system_config',
  VIEW_LOGS: 'view_logs'
};

// Role permissions mapping
export const ROLE_PERMISSIONS = {
  [USER_ROLES.ADMIN]: Object.values(USER_PERMISSIONS),
  
  [USER_ROLES.MANAGER]: [
    USER_PERMISSIONS.CREATE_PRODUCT,
    USER_PERMISSIONS.UPDATE_PRODUCT,
    USER_PERMISSIONS.VIEW_PRODUCT,
    USER_PERMISSIONS.CREATE_MOVEMENT,
    USER_PERMISSIONS.ADJUST_STOCK,
    USER_PERMISSIONS.TRANSFER_STOCK,
    USER_PERMISSIONS.VIEW_STOCK,
    USER_PERMISSIONS.GENERATE_REPORTS,
    USER_PERMISSIONS.VIEW_ANALYTICS,
    USER_PERMISSIONS.EXPORT_DATA,
    USER_PERMISSIONS.VIEW_USERS
  ],
  
  [USER_ROLES.WAREHOUSE]: [
    USER_PERMISSIONS.VIEW_PRODUCT,
    USER_PERMISSIONS.CREATE_MOVEMENT,
    USER_PERMISSIONS.TRANSFER_STOCK,
    USER_PERMISSIONS.VIEW_STOCK
  ],
  
  [USER_ROLES.SALES]: [
    USER_PERMISSIONS.VIEW_PRODUCT,
    USER_PERMISSIONS.VIEW_STOCK,
    USER_PERMISSIONS.CREATE_MOVEMENT
  ],
  
  [USER_ROLES.VIEWER]: [
    USER_PERMISSIONS.VIEW_PRODUCT,
    USER_PERMISSIONS.VIEW_STOCK
  ]
};

// User status
export const USER_STATUS = {
  ACTIVE: 'active',
  INACTIVE: 'inactive',
  SUSPENDED: 'suspended'
};