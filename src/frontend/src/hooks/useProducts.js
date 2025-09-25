import { useQuery, useMutation, useQueryClient } from 'react-query';
import api from '../services/api';
import toast from 'react-hot-toast';

export const useProducts = (filters = {}) => {
  return useQuery(
    ['products', filters],
    async () => {
      const response = await api.get('/products', { params: filters });
      return response.data;
    },
    {
      keepPreviousData: true,
    }
  );
};

export const useProduct = (productId) => {
  return useQuery(
    ['product', productId],
    async () => {
      const response = await api.get(`/products/${productId}`);
      return response.data.data;
    },
    {
      enabled: !!productId,
    }
  );
};

export const useCreateProduct = () => {
  const queryClient = useQueryClient();

  return useMutation(
    async (productData) => {
      const response = await api.post('/products', productData);
      return response.data.data;
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries('products');
        toast.success('Producto creado exitosamente');
      },
      onError: (error) => {
        const message = error.response?.data?.message || 'Error al crear el producto';
        toast.error(message);
      },
    }
  );
};

export const useUpdateProduct = () => {
  const queryClient = useQueryClient();

  return useMutation(
    async ({ productId, productData }) => {
      const response = await api.put(`/products/${productId}`, productData);
      return response.data.data;
    },
    {
      onSuccess: (data, variables) => {
        queryClient.invalidateQueries('products');
        queryClient.invalidateQueries(['product', variables.productId]);
        toast.success('Producto actualizado exitosamente');
      },
      onError: (error) => {
        const message = error.response?.data?.message || 'Error al actualizar el producto';
        toast.error(message);
      },
    }
  );
};

export const useDeleteProduct = () => {
  const queryClient = useQueryClient();

  return useMutation(
    async (productId) => {
      await api.delete(`/products/${productId}`);
      return productId;
    },
    {
      onSuccess: () => {
        queryClient.invalidateQueries('products');
        toast.success('Producto eliminado exitosamente');
      },
      onError: (error) => {
        const message = error.response?.data?.message || 'Error al eliminar el producto';
        toast.error(message);
      },
    }
  );
};

export const useSearchProducts = (searchTerm) => {
  return useQuery(
    ['products', 'search', searchTerm],
    async () => {
      const response = await api.get('/products/search', {
        params: { q: searchTerm, limit: 10 }
      });
      return response.data.data;
    },
    {
      enabled: searchTerm && searchTerm.length >= 2,
      staleTime: 30000, // 30 seconds
    }
  );
};