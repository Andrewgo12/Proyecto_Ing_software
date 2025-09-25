import { render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from 'react-query';
import InventoryList from '../../../../src/frontend/src/components/inventory/InventoryList';
import * as inventoryHooks from '../../../../src/frontend/src/hooks/useInventory';

jest.mock('../../../../src/frontend/src/hooks/useInventory');

const createTestQueryClient = () => new QueryClient({
  defaultOptions: { queries: { retry: false }, mutations: { retry: false } }
});

const renderWithQueryClient = (component) => {
  const queryClient = createTestQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      {component}
    </QueryClientProvider>
  );
};

describe('InventoryList Component', () => {
  const mockStockData = [
    {
      product_id: '1',
      product_name: 'Test Product',
      product_sku: 'TEST-001',
      location_name: 'Main Warehouse',
      quantity: 10,
      min_stock_level: 5
    }
  ];

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should render inventory list', async () => {
    inventoryHooks.useStock.mockReturnValue({
      data: mockStockData,
      isLoading: false
    });

    renderWithQueryClient(<InventoryList />);

    await waitFor(() => {
      expect(screen.getByText('Test Product')).toBeInTheDocument();
      expect(screen.getByText('TEST-001')).toBeInTheDocument();
      expect(screen.getByText('Main Warehouse')).toBeInTheDocument();
    });
  });

  it('should show loading spinner', () => {
    inventoryHooks.useStock.mockReturnValue({
      data: null,
      isLoading: true
    });

    renderWithQueryClient(<InventoryList />);

    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
  });

  it('should display correct stock status', async () => {
    const lowStockData = [{
      ...mockStockData[0],
      quantity: 3,
      min_stock_level: 5
    }];

    inventoryHooks.useStock.mockReturnValue({
      data: lowStockData,
      isLoading: false
    });

    renderWithQueryClient(<InventoryList />);

    await waitFor(() => {
      expect(screen.getByText('Stock Bajo')).toBeInTheDocument();
    });
  });
});