import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { X } from 'lucide-react';
import api from '../../services/api';
import LoadingSpinner from '../common/LoadingSpinner';
import toast from 'react-hot-toast';

const ProductForm = ({ product, onClose }) => {
  const [isLoading, setIsLoading] = useState(false);
  const isEditing = !!product;

  const {
    register,
    handleSubmit,
    formState: { errors },
    reset
  } = useForm({
    defaultValues: product || {}
  });

  useEffect(() => {
    if (product) {
      reset(product);
    }
  }, [product, reset]);

  const onSubmit = async (data) => {
    setIsLoading(true);
    try {
      if (isEditing) {
        await api.put(`/products/${product.id}`, data);
        toast.success('Producto actualizado exitosamente');
      } else {
        await api.post('/products', data);
        toast.success('Producto creado exitosamente');
      }
      onClose();
    } catch (error) {
      const message = error.response?.data?.message || 'Error al guardar el producto';
      toast.error(message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full mx-4 max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">
            {isEditing ? 'Editar Producto' : 'Nuevo Producto'}
          </h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className="p-6 space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              SKU *
            </label>
            <input
              {...register('sku', { required: 'SKU es requerido' })}
              type="text"
              className="input-field"
              placeholder="Ej: PROD-001"
            />
            {errors.sku && (
              <p className="mt-1 text-sm text-red-600">{errors.sku.message}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Nombre *
            </label>
            <input
              {...register('name', { required: 'Nombre es requerido' })}
              type="text"
              className="input-field"
              placeholder="Nombre del producto"
            />
            {errors.name && (
              <p className="mt-1 text-sm text-red-600">{errors.name.message}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Descripción
            </label>
            <textarea
              {...register('description')}
              rows={3}
              className="input-field"
              placeholder="Descripción del producto"
            />
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Precio de Venta *
              </label>
              <input
                {...register('unit_price', { 
                  required: 'Precio es requerido',
                  min: { value: 0, message: 'Precio debe ser mayor a 0' }
                })}
                type="number"
                step="0.01"
                className="input-field"
                placeholder="0.00"
              />
              {errors.unit_price && (
                <p className="mt-1 text-sm text-red-600">{errors.unit_price.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Costo *
              </label>
              <input
                {...register('cost_price', { 
                  required: 'Costo es requerido',
                  min: { value: 0, message: 'Costo debe ser mayor a 0' }
                })}
                type="number"
                step="0.01"
                className="input-field"
                placeholder="0.00"
              />
              {errors.cost_price && (
                <p className="mt-1 text-sm text-red-600">{errors.cost_price.message}</p>
              )}
            </div>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Categoría *
            </label>
            <select
              {...register('category_id', { required: 'Categoría es requerida' })}
              className="input-field"
            >
              <option value="">Seleccionar categoría</option>
              <option value="cat-1">Electrónicos</option>
              <option value="cat-2">Ropa</option>
              <option value="cat-3">Hogar</option>
            </select>
            {errors.category_id && (
              <p className="mt-1 text-sm text-red-600">{errors.category_id.message}</p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Stock Mínimo
              </label>
              <input
                {...register('min_stock_level')}
                type="number"
                className="input-field"
                placeholder="0"
                defaultValue={0}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Stock Máximo
              </label>
              <input
                {...register('max_stock_level')}
                type="number"
                className="input-field"
                placeholder="100"
              />
            </div>
          </div>

          <div className="flex items-center">
            <input
              {...register('is_active')}
              type="checkbox"
              className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              defaultChecked={true}
            />
            <label className="ml-2 block text-sm text-gray-900">
              Producto activo
            </label>
          </div>

          <div className="flex justify-end space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="btn-secondary"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={isLoading}
              className="btn-primary flex items-center space-x-2"
            >
              {isLoading && <LoadingSpinner size="sm" className="text-white" />}
              <span>{isEditing ? 'Actualizar' : 'Crear'}</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default ProductForm;