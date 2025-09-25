import { useQuery } from 'react-query';
import { Package, AlertTriangle, TrendingUp, DollarSign } from 'lucide-react';
import api from '../services/api';
import LoadingSpinner from '../components/common/LoadingSpinner';

const Dashboard = () => {
  const { data: metrics, isLoading } = useQuery(
    'dashboard-metrics',
    async () => {
      const response = await api.get('/reports/dashboard');
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

  const cards = [
    {
      title: 'Total Productos',
      value: metrics?.inventory?.total_products || 0,
      icon: Package,
      color: 'bg-blue-500',
      change: '+12%'
    },
    {
      title: 'Valor Inventario',
      value: `$${(metrics?.inventory?.total_value || 0).toLocaleString()}`,
      icon: DollarSign,
      color: 'bg-green-500',
      change: '+8%'
    },
    {
      title: 'Stock Bajo',
      value: metrics?.alerts?.low_stock_count || 0,
      icon: AlertTriangle,
      color: 'bg-yellow-500',
      change: '-5%'
    },
    {
      title: 'Movimientos (30d)',
      value: metrics?.movements?.total_movements || 0,
      icon: TrendingUp,
      color: 'bg-purple-500',
      change: '+15%'
    }
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-600">Resumen general de tu inventario</p>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {cards.map((card, index) => (
          <div key={index} className="bg-white rounded-lg shadow p-6">
            <div className="flex items-center">
              <div className={`${card.color} p-3 rounded-lg`}>
                <card.icon className="w-6 h-6 text-white" />
              </div>
              <div className="ml-4 flex-1">
                <p className="text-sm font-medium text-gray-600">{card.title}</p>
                <div className="flex items-center">
                  <p className="text-2xl font-semibold text-gray-900">{card.value}</p>
                  <span className="ml-2 text-sm text-green-600">{card.change}</span>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Activity */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white rounded-lg shadow">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">Actividad Reciente</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {[1, 2, 3].map((item) => (
                <div key={item} className="flex items-center space-x-3">
                  <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                  <div className="flex-1">
                    <p className="text-sm text-gray-900">Entrada de mercancía registrada</p>
                    <p className="text-xs text-gray-500">Hace 2 horas</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="bg-white rounded-lg shadow">
          <div className="p-6 border-b border-gray-200">
            <h3 className="text-lg font-medium text-gray-900">Alertas Pendientes</h3>
          </div>
          <div className="p-6">
            <div className="space-y-4">
              {metrics?.alerts?.low_stock_count > 0 ? (
                <div className="flex items-center space-x-3">
                  <AlertTriangle className="w-5 h-5 text-yellow-500" />
                  <div>
                    <p className="text-sm text-gray-900">
                      {metrics.alerts.low_stock_count} productos con stock bajo
                    </p>
                    <p className="text-xs text-gray-500">Requiere atención</p>
                  </div>
                </div>
              ) : (
                <p className="text-sm text-gray-500">No hay alertas pendientes</p>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;