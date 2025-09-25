const Product = require('../models/Product');
const logger = require('../utils/logger');

class ProductController {
  async getProducts(req, res, next) {
    try {
      const { page = 1, limit = 10, search, category, active } = req.query;
      
      const filters = {};
      if (search) filters.search = search;
      if (category) filters.category_id = category;
      if (active !== undefined) filters.is_active = active === 'true';

      const products = await Product.findAll({
        ...filters,
        page: parseInt(page),
        limit: parseInt(limit)
      });

      res.json({
        success: true,
        data: products.data,
        pagination: products.pagination
      });
    } catch (error) {
      next(error);
    }
  }

  async getProduct(req, res, next) {
    try {
      const { id } = req.params;
      const product = await Product.findById(id);

      if (!product) {
        return res.status(404).json({ message: 'Product not found' });
      }

      res.json({
        success: true,
        data: product
      });
    } catch (error) {
      next(error);
    }
  }

  async createProduct(req, res, next) {
    try {
      const productData = req.body;
      
      // Check if SKU already exists
      const existingProduct = await Product.findBySku(productData.sku);
      if (existingProduct) {
        return res.status(409).json({ message: 'SKU already exists' });
      }

      const product = await Product.create({
        ...productData,
        created_by: req.user.userId
      });

      logger.info(`Product created: ${product.sku} by user ${req.user.email}`);

      res.status(201).json({
        success: true,
        data: product,
        message: 'Product created successfully'
      });
    } catch (error) {
      next(error);
    }
  }

  async updateProduct(req, res, next) {
    try {
      const { id } = req.params;
      const updateData = req.body;

      const product = await Product.findById(id);
      if (!product) {
        return res.status(404).json({ message: 'Product not found' });
      }

      // Check SKU uniqueness if being updated
      if (updateData.sku && updateData.sku !== product.sku) {
        const existingProduct = await Product.findBySku(updateData.sku);
        if (existingProduct) {
          return res.status(409).json({ message: 'SKU already exists' });
        }
      }

      const updatedProduct = await Product.update(id, {
        ...updateData,
        updated_by: req.user.userId
      });

      logger.info(`Product updated: ${updatedProduct.sku} by user ${req.user.email}`);

      res.json({
        success: true,
        data: updatedProduct,
        message: 'Product updated successfully'
      });
    } catch (error) {
      next(error);
    }
  }

  async deleteProduct(req, res, next) {
    try {
      const { id } = req.params;

      const product = await Product.findById(id);
      if (!product) {
        return res.status(404).json({ message: 'Product not found' });
      }

      // Soft delete
      await Product.softDelete(id, req.user.userId);

      logger.info(`Product deleted: ${product.sku} by user ${req.user.email}`);

      res.json({
        success: true,
        message: 'Product deleted successfully'
      });
    } catch (error) {
      next(error);
    }
  }

  async getProductStock(req, res, next) {
    try {
      const { id } = req.params;
      const { location_id } = req.query;

      const stockLevels = await Product.getStockLevels(id, location_id);

      res.json({
        success: true,
        data: stockLevels
      });
    } catch (error) {
      next(error);
    }
  }

  async searchProducts(req, res, next) {
    try {
      const { q, limit = 10 } = req.query;

      if (!q || q.length < 2) {
        return res.status(400).json({ message: 'Search query must be at least 2 characters' });
      }

      const products = await Product.search(q, parseInt(limit));

      res.json({
        success: true,
        data: products
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new ProductController();