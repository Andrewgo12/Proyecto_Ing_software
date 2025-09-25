import React, { useState } from 'react';
import { useQuery } from 'react-query';
import { Filter, AlertTriangle, Package } from 'lucide-react';
import { useStock } from '../../hooks/useInventory';
import LoadingSpinner from '../common/LoadingSpinner';

const InventoryList = () => {
  const [filters, setFilters] = useState({
    location_id: '',
    low_stock: false
  });

  const { data: stockData, isLoading } = useStock(filters);

  const getStatusColor = (stock) => {
    if (stock.quantity === 0) return 'bg-red-100 text-red-800';
    if (stock.quantity <= stock.min_stock_level) return 'bg-yellow-100 text-yellow-800';
    return 'bg-green-100 text-green-800';
  };

  const getStatusText = (stock) => {
    if (stock.quantity === 0) return 'Agotado';
    if (stock.quantity <= stock.min_stock_level) return 'Stock Bajo';
    return 'Normal';
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-4">
        <div className="flex items-center space-x-4">
          <Filter className="w-5 h-5 text-gray-400" />
          <select
            value={filters.location_id}
            onChange={(e) => setFilters({ ...filters, location_id: e.target.value })}
            className="input-field max-w-xs"
          >
            <option value="">Todas las ubicaciones</option>
            <option value="location-1">Almacén Principal</option>
            <option value="location-2">Tienda Centro</option>
          </select>
          <label className="flex items-center space-x-2">
            <input
              type="checkbox"
              checked={filters.low_stock}
              onChange={(e) => setFilters({ ...filters, low_stock: e.target.checked })}
              className="rounded border-gray-300"
            />
            <span className="text-sm">Solo stock bajo</span>
          </label>
        </div>
      </div>

      {/* Stock List */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                Producto
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                Ubicación
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                Stock Actual
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                Stock Mínimo
              </th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                Estado
              </th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {stockData?.map((stock) => (
              <tr key={`${stock.product_id}-${stock.location_id}`} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="flex items-center">
                    <Package className="w-5 h-5 text-gray-400 mr-3" />
                    <div>
                      <div className="text-sm font-medium text-gray-900">{stock.product_name}</div>
                      <div className="text-sm text-gray-500">{stock.product_sku}</div>
                    </div>
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
                  <span className={`inline-flex px-2 py-1 text-xs font-semibold rounded-full ${getStatusColor(stock)}`}>
                    {getStatusText(stock)}
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

export default InventoryList;