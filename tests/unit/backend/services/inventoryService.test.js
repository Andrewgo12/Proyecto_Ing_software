const InventoryService = require('../../../../src/backend/src/services/inventoryService');
const StockLevel = require('../../../../src/backend/src/models/Inventory');
const InventoryMovement = require('../../../../src/backend/src/models/Movement');

jest.mock('../../../../src/backend/src/models/Inventory');
jest.mock('../../../../src/backend/src/models/Movement');

describe('InventoryService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('processMovement', () => {
    it('should process IN movement successfully', async () => {
      const movementData = {
        product_id: '1',
        location_id: '1',
        movement_type: 'IN',
        quantity: 10
      };

      InventoryMovement.create.mockResolvedValue({ id: '1', ...movementData });
      StockLevel.updateStock.mockResolvedValue(true);
      InventoryService.checkLowStockAlerts = jest.fn();

      const result = await InventoryService.processMovement(movementData);

      expect(InventoryMovement.create).toHaveBeenCalledWith(movementData);
      expect(StockLevel.updateStock).toHaveBeenCalledWith('1', '1', 10, 'IN');
      expect(result.id).toBe('1');
    });

    it('should validate stock for OUT movement', async () => {
      const movementData = {
        product_id: '1',
        location_id: '1',
        movement_type: 'OUT',
        quantity: 15
      };

      StockLevel.getByProductAndLocation.mockResolvedValue({ quantity: 10 });

      await expect(InventoryService.processMovement(movementData))
        .rejects.toThrow('Insufficient stock for this operation');
    });
  });

  describe('optimizeStockLevels', () => {
    it('should return optimization recommendations', async () => {
      const mockProducts = [
        { id: '1', product_name: 'Product 1', total_quantity: 90, min_stock_level: 5, max_stock_level: 50 }
      ];

      InventoryMovement.getTopMovedProducts.mockResolvedValue(mockProducts);

      const result = await InventoryService.optimizeStockLevels('location-1');

      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({
        product_id: '1',
        recommended_min: 7, // 90/90 * 7 days
        recommended_max: 30 // 90/90 * 30 days
      });
    });
  });
});