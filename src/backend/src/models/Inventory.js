const db = require('../utils/database');

class StockLevel {
  static async findAll(filters = {}) {
    let query = db('stock_levels as sl')
      .leftJoin('products as p', 'sl.product_id', 'p.id')
      .leftJoin('locations as l', 'sl.location_id', 'l.id')
      .select(
        'sl.*',
        'p.name as product_name',
        'p.sku as product_sku',
        'l.name as location_name',
        'l.code as location_code'
      );

    if (filters.product_id) {
      query = query.where('sl.product_id', filters.product_id);
    }

    if (filters.location_id) {
      query = query.where('sl.location_id', filters.location_id);
    }

    if (filters.low_stock) {
      query = query.whereRaw('sl.quantity <= sl.min_stock_level');
    }

    return await query.orderBy('p.name');
  }

  static async getByProductAndLocation(productId, locationId) {
    return await db('stock_levels')
      .where('product_id', productId)
      .andWhere('location_id', locationId)
      .first();
  }

  static async create(stockData) {
    const [stockLevel] = await db('stock_levels')
      .insert({
        ...stockData,
        created_at: new Date(),
        updated_at: new Date()
      })
      .returning('*');
    
    return stockLevel;
  }

  static async update(id, updateData) {
    const [stockLevel] = await db('stock_levels')
      .where('id', id)
      .update({
        ...updateData,
        updated_at: new Date()
      })
      .returning('*');
    
    return stockLevel;
  }

  static async updateStock(productId, locationId, quantity, movementType) {
    const stockLevel = await this.getByProductAndLocation(productId, locationId);
    
    if (!stockLevel) {
      // Create new stock level if it doesn't exist
      return await this.create({
        product_id: productId,
        location_id: locationId,
        quantity: movementType === 'IN' ? quantity : 0,
        min_stock_level: 0,
        max_stock_level: null
      });
    }

    const newQuantity = movementType === 'IN' 
      ? stockLevel.quantity + quantity 
      : stockLevel.quantity - quantity;

    return await this.update(stockLevel.id, { 
      quantity: Math.max(0, newQuantity) 
    });
  }

  static async getLowStock(locationId = null) {
    let query = db('stock_levels as sl')
      .leftJoin('products as p', 'sl.product_id', 'p.id')
      .leftJoin('locations as l', 'sl.location_id', 'l.id')
      .select(
        'sl.*',
        'p.name as product_name',
        'p.sku as product_sku',
        'l.name as location_name'
      )
      .whereRaw('sl.quantity <= sl.min_stock_level')
      .andWhere('p.is_active', true);

    if (locationId) {
      query = query.where('sl.location_id', locationId);
    }

    return await query.orderBy('sl.quantity');
  }

  static async getOutOfStock(locationId = null) {
    let query = db('stock_levels as sl')
      .leftJoin('products as p', 'sl.product_id', 'p.id')
      .leftJoin('locations as l', 'sl.location_id', 'l.id')
      .select(
        'sl.*',
        'p.name as product_name',
        'p.sku as product_sku',
        'l.name as location_name'
      )
      .where('sl.quantity', 0)
      .andWhere('p.is_active', true);

    if (locationId) {
      query = query.where('sl.location_id', locationId);
    }

    return await query.orderBy('p.name');
  }

  static async getTotalValue(locationId = null) {
    let query = db('stock_levels as sl')
      .leftJoin('products as p', 'sl.product_id', 'p.id')
      .select(
        db.raw('SUM(sl.quantity * p.unit_price) as total_value'),
        db.raw('SUM(sl.quantity * p.cost_price) as total_cost'),
        db.raw('COUNT(DISTINCT sl.product_id) as total_products'),
        db.raw('SUM(sl.quantity) as total_quantity')
      )
      .where('p.is_active', true);

    if (locationId) {
      query = query.where('sl.location_id', locationId);
    }

    return await query.first();
  }

  static async getStockHistory(productId, locationId, days = 30) {
    return await db('inventory_movements as im')
      .leftJoin('products as p', 'im.product_id', 'p.id')
      .leftJoin('locations as l', 'im.location_id', 'l.id')
      .select(
        'im.created_at',
        'im.movement_type',
        'im.quantity',
        'p.name as product_name',
        'l.name as location_name'
      )
      .where('im.product_id', productId)
      .andWhere('im.location_id', locationId)
      .andWhere('im.created_at', '>=', db.raw(`NOW() - INTERVAL '${days} days'`))
      .orderBy('im.created_at', 'desc');
  }
}

module.exports = StockLevel;