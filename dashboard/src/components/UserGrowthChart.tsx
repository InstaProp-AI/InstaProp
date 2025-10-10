import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

interface UserGrowthChartProps {
  data?: any[];
}

const UserGrowthChart: React.FC<UserGrowthChartProps> = ({ data }) => {
  // Default sample data if no data provided
  const defaultData = [
    { month: 'Jan', users: 12, developers: 2 },
    { month: 'Feb', users: 19, developers: 3 },
    { month: 'Mar', users: 25, developers: 4 },
    { month: 'Apr', users: 31, developers: 5 },
    { month: 'May', users: 38, developers: 6 },
    { month: 'Jun', users: 45, developers: 7 },
    { month: 'Jul', users: 54, developers: 8 },
    { month: 'Aug', users: 62, developers: 9 },
    { month: 'Sep', users: 71, developers: 10 },
    { month: 'Oct', users: 89, developers: 12 },
  ];

  const chartData = data || defaultData;

  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart data={chartData}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
        <XAxis dataKey="month" stroke="#6b7280" style={{ fontSize: '0.75rem' }} />
        <YAxis stroke="#6b7280" style={{ fontSize: '0.75rem' }} />
        <Tooltip 
          contentStyle={{ 
            backgroundColor: 'white', 
            border: '1px solid #e5e7eb',
            borderRadius: '0.5rem',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
          }}
        />
        <Legend />
        <Bar dataKey="users" fill="#10b981" radius={[8, 8, 0, 0]} />
        <Bar dataKey="developers" fill="#3b82f6" radius={[8, 8, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
};

export default UserGrowthChart;


