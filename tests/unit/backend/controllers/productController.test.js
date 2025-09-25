const request = require('supertest');
const app = require('../../../../src/backend/server');
const Product = require('../../../../src/backend/src/models/Product');

jest.mock('../../../../src/backend/src/models/Product');

describe('Product Controller', () => {
  let authToken;

  beforeEach(() => {
    authToken = 'Bearer mock-jwt-token';
    jest.clearAllMocks();
  });

  describe('GET /api/products', () => {
    it('should return products list', async () => {
      const mockProducts = {
        data: [
          { id: '1', name: 'Product 1', sku: 'SKU001' },
          { id: '2', name: 'Product 2', sku: 'SKU002' }
        ],
        pagination: { page: 1, limit: 10, total: 2, pages: 1 }
      };

      Product.findAll.mockResolvedValue(mockProducts);

      const response = await request(app)
        .get('/api/products')
        .set('Authorization', authToken)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockProducts.data);
    });

    it('should handle search parameter', async () => {
      Product.findAll.mockResolvedValue({ data: [], pagination: {} });

      await request(app)
        .get('/api/products?search=test')
        .set('Authorization', authToken)
        .expect(200);

      expect(Product.findAll).toHaveBeenCalledWith(
        expect.objectContaining({ search: 'test' })
      );
    });
  });

  describe('POST /api/products', () => {
    it('should create new product', async () => {
      const newProduct = {
        sku: 'SKU003',
        name: 'New Product',
        unit_price: 100,
        cost_price: 50,
        category_id: 'cat-1'
      };

      Product.findBySku.mockResolvedValue(null);
      Product.create.mockResolvedValue({ id: '3', ...newProduct });

      const response = await request(app)
        .post('/api/products')
        .set('Authorization', authToken)
        .send(newProduct)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(Product.create).toHaveBeenCalledWith(
        expect.objectContaining(newProduct)
      );
    });

    it('should reject duplicate SKU', async () => {
      const duplicateProduct = {
        sku: 'EXISTING-SKU',
        name: 'Product',
        unit_price: 100,
        cost_price: 50,
        category_id: 'cat-1'
      };

      Product.findBySku.mockResolvedValue({ id: '1', sku: 'EXISTING-SKU' });

      await request(app)
        .post('/api/products')
        .set('Authorization', authToken)
        .send(duplicateProduct)
        .expect(409);
    });
  });

  describe('PUT /api/products/:id', () => {
    it('should update existing product', async () => {
      const updateData = { name: 'Updated Product' };
      const existingProduct = { id: '1', sku: 'SKU001', name: 'Old Product' };

      Product.findById.mockResolvedValue(existingProduct);
      Product.update.mockResolvedValue({ ...existingProduct, ...updateData });

      const response = await request(app)
        .put('/api/products/1')
        .set('Authorization', authToken)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Product.update).toHaveBeenCalledWith('1', expect.objectContaining(updateData));
    });
  });

  describe('DELETE /api/products/:id', () => {
    it('should soft delete product', async () => {
      const product = { id: '1', sku: 'SKU001' };
      Product.findById.mockResolvedValue(product);
      Product.softDelete.mockResolvedValue(true);

      await request(app)
        .delete('/api/products/1')
        .set('Authorization', authToken)
        .expect(200);

      expect(Product.softDelete).toHaveBeenCalledWith('1', expect.any(String));
    });
  });
});