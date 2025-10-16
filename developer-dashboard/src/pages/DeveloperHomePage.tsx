import React, { useState, useEffect } from 'react';
import { developerApi, DeveloperAnalytics } from '../services/developerApi';
import DeveloperStatsCard from '../components/DeveloperStatsCard';
import PropertyAnalyticsChart from '../components/PropertyAnalyticsChart';
import { 
  TrendingUp, 
  DollarSign, 
  Home, 
  MessageSquare,
  Eye,
  CheckCircle,
  BarChart3,
  Target
} from 'lucide-react';

const DeveloperHomePage: React.FC = () => {
  const [analytics, setAnalytics] = useState<DeveloperAnalytics | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadAnalytics();
  }, []);

  const loadAnalytics = async () => {
    try {
      const data = await developerApi.getAnalytics();
      setAnalytics(data);
    } catch (error) {
      console.error('Error loading analytics:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6">Developer Dashboard</h1>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <DeveloperStatsCard
          title="Total Properties"
          value={analytics?.totalProperties || 0}
          icon={<Home className="w-6 h-6" />}
          color="blue"
        />
        <DeveloperStatsCard
          title="Active Auctions"
          value={analytics?.activeAuctions || 0}
          icon={<TrendingUp className="w-6 h-6" />}
          color="green"
        />
        <DeveloperStatsCard
          title="Properties Sold"
          value={analytics?.soldProperties || 0}
          icon={<CheckCircle className="w-6 h-6" />}
          color="purple"
        />
        <DeveloperStatsCard
          title="Total Revenue"
          value={`$${(analytics?.totalRevenue || 0).toLocaleString()}`}
          icon={<DollarSign className="w-6 h-6" />}
          color="yellow"
        />
      </div>

      {/* Secondary Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <DeveloperStatsCard
          title="Chat Inquiries"
          value={analytics?.chatInquiries || 0}
          icon={<MessageSquare className="w-6 h-6" />}
          color="indigo"
        />
        <DeveloperStatsCard
          title="Total Bids"
          value={analytics?.totalBids || 0}
          icon={<Target className="w-6 h-6" />}
          color="pink"
        />
        <DeveloperStatsCard
          title="Total Views"
          value="0"
          icon={<Eye className="w-6 h-6" />}
          color="cyan"
        />
        <DeveloperStatsCard
          title="Conversion Rate"
          value={`${(analytics?.chatConversionRate || 0).toFixed(1)}%`}
          icon={<BarChart3 className="w-6 h-6" />}
          color="orange"
        />
      </div>

      {/* Property Analytics Chart */}
      {analytics && analytics.propertyAnalytics.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-xl font-bold mb-4">Property Performance</h2>
          <PropertyAnalyticsChart data={analytics.propertyAnalytics} />
        </div>
      )}

      {/* Quick Stats Table */}
      {analytics && analytics.propertyAnalytics.length > 0 && (
        <div className="mt-8 bg-white rounded-lg shadow overflow-hidden">
          <h2 className="text-xl font-bold p-6 border-b">Property Details</h2>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Property
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Location
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Chat Inquiries
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Total Bids
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Current Price
                  </th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Status
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {analytics.propertyAnalytics.map((property) => (
                  <tr key={property.propertyId}>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm font-medium text-gray-900">
                        {property.propertyName}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-500">{property.propertyLocation || 'N/A'}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">{property.chatInquiries}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">{property.totalBids}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">${property.currentPrice.toLocaleString()}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        property.status === 'Approved' 
                          ? 'bg-green-100 text-green-800' 
                          : 'bg-yellow-100 text-yellow-800'
                      }`}>
                        {property.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
};

export default DeveloperHomePage;

