const request = require('supertest');
const app = require('../../../src/backend/server');
const db = require('../../../src/backend/src/utils/database');

describe('Products API Integration', () => {
  let authToken;
  let testProduct;

  beforeAll(async () => {
    // Setup test database
    await db.migrate.latest();
    await db.seed.run();

    // Login to get auth token
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'admin@test.com',
        password: 'password123'
      });

    authToken = `Bearer ${loginResponse.body.data.accessToken}`;
  });

  afterAll(async () => {
    // Cleanup test database
    await db.migrate.rollback();
    await db.destroy();
  });

  beforeEach(async () => {
    // Clean products table before each test
    await db('products').del();
  });

  describe('POST /api/products', () => {
    it('should create a new product', async () => {
      const productData = {
        sku: 'TEST-001',
        name: 'Test Product',
        description: 'A test product',
        unit_price: 100.00,
        cost_price: 60.00,
        category_id: 'test-category-id',
        min_stock_level: 10,
        max_stock_level: 100
      };

      const response = await request(app)
        .post('/api/products')
        .set('Authorization', authToken)
        .send(productData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        sku: 'TEST-001',
        name: 'Test Product',
        unit_price: 100.00,
        cost_price: 60.00
      });

      testProduct = response.body.data;
    });

    it('should reject duplicate SKU', async () => {
      // Create first product
      await request(app)
        .post('/api/products')
        .set('Authorization', authToken)
        .send({
          sku: 'DUPLICATE-SKU',
          name: 'First Product',
          unit_price: 100,
          cost_price: 60,
          category_id: 'test-category-id'
        });

      // Try to create second product with same SKU
      const response = await request(app)
        .post('/api/products')
        .set('Authorization', authToken)
        .send({
          sku: 'DUPLICATE-SKU',
          name: 'Second Product',
          unit_price: 200,
          cost_price: 120,
          category_id: 'test-category-id'
        })
        .expect(409);

      expect(response.body.message).toContain('SKU already exists');
    });

    it('should validate required fields', async () => {
      const response = await request(app)
        .post('/api/products')
        .set('Authorization', authToken)
        .send({
          name: 'Incomplete Product'
          // Missing required fields
        })
        .expect(400);

      expect(response.body.success).toBe(false);
      expect(response.body.errors).toBeDefined();
    });
  });

  describe('GET /api/products', () => {
    beforeEach(async () => {
      // Create test products
      await db('products').insert([
        {
          id: '1',
          sku: 'PROD-001',
          name: 'Product 1',
          unit_price: 100,
          cost_price: 60,
          category_id: 'cat-1',
          is_active: true
        },
        {
          id: '2',
          sku: 'PROD-002',
          name: 'Product 2',
          unit_price: 200,
          cost_price: 120,
          category_id: 'cat-1',
          is_active: true
        }
      ]);
    });

    it('should return paginated products list', async () => {
      const response = await request(app)
        .get('/api/products')
        .set('Authorization', authToken)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveLength(2);
      expect(response.body.pagination).toMatchObject({
        page: 1,
        limit: 10,
        total: 2,
        pages: 1
      });
    });

    it('should filter products by search term', async () => {
      const response = await request(app)
        .get('/api/products?search=Product 1')
        .set('Authorization', authToken)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.data[0].name).toBe('Product 1');
    });

    it('should handle pagination parameters', async () => {
      const response = await request(app)
        .get('/api/products?page=1&limit=1')
        .set('Authorization', authToken)
        .expect(200);

      expect(response.body.data).toHaveLength(1);
      expect(response.body.pagination.limit).toBe(1);
    });
  });

  describe('GET /api/products/:id', () => {
    beforeEach(async () => {
      const [product] = await db('products').insert({
        id: 'test-product-id',
        sku: 'SINGLE-PROD',
        name: 'Single Product',
        unit_price: 150,
        cost_price: 90,
        category_id: 'cat-1',
        is_active: true
      }).returning('*');

      testProduct = product;
    });

    it('should return single product by ID', async () => {
      const response = await request(app)
        .get(`/api/products/${testProduct.id}`)
        .set('Authorization', authToken)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toMatchObject({
        id: testProduct.id,
        sku: 'SINGLE-PROD',
        name: 'Single Product'
      });
    });

    it('should return 404 for non-existent product', async () => {
      await request(app)
        .get('/api/products/non-existent-id')
        .set('Authorization', authToken)
        .expect(404);
    });
  });

  describe('PUT /api/products/:id', () => {
    beforeEach(async () => {
      const [product] = await db('products').insert({
        id: 'update-test-id',
        sku: 'UPDATE-PROD',
        name: 'Update Product',
        unit_price: 100,
        cost_price: 60,
        category_id: 'cat-1',
        is_active: true
      }).returning('*');

      testProduct = product;
    });

    it('should update product successfully', async () => {
      const updateData = {
        name: 'Updated Product Name',
        unit_price: 150
      };

      const response = await request(app)
        .put(`/api/products/${testProduct.id}`)
        .set('Authorization', authToken)
        .send(updateData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data.name).toBe('Updated Product Name');
      expect(response.body.data.unit_price).toBe(150);
    });

    it('should validate SKU uniqueness on update', async () => {
      // Create another product
      await db('products').insert({
        id: 'other-product',
        sku: 'OTHER-SKU',
        name: 'Other Product',
        unit_price: 100,
        cost_price: 60,
        category_id: 'cat-1'
      });

      // Try to update first product with existing SKU
      const response = await request(app)
        .put(`/api/products/${testProduct.id}`)
        .set('Authorization', authToken)
        .send({ sku: 'OTHER-SKU' })
        .expect(409);

      expect(response.body.message).toContain('SKU already exists');
    });
  });

  describe('DELETE /api/products/:id', () => {
    beforeEach(async () => {
      const [product] = await db('products').insert({
        id: 'delete-test-id',
        sku: 'DELETE-PROD',
        name: 'Delete Product',
        unit_price: 100,
        cost_price: 60,
        category_id: 'cat-1',
        is_active: true
      }).returning('*');

      testProduct = product;
    });

    it('should soft delete product', async () => {
      const response = await request(app)
        .delete(`/api/products/${testProduct.id}`)
        .set('Authorization', authToken)
        .expect(200);

      expect(response.body.success).toBe(true);

      // Verify product is soft deleted
      const deletedProduct = await db('products')
        .where('id', testProduct.id)
        .first();

      expect(deletedProduct.is_active).toBe(false);
      expect(deletedProduct.deleted_at).toBeTruthy();
    });
  });

  describe('Authentication', () => {
    it('should require authentication for all endpoints', async () => {
      await request(app)
        .get('/api/products')
        .expect(401);

      await request(app)
        .post('/api/products')
        .send({ name: 'Test' })
        .expect(401);
    });

    it('should reject invalid tokens', async () => {
      await request(app)
        .get('/api/products')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });
});