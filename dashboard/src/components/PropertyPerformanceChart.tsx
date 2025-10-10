import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Legend, Tooltip } from 'recharts';

interface PropertyPerformanceChartProps {
  data?: any[];
}

const PropertyPerformanceChart: React.FC<PropertyPerformanceChartProps> = ({ data }) => {
  // Default sample data if no data provided
  const defaultData = [
    { name: 'Residential', value: 45, color: '#3b82f6' },
    { name: 'Commercial', value: 25, color: '#8b5cf6' },
    { name: 'Condo', value: 20, color: '#10b981' },
    { name: 'Townhouse', value: 10, color: '#f59e0b' },
  ];

  const chartData = data || defaultData;

  return (
    <ResponsiveContainer width="100%" height={300}>
      <PieChart>
        <Pie
          data={chartData}
          cx="50%"
          cy="50%"
          labelLine={false}
          label={(entry) => `${entry.name}: ${entry.value}`}
          outerRadius={100}
          fill="#8884d8"
          dataKey="value"
        >
          {chartData.map((entry, index) => (
            <Cell key={`cell-${index}`} fill={entry.color} />
          ))}
        </Pie>
        <Tooltip 
          contentStyle={{ 
            backgroundColor: 'white', 
            border: '1px solid #e5e7eb',
            borderRadius: '0.5rem',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
          }}
        />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
};

export default PropertyPerformanceChart;


