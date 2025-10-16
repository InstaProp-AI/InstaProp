import React from 'react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { PropertyAnalytics } from '../services/developerApi';

interface PropertyAnalyticsChartProps {
  data: PropertyAnalytics[];
}

const PropertyAnalyticsChart: React.FC<PropertyAnalyticsChartProps> = ({ data }) => {
  const chartData = data.map((property) => ({
    name: property.propertyName.length > 20 
      ? property.propertyName.substring(0, 20) + '...' 
      : property.propertyName,
    chats: property.chatInquiries,
    bids: property.totalBids,
    views: property.views,
  }));

  return (
    <ResponsiveContainer width="100%" height={400}>
      <BarChart data={chartData}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="name" angle={-45} textAnchor="end" height={100} />
        <YAxis />
        <Tooltip />
        <Legend />
        <Bar dataKey="chats" fill="#8884d8" name="Chat Inquiries" />
        <Bar dataKey="bids" fill="#82ca9d" name="Total Bids" />
        <Bar dataKey="views" fill="#ffc658" name="Views" />
      </BarChart>
    </ResponsiveContainer>
  );
};

export default PropertyAnalyticsChart;

