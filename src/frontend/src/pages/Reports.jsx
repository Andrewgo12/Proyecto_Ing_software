import { useState } from 'react';
import { useQuery } from 'react-query';
import { Download, Calendar, BarChart3 } from 'lucide-react';
import api from '../services/api';
import LoadingSpinner from '../components/common/LoadingSpinner';

const Reports = () => {
  const [reportType, setReportType] = useState('inventory');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [isGenerating, setIsGenerating] = useState(false);

  const { data: performanceData, isLoading } = useQuery(
    'product-performance',
    async () => {
      const response = await api.get('/reports/product-performance', {
        params: { days: 30, limit: 10 }
      });
      return response.data.data;
    }
  );

  const generateReport = async () => {
    setIsGenerating(true);
    try {
      const params = {
        format: 'json',
        ...(dateFrom && { date_from: dateFrom }),
        ...(dateTo && { date_to: dateTo })
      };

      const response = await api.get(`/reports/${reportType}`, { params });
      
      // For demo purposes, we'll just show the data
      console.log('Report data:', response.data);
      
      // In a real app, you'd handle file download here
      alert('Reporte generado exitosamente');
    } catch (error) {
      console.error('Error generating report:', error);
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Reportes</h1>
        <p className="text-gray-600">Genera reportes y análisis de tu inventario</p>
      </div>

      {/* Report Generator */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">Generar Reporte</h3>
        
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Tipo de Reporte
            </label>
            <select
              value={reportType}
              onChange={(e) => setReportType(e.target.value)}
              className="input-field"
            >
              <option value="inventory">Inventario Actual</option>
              <option value="movements">Movimientos</option>
              <option value="valuation">Valorización</option>
            </select>
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Fecha Desde
            </label>
            <input
              type="date"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="input-field"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Fecha Hasta
            </label>
            <input
              type="date"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              className="input-field"
            />
          </div>
          
          <div className="flex items-end">
            <button
              onClick={generateReport}
              disabled={isGenerating}
              className="btn-primary flex items-center space-x-2 w-full"
            >
              {isGenerating ? (
                <LoadingSpinner size="sm" className="text-white" />
              ) : (
                <Download className="w-4 h-4" />
              )}
              <span>Generar</span>
            </button>
          </div>
        </div>
      </div>

      {/* Quick Reports */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <BarChart3 className="w-8 h-8 text-blue-600" />
            <div className="ml-4">
              <h3 className="text-lg font-medium text-gray-900">Reporte de Stock</h3>
              <p className="text-sm text-gray-600">Estado actual del inventario</p>
            </div>
          </div>
          <button className="mt-4 btn-secondary w-full">
            Generar Ahora
          </button>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <Calendar className="w-8 h-8 text-green-600" />
            <div className="ml-4">
              <h3 className="text-lg font-medium text-gray-900">Movimientos Mensuales</h3>
              <p className="text-sm text-gray-600">Actividad del último mes</p>
            </div>
          </div>
          <button className="mt-4 btn-secondary w-full">
            Generar Ahora
          </button>
        </div>

        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center">
            <Download className="w-8 h-8 text-purple-600" />
            <div className="ml-4">
              <h3 className="text-lg font-medium text-gray-900">Valorización</h3>
              <p className="text-sm text-gray-600">Valor total del inventario</p>
            </div>
          </div>
          <button className="mt-4 btn-secondary w-full">
            Generar Ahora
          </button>
        </div>
      </div>

      {/* Product Performance */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-6 border-b border-gray-200">
          <h3 className="text-lg font-medium text-gray-900">Productos Más Movidos (30 días)</h3>
        </div>
        <div className="p-6">
          {isLoading ? (
            <div className="flex justify-center">
              <LoadingSpinner size="md" />
            </div>
          ) : (
            <div className="space-y-4">
              {performanceData?.map((product, index) => (
                <div key={product.id} className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <span className="text-sm font-medium text-gray-500">#{index + 1}</span>
                    <div>
                      <p className="text-sm font-medium text-gray-900">{product.product_name}</p>
                      <p className="text-xs text-gray-500">{product.product_sku}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-medium text-gray-900">{product.total_quantity} unidades</p>
                    <p className="text-xs text-gray-500">{product.movement_count} movimientos</p>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Reports;