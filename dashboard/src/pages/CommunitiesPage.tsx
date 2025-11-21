import React, { useState, useEffect } from 'react';
import { communitiesApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { Users, MessageSquare, Calendar, TrendingUp } from 'lucide-react';

const CommunitiesPage: React.FC = () => {
  const toast = useToast();
  const [communities, setCommunities] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchCommunities();
  }, []);

  const fetchCommunities = async () => {
    try {
      setLoading(true);
      const data = await communitiesApi.getCommunities();
      setCommunities(data);
    } catch (error: any) {
      console.error('Error fetching communities:', error);
      toast.error(error?.response?.data?.message || 'Failed to load communities');
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
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Communities</h1>
        <p className="text-gray-600">Manage and participate in property communities</p>
      </div>

      {communities.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow">
          <Users className="mx-auto h-12 w-12 text-gray-400 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No communities found</h3>
          <p className="text-gray-600">Communities will appear here once they are created.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {communities.map((community) => (
            <div key={community.communityId || community.id} className="bg-white rounded-lg shadow p-6 hover:shadow-lg transition-shadow">
              <h3 className="text-xl font-semibold mb-2">{community.name}</h3>
              <p className="text-gray-600 mb-4 line-clamp-2">{community.description}</p>
              <div className="flex items-center justify-between text-sm text-gray-500">
                <div className="flex items-center gap-2">
                  <Users className="h-4 w-4" />
                  <span>{community.memberCount || 0} members</span>
                </div>
                <div className="flex items-center gap-2">
                  <MessageSquare className="h-4 w-4" />
                  <span>{community.postCount || 0} posts</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default CommunitiesPage;

