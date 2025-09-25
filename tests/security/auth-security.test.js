const request = require('supertest');
const app = require('../../src/backend/server');

describe('Authentication Security Tests', () => {
  describe('JWT Token Security', () => {
    it('should reject requests without token', async () => {
      const response = await request(app)
        .get('/api/products')
        .expect(401);

      expect(response.body.error.code).toBe('AUTH_003');
    });

    it('should reject invalid tokens', async () => {
      const response = await request(app)
        .get('/api/products')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);

      expect(response.body.error.code).toBe('AUTH_003');
    });

    it('should reject expired tokens', async () => {
      const expiredToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.expired';
      
      const response = await request(app)
        .get('/api/products')
        .set('Authorization', `Bearer ${expiredToken}`)
        .expect(401);

      expect(response.body.error.code).toBe('AUTH_002');
    });
  });

  describe('Rate Limiting', () => {
    it('should enforce rate limits on login endpoint', async () => {
      const loginData = {
        email: 'test@test.com',
        password: 'wrongpassword'
      };

      // Make multiple failed login attempts
      for (let i = 0; i < 6; i++) {
        await request(app)
          .post('/api/auth/login')
          .send(loginData);
      }

      // 6th attempt should be rate limited
      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(429);

      expect(response.body.error.message).toContain('Too many requests');
    });
  });

  describe('Password Security', () => {
    it('should reject weak passwords', async () => {
      const userData = {
        email: 'test@test.com',
        password: '123',
        firstName: 'Test',
        lastName: 'User'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(400);

      expect(response.body.error.code).toBe('AUTH_005');
    });

    it('should hash passwords properly', async () => {
      const userData = {
        email: 'test@test.com',
        password: 'SecurePassword123!',
        firstName: 'Test',
        lastName: 'User'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData)
        .expect(201);

      // Password should not be returned in response
      expect(response.body.data.user.password).toBeUndefined();
    });
  });
});