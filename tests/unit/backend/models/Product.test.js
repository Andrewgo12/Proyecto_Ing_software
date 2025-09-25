const Product = require('../../../../src/backend/src/models/Product');
const db = require('../../../../src/backend/src/utils/database');

jest.mock('../../../../src/backend/src/utils/database');

describe('Product Model', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('findAll', () => {
    it('should return paginated products', async () => {
      const mockProducts = [
        { id: '1', name: 'Product 1', sku: 'SKU001' },
        { id: '2', name: 'Product 2', sku: 'SKU002' }
      ];

      const mockQuery = {
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        orWhere: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        offset: jest.fn().mockReturnThis(),
        clone: jest.fn().mockReturnThis(),
        clearSelect: jest.fn().mockReturnThis(),
        count: jest.fn().mockReturnThis(),
        first: jest.fn().mockResolvedValue({ count: '2' })
      };

      db.mockReturnValue(mockQuery);
      mockQuery.orderBy.mockResolvedValue(mockProducts);

      const result = await Product.findAll({ page: 1, limit: 10 });

      expect(result.data).toEqual(mockProducts);
      expect(result.pagination.total).toBe(2);
    });

    it('should apply search filter', async () => {
      const mockQuery = {
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        orWhere: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        limit: jest.fn().mockReturnThis(),
        offset: jest.fn().mockReturnThis(),
        clone: jest.fn().mockReturnThis(),
        clearSelect: jest.fn().mockReturnThis(),
        count: jest.fn().mockReturnThis(),
        first: jest.fn().mockResolvedValue({ count: '0' })
      };

      db.mockReturnValue(mockQuery);
      mockQuery.orderBy.mockResolvedValue([]);

      await Product.findAll({ search: 'test product' });

      expect(mockQuery.where).toHaveBeenCalled();
    });
  });

  describe('findById', () => {
    it('should return product by id', async () => {
      const mockProduct = { id: '1', name: 'Product 1', sku: 'SKU001' };
      
      const mockQuery = {
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        first: jest.fn().mockResolvedValue(mockProduct)
      };

      db.mockReturnValue(mockQuery);

      const result = await Product.findById('1');

      expect(result).toEqual(mockProduct);
      expect(mockQuery.where).toHaveBeenCalledWith('p.id', '1');
    });
  });

  describe('create', () => {
    it('should create new product', async () => {
      const productData = {
        sku: 'SKU003',
        name: 'New Product',
        unit_price: 100,
        cost_price: 50
      };

      const mockProduct = { id: '3', ...productData };
      
      const mockQuery = {
        insert: jest.fn().mockReturnThis(),
        returning: jest.fn().mockResolvedValue([mockProduct])
      };

      db.mockReturnValue(mockQuery);

      const result = await Product.create(productData);

      expect(result).toEqual(mockProduct);
      expect(mockQuery.insert).toHaveBeenCalledWith(
        expect.objectContaining(productData)
      );
    });
  });

  describe('update', () => {
    it('should update existing product', async () => {
      const updateData = { name: 'Updated Product' };
      const updatedProduct = { id: '1', name: 'Updated Product' };
      
      const mockQuery = {
        where: jest.fn().mockReturnThis(),
        update: jest.fn().mockReturnThis(),
        returning: jest.fn().mockResolvedValue([updatedProduct])
      };

      db.mockReturnValue(mockQuery);

      const result = await Product.update('1', updateData);

      expect(result).toEqual(updatedProduct);
      expect(mockQuery.where).toHaveBeenCalledWith('id', '1');
    });
  });

  describe('getLowStockProducts', () => {
    it('should return products with low stock', async () => {
      const mockLowStockProducts = [
        { id: '1', name: 'Product 1', quantity: 5, min_stock_level: 10 }
      ];
      
      const mockQuery = {
        join: jest.fn().mockReturnThis(),
        leftJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        whereRaw: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockResolvedValue(mockLowStockProducts)
      };

      db.mockReturnValue(mockQuery);

      const result = await Product.getLowStockProducts();

      expect(result).toEqual(mockLowStockProducts);
      expect(mockQuery.whereRaw).toHaveBeenCalledWith('sl.quantity <= sl.min_stock_level');
    });
  });
});