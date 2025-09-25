const InventoryMovement = require('../models/Movement');
const StockLevel = require('../models/Inventory');
const logger = require('../utils/logger');

class InventoryController {
  async getStock(req, res, next) {
    try {
      const { location_id, product_id, low_stock } = req.query;
      
      const filters = {};
      if (location_id) filters.location_id = location_id;
      if (product_id) filters.product_id = product_id;
      if (low_stock === 'true') filters.low_stock = true;

      const stockLevels = await StockLevel.findAll(filters);

      res.json({
        success: true,
        data: stockLevels
      });
    } catch (error) {
      next(error);
    }
  }

  async getMovements(req, res, next) {
    try {
      const { page = 1, limit = 20, product_id, location_id, type, date_from, date_to } = req.query;
      
      const filters = {
        page: parseInt(page),
        limit: parseInt(limit)
      };
      
      if (product_id) filters.product_id = product_id;
      if (location_id) filters.location_id = location_id;
      if (type) filters.movement_type = type;
      if (date_from) filters.date_from = date_from;
      if (date_to) filters.date_to = date_to;

      const movements = await InventoryMovement.findAll(filters);

      res.json({
        success: true,
        data: movements.data,
        pagination: movements.pagination
      });
    } catch (error) {
      next(error);
    }
  }

  async createMovement(req, res, next) {
    try {
      const movementData = {
        ...req.body,
        user_id: req.user.userId
      };

      // Validate stock for outbound movements
      if (['OUT', 'TRANSFER'].includes(movementData.movement_type)) {
        const currentStock = await StockLevel.getByProductAndLocation(
          movementData.product_id, 
          movementData.location_id
        );
        
        if (!currentStock || currentStock.quantity < movementData.quantity) {
          return res.status(400).json({ 
            message: 'Insufficient stock for this operation' 
          });
        }
      }

      const movement = await InventoryMovement.create(movementData);
      
      // Update stock levels
      await StockLevel.updateStock(
        movementData.product_id,
        movementData.location_id,
        movementData.quantity,
        movementData.movement_type
      );

      logger.info(`Movement created: ${movement.id} by user ${req.user.email}`);

      res.status(201).json({
        success: true,
        data: movement,
        message: 'Movement registered successfully'
      });
    } catch (error) {
      next(error);
    }
  }

  async adjustStock(req, res, next) {
    try {
      const { product_id, location_id, new_quantity, reason } = req.body;

      const currentStock = await StockLevel.getByProductAndLocation(product_id, location_id);
      if (!currentStock) {
        return res.status(404).json({ message: 'Stock level not found' });
      }

      const adjustment = new_quantity - currentStock.quantity;
      
      // Create adjustment movement
      const movement = await InventoryMovement.create({
        product_id,
        location_id,
        movement_type: 'ADJUSTMENT',
        quantity: Math.abs(adjustment),
        direction: adjustment > 0 ? 'IN' : 'OUT',
        reason,
        user_id: req.user.userId
      });

      // Update stock level
      await StockLevel.update(currentStock.id, { quantity: new_quantity });

      logger.info(`Stock adjusted: Product ${product_id} at location ${location_id} by user ${req.user.email}`);

      res.json({
        success: true,
        data: { movement, new_quantity },
        message: 'Stock adjusted successfully'
      });
    } catch (error) {
      next(error);
    }
  }

  async transferStock(req, res, next) {
    try {
      const { product_id, from_location_id, to_location_id, quantity, notes } = req.body;

      // Validate source stock
      const sourceStock = await StockLevel.getByProductAndLocation(product_id, from_location_id);
      if (!sourceStock || sourceStock.quantity < quantity) {
        return res.status(400).json({ message: 'Insufficient stock at source location' });
      }

      // Create outbound movement
      const outMovement = await InventoryMovement.create({
        product_id,
        location_id: from_location_id,
        movement_type: 'TRANSFER_OUT',
        quantity,
        destination_location_id: to_location_id,
        notes,
        user_id: req.user.userId
      });

      // Create inbound movement
      const inMovement = await InventoryMovement.create({
        product_id,
        location_id: to_location_id,
        movement_type: 'TRANSFER_IN',
        quantity,
        source_location_id: from_location_id,
        notes,
        reference_movement_id: outMovement.id,
        user_id: req.user.userId
      });

      // Update stock levels
      await StockLevel.updateStock(product_id, from_location_id, -quantity, 'OUT');
      await StockLevel.updateStock(product_id, to_location_id, quantity, 'IN');

      logger.info(`Stock transferred: Product ${product_id} from ${from_location_id} to ${to_location_id} by user ${req.user.email}`);

      res.json({
        success: true,
        data: { outMovement, inMovement },
        message: 'Stock transferred successfully'
      });
    } catch (error) {
      next(error);
    }
  }

  async getLowStockAlerts(req, res, next) {
    try {
      const { location_id } = req.query;
      const lowStockItems = await StockLevel.getLowStock(location_id);

      res.json({
        success: true,
        data: lowStockItems
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new InventoryController();