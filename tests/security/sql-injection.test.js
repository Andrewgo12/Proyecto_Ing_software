const request = require('supertest');
const app = require('../../src/backend/server');

describe('SQL Injection Security Tests', () => {
  let authToken;

  beforeAll(async () => {
    const loginResponse = await request(app)
      .post('/api/auth/login')
      .send({
        email: 'admin@test.com',
        password: 'password123'
      });
    
    authToken = loginResponse.body.data.accessToken;
  });

  describe('Product Search SQL Injection', () => {
    it('should prevent SQL injection in product search', async () => {
      const maliciousQuery = "'; DROP TABLE products; --";
      
      const response = await request(app)
        .get(`/api/products/search?q=${encodeURIComponent(maliciousQuery)}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(400);

      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should sanitize special characters in search', async () => {
      const specialChars = "test'\"<>{}[]()";
      
      const response = await request(app)
        .get(`/api/products/search?q=${encodeURIComponent(specialChars)}`)
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body.success).toBe(true);
    });
  });

  describe('Product Creation SQL Injection', () => {
    it('should prevent SQL injection in product creation', async () => {
      const maliciousProduct = {
        sku: "'; DROP TABLE products; --",
        name: "Test Product",
        price: 100
      };

      const response = await request(app)
        .post('/api/products')
        .set('Authorization', `Bearer ${authToken}`)
        .send(maliciousProduct)
        .expect(400);

      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('Inventory Movement SQL Injection', () => {
    it('should prevent SQL injection in movement notes', async () => {
      const maliciousMovement = {
        product_id: 'valid-id',
        location_id: 'valid-id',
        movement_type: 'IN',
        quantity: 10,
        notes: "'; DELETE FROM inventory_movements; --"
      };

      const response = await request(app)
        .post('/api/inventory/movements')
        .set('Authorization', `Bearer ${authToken}`)
        .send(maliciousMovement)
        .expect(400);

      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('User Management SQL Injection', () => {
    it('should prevent SQL injection in user email', async () => {
      const maliciousUser = {
        email: "admin'; DROP TABLE users; --@test.com",
        password: "password123",
        firstName: "Test",
        lastName: "User"
      };

      const response = await request(app)
        .post('/api/users')
        .set('Authorization', `Bearer ${authToken}`)
        .send(maliciousUser)
        .expect(400);

      expect(response.body.error.code).toBe('VALIDATION_ERROR');
    });
  });
});