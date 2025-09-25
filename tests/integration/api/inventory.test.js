const request = require('supertest');
const app = require('../../../src/backend/server');
const db = require('../../../src/backend/src/utils/database');

describe('Inventory API Integration', () => {
  let authToken;

  beforeAll(async () => {
    await db.migrate.latest();
    await db.seed.run();

    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({ email: 'admin@test.com', password: 'password123' });

    authToken = `Bearer ${loginResponse.body.data.accessToken}`;
  });

  afterAll(async () => {
    await db.migrate.rollback();
    await db.destroy();
  });

  describe('GET /api/inventory/stock', () => {
    it('should return stock levels', async () => {
      const response = await request(app)
        .get('/api/inventory/stock')
        .set('Authorization', authToken)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should filter by location', async () => {
      await request(app)
        .get('/api/inventory/stock?location_id=location-1')
        .set('Authorization', authToken)
        .expect(200);
    });
  });

  describe('POST /api/inventory/movements', () => {
    it('should create movement', async () => {
      const movementData = {
        product_id: 'product-1',
        location_id: 'location-1',
        movement_type: 'IN',
        quantity: 10,
        notes: 'Test movement'
      };

      const response = await request(app)
        .post('/api/inventory/movements')
        .set('Authorization', authToken)
        .send(movementData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data.quantity).toBe(10);
    });
  });
});