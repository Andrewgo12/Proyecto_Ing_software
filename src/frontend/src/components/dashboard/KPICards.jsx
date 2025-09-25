import React from 'react';
import { Package, DollarSign, AlertTriangle, TrendingUp } from 'lucide-react';

const KPICards = ({ metrics }) => {
  const cards = [
    {
      title: 'Total Productos',
      value: metrics?.inventory?.total_products || 0,
      icon: Package,
      color: 'bg-blue-500',
      change: '+12%',
      changeColor: 'text-green-600'
    },
    {
      title: 'Valor Inventario',
      value: `$${(metrics?.inventory?.total_value || 0).toLocaleString()}`,
      icon: DollarSign,
      color: 'bg-green-500',
      change: '+8%',
      changeColor: 'text-green-600'
    },
    {
      title: 'Stock Bajo',
      value: metrics?.alerts?.low_stock_count || 0,
      icon: AlertTriangle,
      color: 'bg-yellow-500',
      change: '-5%',
      changeColor: 'text-green-600'
    },
    {
      title: 'Movimientos (30d)',
      value: metrics?.movements?.total_movements || 0,
      icon: TrendingUp,
      color: 'bg-purple-500',
      change: '+15%',
      changeColor: 'text-green-600'
    }
  ];

  return (
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
                <span className={`ml-2 text-sm ${card.changeColor}`}>{card.change}</span>
              </div>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
};

export default KPICards;