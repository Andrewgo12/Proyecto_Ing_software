// Movement types
export const MOVEMENT_TYPES = {
  IN: 'IN',
  OUT: 'OUT',
  TRANSFER_IN: 'TRANSFER_IN',
  TRANSFER_OUT: 'TRANSFER_OUT',
  ADJUSTMENT: 'ADJUSTMENT',
  RETURN: 'RETURN',
  DAMAGE: 'DAMAGE',
  EXPIRED: 'EXPIRED'
};

// Stock status
export const STOCK_STATUS = {
  NORMAL: 'normal',
  LOW: 'low',
  OUT: 'out',
  OVERSTOCK: 'overstock',
  CRITICAL: 'critical'
};

// Movement reasons
export const MOVEMENT_REASONS = {
  PURCHASE: 'purchase',
  SALE: 'sale',
  TRANSFER: 'transfer',
  ADJUSTMENT: 'adjustment',
  RETURN: 'return',
  DAMAGE: 'damage',
  EXPIRED: 'expired',
  THEFT: 'theft',
  LOST: 'lost',
  FOUND: 'found'
};

// Alert types
export const ALERT_TYPES = {
  LOW_STOCK: 'low_stock',
  OUT_OF_STOCK: 'out_of_stock',
  OVERSTOCK: 'overstock',
  EXPIRING_SOON: 'expiring_soon',
  EXPIRED: 'expired',
  MOVEMENT_ANOMALY: 'movement_anomaly'
};

// Alert priorities
export const ALERT_PRIORITIES = {
  LOW: 'low',
  MEDIUM: 'medium',
  HIGH: 'high',
  CRITICAL: 'critical'
};

// Location types
export const LOCATION_TYPES = {
  WAREHOUSE: 'warehouse',
  STORE: 'store',
  OFFICE: 'office',
  VEHICLE: 'vehicle',
  EXTERNAL: 'external'
};

// Unit of measure
export const UNITS_OF_MEASURE = {
  PIECE: 'piece',
  KG: 'kg',
  GRAM: 'gram',
  LITER: 'liter',
  ML: 'ml',
  METER: 'meter',
  CM: 'cm',
  BOX: 'box',
  PACK: 'pack',
  DOZEN: 'dozen'
};