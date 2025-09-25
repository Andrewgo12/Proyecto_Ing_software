import { useQuery, useMutation, useQueryClient } from 'react-query';
import api from '../services/api';
import toast from 'react-hot-toast';

export const useStock = (filters = {}) => {
  return useQuery(
    ['stock', filters],
    async () => {
      const response = await api.get('/inventory/stock', { params: filters });
      return response.data.data;
    }
  );
};

export const useLowStock = (locationId) => {
  return useQuery(
    ['low-stock', locationId],
    async () => {
      const response = await api.get('/inventory/stock/low', {
        params: locationId ? { location_id: locationId } : {}
      });
      return response.data.data;
    }
  );
};

export const useMovements = (filters = {}) => {
  return useQuery(
    ['movements', filters],
    async () => {
      const response = await api.get('/inventory/movements', { params: filters });
      return response.data;
    },
    {
      keepPreviousData: true,
    }
  );
};

export const useCreateMovement = () => {
  const queryClient = useQueryClient();

  return useMutation(
    async (movementData) => {
      const response = await api.post('/inventory/movements', movementData);
      return response.data.data;
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries('stock');
        queryClient.invalidateQueries('movements');
        queryClient.invalidateQueries('dashboard-metrics');
        toast.success('Movimiento registrado exitosamente');
      },
      onError: (error) => {
        const message = error.response?.data?.message || 'Error al registrar el movimiento';
        toast.error(message);
      },
    }
  );
};

export const useAdjustStock = () => {
  const queryClient = useQueryClient();

  return useMutation(
    async (adjustmentData) => {
      const response = await api.post('/inventory/adjust', adjustmentData);
      return response.data.data;
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries('stock');
        queryClient.invalidateQueries('movements');
        queryClient.invalidateQueries('dashboard-metrics');
        toast.success('Stock ajustado exitosamente');
      },
      onError: (error) => {
        const message = error.response?.data?.message || 'Error al ajustar el stock';
        toast.error(message);
      },
    }
  );
};

export const useTransferStock = () => {
  const queryClient = useQueryClient();

  return useMutation(
    async (transferData) => {
      const response = await api.post('/inventory/transfer', transferData);
      return response.data.data;
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries('stock');
        queryClient.invalidateQueries('movements');
        queryClient.invalidateQueries('dashboard-metrics');
        toast.success('Transferencia realizada exitosamente');
      },
      onError: (error) => {
        const message = error.response?.data?.message || 'Error al realizar la transferencia';
        toast.error(message);
      },
    }
  );
};