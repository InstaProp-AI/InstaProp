import React from 'react';
import { LineChart, Line, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

interface RevenueChartProps {
  data?: any[];
  type?: 'line' | 'area';
}

const RevenueChart: React.FC<RevenueChartProps> = ({ data, type = 'area' }) => {
  // Default sample data if no data provided
  const defaultData = [
    { date: 'Jan', revenue: 45000, bids: 23 },
    { date: 'Feb', revenue: 52000, bids: 28 },
    { date: 'Mar', revenue: 48000, bids: 25 },
    { date: 'Apr', revenue: 61000, bids: 32 },
    { date: 'May', revenue: 55000, bids: 29 },
    { date: 'Jun', revenue: 67000, bids: 35 },
    { date: 'Jul', revenue: 74000, bids: 38 },
    { date: 'Aug', revenue: 69000, bids: 36 },
    { date: 'Sep', revenue: 81000, bids: 42 },
    { date: 'Oct', revenue: 92000, bids: 48 },
  ];

  const chartData = data || defaultData;

  if (type === 'line') {
    return (
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={chartData}>
          <defs>
            <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#667eea" stopOpacity={0.8}/>
              <stop offset="95%" stopColor="#764ba2" stopOpacity={0.8}/>
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
          <XAxis dataKey="date" stroke="#6b7280" style={{ fontSize: '0.75rem' }} />
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
          <Line 
            type="monotone" 
            dataKey="revenue" 
            stroke="url(#colorRevenue)" 
            strokeWidth={3}
            dot={{ fill: '#667eea', r: 4 }}
            activeDot={{ r: 6 }}
          />
        </LineChart>
      </ResponsiveContainer>
    );
  }

  return (
    <ResponsiveContainer width="100%" height={300}>
      <AreaChart data={chartData}>
        <defs>
          <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#667eea" stopOpacity={0.8}/>
            <stop offset="95%" stopColor="#764ba2" stopOpacity={0.1}/>
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
        <XAxis dataKey="date" stroke="#6b7280" style={{ fontSize: '0.75rem' }} />
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
        <Area 
          type="monotone" 
          dataKey="revenue" 
          stroke="#667eea" 
          strokeWidth={2}
          fillOpacity={1} 
          fill="url(#colorRevenue)" 
        />
      </AreaChart>
    </ResponsiveContainer>
  );
};

export default RevenueChart;


