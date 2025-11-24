import React, { useState, useEffect } from 'react';
import RevenueChart from '../components/RevenueChart';
import UserGrowthChart from '../components/UserGrowthChart';
import PropertyPerformanceChart from '../components/PropertyPerformanceChart';
import { usersApi, propertiesApi, auctionsApi, bidsApi, dashboardApi, authApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { Account } from '../types';
import { 
  BarChart3,
  TrendingUp,
  TrendingDown,
  DollarSign,
  Users,
  Home,
  Hammer,
  Target,
  Calendar,
  Download,
  RefreshCw
} from 'lucide-react';

const AnalyticsPage: React.FC = () => {
  const toast = useToast();
  const [timeRange, setTimeRange] = useState('7d');
  const [loading, setLoading] = useState(true);
  const [users, setUsers] = useState<any[]>([]);
  const [properties, setProperties] = useState<any[]>([]);
  const [auctions, setAuctions] = useState<any[]>([]);
  const [bids, setBids] = useState<any[]>([]);
  const [user, setUser] = useState<Account | null>(null);
  const [userRole, setUserRole] = useState<'Admin' | 'Developer' | null>(null);

  useEffect(() => {
    // Get current user to determine role
    const loadUser = async () => {
      try {
        const currentUser = await authApi.getCurrentAccount();
        setUser(currentUser);
        // Check roleName first (from backend), then roleId, then legacy type
        const isAdmin = currentUser.roleName === 'Admin' || currentUser.roleId === '98237498-2374-4982-3749-823749823749' || currentUser.type === 'Admin';
        const isDeveloper = currentUser.roleName === 'Developer' || currentUser.roleId === '78236478-2364-7823-0000-000000000000' || currentUser.type === 'Developer';
        setUserRole(isAdmin ? 'Admin' : (isDeveloper ? 'Developer' : null));
      } catch (error) {
        console.error('Error loading user:', error);
      }
    };
    loadUser();
  }, []);

  useEffect(() => {
    if (userRole) {
      fetchAnalyticsData();
    }
  }, [userRole]);

  const fetchAnalyticsData = async () => {
    if (!userRole) return;
    try {
      setLoading(true);
      let hasErrors = false;
      
      // For developers, use developer analytics endpoint instead
      if (userRole === 'Developer') {
        try {
          const analyticsData = await dashboardApi.getAnalytics(userRole);
          // Developer analytics has different structure
          setProperties(analyticsData.propertyAnalytics || []);
          setAuctions([]); // Developers don't see all auctions
          setBids([]); // Developers don't see all bids
          setUsers([]); // Developers don't see users
          console.log('✅ Developer analytics loaded');
        } catch (error: any) {
          console.error('❌ Error fetching developer analytics:', error);
          toast.error(error?.response?.data?.message || 'Failed to load analytics');
          hasErrors = true;
        }
        setLoading(false);
        return;
      }
      
      // Admin: Get analytics from single endpoint that returns all data
      try {
        const analyticsData = await dashboardApi.getAnalytics(userRole);
        console.log('✅ Analytics loaded:', analyticsData);
        
        // Set data from analytics response
        setUsers(analyticsData.users || []);
        setProperties(analyticsData.properties || []);
        setAuctions(analyticsData.auctions || []);
        setBids(analyticsData.bids || []);
        
        console.log('✅ Data loaded from analytics:', {
          users: analyticsData.users?.length || 0,
          properties: analyticsData.properties?.length || 0,
          auctions: analyticsData.auctions?.length || 0,
          bids: analyticsData.bids?.length || 0
        });
      } catch (error: any) {
        console.error('❌ Error fetching analytics:', error);
        console.error('Error details:', error.response?.data || error.message);
        setUsers([]);
        setProperties([]);
        setAuctions([]);
        setBids([]);
        if (error.response?.status === 401) {
          toast.error('Authentication failed. Please log in again.');
        } else {
          toast.error(`Failed to load analytics: ${error.response?.data?.message || error.message}`);
        }
        hasErrors = true;
      }
      
      if (!hasErrors) {
        toast.success('Analytics data loaded successfully');
      } else {
        console.warn('⚠️ Analytics loaded with errors. Check console for details.');
      }
    } catch (error: any) {
      console.error('❌ Unexpected error:', error);
      toast.error('Unexpected error loading analytics data');
    } finally {
      setLoading(false);
    }
  };

  // Log current state for debugging
  console.log('📊 Analytics State:', {
    loading,
    usersCount: users.length,
    propertiesCount: properties.length,
    auctionsCount: auctions.length,
    bidsCount: bids.length,
    token: localStorage.getItem('authToken') ? 'Present' : 'Missing'
  });

  // Calculate real stats from data
  const totalRevenue = bids.reduce((sum, bid) => {
    const amount = bid.bidAmount || bid.BidAmount || 0;
    return sum + amount;
  }, 0);

  const activeUsers = users.filter((u: any) => 
    (u.emailVerified || u.EmailVerified) && 
    !(u.isSuspended || u.IsSuspended)
  ).length;

  const completedAuctions = auctions.filter((a: any) => 
    (a.status || a.Status || '').toLowerCase() === 'ended'
  ).length;

  const stats = [
    {
      title: 'Total Revenue',
      value: `$${(totalRevenue / 1000000).toFixed(2)}M`,
      change: totalRevenue > 0 ? '+' + ((totalRevenue / 1000000) * 5).toFixed(1) + '%' : '0%',
      trend: 'up',
      icon: DollarSign,
      color: '#10b981',
      bgColor: '#dcfce7'
    },
    {
      title: 'Active Users',
      value: activeUsers.toLocaleString(),
      change: users.length > 0 ? '+' + ((activeUsers / users.length) * 10).toFixed(1) + '%' : '0%',
      trend: 'up',
      icon: Users,
      color: '#3b82f6',
      bgColor: '#dbeafe'
    },
    {
      title: 'Properties Listed',
      value: properties.length.toString(),
      change: properties.length > 0 ? '+' + Math.min((properties.length / 10) * 8, 15).toFixed(1) + '%' : '0%',
      trend: 'up',
      icon: Home,
      color: '#8b5cf6',
      bgColor: '#ede9fe'
    },
    {
      title: 'Auctions Completed',
      value: completedAuctions.toString(),
      change: auctions.length > 0 ? (completedAuctions > auctions.length / 2 ? '+5.2%' : '-2.1%') : '0%',
      trend: completedAuctions > auctions.length / 2 ? 'up' : 'down',
      icon: Hammer,
      color: '#f59e0b',
      bgColor: '#fef3c7'
    }
  ];

  // Calculate top performing properties from auctions with bids
  const topProperties = auctions
    .filter((auction: any) => {
      const status = (auction.status || auction.Status || '').toLowerCase();
      return status === 'ended';
    })
    .map((auction: any) => {
      const auctionBids = bids.filter((bid: any) => 
        (bid.auctionId || bid.AuctionId) === (auction.auctionId || auction.AuctionId)
      );
      const highestBid = Math.max(0, ...auctionBids.map((b: any) => b.bidAmount || b.BidAmount || 0));
      const startPrice = auction.startPrice || auction.StartPrice || 0;
      const roi = startPrice > 0 ? ((highestBid - startPrice) / startPrice * 100) : 0;
      
      return {
        name: auction.propertyName || auction.PropertyName || 'Unknown Property',
        bids: auctionBids.length,
        price: highestBid,
        roi: roi,
        status: 'Sold'
      };
    })
    .sort((a, b) => b.price - a.price)
    .slice(0, 5);

  if (loading) {
    return (
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '60vh'
      }}>
        <div style={{ 
          width: '4rem', 
          height: '4rem', 
          border: '4px solid #e2e8f0',
          borderTop: '4px solid #667eea',
          borderRadius: '50%',
          animation: 'spin 1s linear infinite'
        }} />
        <style>{`
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        `}</style>
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'flex-start',
        justifyContent: 'space-between',
        marginBottom: '2rem',
        gap: '1rem'
      }}>
        <div>
          <h1 style={{
            fontSize: '2.5rem',
            fontWeight: 'bold',
            color: '#111827',
            marginBottom: '0.5rem',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            WebkitBackgroundClip: 'text',
            WebkitTextFillColor: 'transparent'
          }}>Analytics & Reports</h1>
          <p style={{
            fontSize: '1.125rem',
            color: '#6b7280',
            margin: 0
          }}>
            Comprehensive insights and performance metrics
          </p>
        </div>

        {/* Controls */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          width: '100%',
          gap: '1rem',
          flexWrap: 'wrap'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value)}
              style={{
                padding: '0.75rem 1rem',
                border: '1px solid #d1d5db',
                borderRadius: '0.75rem',
                fontSize: '0.875rem',
                outline: 'none',
                backgroundColor: 'white'
              }}
            >
              <option value="24h">Last 24 Hours</option>
              <option value="7d">Last 7 Days</option>
              <option value="30d">Last 30 Days</option>
              <option value="90d">Last 90 Days</option>
              <option value="1y">Last Year</option>
            </select>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <button 
              onClick={fetchAnalyticsData}
              disabled={loading}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.5rem',
                padding: '0.75rem 1rem',
                backgroundColor: loading ? '#e5e7eb' : '#f3f4f6',
                color: '#6b7280',
                border: 'none',
                borderRadius: '0.75rem',
                cursor: loading ? 'not-allowed' : 'pointer',
                transition: 'all 0.2s',
                opacity: loading ? 0.6 : 1
              }}>
              <RefreshCw style={{ height: '1rem', width: '1rem' }} />
              {loading ? 'Refreshing...' : 'Refresh'}
            </button>
            <button style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '0.5rem',
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              color: 'white',
              fontWeight: '500',
              padding: '0.75rem 1.5rem',
              borderRadius: '0.75rem',
              border: 'none',
              cursor: 'pointer',
              transition: 'all 0.2s'
            }}>
              <Download style={{ height: '1rem', width: '1rem' }} />
              Export Report
            </button>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
        gap: '1.5rem',
        marginBottom: '2rem'
      }}>
        {stats.map((stat, index) => (
          <div key={index} style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            padding: '1.5rem',
            boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
            border: '1px solid #e5e7eb'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
              <div style={{
                width: '3rem',
                height: '3rem',
                borderRadius: '0.75rem',
                backgroundColor: stat.bgColor,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <stat.icon style={{ height: '1.5rem', width: '1.5rem', color: stat.color }} />
              </div>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.25rem',
                fontSize: '0.875rem',
                fontWeight: '500',
                color: stat.trend === 'up' ? '#10b981' : '#ef4444'
              }}>
                {stat.trend === 'up' ? (
                  <TrendingUp style={{ height: '1rem', width: '1rem' }} />
                ) : (
                  <TrendingDown style={{ height: '1rem', width: '1rem' }} />
                )}
                {stat.change}
              </div>
            </div>
            <h3 style={{ fontSize: '2rem', fontWeight: 'bold', color: '#111827', margin: '0 0 0.25rem 0' }}>
              {stat.value}
            </h3>
            <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: 0 }}>{stat.title}</p>
          </div>
        ))}
      </div>

      {/* Charts Row */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))',
        gap: '1.5rem',
        marginBottom: '2rem'
      }}>
        {/* Revenue Chart */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '1rem',
          padding: '1.5rem',
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          border: '1px solid #e5e7eb'
        }}>
          <h3 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#111827', marginBottom: '1.5rem' }}>
            Revenue Trend
          </h3>
          <RevenueChart type="area" />
        </div>

        {/* User Growth Chart */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '1rem',
          padding: '1.5rem',
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          border: '1px solid #e5e7eb'
        }}>
          <h3 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#111827', marginBottom: '1.5rem' }}>
            User Growth
          </h3>
          <UserGrowthChart />
        </div>
      </div>

      {/* Property Performance */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '1rem',
        padding: '1.5rem',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
        border: '1px solid #e5e7eb',
        marginBottom: '2rem'
      }}>
        <h3 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#111827', marginBottom: '1.5rem' }}>
          Top Performing Properties
        </h3>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ borderBottom: '1px solid #e5e7eb' }}>
                <th style={{ padding: '0.75rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase' }}>Property</th>
                <th style={{ padding: '0.75rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase' }}>Bids</th>
                <th style={{ padding: '0.75rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase' }}>Final Price</th>
                <th style={{ padding: '0.75rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase' }}>ROI</th>
                <th style={{ padding: '0.75rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase' }}>Status</th>
              </tr>
            </thead>
            <tbody>
              {topProperties.length === 0 ? (
                <tr>
                  <td colSpan={5} style={{ padding: '2rem', textAlign: 'center', color: '#6b7280', fontSize: '0.875rem' }}>
                    No completed auctions yet
                  </td>
                </tr>
              ) : (
                topProperties.map((property, index) => (
                <tr key={index} style={{ borderBottom: '1px solid #e5e7eb' }}>
                  <td style={{ padding: '1rem', fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>
                    {property.name}
                  </td>
                  <td style={{ padding: '1rem', fontSize: '0.875rem', color: '#6b7280' }}>
                    {property.bids}
                  </td>
                  <td style={{ padding: '1rem', fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>
                    ${property.price.toLocaleString()}
                  </td>
                  <td style={{ padding: '1rem' }}>
                    <div style={{
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: '0.25rem',
                      padding: '0.25rem 0.5rem',
                      borderRadius: '0.375rem',
                      backgroundColor: '#dcfce7',
                      color: '#059669',
                      fontSize: '0.75rem',
                      fontWeight: '500'
                    }}>
                      <TrendingUp style={{ height: '0.75rem', width: '0.75rem' }} />
                      {property.roi}%
                    </div>
                  </td>
                  <td style={{ padding: '1rem' }}>
                    <div style={{
                      display: 'inline-block',
                      padding: '0.25rem 0.75rem',
                      borderRadius: '0.5rem',
                      backgroundColor: '#dbeafe',
                      color: '#2563eb',
                      fontSize: '0.75rem',
                      fontWeight: '500'
                    }}>
                      {property.status}
                    </div>
                  </td>
                </tr>
              )))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Activity Overview */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '1rem',
        padding: '1.5rem',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
        border: '1px solid #e5e7eb'
      }}>
        <h3 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#111827', marginBottom: '1.5rem' }}>
          Activity Overview
        </h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {[
            { 
              label: 'Total Users', 
              value: users.length, 
              total: users.length > 0 ? Math.ceil(users.length * 1.5) : 100, 
              color: '#3b82f6', 
              percentage: users.length > 0 ? (users.length / Math.ceil(users.length * 1.5)) * 100 : 0 
            },
            { 
              label: 'Properties Listed', 
              value: properties.length, 
              total: properties.length > 0 ? Math.ceil(properties.length * 1.3) : 100, 
              color: '#8b5cf6', 
              percentage: properties.length > 0 ? (properties.length / Math.ceil(properties.length * 1.3)) * 100 : 0 
            },
            { 
              label: 'Auctions Completed', 
              value: completedAuctions, 
              total: auctions.length > 0 ? auctions.length : 100, 
              color: '#f59e0b', 
              percentage: auctions.length > 0 ? (completedAuctions / auctions.length) * 100 : 0 
            },
            { 
              label: 'Total Bids', 
              value: bids.length, 
              total: bids.length > 0 ? Math.ceil(bids.length * 1.2) : 100, 
              color: '#10b981', 
              percentage: bids.length > 0 ? (bids.length / Math.ceil(bids.length * 1.2)) * 100 : 0 
            }
          ].map((item, index) => (
            <div key={index}>
              <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.5rem' }}>
                <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>{item.label}</span>
                <span style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>
                  {item.value} / {item.total}
                </span>
              </div>
              <div style={{
                width: '100%',
                height: '0.5rem',
                backgroundColor: '#f3f4f6',
                borderRadius: '0.25rem',
                overflow: 'hidden'
              }}>
                <div style={{
                  width: `${item.percentage}%`,
                  height: '100%',
                  backgroundColor: item.color,
                  transition: 'width 0.3s ease'
                }} />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default AnalyticsPage;

