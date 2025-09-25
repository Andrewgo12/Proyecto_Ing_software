const ReportService = require('../../../../src/backend/src/services/reportService');
const db = require('../../../../src/backend/src/utils/database');
const StockLevel = require('../../../../src/backend/src/models/Inventory');
const InventoryMovement = require('../../../../src/backend/src/models/Movement');

jest.mock('../../../../src/backend/src/utils/database');
jest.mock('../../../../src/backend/src/models/Inventory');
jest.mock('../../../../src/backend/src/models/Movement');

describe('ReportService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('generateInventoryReport', () => {
    it('should generate inventory report in JSON format', async () => {
      const mockData = [
        {
          sku: 'SKU001',
          product_name: 'Product 1',
          category_name: 'Electronics',
          location_name: 'Main Warehouse',
          quantity: 100,
          unit_price: 50,
          total_value: 5000
        }
      ];

      const mockQuery = {
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockResolvedValue(mockData)
      };

      db.mockReturnValue(mockQuery);

      const result = await ReportService.generateInventoryReport({}, 'json');

      expect(result.report_type).toBe('inventory');
      expect(result.data).toEqual(mockData);
      expect(result.summary.total_products).toBe(1);
      expect(result.summary.total_value).toBe(5000);
    });

    it('should apply location filter', async () => {
      const mockQuery = {
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockResolvedValue([])
      };

      db.mockReturnValue(mockQuery);

      await ReportService.generateInventoryReport({ location_id: 'loc-1' });

      expect(mockQuery.where).toHaveBeenCalledWith('sl.location_id', 'loc-1');
    });
  });

  describe('generateMovementReport', () => {
    it('should generate movement report', async () => {
      const mockMovements = {
        data: [
          { id: '1', product_name: 'Product 1', movement_type: 'IN', quantity: 10 }
        ],
        pagination: { page: 1, limit: 10, total: 1, pages: 1 }
      };

      InventoryMovement.findAll.mockResolvedValue(mockMovements);

      const result = await ReportService.generateMovementReport({}, 'json');

      expect(result.report_type).toBe('movements');
      expect(result.data).toEqual(mockMovements.data);
      expect(result.pagination).toEqual(mockMovements.pagination);
    });
  });

  describe('getDashboardMetrics', () => {
    it('should return dashboard metrics', async () => {
      const mockStockStats = {
        total_value: '50000.00',
        total_cost: '30000.00',
        total_products: '100',
        total_quantity: '1000'
      };

      const mockMovementStats = {
        total_movements: '500',
        inbound_movements: '300',
        outbound_movements: '200',
        adjustments: '0'
      };

      StockLevel.getTotalValue.mockResolvedValue(mockStockStats);
      InventoryMovement.getMovementStats.mockResolvedValue(mockMovementStats);
      StockLevel.getLowStock.mockResolvedValue([{ id: '1' }, { id: '2' }]);
      StockLevel.getOutOfStock.mockResolvedValue([{ id: '3' }]);

      const result = await ReportService.getDashboardMetrics();

      expect(result.inventory.total_value).toBe(50000);
      expect(result.inventory.total_products).toBe(100);
      expect(result.movements.total_movements).toBe(500);
      expect(result.alerts.low_stock_count).toBe(2);
      expect(result.alerts.out_of_stock_count).toBe(1);
    });
  });

  describe('getProductPerformance', () => {
    it('should return top moved products', async () => {
      const mockPerformance = [
        { id: '1', product_name: 'Product 1', total_quantity: '100', movement_count: '10' }
      ];

      InventoryMovement.getTopMovedProducts.mockResolvedValue(mockPerformance);

      const result = await ReportService.getProductPerformance({ days: 30, limit: 10 });

      expect(result).toEqual(mockPerformance);
      expect(InventoryMovement.getTopMovedProducts).toHaveBeenCalledWith(30, 10, undefined);
    });
  });

  describe('getStockTrends', () => {
    it('should return stock history for specific product and location', async () => {
      const mockHistory = [
        { created_at: '2024-01-01', movement_type: 'IN', quantity: 10 }
      ];

      StockLevel.getStockHistory.mockResolvedValue(mockHistory);

      const result = await ReportService.getStockTrends({
        product_id: '1',
        location_id: '1',
        days: 30
      });

      expect(result).toEqual(mockHistory);
      expect(StockLevel.getStockHistory).toHaveBeenCalledWith('1', '1', 30);
    });

    it('should return daily movements when no specific product', async () => {
      const mockDailyMovements = [
        { date: '2024-01-01', total_movements: '5', inbound_quantity: '50' }
      ];

      InventoryMovement.getDailyMovements.mockResolvedValue(mockDailyMovements);

      const result = await ReportService.getStockTrends({ days: 30 });

      expect(result).toEqual(mockDailyMovements);
      expect(InventoryMovement.getDailyMovements).toHaveBeenCalledWith(30, undefined);
    });
  });
});