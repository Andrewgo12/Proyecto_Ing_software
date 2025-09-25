const express = require('express');
const inventoryController = require('../controllers/inventoryController');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/auth');
const validation = require('../middleware/validation');
const Joi = require('joi');

const router = express.Router();

// Validation schemas
const movementSchema = Joi.object({
  product_id: Joi.string().uuid().required(),
  location_id: Joi.string().uuid().required(),
  movement_type: Joi.string().valid('IN', 'OUT', 'TRANSFER', 'ADJUSTMENT').required(),
  quantity: Joi.number().positive().required(),
  unit_cost: Joi.number().positive().optional(),
  reference_number: Joi.string().max(100).optional(),
  notes: Joi.string().max(500).optional(),
  destination_location_id: Joi.string().uuid().optional()
});

const adjustmentSchema = Joi.object({
  product_id: Joi.string().uuid().required(),
  location_id: Joi.string().uuid().required(),
  new_quantity: Joi.number().min(0).required(),
  reason: Joi.string().max(200).required()
});

const transferSchema = Joi.object({
  product_id: Joi.string().uuid().required(),
  from_location_id: Joi.string().uuid().required(),
  to_location_id: Joi.string().uuid().required(),
  quantity: Joi.number().positive().required(),
  notes: Joi.string().max(500).optional()
});

// Apply authentication to all routes
router.use(authMiddleware);

// Stock level routes
router.get('/stock', inventoryController.getStock);
router.get('/stock/low', inventoryController.getLowStockAlerts);

// Movement routes
router.get('/movements', inventoryController.getMovements);
router.post('/movements', 
  requireRole(['admin', 'manager', 'warehouse']),
  validation(movementSchema),
  inventoryController.createMovement
);

// Stock adjustment routes
router.post('/adjust',
  requireRole(['admin', 'manager']),
  validation(adjustmentSchema),
  inventoryController.adjustStock
);

// Transfer routes
router.post('/transfer',
  requireRole(['admin', 'manager', 'warehouse']),
  validation(transferSchema),
  inventoryController.transferStock
);

module.exports = router;