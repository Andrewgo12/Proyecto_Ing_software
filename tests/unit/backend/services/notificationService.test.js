const NotificationService = require('../../../../src/backend/src/services/notificationService');

jest.mock('nodemailer');

describe('NotificationService', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('sendLowStockAlert', () => {
    it('should send low stock alert email', async () => {
      const stockLevel = {
        product_name: 'Test Product',
        product_sku: 'TEST-001',
        location_name: 'Main Warehouse',
        quantity: 5,
        min_stock_level: 10
      };

      NotificationService.sendEmail = jest.fn().mockResolvedValue({ messageId: 'test-id' });

      await NotificationService.sendLowStockAlert(stockLevel);

      expect(NotificationService.sendEmail).toHaveBeenCalledWith(
        expect.objectContaining({
          subject: expect.stringContaining('Alerta de Stock Bajo'),
          html: expect.stringContaining('Test Product')
        })
      );
    });
  });

  describe('sendBulkAlert', () => {
    it('should send bulk alert for multiple products', async () => {
      const alerts = [
        { product_name: 'Product 1', quantity: 5, min_stock_level: 10 },
        { product_name: 'Product 2', quantity: 2, min_stock_level: 8 }
      ];

      NotificationService.sendEmail = jest.fn().mockResolvedValue({ messageId: 'test-id' });

      await NotificationService.sendBulkAlert(alerts);

      expect(NotificationService.sendEmail).toHaveBeenCalledWith(
        expect.objectContaining({
          subject: expect.stringContaining('2 alertas'),
          html: expect.stringContaining('Product 1')
        })
      );
    });
  });
});