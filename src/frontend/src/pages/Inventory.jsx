import { useState } from 'react';
import { useQuery } from 'react-query';
import { Plus, Filter, AlertTriangle } from 'lucide-react';
import api from '../services/api';
import LoadingSpinner from '../components/common/LoadingSpinner';

const Inventory = () => {
  const [showMovementForm, setShowMovementForm] = useState(false);
  const [selectedLocation, setSelectedLocation] = useState('');

  const { data: stockData, isLoading } = useQuery(
    ['stock', selectedLocation],
    async () => {
      const response = await api.get('/inventory/stock', {
        params: selectedLocation ? { location_id: selectedLocation } : {}
      });
      return response.data.data;
    }
  );

  const { data: lowStockData } = useQuery(
    ['low-stock', selectedLocation],
    async () => {
      const response = await api.get('/inventory/stock/low', {
        params: selectedLocation ? { location_id: selectedLocation } : {}
      });
      return response.data.data;
    }
  );

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Inventario</h1>
          <p className="text-gray-600">Control de stock y movimientos</p>
        </div>
        <button
          onClick={() => setShowMovementForm(true)}
          className="btn-primary flex items-center space-x-2"
        >
          <Plus className="w-4 h-4" />
          <span>Nuevo Movimiento</span>
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-4">
        <div className="flex items-center space-x-4">
          <Filter className="w-5 h-5 text-gray-400" />
          <select
            value={selectedLocation}
            onChange={(e) => setSelectedLocation(e.target.value)}
            className="input-field max-w-xs"
          >
            <option value="">Todas las ubicaciones</option>
            <option value="location-1">Almacén Principal</option>
            <option value="location-2">Tienda Centro</option>
          </select>
        </div>
      </div>

      {/* Low Stock Alert */}
      {lowStockData && lowStockData.length > 0 && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div className="flex items-center">
            <AlertTriangle className="w-5 h-5 text-yellow-600 mr-2" />
            <h3 className="text-sm font-medium text-yellow-800">
              {lowStockData.length} productos con stock bajo
            </h3>
          </div>
        </div>
      )}

      {/* Stock Table */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Producto
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Ubicación
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Stock Actual
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Stock Mínimo
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Estado
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {stockData?.map((stock) => (
              <tr key={`${stock.product_id}-${stock.location_id}`} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div>
                    <div className="text-sm font-medium text-gray-900">{stock.product_name}</div>
                    <div className="text-sm text-gray-500">{stock.product_sku}</div>
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {stock.location_name}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {stock.quantity}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                  {stock.min_stock_level}
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${
                    stock.quantity === 0
                      ? 'bg-red-100 text-red-800'
                      : stock.quantity <= stock.min_stock_level
                      ? 'bg-yellow-100 text-yellow-800'
                      : 'bg-green-100 text-green-800'
                  }`}>
                    {stock.quantity === 0 
                      ? 'Agotado' 
                      : stock.quantity <= stock.min_stock_level 
                      ? 'Stock Bajo' 
                      : 'Normal'
                    }
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};

export default Inventory;