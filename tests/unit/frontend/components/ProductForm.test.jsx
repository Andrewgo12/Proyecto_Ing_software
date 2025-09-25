import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { QueryClient, QueryClientProvider } from 'react-query';
import ProductForm from '../../../../src/frontend/src/components/inventory/ProductForm';
import * as api from '../../../../src/frontend/src/services/api';

jest.mock('../../../../src/frontend/src/services/api');

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

describe('ProductForm Component', () => {
  const mockOnClose = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should render form fields', () => {
    renderWithQueryClient(<ProductForm onClose={mockOnClose} />);

    expect(screen.getByLabelText(/SKU/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Nombre/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Precio de Venta/i)).toBeInTheDocument();
    expect(screen.getByLabelText(/Costo/i)).toBeInTheDocument();
  });

  it('should validate required fields', async () => {
    renderWithQueryClient(<ProductForm onClose={mockOnClose} />);

    fireEvent.click(screen.getByText('Guardar'));

    await waitFor(() => {
      expect(screen.getByText('SKU es requerido')).toBeInTheDocument();
      expect(screen.getByText('Nombre es requerido')).toBeInTheDocument();
    });
  });

  it('should submit form with valid data', async () => {
    api.default.post.mockResolvedValue({
      data: { data: { id: '1', sku: 'TEST-001', name: 'Test Product' } }
    });

    renderWithQueryClient(<ProductForm onClose={mockOnClose} />);

    fireEvent.change(screen.getByLabelText(/SKU/i), { target: { value: 'TEST-001' } });
    fireEvent.change(screen.getByLabelText(/Nombre/i), { target: { value: 'Test Product' } });
    fireEvent.change(screen.getByLabelText(/Precio de Venta/i), { target: { value: '100' } });
    fireEvent.change(screen.getByLabelText(/Costo/i), { target: { value: '60' } });

    fireEvent.click(screen.getByText('Guardar'));

    await waitFor(() => {
      expect(api.default.post).toHaveBeenCalledWith('/products', expect.objectContaining({
        sku: 'TEST-001',
        name: 'Test Product',
        unit_price: '100',
        cost_price: '60'
      }));
    });
  });
});