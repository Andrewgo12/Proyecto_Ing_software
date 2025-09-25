const db = require('../utils/database');

class Product {
  static async findAll(filters = {}) {
    let query = db('products as p')
      .leftJoin('categories as c', 'p.category_id', 'c.id')
      .select(
        'p.*',
        'c.name as category_name'
      );

    // Apply filters
    if (filters.search) {
      query = query.where(function() {
        this.where('p.name', 'ilike', `%${filters.search}%`)
            .orWhere('p.sku', 'ilike', `%${filters.search}%`)
            .orWhere('p.description', 'ilike', `%${filters.search}%`);
      });
    }

    if (filters.category_id) {
      query = query.where('p.category_id', filters.category_id);
    }

    if (filters.is_active !== undefined) {
      query = query.where('p.is_active', filters.is_active);
    }

    // Pagination
    const page = filters.page || 1;
    const limit = filters.limit || 10;
    const offset = (page - 1) * limit;

    const totalQuery = query.clone().clearSelect().count('* as count').first();
    const total = await totalQuery;

    const products = await query
      .orderBy('p.created_at', 'desc')
      .limit(limit)
      .offset(offset);

    return {
      data: products,
      pagination: {
        page,
        limit,
        total: parseInt(total.count),
        pages: Math.ceil(total.count / limit)
      }
    };
  }

  static async findById(id) {
    return await db('products as p')
      .leftJoin('categories as c', 'p.category_id', 'c.id')
      .select(
        'p.*',
        'c.name as category_name'
      )
      .where('p.id', id)
      .first();
  }

  static async findBySku(sku) {
    return await db('products')
      .where('sku', sku)
      .first();
  }

  static async create(productData) {
    const [product] = await db('products')
      .insert({
        ...productData,
        created_at: new Date(),
        updated_at: new Date()
      })
      .returning('*');
    
    return product;
  }

  static async update(id, updateData) {
    const [product] = await db('products')
      .where('id', id)
      .update({
        ...updateData,
        updated_at: new Date()
      })
      .returning('*');
    
    return product;
  }

  static async softDelete(id, deletedBy) {
    return await db('products')
      .where('id', id)
      .update({
        is_active: false,
        deleted_at: new Date(),
        deleted_by: deletedBy,
        updated_at: new Date()
      });
  }

  static async getStockLevels(productId, locationId = null) {
    let query = db('stock_levels as sl')
      .leftJoin('locations as l', 'sl.location_id', 'l.id')
      .select(
        'sl.*',
        'l.name as location_name',
        'l.code as location_code'
      )
      .where('sl.product_id', productId);

    if (locationId) {
      query = query.where('sl.location_id', locationId);
    }

    return await query.orderBy('l.name');
  }

  static async search(searchTerm, limit = 10) {
    return await db('products')
      .select('id', 'sku', 'name', 'unit_price')
      .where(function() {
        this.where('name', 'ilike', `%${searchTerm}%`)
            .orWhere('sku', 'ilike', `%${searchTerm}%`);
      })
      .andWhere('is_active', true)
      .limit(limit)
      .orderBy('name');
  }

  static async getLowStockProducts(locationId = null) {
    let query = db('products as p')
      .join('stock_levels as sl', 'p.id', 'sl.product_id')
      .leftJoin('locations as l', 'sl.location_id', 'l.id')
      .select(
        'p.id',
        'p.sku',
        'p.name',
        'sl.quantity',
        'sl.min_stock_level',
        'l.name as location_name'
      )
      .whereRaw('sl.quantity <= sl.min_stock_level')
      .andWhere('p.is_active', true);

    if (locationId) {
      query = query.where('sl.location_id', locationId);
    }

    return await query.orderBy('sl.quantity');
  }

  static async getProductStats() {
    const stats = await db('products')
      .select(
        db.raw('COUNT(*) as total_products'),
        db.raw('COUNT(CASE WHEN is_active = true THEN 1 END) as active_products'),
        db.raw('AVG(unit_price) as avg_price'),
        db.raw('SUM(CASE WHEN is_active = true THEN 1 ELSE 0 END) as products_in_stock')
      )
      .first();
    
    return stats;
  }
}

module.exports = Product;