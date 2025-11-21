import React, { useState, useEffect } from 'react';
import { rewardsApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { Gift, Star, History, TrendingUp } from 'lucide-react';

const RewardsPage: React.FC = () => {
  const toast = useToast();
  const [redemptionHistory, setRedemptionHistory] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchRedemptionHistory();
  }, []);

  const fetchRedemptionHistory = async () => {
    try {
      setLoading(true);
      const data = await rewardsApi.getRedemptionHistory();
      setRedemptionHistory(data || []);
    } catch (error: any) {
      console.error('Error fetching redemption history:', error);
      toast.error(error?.response?.data?.message || 'Failed to load redemption history');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '50vh' }}>
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Rewards & Redemptions</h1>
        <p className="text-gray-600">Manage rewards and view redemption history</p>
      </div>

      {redemptionHistory.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow">
          <Gift className="mx-auto h-12 w-12 text-gray-400 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No redemptions found</h3>
          <p className="text-gray-600">Your reward redemption history will appear here.</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-lg font-semibold">Redemption History</h2>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Reward</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Points</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {redemptionHistory.map((redemption) => (
                  <tr key={redemption.redemptionId || redemption.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-2">
                        <History className="h-4 w-4 text-gray-400" />
                        <span className="text-sm text-gray-900">
                          {new Date(redemption.redeemedAt || redemption.createdAt).toLocaleDateString()}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-2">
                        <Gift className="h-4 w-4 text-purple-500" />
                        <span className="text-sm font-medium text-gray-900">
                          {redemption.rewardType || redemption.rewardName || 'Unknown'}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-2">
                        <Star className="h-4 w-4 text-yellow-500" />
                        <span className="text-sm text-gray-900">{redemption.pointsCost || redemption.points || 0}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${
                        redemption.status === 'Completed' || redemption.status === 'Approved'
                          ? 'bg-green-100 text-green-800'
                          : redemption.status === 'Pending'
                          ? 'bg-yellow-100 text-yellow-800'
                          : 'bg-gray-100 text-gray-800'
                      }`}>
                        {redemption.status || 'Pending'}
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

export default RewardsPage;

