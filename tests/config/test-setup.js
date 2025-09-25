// Global test setup
const { execSync } = require('child_process');

// Setup test database
beforeAll(async () => {
  // Set test environment
  process.env.NODE_ENV = 'test';
  process.env.DB_NAME = 'inventario_pymes_test';
  
  // Run test migrations
  try {
    execSync('npm run migrate:test', { stdio: 'inherit' });
  } catch (error) {
    console.warn('Migration failed, continuing with tests');
  }
});

// Cleanup after all tests
afterAll(async () => {
  // Close database connections
  if (global.db) {
    await global.db.destroy();
  }
  
  // Close Redis connections
  if (global.redis) {
    await global.redis.quit();
  }
});

// Global test utilities
global.testUtils = {
  createTestUser: (overrides = {}) => ({
    email: 'test@test.com',
    password: 'password123',
    firstName: 'Test',
    lastName: 'User',
    role: 'warehouse',
    ...overrides
  }),
  
  createTestProduct: (overrides = {}) => ({
    sku: 'TEST-001',
    name: 'Test Product',
    category_id: 'test-category',
    unit_price: 100,
    cost_price: 60,
    ...overrides
  }),
  
  createTestMovement: (overrides = {}) => ({
    product_id: 'test-product',
    location_id: 'test-location',
    movement_type: 'IN',
    quantity: 10,
    notes: 'Test movement',
    ...overrides
  })
};

// Mock external services
jest.mock('nodemailer', () => ({
  createTransport: () => ({
    sendMail: jest.fn().mockResolvedValue({ messageId: 'test-message-id' })
  })
}));