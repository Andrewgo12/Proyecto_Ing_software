const db = require('../utils/database');
const Product = require('../models/Product');
const StockLevel = require('../models/Inventory');
const InventoryMovement = require('../models/Movement');

class ReportService {
  static async generateInventoryReport(filters = {}, format = 'json') {
    let query = db('stock_levels as sl')
      .leftJoin('products as p', 'sl.product_id', 'p.id')
      .leftJoin('locations as l', 'sl.location_id', 'l.id')
      .leftJoin('categories as c', 'p.category_id', 'c.id')
      .select(
        'p.sku',
        'p.name as product_name',
        'c.name as category_name',
        'l.name as location_name',
        'sl.quantity',
        'sl.min_stock_level',
        'sl.max_stock_level',
        'p.unit_price',
        'p.cost_price',
        db.raw('(sl.quantity * p.unit_price) as total_value'),
        db.raw('(sl.quantity * p.cost_price) as total_cost')
      )
      .where('p.is_active', true);

    if (filters.location_id) {
      query = query.where('sl.location_id', filters.location_id);
    }

    if (filters.category_id) {
      query = query.where('p.category_id', filters.category_id);
    }

    const data = await query.orderBy('p.name');

    if (format === 'json') {
      return {
        report_type: 'inventory',
        generated_at: new Date(),
        filters,
        data,
        summary: {
          total_products: data.length,
          total_value: data.reduce((sum, item) => sum + parseFloat(item.total_value || 0), 0),
          total_cost: data.reduce((sum, item) => sum + parseFloat(item.total_cost || 0), 0)
        }
      };
    }

    // For other formats, you would implement CSV/Excel generation here
    return data;
  }

  static async generateMovementReport(filters = {}, format = 'json') {
    const movements = await InventoryMovement.findAll(filters);

    if (format === 'json') {
      return {
        report_type: 'movements',
        generated_at: new Date(),
        filters,
        ...movements
      };
    }

    return movements.data;
  }

  static async generateValuationReport(filters = {}, format = 'json') {
    const valuation = await StockLevel.getTotalValue(filters.location_id);

    const data = {
      report_type: 'valuation',
      generated_at: new Date(),
      method: filters.method || 'FIFO',
      location_id: filters.location_id,
      valuation
    };

    return format === 'json' ? data : valuation;
  }

  static async getDashboardMetrics(locationId = null) {
    const [
      stockStats,
      movementStats,
      lowStockCount,
      outOfStockCount
    ] = await Promise.all([
      StockLevel.getTotalValue(locationId),
      InventoryMovement.getMovementStats({ 
        date_from: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        location_id: locationId 
      }),
      StockLevel.getLowStock(locationId).then(items => items.length),
      StockLevel.getOutOfStock(locationId).then(items => items.length)
    ]);

    return {
      inventory: {
        total_value: parseFloat(stockStats.total_value || 0),
        total_cost: parseFloat(stockStats.total_cost || 0),
        total_products: parseInt(stockStats.total_products || 0),
        total_quantity: parseInt(stockStats.total_quantity || 0)
      },
      movements: {
        total_movements: parseInt(movementStats.total_movements || 0),
        inbound_movements: parseInt(movementStats.inbound_movements || 0),
        outbound_movements: parseInt(movementStats.outbound_movements || 0),
        adjustments: parseInt(movementStats.adjustments || 0)
      },
      alerts: {
        low_stock_count: lowStockCount,
        out_of_stock_count: outOfStockCount
      }
    };
  }

  static async getProductPerformance(options = {}) {
    const { days = 30, limit = 10, location_id } = options;
    
    return await InventoryMovement.getTopMovedProducts(days, limit, location_id);
  }

  static async getStockTrends(options = {}) {
    const { product_id, location_id, days = 30 } = options;
    
    if (product_id && location_id) {
      return await StockLevel.getStockHistory(product_id, location_id, days);
    }

    return await InventoryMovement.getDailyMovements(days, location_id);
  }
}

module.exports = ReportService;