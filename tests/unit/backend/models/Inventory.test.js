const StockLevel = require('../../../../src/backend/src/models/Inventory');
const db = require('../../../../src/backend/src/utils/database');

jest.mock('../../../../src/backend/src/utils/database');

describe('StockLevel Model', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll', () => {
    it('should return all stock levels', async () => {
      const mockStockLevels = [
        { id: '1', product_id: '1', location_id: '1', quantity: 100 },
        { id: '2', product_id: '2', location_id: '1', quantity: 50 }
      ];

      const mockQuery = {
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        whereRaw: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockResolvedValue(mockStockLevels)
      };

      db.mockReturnValue(mockQuery);

      const result = await StockLevel.findAll();

      expect(result).toEqual(mockStockLevels);
    });

    it('should filter by location', async () => {
      const mockQuery = {
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockResolvedValue([])
      };

      db.mockReturnValue(mockQuery);

      await StockLevel.findAll({ location_id: 'loc-1' });

      expect(mockQuery.where).toHaveBeenCalledWith('sl.location_id', 'loc-1');
    });

    it('should filter low stock items', async () => {
      const mockQuery = {
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        whereRaw: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockResolvedValue([])
      };

      db.mockReturnValue(mockQuery);

      await StockLevel.findAll({ low_stock: true });

      expect(mockQuery.whereRaw).toHaveBeenCalledWith('sl.quantity <= sl.min_stock_level');
    });
  });

  describe('getByProductAndLocation', () => {
    it('should return stock level for specific product and location', async () => {
      const mockStockLevel = { id: '1', product_id: '1', location_id: '1', quantity: 100 };

      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        first: jest.fn().mockResolvedValue(mockStockLevel)
      };

      db.mockReturnValue(mockQuery);

      const result = await StockLevel.getByProductAndLocation('1', '1');

      expect(result).toEqual(mockStockLevel);
      expect(mockQuery.where).toHaveBeenCalledWith('product_id', '1');
      expect(mockQuery.andWhere).toHaveBeenCalledWith('location_id', '1');
    });
  });

  describe('updateStock', () => {
    it('should update existing stock level', async () => {
      const existingStock = { id: '1', quantity: 100 };
      const updatedStock = { id: '1', quantity: 110 };

      // Mock getByProductAndLocation
      StockLevel.getByProductAndLocation = jest.fn().mockResolvedValue(existingStock);
      StockLevel.update = jest.fn().mockResolvedValue(updatedStock);

      const result = await StockLevel.updateStock('1', '1', 10, 'IN');

      expect(StockLevel.getByProductAndLocation).toHaveBeenCalledWith('1', '1');
      expect(StockLevel.update).toHaveBeenCalledWith('1', { quantity: 110 });
      expect(result).toEqual(updatedStock);
    });

    it('should create new stock level if not exists', async () => {
      const newStock = { id: '2', product_id: '2', location_id: '1', quantity: 10 };

      StockLevel.getByProductAndLocation = jest.fn().mockResolvedValue(null);
      StockLevel.create = jest.fn().mockResolvedValue(newStock);

      const result = await StockLevel.updateStock('2', '1', 10, 'IN');

      expect(StockLevel.create).toHaveBeenCalledWith({
        product_id: '2',
        location_id: '1',
        quantity: 10,
        min_stock_level: 0,
        max_stock_level: null
      });
      expect(result).toEqual(newStock);
    });

    it('should handle outbound movements', async () => {
      const existingStock = { id: '1', quantity: 100 };
      const updatedStock = { id: '1', quantity: 90 };

      StockLevel.getByProductAndLocation = jest.fn().mockResolvedValue(existingStock);
      StockLevel.update = jest.fn().mockResolvedValue(updatedStock);

      await StockLevel.updateStock('1', '1', 10, 'OUT');

      expect(StockLevel.update).toHaveBeenCalledWith('1', { quantity: 90 });
    });
  });

  describe('getLowStock', () => {
    it('should return products with low stock', async () => {
      const mockLowStock = [
        { id: '1', product_name: 'Product 1', quantity: 5, min_stock_level: 10 }
      ];

      const mockQuery = {
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        whereRaw: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockResolvedValue(mockLowStock)
      };

      db.mockReturnValue(mockQuery);

      const result = await StockLevel.getLowStock();

      expect(result).toEqual(mockLowStock);
      expect(mockQuery.whereRaw).toHaveBeenCalledWith('sl.quantity <= sl.min_stock_level');
    });
  });

  describe('getTotalValue', () => {
    it('should calculate total inventory value', async () => {
      const mockValue = {
        total_value: '50000.00',
        total_cost: '30000.00',
        total_products: '100',
        total_quantity: '1000'
      };

      const mockQuery = {
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        first: jest.fn().mockResolvedValue(mockValue)
      };

      db.mockReturnValue(mockQuery);

      const result = await StockLevel.getTotalValue();

      expect(result).toEqual(mockValue);
    });
  });
});