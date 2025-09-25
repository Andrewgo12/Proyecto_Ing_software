const express = require('express');
const reportController = require('../controllers/reportController');
const authMiddleware = require('../middleware/auth');
const { requireRole } = require('../middleware/auth');

const router = express.Router();

// Apply authentication to all routes
router.use(authMiddleware);

// Dashboard metrics (all authenticated users)
router.get('/dashboard', reportController.getDashboardMetrics);

// Report routes (manager and admin only)
router.get('/inventory',
  requireRole(['admin', 'manager']),
  reportController.generateInventoryReport
);

router.get('/movements',
  requireRole(['admin', 'manager']),
  reportController.generateMovementReport
);

router.get('/valuation',
  requireRole(['admin', 'manager']),
  reportController.generateValuationReport
);

// Analytics routes
router.get('/product-performance',
  requireRole(['admin', 'manager']),
  reportController.getProductPerformance
);

router.get('/stock-trends',
  requireRole(['admin', 'manager']),
  reportController.getStockTrends
);

module.exports = router;