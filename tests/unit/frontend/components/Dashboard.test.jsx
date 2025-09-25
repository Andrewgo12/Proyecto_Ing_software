import { render, screen, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from 'react-query';
import Dashboard from '../../../../src/frontend/src/pages/Dashboard';
import * as api from '../../../../src/frontend/src/services/api';

jest.mock('../../../../src/frontend/src/services/api');

const createTestQueryClient = () => new QueryClient({
  defaultOptions: {
    queries: { retry: false },
    mutations: { retry: false },
  },
});

const renderWithQueryClient = (component) => {
  const queryClient = createTestQueryClient();
  return render(
    <QueryClientProvider client={queryClient}>
      {component}
    </QueryClientProvider>
  );
};

describe('Dashboard Component', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should render dashboard title', () => {
    api.default.get.mockResolvedValue({
      data: {
        data: {
          inventory: { total_products: 0, total_value: 0 },
          movements: { total_movements: 0 },
          alerts: { low_stock_count: 0 }
        }
      }
    });

    renderWithQueryClient(<Dashboard />);

    expect(screen.getByText('Dashboard')).toBeInTheDocument();
    expect(screen.getByText('Resumen general de tu inventario')).toBeInTheDocument();
  });

  it('should display loading spinner initially', () => {
    api.default.get.mockImplementation(() => new Promise(() => {}));

    renderWithQueryClient(<Dashboard />);

    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();
  });

  it('should display metrics cards when data loads', async () => {
    const mockMetrics = {
      inventory: {
        total_products: 150,
        total_value: 75000,
        total_cost: 45000,
        total_quantity: 2500
      },
      movements: {
        total_movements: 320,
        inbound_movements: 180,
        outbound_movements: 140,
        adjustments: 0
      },
      alerts: {
        low_stock_count: 5,
        out_of_stock_count: 2
      }
    };

    api.default.get.mockResolvedValue({
      data: { data: mockMetrics }
    });

    renderWithQueryClient(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByText('150')).toBeInTheDocument();
      expect(screen.getByText('$75,000')).toBeInTheDocument();
      expect(screen.getByText('5')).toBeInTheDocument();
      expect(screen.getByText('320')).toBeInTheDocument();
    });
  });

  it('should display KPI cards with correct titles', async () => {
    api.default.get.mockResolvedValue({
      data: {
        data: {
          inventory: { total_products: 100, total_value: 50000 },
          movements: { total_movements: 200 },
          alerts: { low_stock_count: 3 }
        }
      }
    });

    renderWithQueryClient(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByText('Total Productos')).toBeInTheDocument();
      expect(screen.getByText('Valor Inventario')).toBeInTheDocument();
      expect(screen.getByText('Stock Bajo')).toBeInTheDocument();
      expect(screen.getByText('Movimientos (30d)')).toBeInTheDocument();
    });
  });

  it('should display recent activity section', async () => {
    api.default.get.mockResolvedValue({
      data: {
        data: {
          inventory: { total_products: 0, total_value: 0 },
          movements: { total_movements: 0 },
          alerts: { low_stock_count: 0 }
        }
      }
    });

    renderWithQueryClient(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByText('Actividad Reciente')).toBeInTheDocument();
      expect(screen.getByText('Alertas Pendientes')).toBeInTheDocument();
    });
  });

  it('should show low stock alert when there are items', async () => {
    api.default.get.mockResolvedValue({
      data: {
        data: {
          inventory: { total_products: 100, total_value: 50000 },
          movements: { total_movements: 200 },
          alerts: { low_stock_count: 5 }
        }
      }
    });

    renderWithQueryClient(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByText('5 productos con stock bajo')).toBeInTheDocument();
      expect(screen.getByText('Requiere atención')).toBeInTheDocument();
    });
  });

  it('should show no alerts message when no low stock', async () => {
    api.default.get.mockResolvedValue({
      data: {
        data: {
          inventory: { total_products: 100, total_value: 50000 },
          movements: { total_movements: 200 },
          alerts: { low_stock_count: 0 }
        }
      }
    });

    renderWithQueryClient(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByText('No hay alertas pendientes')).toBeInTheDocument();
    });
  });
});