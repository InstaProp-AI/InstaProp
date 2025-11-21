import React, { useState, useEffect } from 'react';
import { priceHistoryApi, propertiesApi, authApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { TrendingUp, TrendingDown, DollarSign, Calendar, Building } from 'lucide-react';

const PriceHistoryPage: React.FC = () => {
  const toast = useToast();
  const [priceHistory, setPriceHistory] = useState<any[]>([]);
  const [properties, setProperties] = useState<any[]>([]);
  const [selectedPropertyId, setSelectedPropertyId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchProperties();
  }, []);

  useEffect(() => {
    if (selectedPropertyId) {
      fetchPriceHistory(selectedPropertyId);
    }
  }, [selectedPropertyId]);

  const fetchProperties = async () => {
    try {
      // Get user role to determine which endpoint to use
      const currentUser = await authApi.getCurrentAccount();
      // Check roleName first (from backend), then roleId, then legacy type
      const isAdmin = currentUser.roleName === 'Admin' || currentUser.roleId === 9823749823749823 || currentUser.type === 'Admin';
      const isDeveloper = currentUser.roleName === 'Developer' || currentUser.roleId === 7823647823647823 || currentUser.type === 'Developer';
      const userRole = isAdmin ? 'Admin' : (isDeveloper ? 'Developer' : null);
      
      // Get properties - handle both paginated (Admin) and non-paginated (Developer) responses
      const response = await propertiesApi.getProperties(userRole || undefined);
      const propertiesData = userRole === 'Admin' && 'data' in response 
        ? (response as any).data || []
        : (response as any[]) || [];
      
      setProperties(propertiesData);
      if (propertiesData.length > 0 && !selectedPropertyId) {
        setSelectedPropertyId(propertiesData[0].propertyId);
      }
    } catch (error: any) {
      console.error('Error fetching properties:', error);
      toast.error(error?.response?.data?.message || 'Failed to load properties');
    }
  };

  const fetchPriceHistory = async (propertyId: number) => {
    try {
      setLoading(true);
      const data = await priceHistoryApi.getPriceHistoryForChildProperty(propertyId);
      setPriceHistory(data || []);
    } catch (error: any) {
      console.error('Error fetching price history:', error);
      toast.error(error?.response?.data?.message || 'Failed to load price history');
    } finally {
      setLoading(false);
    }
  };

  if (loading && !priceHistory.length) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '50vh' }}>
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Price History</h1>
        <p className="text-gray-600">Track property price changes over time</p>
      </div>

      <div className="mb-6">
        <label className="block text-sm font-medium text-gray-700 mb-2">Select Property</label>
        <select
          value={selectedPropertyId || ''}
          onChange={(e) => setSelectedPropertyId(Number(e.target.value))}
          className="block w-full max-w-md px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
        >
          <option value="">Select a property</option>
          {properties.map((property) => (
            <option key={property.propertyId} value={property.propertyId}>
              {property.name} - {property.location}
            </option>
          ))}
        </select>
      </div>

      {priceHistory.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow">
          <TrendingUp className="mx-auto h-12 w-12 text-gray-400 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No price history found</h3>
          <p className="text-gray-600">Price history will appear here once recorded for this property.</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold">Price History</h2>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Price</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Change</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Source</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {priceHistory.map((entry, index) => {
                  const previousPrice = index > 0 ? priceHistory[index - 1].price : entry.price;
                  const change = entry.price - previousPrice;
                  const changePercent = previousPrice > 0 ? ((change / previousPrice) * 100).toFixed(2) : 0;
                  
                  return (
                    <tr key={entry.priceHistoryId || entry.id || index} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4 text-gray-400" />
                          <span className="text-sm text-gray-900">
                            {new Date(entry.date || entry.recordedAt).toLocaleDateString()}
                          </span>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="flex items-center gap-2">
                          <DollarSign className="h-4 w-4 text-gray-400" />
                          <span className="text-sm font-medium text-gray-900">
                            {entry.price?.toLocaleString() || 'N/A'}
                          </span>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        {index > 0 && (
                          <div className={`flex items-center gap-1 ${change >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                            {change >= 0 ? (
                              <TrendingUp className="h-4 w-4" />
                            ) : (
                              <TrendingDown className="h-4 w-4" />
                            )}
                            <span className="text-sm font-medium">
                              {change >= 0 ? '+' : ''}{changePercent}%
                            </span>
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="text-sm text-gray-500">{entry.source || 'Manual'}</span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default PriceHistoryPage;

