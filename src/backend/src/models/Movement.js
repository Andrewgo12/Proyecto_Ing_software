const db = require('../utils/database');

class InventoryMovement {
  static async findAll(filters = {}) {
    let query = db('inventory_movements as im')
      .leftJoin('products as p', 'im.product_id', 'p.id')
      .leftJoin('locations as l', 'im.location_id', 'l.id')
      .leftJoin('users as u', 'im.user_id', 'u.id')
      .select(
        'im.*',
        'p.name as product_name',
        'p.sku as product_sku',
        'l.name as location_name',
        'l.code as location_code',
        'u.first_name as user_first_name',
        'u.last_name as user_last_name'
      );

    // Apply filters
    if (filters.product_id) {
      query = query.where('im.product_id', filters.product_id);
    }

    if (filters.location_id) {
      query = query.where('im.location_id', filters.location_id);
    }

    if (filters.movement_type) {
      query = query.where('im.movement_type', filters.movement_type);
    }

    if (filters.date_from) {
      query = query.where('im.created_at', '>=', filters.date_from);
    }

    if (filters.date_to) {
      query = query.where('im.created_at', '<=', filters.date_to);
    }

    // Pagination
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const offset = (page - 1) * limit;

    const totalQuery = query.clone().clearSelect().count('* as count').first();
    const total = await totalQuery;

    const movements = await query
      .orderBy('im.created_at', 'desc')
      .limit(limit)
      .offset(offset);

    return {
      data: movements,
      pagination: {
        page,
        limit,
        total: parseInt(total.count),
        pages: Math.ceil(total.count / limit)
      }
    };
  }

  static async findById(id) {
    return await db('inventory_movements as im')
      .leftJoin('products as p', 'im.product_id', 'p.id')
      .leftJoin('locations as l', 'im.location_id', 'l.id')
      .leftJoin('users as u', 'im.user_id', 'u.id')
      .select(
        'im.*',
        'p.name as product_name',
        'p.sku as product_sku',
        'l.name as location_name',
        'u.first_name as user_first_name',
        'u.last_name as user_last_name'
      )
      .where('im.id', id)
      .first();
  }

  static async create(movementData) {
    const [movement] = await db('inventory_movements')
      .insert({
        ...movementData,
        created_at: new Date()
      })
      .returning('*');
    
    return movement;
  }

  static async getMovementsByProduct(productId, limit = 10) {
    return await db('inventory_movements as im')
      .leftJoin('locations as l', 'im.location_id', 'l.id')
      .leftJoin('users as u', 'im.user_id', 'u.id')
      .select(
        'im.*',
        'l.name as location_name',
        'u.first_name as user_first_name',
        'u.last_name as user_last_name'
      )
      .where('im.product_id', productId)
      .orderBy('im.created_at', 'desc')
      .limit(limit);
  }

  static async getMovementsByLocation(locationId, limit = 10) {
    return await db('inventory_movements as im')
      .leftJoin('products as p', 'im.product_id', 'p.id')
      .leftJoin('users as u', 'im.user_id', 'u.id')
      .select(
        'im.*',
        'p.name as product_name',
        'p.sku as product_sku',
        'u.first_name as user_first_name',
        'u.last_name as user_last_name'
      )
      .where('im.location_id', locationId)
      .orderBy('im.created_at', 'desc')
      .limit(limit);
  }

  static async getMovementStats(filters = {}) {
    let query = db('inventory_movements as im')
      .select(
        db.raw('COUNT(*) as total_movements'),
        db.raw('COUNT(CASE WHEN movement_type = \'IN\' THEN 1 END) as inbound_movements'),
        db.raw('COUNT(CASE WHEN movement_type = \'OUT\' THEN 1 END) as outbound_movements'),
        db.raw('COUNT(CASE WHEN movement_type = \'ADJUSTMENT\' THEN 1 END) as adjustments'),
        db.raw('SUM(CASE WHEN movement_type = \'IN\' THEN quantity ELSE 0 END) as total_inbound_quantity'),
        db.raw('SUM(CASE WHEN movement_type = \'OUT\' THEN quantity ELSE 0 END) as total_outbound_quantity')
      );

    if (filters.date_from) {
      query = query.where('im.created_at', '>=', filters.date_from);
    }

    if (filters.date_to) {
      query = query.where('im.created_at', '<=', filters.date_to);
    }

    if (filters.location_id) {
      query = query.where('im.location_id', filters.location_id);
    }

    return await query.first();
  }

  static async getDailyMovements(days = 30, locationId = null) {
    let query = db('inventory_movements as im')
      .select(
        db.raw('DATE(created_at) as date'),
        db.raw('COUNT(*) as total_movements'),
        db.raw('SUM(CASE WHEN movement_type = \'IN\' THEN quantity ELSE 0 END) as inbound_quantity'),
        db.raw('SUM(CASE WHEN movement_type = \'OUT\' THEN quantity ELSE 0 END) as outbound_quantity')
      )
      .where('im.created_at', '>=', db.raw(`NOW() - INTERVAL '${days} days'`))
      .groupBy(db.raw('DATE(created_at)'))
      .orderBy('date', 'desc');

    if (locationId) {
      query = query.where('im.location_id', locationId);
    }

    return await query;
  }

  static async getTopMovedProducts(days = 30, limit = 10, locationId = null) {
    let query = db('inventory_movements as im')
      .leftJoin('products as p', 'im.product_id', 'p.id')
      .select(
        'p.id',
        'p.name as product_name',
        'p.sku as product_sku',
        db.raw('SUM(im.quantity) as total_quantity'),
        db.raw('COUNT(*) as movement_count')
      )
      .where('im.created_at', '>=', db.raw(`NOW() - INTERVAL '${days} days'`))
      .groupBy('p.id', 'p.name', 'p.sku')
      .orderBy('total_quantity', 'desc')
      .limit(limit);

    if (locationId) {
      query = query.where('im.location_id', locationId);
    }

    return await query;
  }
}

module.exports = InventoryMovement;