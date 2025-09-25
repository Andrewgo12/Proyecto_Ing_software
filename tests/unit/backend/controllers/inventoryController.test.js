const request = require('supertest');
const app = require('../../../../src/backend/server');
const StockLevel = require('../../../../src/backend/src/models/Inventory');
const InventoryMovement = require('../../../../src/backend/src/models/Movement');

jest.mock('../../../../src/backend/src/models/Inventory');
jest.mock('../../../../src/backend/src/models/Movement');

describe('Inventory Controller', () => {
  let authToken;

  beforeEach(() => {
    authToken = 'Bearer mock-jwt-token';
    jest.clearAllMocks();
  });

  describe('GET /api/inventory/stock', () => {
    it('should return stock levels', async () => {
      const mockStock = [
        { product_id: '1', location_id: '1', quantity: 100 },
        { product_id: '2', location_id: '1', quantity: 50 }
      ];

      StockLevel.findAll.mockResolvedValue(mockStock);

      const response = await request(app)
        .get('/api/inventory/stock')
        .set('Authorization', authToken)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toEqual(mockStock);
    });
  });

  describe('POST /api/inventory/movements', () => {
    it('should create inventory movement', async () => {
      const movementData = {
        product_id: '1',
        location_id: '1',
        movement_type: 'IN',
        quantity: 10
      };

      const mockMovement = { id: '1', ...movementData };
      InventoryMovement.create.mockResolvedValue(mockMovement);
      StockLevel.updateStock.mockResolvedValue(true);

      const response = await request(app)
        .post('/api/inventory/movements')
        .set('Authorization', authToken)
        .send(movementData)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(InventoryMovement.create).toHaveBeenCalled();
      expect(StockLevel.updateStock).toHaveBeenCalled();
    });

    it('should validate stock for outbound movements', async () => {
      const movementData = {
        product_id: '1',
        location_id: '1',
        movement_type: 'OUT',
        quantity: 100
      };

      StockLevel.getByProductAndLocation.mockResolvedValue({ quantity: 50 });

      await request(app)
        .post('/api/inventory/movements')
        .set('Authorization', authToken)
        .send(movementData)
        .expect(400);
    });
  });

  describe('POST /api/inventory/adjust', () => {
    it('should adjust stock levels', async () => {
      const adjustmentData = {
        product_id: '1',
        location_id: '1',
        new_quantity: 75,
        reason: 'Physical count adjustment'
      };

      const currentStock = { id: '1', quantity: 100 };
      StockLevel.getByProductAndLocation.mockResolvedValue(currentStock);
      InventoryMovement.create.mockResolvedValue({ id: '1' });
      StockLevel.update.mockResolvedValue(true);

      const response = await request(app)
        .post('/api/inventory/adjust')
        .set('Authorization', authToken)
        .send(adjustmentData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(StockLevel.update).toHaveBeenCalledWith('1', { quantity: 75 });
    });
  });

  describe('POST /api/inventory/transfer', () => {
    it('should transfer stock between locations', async () => {
      const transferData = {
        product_id: '1',
        from_location_id: '1',
        to_location_id: '2',
        quantity: 25
      };

      StockLevel.getByProductAndLocation.mockResolvedValue({ quantity: 100 });
      InventoryMovement.create.mockResolvedValue({ id: '1' });
      StockLevel.updateStock.mockResolvedValue(true);

      const response = await request(app)
        .post('/api/inventory/transfer')
        .set('Authorization', authToken)
        .send(transferData)
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(InventoryMovement.create).toHaveBeenCalledTimes(2);
      expect(StockLevel.updateStock).toHaveBeenCalledTimes(2);
    });
  });
});