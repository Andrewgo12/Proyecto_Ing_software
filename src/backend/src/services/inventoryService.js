const StockLevel = require('../models/Inventory');
const InventoryMovement = require('../models/Movement');
const logger = require('../utils/logger');

class InventoryService {
  static async processMovement(movementData) {
    const { product_id, location_id, movement_type, quantity } = movementData;

    // Validate stock for outbound movements
    if (['OUT', 'TRANSFER_OUT'].includes(movement_type)) {
      const currentStock = await StockLevel.getByProductAndLocation(product_id, location_id);
      if (!currentStock || currentStock.quantity < quantity) {
        throw new Error('Insufficient stock for this operation');
      }
    }

    // Create movement record
    const movement = await InventoryMovement.create(movementData);

    // Update stock levels
    const direction = ['IN', 'TRANSFER_IN'].includes(movement_type) ? 'IN' : 'OUT';
    await StockLevel.updateStock(product_id, location_id, quantity, direction);

    // Check for low stock alerts
    await this.checkLowStockAlerts(product_id, location_id);

    return movement;
  }

  static async checkLowStockAlerts(productId, locationId) {
    const stockLevel = await StockLevel.getByProductAndLocation(productId, locationId);
    
    if (stockLevel && stockLevel.quantity <= stockLevel.min_stock_level) {
      logger.warn(`Low stock alert: Product ${productId} at location ${locationId}`, {
        current_stock: stockLevel.quantity,
        min_stock: stockLevel.min_stock_level
      });
      
      // Here you could trigger notifications, emails, etc.
      // await NotificationService.sendLowStockAlert(stockLevel);
    }
  }

  static async calculateStockValue(locationId = null) {
    return await StockLevel.getTotalValue(locationId);
  }

  static async getStockMovementSummary(filters = {}) {
    const movements = await InventoryMovement.findAll(filters);
    
    const summary = {
      total_movements: movements.data.length,
      inbound_quantity: 0,
      outbound_quantity: 0,
      adjustments: 0
    };

    movements.data.forEach(movement => {
      if (['IN', 'TRANSFER_IN'].includes(movement.movement_type)) {
        summary.inbound_quantity += movement.quantity;
      } else if (['OUT', 'TRANSFER_OUT'].includes(movement.movement_type)) {
        summary.outbound_quantity += movement.quantity;
      } else if (movement.movement_type === 'ADJUSTMENT') {
        summary.adjustments += 1;
      }
    });

    return summary;
  }

  static async optimizeStockLevels(locationId) {
    // Get products with movement history
    const products = await InventoryMovement.getTopMovedProducts(90, 50, locationId);
    
    const recommendations = [];
    
    for (const product of products) {
      const avgMovement = product.total_quantity / 90; // Daily average
      const recommendedMin = Math.ceil(avgMovement * 7); // 1 week buffer
      const recommendedMax = Math.ceil(avgMovement * 30); // 1 month max
      
      recommendations.push({
        product_id: product.id,
        product_name: product.product_name,
        current_min: product.min_stock_level,
        current_max: product.max_stock_level,
        recommended_min: recommendedMin,
        recommended_max: recommendedMax,
        avg_daily_movement: avgMovement
      });
    }
    
    return recommendations;
  }
}

module.exports = InventoryService;