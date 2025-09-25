import React, { useState } from 'react';
import { useQuery } from 'react-query';
import { Calendar, User, Package, ArrowUpDown } from 'lucide-react';
import { useMovements } from '../../hooks/useInventory';
import LoadingSpinner from '../common/LoadingSpinner';
import { formatDate } from '../../utils/helpers';

const StockMovements = ({ productId, locationId }) => {
  const [page, setPage] = useState(1);
  const [filters, setFilters] = useState({
    product_id: productId,
    location_id: locationId,
    page,
    limit: 10
  });

  const { data: movementsData, isLoading } = useMovements(filters);

  const getMovementIcon = (type) => {
    switch (type) {
      case 'IN':
      case 'TRANSFER_IN':
        return <ArrowUpDown className="w-4 h-4 text-green-600 rotate-180" />;
      case 'OUT':
      case 'TRANSFER_OUT':
        return <ArrowUpDown className="w-4 h-4 text-red-600" />;
      case 'ADJUSTMENT':
        return <Package className="w-4 h-4 text-blue-600" />;
      default:
        return <ArrowUpDown className="w-4 h-4 text-gray-600" />;
    }
  };

  const getMovementColor = (type) => {
    switch (type) {
      case 'IN':
      case 'TRANSFER_IN':
        return 'text-green-600';
      case 'OUT':
      case 'TRANSFER_OUT':
        return 'text-red-600';
      case 'ADJUSTMENT':
        return 'text-blue-600';
      default:
        return 'text-gray-600';
    }
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-32">
        <LoadingSpinner size="md" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <h3 className="text-lg font-medium text-gray-900">Movimientos Recientes</h3>
      
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="divide-y divide-gray-200">
          {movementsData?.data?.map((movement) => (
            <div key={movement.id} className="p-4 hover:bg-gray-50">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  {getMovementIcon(movement.movement_type)}
                  <div>
                    <div className="flex items-center space-x-2">
                      <span className={`font-medium ${getMovementColor(movement.movement_type)}`}>
                        {movement.movement_type}
                      </span>
                      <span className="text-sm text-gray-500">
                        {movement.quantity} unidades
                      </span>
                    </div>
                    <div className="text-sm text-gray-600">
                      {movement.product_name} - {movement.location_name}
                    </div>
                  </div>
                </div>
                
                <div className="text-right">
                  <div className="flex items-center text-sm text-gray-500">
                    <Calendar className="w-4 h-4 mr-1" />
                    {formatDate(movement.created_at)}
                  </div>
                  <div className="flex items-center text-sm text-gray-500 mt-1">
                    <User className="w-4 h-4 mr-1" />
                    {movement.user_first_name} {movement.user_last_name}
                  </div>
                </div>
              </div>
              
              {movement.notes && (
                <div className="mt-2 text-sm text-gray-600 bg-gray-50 p-2 rounded">
                  {movement.notes}
                </div>
              )}
            </div>
          ))}
        </div>
        
        {movementsData?.pagination && (
          <div className="px-4 py-3 bg-gray-50 border-t flex justify-between items-center">
            <div className="text-sm text-gray-700">
              Página {movementsData.pagination.page} de {movementsData.pagination.pages}
            </div>
            <div className="flex space-x-2">
              <button
                onClick={() => setPage(page - 1)}
                disabled={page === 1}
                className="btn-secondary disabled:opacity-50 text-sm px-3 py-1"
              >
                Anterior
              </button>
              <button
                onClick={() => setPage(page + 1)}
                disabled={page >= movementsData.pagination.pages}
                className="btn-secondary disabled:opacity-50 text-sm px-3 py-1"
              >
                Siguiente
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default StockMovements;