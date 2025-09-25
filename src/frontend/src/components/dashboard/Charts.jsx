import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';

const Charts = ({ data }) => {
  const movementData = [
    { name: 'Ene', entradas: 120, salidas: 80 },
    { name: 'Feb', entradas: 150, salidas: 95 },
    { name: 'Mar', entradas: 180, salidas: 110 },
    { name: 'Abr', entradas: 140, salidas: 85 },
    { name: 'May', entradas: 200, salidas: 130 },
    { name: 'Jun', entradas: 170, salidas: 100 }
  ];

  const stockStatusData = [
    { name: 'Normal', value: 75, color: '#10B981' },
    { name: 'Stock Bajo', value: 20, color: '#F59E0B' },
    { name: 'Agotado', value: 5, color: '#EF4444' }
  ];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Movement Chart */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">
          Movimientos Mensuales
        </h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={movementData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="name" />
            <YAxis />
            <Tooltip />
            <Bar dataKey="entradas" fill="#10B981" name="Entradas" />
            <Bar dataKey="salidas" fill="#EF4444" name="Salidas" />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Stock Status Chart */}
      <div className="bg-white rounded-lg shadow p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-4">
          Estado del Stock
        </h3>
        <ResponsiveContainer width="100%" height={300}>
          <PieChart>
            <Pie
              data={stockStatusData}
              cx="50%"
              cy="50%"
              outerRadius={80}
              dataKey="value"
              label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
            >
              {stockStatusData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={entry.color} />
              ))}
            </Pie>
            <Tooltip />
          </PieChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default Charts;