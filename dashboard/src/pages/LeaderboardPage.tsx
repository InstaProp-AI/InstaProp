import React, { useState, useEffect } from 'react';
import { leaderboardApi } from '../services/api';
import { withTimeout } from '../utils/apiTimeout';
import { useToast } from '../contexts/ToastContext';
import { Trophy, Medal, Award, TrendingUp, DollarSign } from 'lucide-react';

const LeaderboardPage: React.FC = () => {
  const toast = useToast();
  const [leaderboard, setLeaderboard] = useState<any[]>([]);
  const [highlights, setHighlights] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchLeaderboard();
  }, []);

  const fetchLeaderboard = async () => {
    try {
      setLoading(true);
      setError(null);
      const [leaderboardData, highlightsData] = await Promise.all([
        withTimeout(
          leaderboardApi.getLeaderboard(),
          10000,
          'Request took too long. The server may be slow or unavailable. Please try again.'
        ),
        withTimeout(
          leaderboardApi.getHighlights(),
          10000,
          'Request took too long. The server may be slow or unavailable.'
        )
      ]);
      // The API returns an object with an Entries property, not a direct array
      // Ensure we always get an array - handle both camelCase and PascalCase
      let entries: any[] = [];
      if (leaderboardData) {
        // Check for camelCase 'entries' first (common in JSON responses)
        if (Array.isArray(leaderboardData.entries)) {
          entries = leaderboardData.entries;
        } 
        // Check for PascalCase 'Entries' (if JSON serialization preserves case)
        else if (Array.isArray(leaderboardData.Entries)) {
          entries = leaderboardData.Entries;
        } 
        // If the data itself is an array
        else if (Array.isArray(leaderboardData)) {
          entries = leaderboardData;
        }
      }
      setLeaderboard(entries);
      setHighlights(highlightsData);
    } catch (error: any) {
      console.error('Error fetching leaderboard:', error);
      let errorMessage = 'Failed to load leaderboard';
      if (error.message && error.message.includes('timed out')) {
        errorMessage = error.message;
      } else if (error.message && error.message.includes('Cannot connect')) {
        errorMessage = 'Cannot connect to server. Please check your connection and ensure the API is running.';
      } else {
        errorMessage = error?.response?.data?.message || error.message || errorMessage;
      }
      setError(errorMessage);
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const getRankIcon = (rank: number) => {
    if (rank === 1) return <Trophy className="h-6 w-6 text-yellow-500" />;
    if (rank === 2) return <Medal className="h-6 w-6 text-gray-400" />;
    if (rank === 3) return <Medal className="h-6 w-6 text-orange-600" />;
    return <Award className="h-5 w-5 text-gray-400" />;
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '50vh' }}>
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Leaderboard</h1>
          <p className="text-gray-600">Top performers and rankings</p>
        </div>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '40vh',
          flexDirection: 'column',
          gap: '1rem',
          padding: '2rem',
          backgroundColor: 'white',
          borderRadius: '0.5rem',
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)'
        }}>
          <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', color: '#ef4444' }}>Error Loading Leaderboard</h2>
          <p style={{ color: '#6b7280', textAlign: 'center', maxWidth: '500px' }}>{error}</p>
          <button
            onClick={fetchLeaderboard}
            style={{
              padding: '0.75rem 1.5rem',
              backgroundColor: '#2563eb',
              color: 'white',
              border: 'none',
              borderRadius: '0.5rem',
              cursor: 'pointer',
              fontSize: '1rem'
            }}
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Leaderboard</h1>
        <p className="text-gray-600">Top performers and rankings</p>
      </div>

      {highlights && (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
          {highlights.ThisWeek?.First && (
            <div className="bg-gradient-to-br from-yellow-400 to-yellow-600 rounded-lg p-6 text-white">
              <div className="flex items-center justify-between mb-4">
                <Trophy className="h-8 w-8" />
                <span className="font-bold text-lg">#1</span>
              </div>
              <h3 className="font-bold text-xl mb-2">{highlights.ThisWeek.First.DisplayName || 'Unknown'}</h3>
              <div className="flex items-center gap-2">
                <DollarSign className="h-5 w-5" />
                <span className="text-lg font-semibold">{highlights.ThisWeek.First.Points || 0} points</span>
              </div>
            </div>
          )}
        </div>
      )}

      {leaderboard.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow">
          <Trophy className="mx-auto h-12 w-12 text-gray-400 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No leaderboard data</h3>
          <p className="text-gray-600">Leaderboard rankings will appear here.</p>
        </div>
      ) : (
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Rank</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">User</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Points</th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Activity</th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {Array.isArray(leaderboard) && leaderboard.map((entry, index) => (
                <tr key={entry.AccountId || entry.accountId || entry.userId || index} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center gap-2">
                      {getRankIcon(entry.Rank || index + 1)}
                      <span className="font-medium">#{entry.Rank || index + 1}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="text-sm font-medium text-gray-900">{entry.DisplayName || entry.userName || entry.name || 'Unknown'}</div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center gap-2">
                      <DollarSign className="h-4 w-4 text-gray-400" />
                      <span className="text-sm text-gray-900">{entry.Points || entry.totalPoints || entry.points || 0}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center gap-2">
                      <TrendingUp className="h-4 w-4 text-green-500" />
                      <span className="text-sm text-gray-900">{entry.TotalRewards || entry.activityCount || 0}</span>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default LeaderboardPage;

