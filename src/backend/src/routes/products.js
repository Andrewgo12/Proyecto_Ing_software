const express = require('express');
const productController = require('../controllers/productController');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/auth');
const validation = require('../middleware/validation');
const Joi = require('joi');

const router = express.Router();

// Validation schemas
const productSchema = Joi.object({
  sku: Joi.string().max(50).required(),
  name: Joi.string().max(255).required(),
  description: Joi.string().max(1000).optional(),
  category_id: Joi.string().uuid().required(),
  unit_price: Joi.number().positive().required(),
  cost_price: Joi.number().positive().required(),
  unit_of_measure: Joi.string().max(20).default('unidad'),
  barcode: Joi.string().max(100).optional(),
  min_stock_level: Joi.number().min(0).default(0),
  max_stock_level: Joi.number().min(0).optional(),
  reorder_point: Joi.number().min(0).optional(),
  is_active: Joi.boolean().default(true)
});

const updateProductSchema = productSchema.fork(['sku', 'name', 'category_id', 'unit_price', 'cost_price'], 
  (schema) => schema.optional()
);

// Apply authentication to all routes
router.use(authMiddleware);

// Public routes (all authenticated users)
router.get('/', productController.getProducts);
router.get('/search', productController.searchProducts);
router.get('/:id', productController.getProduct);
router.get('/:id/stock', productController.getProductStock);

// Protected routes (admin, manager, warehouse)
router.post('/',
  requireRole(['admin', 'manager']),
  validation(productSchema),
  productController.createProduct
);

router.put('/:id',
  requireRole(['admin', 'manager']),
  validation(updateProductSchema),
  productController.updateProduct
);

router.delete('/:id',
  requireRole(['admin']),
  productController.deleteProduct
);

module.exports = router;