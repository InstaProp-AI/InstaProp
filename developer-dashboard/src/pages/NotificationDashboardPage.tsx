import React, { useState, useEffect } from 'react';
import { Bell, Send, Users, CheckCircle, AlertCircle, Loader } from 'lucide-react';
import { notificationsApi } from '../services/api';
import { useToast } from '../hooks/useToast';

interface UserStats {
  totalUsers: number;
  propertyOwnersCount: number;
  auctionOwnersCount: number;
  biddersCount: number;
  verifiedCount: number;
  unverifiedCount: number;
}

interface UserSummary {
  accountId: number;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  status: string;
  createdAt: string;
}

const NotificationDashboardPage: React.FC = () => {
  const [stats, setStats] = useState<UserStats | null>(null);
  const [users, setUsers] = useState<UserSummary[]>([]);
  const [selectedTargetType, setSelectedTargetType] = useState('logged_in_users');
  const [selectedUserIds, setSelectedUserIds] = useState<number[]>([]);
  const [title, setTitle] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [sending, setSending] = useState(false);
  const [showUserSelector, setShowUserSelector] = useState(false);
  const { showToast } = useToast();

  const targetTypes = {
    all_users_including_guests: 'Everyone (Including Visitors)',
    guests_only: 'Visitors Only (Not Logged In)',
    logged_in_users: 'Registered Users',
    property_owners: 'Property Owners',
    auction_owners: 'Active Auction Sellers',
    bidders: 'Active Bidders',
    verified_users: 'Verified Accounts',
    unverified_users: 'Unverified Accounts',
    specific: 'Selected Users',
  };

  useEffect(() => {
    loadStats();
  }, []);

  useEffect(() => {
    if (selectedTargetType === 'specific') {
      loadUsers();
    }
  }, [selectedTargetType]);

  const loadStats = async () => {
    try {
      setLoading(true);
      const data = await notificationsApi.getUserStats();
      setStats(data);
    } catch (error: any) {
      showToast(error.message || 'Failed to load statistics', 'error');
    } finally {
      setLoading(false);
    }
  };

  const loadUsers = async () => {
    try {
      setLoading(true);
      const data = await notificationsApi.getUsers();
      setUsers(data);
    } catch (error: any) {
      showToast(error.message || 'Failed to load users', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleSendNotification = async () => {
    if (!title.trim() || !message.trim()) {
      showToast('Please enter title and message', 'error');
      return;
    }

    if (selectedTargetType === 'specific' && selectedUserIds.length === 0) {
      showToast('Please select at least one user', 'error');
      return;
    }

    const confirmed = window.confirm(
      `Send notification to ${targetTypes[selectedTargetType as keyof typeof targetTypes]}?${
        selectedTargetType === 'specific' ? `\n\nSelected: ${selectedUserIds.length} user(s)` : ''
      }`
    );

    if (!confirmed) return;

    try {
      setSending(true);
      const response = await notificationsApi.sendNotification({
        targetType: selectedTargetType,
        title: title.trim(),
        message: message.trim(),
        userIds: selectedTargetType === 'specific' ? selectedUserIds : undefined,
      });

      // Show detailed success message
      const successMsg = response.message || `✅ Notification sent successfully to ${response.estimatedRecipients || 0} user(s)!`;
      showToast(successMsg, 'success');
      
      // Show additional confirmation alert
      alert(
        `🎉 Notification Sent Successfully!\n\n` +
        `Title: "${title.trim()}"\n` +
        `Recipients: ${response.estimatedRecipients || 0} user(s)\n` +
        `Target: ${targetTypes[selectedTargetType as keyof typeof targetTypes]}\n` +
        `Notification ID: ${response.notificationId || 'N/A'}\n\n` +
        `Users will see this notification in their app!`
      );
      
      // Clear form
      setTitle('');
      setMessage('');
      setSelectedUserIds([]);
    } catch (error: any) {
      console.error('Error sending notification:', error);
      const errorMsg = error.response?.data?.message || error.message || 'Failed to send notification';
      showToast(errorMsg, 'error');
      alert(`❌ Error: ${errorMsg}`);
    } finally {
      setSending(false);
    }
  };

  const toggleUserSelection = (userId: number) => {
    setSelectedUserIds((prev) =>
      prev.includes(userId) ? prev.filter((id) => id !== userId) : [...prev, userId]
    );
  };

  return (
    <div>
      <div style={{ marginBottom: '2rem' }}>
        <h1 style={{ fontSize: '1.875rem', fontWeight: 'bold', color: '#111827', marginBottom: '0.5rem' }}>
          Notification Dashboard
        </h1>
        <p style={{ color: '#6b7280' }}>
          Send notifications to users and manage communication
        </p>
      </div>

      {/* Statistics Grid */}
      {stats && (
        <div style={{ marginBottom: '2rem' }}>
          <h2 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#111827', marginBottom: '1rem' }}>
            User Statistics
          </h2>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '1rem' }}>
            <StatCard title="Total Users" value={stats.totalUsers} icon={Users} color="#3b82f6" />
            <StatCard title="Property Owners" value={stats.propertyOwnersCount} icon={Users} color="#f59e0b" />
            <StatCard title="Auction Owners" value={stats.auctionOwnersCount} icon={Users} color="#8b5cf6" />
            <StatCard title="Bidders" value={stats.biddersCount} icon={Users} color="#10b981" />
            <StatCard title="Verified" value={stats.verifiedCount} icon={CheckCircle} color="#14b8a6" />
            <StatCard title="Unverified" value={stats.unverifiedCount} icon={AlertCircle} color="#ef4444" />
          </div>
        </div>
      )}

      {/* Notification Composer */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '0.75rem',
        padding: '1.5rem',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
      }}>
        <h2 style={{ fontSize: '1.25rem', fontWeight: '600', color: '#111827', marginBottom: '1.5rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
          <Bell style={{ height: '1.25rem', width: '1.25rem' }} />
          Compose Notification
        </h2>

        {/* Target Type Selector */}
        <div style={{ marginBottom: '1.5rem' }}>
          <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '500', color: '#374151', marginBottom: '0.5rem' }}>
            Select Recipients
          </label>
          <select
            value={selectedTargetType}
            onChange={(e) => {
              setSelectedTargetType(e.target.value);
              setSelectedUserIds([]);
            }}
            style={{
              width: '100%',
              padding: '0.625rem',
              border: '1px solid #d1d5db',
              borderRadius: '0.5rem',
              fontSize: '0.875rem',
              outline: 'none',
            }}
          >
            {Object.entries(targetTypes).map(([key, label]) => (
              <option key={key} value={key}>
                {label}
              </option>
            ))}
          </select>
        </div>

        {/* User Selector for Specific Users */}
        {selectedTargetType === 'specific' && (
          <div style={{ marginBottom: '1.5rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.75rem' }}>
              <label style={{ fontSize: '0.875rem', fontWeight: '500', color: '#374151' }}>
                Select Users ({selectedUserIds.length})
              </label>
              <button
                type="button"
                onClick={() => setShowUserSelector(!showUserSelector)}
                style={{
                  padding: '0.5rem 1rem',
                  backgroundColor: '#667eea',
                  color: 'white',
                  border: 'none',
                  borderRadius: '0.5rem',
                  fontSize: '0.875rem',
                  cursor: 'pointer',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                }}
              >
                <Users style={{ height: '1rem', width: '1rem' }} />
                {showUserSelector ? 'Hide' : 'Select'}
              </button>
            </div>

            {showUserSelector && (
              <div style={{
                maxHeight: '300px',
                overflowY: 'auto',
                border: '1px solid #d1d5db',
                borderRadius: '0.5rem',
                padding: '0.5rem',
              }}>
                {users.map((user) => (
                  <label
                    key={user.accountId}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      padding: '0.75rem',
                      cursor: 'pointer',
                      borderRadius: '0.5rem',
                      transition: 'background-color 0.2s',
                    }}
                    onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#f3f4f6')}
                    onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = 'transparent')}
                  >
                    <input
                      type="checkbox"
                      checked={selectedUserIds.includes(user.accountId)}
                      onChange={() => toggleUserSelection(user.accountId)}
                      style={{ marginRight: '0.75rem' }}
                    />
                    <div>
                      <div style={{ fontWeight: '500', color: '#111827' }}>
                        {user.firstName} {user.lastName}
                      </div>
                      <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>{user.email}</div>
                    </div>
                  </label>
                ))}
              </div>
            )}

            {selectedUserIds.length > 0 && (
              <div style={{
                marginTop: '0.75rem',
                padding: '0.75rem',
                backgroundColor: '#f0fdf4',
                borderRadius: '0.5rem',
                color: '#166534',
                fontSize: '0.875rem',
              }}>
                {selectedUserIds.length} user(s) selected
              </div>
            )}
          </div>
        )}

        {/* Title Input */}
        <div style={{ marginBottom: '1.5rem' }}>
          <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '500', color: '#374151', marginBottom: '0.5rem' }}>
            Title
          </label>
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Enter notification title"
            maxLength={100}
            style={{
              width: '100%',
              padding: '0.625rem',
              border: '1px solid #d1d5db',
              borderRadius: '0.5rem',
              fontSize: '0.875rem',
              outline: 'none',
            }}
          />
          <div style={{ textAlign: 'right', fontSize: '0.75rem', color: '#6b7280', marginTop: '0.25rem' }}>
            {title.length}/100
          </div>
        </div>

        {/* Message Input */}
        <div style={{ marginBottom: '1.5rem' }}>
          <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '500', color: '#374151', marginBottom: '0.5rem' }}>
            Message
          </label>
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Enter notification message"
            maxLength={500}
            rows={4}
            style={{
              width: '100%',
              padding: '0.625rem',
              border: '1px solid #d1d5db',
              borderRadius: '0.5rem',
              fontSize: '0.875rem',
              outline: 'none',
              resize: 'vertical',
            }}
          />
          <div style={{ textAlign: 'right', fontSize: '0.75rem', color: '#6b7280', marginTop: '0.25rem' }}>
            {message.length}/500
          </div>
        </div>

        {/* Send Button */}
        <button
          onClick={handleSendNotification}
          disabled={sending || !title.trim() || !message.trim()}
          style={{
            width: '100%',
            padding: '0.75rem 1.5rem',
            backgroundColor: sending ? '#9ca3af' : '#667eea',
            color: 'white',
            border: 'none',
            borderRadius: '0.5rem',
            fontSize: '1rem',
            fontWeight: '600',
            cursor: sending ? 'not-allowed' : 'pointer',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            gap: '0.5rem',
            transition: 'background-color 0.2s',
          }}
        >
          {sending ? (
            <>
              <Loader style={{ height: '1.25rem', width: '1.25rem', animation: 'spin 1s linear infinite' }} />
              Sending...
            </>
          ) : (
            <>
              <Send style={{ height: '1.25rem', width: '1.25rem' }} />
              Send Notification
            </>
          )}
        </button>
      </div>

      <style>{`
        @keyframes spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }
      `}</style>
    </div>
  );
};

interface StatCardProps {
  title: string;
  value: number;
  icon: React.ComponentType<any>;
  color: string;
}

const StatCard: React.FC<StatCardProps> = ({ title, value, icon: Icon, color }) => {
  return (
    <div style={{
      backgroundColor: 'white',
      borderRadius: '0.75rem',
      padding: '1.5rem',
      boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
      transition: 'transform 0.2s',
    }}
    className="card-hover">
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: '1rem' }}>
        <div style={{
          width: '3rem',
          height: '3rem',
          borderRadius: '0.75rem',
          backgroundColor: `${color}15`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
        }}>
          <Icon style={{ height: '1.5rem', width: '1.5rem', color }} />
        </div>
      </div>
      <div style={{ fontSize: '2rem', fontWeight: 'bold', color: color, marginBottom: '0.25rem' }}>
        {value}
      </div>
      <div style={{ fontSize: '0.875rem', color: '#6b7280' }}>
        {title}
      </div>
    </div>
  );
};

export default NotificationDashboardPage;

