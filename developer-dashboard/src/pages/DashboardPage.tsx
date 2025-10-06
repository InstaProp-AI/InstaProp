import React, { useState, useEffect } from 'react';
import { 
  TrendingUp, 
  DollarSign, 
  Home, 
  Users, 
  Hammer, 
  Calendar,
  BarChart3,
  Eye,
  Clock,
  CheckCircle,
  AlertCircle,
  ArrowUpRight,
  ArrowDownRight,
  Activity,
  Target,
  Award,
  Zap
} from 'lucide-react';

interface DashboardStats {
  totalProperties: number;
  activeAuctions: number;
  totalBids: number;
  totalUsers: number;
  monthlyRevenue: number;
  averageBidAmount: number;
  propertiesSold: number;
  conversionRate: number;
}

interface RecentActivity {
  id: string;
  type: 'property' | 'auction' | 'bid' | 'user';
  title: string;
  description: string;
  timestamp: string;
  status: 'success' | 'warning' | 'info';
}

const DashboardPage: React.FC = () => {
  const [stats, setStats] = useState<DashboardStats>({
    totalProperties: 0,
    activeAuctions: 0,
    totalBids: 0,
    totalUsers: 0,
    monthlyRevenue: 0,
    averageBidAmount: 0,
    propertiesSold: 0,
    conversionRate: 0
  });

  const [recentActivity, setRecentActivity] = useState<RecentActivity[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Simulate API call
    setTimeout(() => {
      setStats({
        totalProperties: 47,
        activeAuctions: 12,
        totalBids: 234,
        totalUsers: 89,
        monthlyRevenue: 125000,
        averageBidAmount: 8500,
        propertiesSold: 8,
        conversionRate: 17.2
      });

      setRecentActivity([
        {
          id: '1',
          type: 'property',
          title: 'New Property Listed',
          description: 'Modern 3BR house in downtown area',
          timestamp: '2 minutes ago',
          status: 'success'
        },
        {
          id: '2',
          type: 'auction',
          title: 'Auction Started',
          description: 'Luxury penthouse auction began',
          timestamp: '15 minutes ago',
          status: 'info'
        },
        {
          id: '3',
          type: 'bid',
          title: 'High Bid Placed',
          description: '$125,000 bid on commercial property',
          timestamp: '1 hour ago',
          status: 'success'
        },
        {
          id: '4',
          type: 'user',
          title: 'New User Registered',
          description: 'Professional investor joined platform',
          timestamp: '2 hours ago',
          status: 'info'
        },
        {
          id: '5',
          type: 'property',
          title: 'Property Approved',
          description: 'Villa in beachfront location approved',
          timestamp: '3 hours ago',
          status: 'success'
        }
      ]);

      setLoading(false);
    }, 1000);
  }, []);

  const statCards = [
    {
      title: 'Total Properties',
      value: stats.totalProperties,
      change: '+12%',
      changeType: 'positive' as const,
      icon: Home,
      color: 'bg-blue-500',
      bgColor: 'bg-blue-50',
      textColor: 'text-blue-600'
    },
    {
      title: 'Active Auctions',
      value: stats.activeAuctions,
      change: '+8%',
      changeType: 'positive' as const,
      icon: Hammer,
      color: 'bg-orange-500',
      bgColor: 'bg-orange-50',
      textColor: 'text-orange-600'
    },
    {
      title: 'Total Bids',
      value: stats.totalBids,
      change: '+23%',
      changeType: 'positive' as const,
      icon: Target,
      color: 'bg-green-500',
      bgColor: 'bg-green-50',
      textColor: 'text-green-600'
    },
    {
      title: 'Total Users',
      value: stats.totalUsers,
      change: '+5%',
      changeType: 'positive' as const,
      icon: Users,
      color: 'bg-purple-500',
      bgColor: 'bg-purple-50',
      textColor: 'text-purple-600'
    },
    {
      title: 'Monthly Revenue',
      value: `$${stats.monthlyRevenue.toLocaleString()}`,
      change: '+18%',
      changeType: 'positive' as const,
      icon: DollarSign,
      color: 'bg-emerald-500',
      bgColor: 'bg-emerald-50',
      textColor: 'text-emerald-600'
    },
    {
      title: 'Avg Bid Amount',
      value: `$${stats.averageBidAmount.toLocaleString()}`,
      change: '+7%',
      changeType: 'positive' as const,
      icon: TrendingUp,
      color: 'bg-indigo-500',
      bgColor: 'bg-indigo-50',
      textColor: 'text-indigo-600'
    },
    {
      title: 'Properties Sold',
      value: stats.propertiesSold,
      change: '+15%',
      changeType: 'positive' as const,
      icon: CheckCircle,
      color: 'bg-teal-500',
      bgColor: 'bg-teal-50',
      textColor: 'text-teal-600'
    },
    {
      title: 'Conversion Rate',
      value: `${stats.conversionRate}%`,
      change: '+3%',
      changeType: 'positive' as const,
      icon: Award,
      color: 'bg-pink-500',
      bgColor: 'bg-pink-50',
      textColor: 'text-pink-600'
    }
  ];

  if (loading) {
    return (
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '50vh',
        background: 'linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%)'
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
      <div style={{ marginBottom: '2rem' }}>
        <h1 style={{
          fontSize: '2.5rem',
          fontWeight: 'bold',
          color: '#111827',
          marginBottom: '0.5rem',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent'
        }}>Dashboard Overview</h1>
        <p style={{
          fontSize: '1.125rem',
          color: '#6b7280',
          marginBottom: '1rem'
        }}>
          Welcome back! Here's what's happening with your property flipping business.
        </p>
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '1rem',
          padding: '1rem',
          backgroundColor: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          borderRadius: '1rem',
          color: 'white'
        }}>
          <Zap style={{ height: '1.5rem', width: '1.5rem' }} />
          <div>
            <p style={{ margin: 0, fontWeight: '500' }}>Business is booming!</p>
            <p style={{ margin: 0, fontSize: '0.875rem', opacity: 0.9 }}>
              Your revenue is up 18% this month compared to last month.
            </p>
          </div>
        </div>
      </div>

      {/* Stats Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))',
        gap: '1.5rem',
        marginBottom: '2rem'
      }}>
        {statCards.map((card, index) => (
          <div key={index} style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            padding: '1.5rem',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
            border: '1px solid #e5e7eb',
            transition: 'all 0.3s ease',
            background: 'linear-gradient(135deg, #ffffff 0%, #f8fafc 100%)',
            position: 'relative',
            overflow: 'hidden'
          }}>
            <div style={{
              position: 'absolute',
              top: 0,
              right: 0,
              width: '100px',
              height: '100px',
              background: `linear-gradient(135deg, ${card.color.replace('bg-', '')} 0%, ${card.color.replace('bg-', '')}80 100%)`,
              borderRadius: '50%',
              transform: 'translate(30px, -30px)',
              opacity: 0.1
            }} />
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
              <div style={{
                width: '3rem',
                height: '3rem',
                borderRadius: '0.75rem',
                backgroundColor: card.bgColor.replace('bg-', ''),
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                <card.icon style={{ 
                  height: '1.5rem', 
                  width: '1.5rem',
                  color: card.textColor.replace('text-', '')
                }} />
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.25rem',
                  fontSize: '0.875rem',
                  fontWeight: '500',
                  color: card.changeType === 'positive' ? '#059669' : '#dc2626'
                }}>
                  {card.changeType === 'positive' ? (
                    <ArrowUpRight style={{ height: '1rem', width: '1rem' }} />
                  ) : (
                    <ArrowDownRight style={{ height: '1rem', width: '1rem' }} />
                  )}
                  {card.change}
                </div>
                <p style={{ fontSize: '0.75rem', color: '#6b7280', margin: 0 }}>vs last month</p>
              </div>
            </div>
            <h3 style={{
              fontSize: '2rem',
              fontWeight: 'bold',
              color: '#111827',
              margin: '0 0 0.25rem 0'
            }}>{card.value}</h3>
            <p style={{
              fontSize: '0.875rem',
              color: '#6b7280',
              margin: 0
            }}>{card.title}</p>
          </div>
        ))}
      </div>

      {/* Charts and Analytics */}
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
          boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
          border: '1px solid #e5e7eb'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
            <h3 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#111827', margin: 0 }}>
              Revenue Trend
            </h3>
            <div style={{
              padding: '0.5rem 1rem',
              backgroundColor: '#f0f9ff',
              color: '#0369a1',
              borderRadius: '0.5rem',
              fontSize: '0.875rem',
              fontWeight: '500'
            }}>
              Last 30 days
            </div>
          </div>
          <div style={{
            height: '200px',
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            borderRadius: '0.75rem',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: 'white',
            fontSize: '1.125rem',
            fontWeight: '500'
          }}>
            📈 Revenue Chart Placeholder
          </div>
        </div>

        {/* Property Status */}
        <div style={{
          backgroundColor: 'white',
          borderRadius: '1rem',
          padding: '1.5rem',
          boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
          border: '1px solid #e5e7eb'
        }}>
          <h3 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#111827', marginBottom: '1.5rem' }}>
            Property Status
          </h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
            {[
              { label: 'Active Listings', value: 23, color: '#3b82f6', percentage: 49 },
              { label: 'Under Auction', value: 12, color: '#f59e0b', percentage: 26 },
              { label: 'Sold', value: 8, color: '#10b981', percentage: 17 },
              { label: 'Pending', value: 4, color: '#6b7280', percentage: 8 }
            ].map((item, index) => (
              <div key={index} style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div style={{
                  width: '1rem',
                  height: '1rem',
                  borderRadius: '50%',
                  backgroundColor: item.color
                }} />
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '0.25rem' }}>
                    <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>{item.label}</span>
                    <span style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>{item.value}</span>
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
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '1rem',
        padding: '1.5rem',
        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
        border: '1px solid #e5e7eb'
      }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
          <h3 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#111827', margin: 0 }}>
            Recent Activity
          </h3>
          <button style={{
            padding: '0.5rem 1rem',
            backgroundColor: '#f3f4f6',
            color: '#6b7280',
            border: 'none',
            borderRadius: '0.5rem',
            fontSize: '0.875rem',
            cursor: 'pointer',
            transition: 'all 0.2s'
          }}>
            View All
          </button>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
          {recentActivity.map((activity) => (
            <div key={activity.id} style={{
              display: 'flex',
              alignItems: 'center',
              gap: '1rem',
              padding: '1rem',
              backgroundColor: '#f8fafc',
              borderRadius: '0.75rem',
              transition: 'all 0.2s'
            }}>
              <div style={{
                width: '2.5rem',
                height: '2.5rem',
                borderRadius: '50%',
                backgroundColor: activity.status === 'success' ? '#dcfce7' : 
                               activity.status === 'warning' ? '#fef3c7' : '#dbeafe',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center'
              }}>
                {activity.type === 'property' && <Home style={{ height: '1.25rem', width: '1.25rem', color: '#059669' }} />}
                {activity.type === 'auction' && <Hammer style={{ height: '1.25rem', width: '1.25rem', color: '#d97706' }} />}
                {activity.type === 'bid' && <Target style={{ height: '1.25rem', width: '1.25rem', color: '#059669' }} />}
                {activity.type === 'user' && <Users style={{ height: '1.25rem', width: '1.25rem', color: '#2563eb' }} />}
              </div>
              <div style={{ flex: 1 }}>
                <h4 style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827', margin: '0 0 0.25rem 0' }}>
                  {activity.title}
                </h4>
                <p style={{ fontSize: '0.75rem', color: '#6b7280', margin: 0 }}>
                  {activity.description}
                </p>
              </div>
              <div style={{ textAlign: 'right' }}>
                <p style={{ fontSize: '0.75rem', color: '#6b7280', margin: 0 }}>
                  {activity.timestamp}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default DashboardPage;