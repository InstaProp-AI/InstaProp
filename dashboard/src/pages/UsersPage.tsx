import React, { useState, useEffect } from 'react';
import { 
  Users, 
  Search, 
  Filter, 
  Plus, 
  Mail, 
  Phone, 
  MapPin, 
  Calendar, 
  DollarSign, 
  TrendingUp, 
  Eye, 
  Edit, 
  Trash2, 
  Star, 
  Award, 
  Target, 
  Clock, 
  CheckCircle, 
  XCircle, 
  MoreVertical,
  UserPlus,
  Building,
  Home,
  Hammer,
  BarChart3,
  Download,
  Upload,
  Send,
  MessageCircle,
  FileText,
  Ban,
  UserCheck,
  Shield,
  AlertTriangle,
  Bed,
  Bath,
  Square
} from 'lucide-react';
import { Account } from '../types';
import { usersApi, propertiesApi, bidsApi } from '../services/api';
import { exportUsersToCSV } from '../utils/export';
import { useToast } from '../contexts/ToastContext';
import Pagination from '../components/Pagination';

const UsersPage: React.FC = () => {
  const toast = useToast();
  const [users, setUsers] = useState<Account[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState('all');
  const [filterStatus, setFilterStatus] = useState('all');
  const [sortBy, setSortBy] = useState('newest');
  const [selectedUser, setSelectedUser] = useState<Account | null>(null);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showSuspendModal, setShowSuspendModal] = useState(false);
  const [suspensionDuration, setSuspensionDuration] = useState<string>('7');
  const [suspensionReason, setSuspensionReason] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [detailsTab, setDetailsTab] = useState<'info' | 'properties' | 'bids' | 'auctions'>('info');
  const [userProperties, setUserProperties] = useState<any[]>([]);
  const [userBids, setUserBids] = useState<any[]>([]);
  const [userAuctions, setUserAuctions] = useState<any[]>([]);
  const [loadingDetails, setLoadingDetails] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editForm, setEditForm] = useState({ firstName: '', lastName: '', email: '', phoneNumber: '' });

  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const data = await usersApi.getAllUsers();
      console.log('👥 Users fetched:', data.length, 'users');
      console.log('📋 Sample user data:', data[0]);
      
      // Detailed logging for suspended accounts
      const suspendedUsers = data.filter((u: any) => u.isSuspended);
      console.log('🚫 Suspended users count:', suspendedUsers.length);
      console.log('🚫 Suspended users details:', suspendedUsers.map((u: any) => ({
        id: u.accountId,
        name: `${u.firstName} ${u.lastName}`,
        isSuspended: u.isSuspended,
        suspendedUntil: u.suspendedUntil,
        suspensionReason: u.suspensionReason
      })));
      
      // Check for unverified email/phone
      const unverifiedEmail = data.filter((u: any) => !u.emailVerified).length;
      const unverifiedPhone = data.filter((u: any) => !u.phoneVerified).length;
      console.log('📧 Unverified emails:', unverifiedEmail);
      console.log('📱 Unverified phones:', unverifiedPhone);
      
      setUsers(data);
      toast.success(`Loaded ${data.length} users (${suspendedUsers.length} suspended, ${unverifiedEmail} unverified emails, ${unverifiedPhone} unverified phones)`);
    } catch (error: any) {
      console.error('❌ Error fetching users:', error);
      toast.error(error?.response?.data?.message || 'Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyUser = async (accountId: number) => {
    try {
      await usersApi.verifyUser(accountId);
      toast.success('User verified successfully!');
      fetchUsers(); // Refresh the list
    } catch (error: any) {
      console.error('Error verifying user:', error);
      toast.error(error?.response?.data?.message || 'Failed to verify user');
    }
  };

  const handleRejectUser = async (accountId: number) => {
    if (window.confirm('Are you sure you want to reject this user?')) {
      try {
        await usersApi.rejectUser(accountId);
        toast.success('User rejected successfully!');
        fetchUsers(); // Refresh the list
      } catch (error: any) {
        console.error('Error rejecting user:', error);
        toast.error(error?.response?.data?.message || 'Failed to reject user');
      }
    }
  };

  const handleBanUser = async (accountId: number) => {
    if (window.confirm('Are you sure you want to ban/delete this user? This action cannot be undone.')) {
      try {
        await usersApi.banUser(accountId);
        toast.success('User banned successfully!');
        fetchUsers(); // Refresh the list
      } catch (error: any) {
        console.error('Error banning user:', error);
        toast.error(error?.response?.data?.message || 'Failed to ban user');
      }
    }
  };

  const handleSuspendUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser) return;

    try {
      const days = parseInt(suspensionDuration);
      const suspendedUntil = days > 0 ? new Date(Date.now() + days * 24 * 60 * 60 * 1000).toISOString() : null;
      
      await usersApi.suspendUser(
        selectedUser.accountId,
        suspendedUntil,
        suspensionReason || 'Account suspended by administrator'
      );
      
      toast.success(`User suspended${days > 0 ? ` for ${days} days` : ' indefinitely'}!`);
      setShowSuspendModal(false);
      setSuspensionDuration('7');
      setSuspensionReason('');
      fetchUsers();
    } catch (error: any) {
      console.error('Error suspending user:', error);
      toast.error(error?.response?.data?.message || 'Failed to suspend user');
    }
  };

  const handleUnsuspendUser = async (accountId: number) => {
    if (window.confirm('Are you sure you want to unsuspend this user?')) {
      try {
        await usersApi.unsuspendUser(accountId);
        toast.success('User unsuspended successfully!');
        fetchUsers();
      } catch (error: any) {
        console.error('Error unsuspending user:', error);
        toast.error(error?.response?.data?.message || 'Failed to unsuspend user');
      }
    }
  };

  const handleEditUser = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedUser) return;

    try {
      await usersApi.updateUser(selectedUser.accountId, editForm);
      toast.success('User updated successfully!');
      setShowEditModal(false);
      fetchUsers();
      if (showDetailsModal) {
        fetchUserDetails(selectedUser);
      }
    } catch (error: any) {
      console.error('Error updating user:', error);
      toast.error(error?.response?.data?.message || 'Failed to update user');
    }
  };

  const handleVerifyEmailManually = async (accountId: number) => {
    try {
      console.log('📧 Attempting to verify email for user:', accountId);
      await usersApi.verifyEmail(accountId);
      console.log('✅ Email verified successfully for user:', accountId);
      toast.success('Email verified successfully!');
      await fetchUsers();
      
      // If modal is open, refresh the selected user
      if (showDetailsModal && selectedUser?.accountId === accountId) {
        const updatedUser = await usersApi.getUser(accountId);
        setSelectedUser(updatedUser);
      }
    } catch (error: any) {
      console.error('❌ Error verifying email for user:', accountId);
      console.error('❌ Error details:', {
        message: error.message,
        response: error.response?.data,
        status: error.response?.status,
        statusText: error.response?.statusText
      });
      const errorMessage = error.response?.data?.error || error.response?.data?.message || error.message || 'Failed to verify email';
      toast.error(`Failed to verify email: ${errorMessage}`);
    }
  };

  const handleVerifyPhoneManually = async (accountId: number) => {
    try {
      console.log('📱 Attempting to verify phone for user:', accountId);
      await usersApi.verifyPhone(accountId);
      console.log('✅ Phone verified successfully for user:', accountId);
      toast.success('Phone verified successfully!');
      await fetchUsers();
      
      // If modal is open, refresh the selected user
      if (showDetailsModal && selectedUser?.accountId === accountId) {
        const updatedUser = await usersApi.getUser(accountId);
        setSelectedUser(updatedUser);
      }
    } catch (error: any) {
      console.error('❌ Error verifying phone for user:', accountId);
      console.error('❌ Error details:', {
        message: error.message,
        response: error.response?.data,
        status: error.response?.status,
        statusText: error.response?.statusText
      });
      const errorMessage = error.response?.data?.error || error.response?.data?.message || error.message || 'Failed to verify phone';
      toast.error(`Failed to verify phone: ${errorMessage}`);
    }
  };

  const handleResetPassword = async (accountId: number) => {
    if (window.confirm('Force this user to change their password on next login?')) {
      try {
        await usersApi.resetPassword(accountId);
        toast.success('Password reset flag set!');
        fetchUsers();
      } catch (error: any) {
        console.error('Error resetting password:', error);
        toast.error(error?.response?.data?.message || 'Failed to reset password');
      }
    }
  };

  const handleApproveProperty = async (propertyId: number) => {
    try {
      await propertiesApi.approveProperty(propertyId);
      toast.success('Property approved successfully!');
      if (selectedUser) {
        fetchUserDetails(selectedUser);
      }
    } catch (error: any) {
      console.error('Error approving property:', error);
      toast.error(error?.response?.data?.message || 'Failed to approve property');
    }
  };

  const handleRejectProperty = async (propertyId: number) => {
    if (window.confirm('Are you sure you want to reject this property?')) {
      try {
        await propertiesApi.rejectProperty(propertyId);
        toast.success('Property rejected successfully!');
        if (selectedUser) {
          fetchUserDetails(selectedUser);
        }
      } catch (error: any) {
        console.error('Error rejecting property:', error);
        toast.error(error?.response?.data?.message || 'Failed to reject property');
      }
    }
  };

  const handleApproveAuction = async (auctionId: number) => {
    try {
      await auctionsApi.approveAuction(auctionId);
      toast.success('Auction approved successfully!');
      if (selectedUser) {
        fetchUserDetails(selectedUser);
      }
    } catch (error: any) {
      console.error('Error approving auction:', error);
      toast.error(error?.response?.data?.message || 'Failed to approve auction');
    }
  };

  const handleRejectAuction = async (auctionId: number) => {
    if (window.confirm('Are you sure you want to reject this auction?')) {
      try {
        await auctionsApi.rejectAuction(auctionId);
        toast.success('Auction rejected successfully!');
        if (selectedUser) {
          fetchUserDetails(selectedUser);
        }
      } catch (error: any) {
        console.error('Error rejecting auction:', error);
        toast.error(error?.response?.data?.message || 'Failed to reject auction');
      }
    }
  };

  const fetchUserDetails = async (user: Account) => {
    console.log('🔍 Fetching details for user:', user.accountId, user.email);
    console.log('🔍 User suspension status:', user.isSuspended);
    console.log('📋 Full user object received:', user);
    
    setSelectedUser(user);
    setShowDetailsModal(true);
    setDetailsTab('info');
    setLoadingDetails(true);
    
    try {
      // Fetch user details with properties and bids
      const userDetails: any = await usersApi.getUser(user.accountId);
      console.log('✅ User details API response:', userDetails);
      console.log('📋 Suspension in details:', {
        isSuspended: userDetails.isSuspended,
        IsSuspended: userDetails.IsSuspended,
        suspendedUntil: userDetails.suspendedUntil,
        SuspendedUntil: userDetails.SuspendedUntil
      });
      
      // Extract properties and bids from user details (handle both lowercase and uppercase)
      const properties = userDetails.properties || userDetails.Properties || [];
      const bids = userDetails.bids || userDetails.Bids || [];
      
      console.log('📦 Properties found:', properties.length, properties);
      console.log('💰 Bids found:', bids.length, bids);
      
      // Transform bids to include property info for display
      const transformedBids = bids.map((bid: any) => ({
        bidId: bid.bidId || bid.BidId,
        auctionId: bid.auctionId || bid.AuctionId,
        bidderId: bid.bidderId || bid.BidderId,
        bidAmount: bid.bidAmount || bid.BidAmount,
        timestamp: bid.createdAt || bid.CreatedAt,
        propertyName: bid.auction?.property?.name || bid.Auction?.Property?.Name || 'Unknown Property',
        propertyLocation: bid.auction?.property?.location || bid.Auction?.Property?.Location || 'Unknown',
        status: (bid.auction?.status || bid.Auction?.Status)?.toLowerCase() === 'ended' 
          ? ((bid.bidAmount || bid.BidAmount) === (bid.auction?.currentPrice || bid.Auction?.CurrentPrice) ? 'won' : 'outbid')
          : ((bid.bidAmount || bid.BidAmount) === (bid.auction?.currentPrice || bid.Auction?.CurrentPrice) ? 'active' : 'outbid')
      }));
      
      console.log('🔄 Transformed bids:', transformedBids);
      
      setUserProperties(properties);
      setUserBids(transformedBids);
      
      // Fetch user's auctions (properties with active auctions)
      try {
        console.log('🔨 Fetching auctions for user:', user.accountId, user.email);
        const allAuctions = await auctionsApi.getAllAuctions();
        console.log('🔨 Total auctions fetched:', allAuctions.length);
        console.log('🔨 Sample auction data:', allAuctions[0]);
        
        const userAuctions = allAuctions.filter((auction: any) => {
          // Try both camelCase and PascalCase for property fields
          const property = auction.property || auction.Property;
          const ownerId = property?.ownerId || property?.OwnerId || property?.owner?.accountId || property?.Owner?.AccountId;
          
          console.log('🔍 Checking auction:', auction.auctionId, {
            propertyName: property?.name || property?.Name,
            ownerId: ownerId,
            matchesUser: ownerId === user.accountId
          });
          
          return ownerId === user.accountId;
        });
        
        console.log('🔨 User auctions found:', userAuctions.length);
        console.log('🔨 User auctions details:', userAuctions);
        setUserAuctions(userAuctions);
      } catch (error: any) {
        console.error('❌ Error fetching user auctions:', error);
        console.error('❌ Error details:', error.response?.data);
        setUserAuctions([]);
      }
      
    } catch (error: any) {
      console.error('❌ Error fetching user details:', error);
      console.error('❌ Error details:', error.response?.data);
      toast.error('Failed to load user details');
      setUserProperties([]);
      setUserBids([]);
      setUserAuctions([]);
    } finally {
      setLoadingDetails(false);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'Verified': return '#10b981';
      case 'Pending': return '#f59e0b';
      case 'NotVerified': return '#ef4444';
      default: return '#6b7280';
    }
  };

  const getStatusBg = (status: string) => {
    switch (status) {
      case 'Verified': return '#dcfce7';
      case 'Pending': return '#fef3c7';
      case 'NotVerified': return '#fef2f2';
      default: return '#f3f4f6';
    }
  };

  const getTypeIcon = (type: string) => {
    switch (type) {
      case 'Developer': return Building;
      case 'Admin': return Shield;
      default: return Users;
    }
  };

  const filteredUsers = users.filter(user => {
    const matchesSearch = 
      user.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      user.phoneNumber.includes(searchTerm);
    const matchesType = filterType === 'all' || user.type === filterType;
    const matchesStatus = filterStatus === 'all' 
      ? true 
      : filterStatus === 'suspended' 
        ? Boolean(user.isSuspended) === true 
        : user.status === filterStatus;
    
    console.log('🔍 Filter check for user:', user.accountId, {
      isSuspended: user.isSuspended,
      filterStatus,
      matchesStatus
    });
    
    return matchesSearch && matchesType && matchesStatus;
  });

  const sortedUsers = [...filteredUsers].sort((a, b) => {
    switch (sortBy) {
      case 'newest':
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
      case 'oldest':
        return new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
      case 'name':
        return `${a.firstName} ${a.lastName}`.localeCompare(`${b.firstName} ${b.lastName}`);
      default:
        return 0;
    }
  });

  // Pagination
  const totalPages = Math.ceil(sortedUsers.length / itemsPerPage);
  const paginatedUsers = sortedUsers.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

  if (loading) {
    return (
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '50vh'
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
          }}>Users Management</h1>
          <p style={{
            fontSize: '1.125rem',
            color: '#6b7280',
            margin: 0
          }}>
            Manage users, verify KYC documents, and control access
          </p>
        </div>
        
        {/* Stats Cards */}
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
          gap: '1rem',
          width: '100%',
          marginBottom: '1rem'
        }}>
          {[
            {
              title: 'Total Users',
              value: users.length,
              icon: Users,
              color: '#3b82f6',
              bgColor: '#dbeafe'
            },
            {
              title: 'Verified',
              value: users.filter(u => u.status === 'Verified').length,
              icon: CheckCircle,
              color: '#10b981',
              bgColor: '#dcfce7'
            },
            {
              title: 'Pending',
              value: users.filter(u => u.status === 'Pending').length,
              icon: Clock,
              color: '#f59e0b',
              bgColor: '#fef3c7'
            },
            {
              title: 'Suspended',
              value: users.filter(u => u.isSuspended).length,
              icon: Ban,
              color: '#d97706',
              bgColor: '#fef3c7'
            },
            {
              title: 'Not Verified',
              value: users.filter(u => u.status === 'NotVerified').length,
              icon: AlertTriangle,
              color: '#ef4444',
              bgColor: '#fef2f2'
            }
          ].map((stat, index) => (
            <div key={index} style={{
              backgroundColor: 'white',
              borderRadius: '0.75rem',
              padding: '1.25rem',
              boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
              border: '1px solid #e5e7eb'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <div>
                  <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: '0 0 0.5rem 0' }}>{stat.title}</p>
                  <p style={{ fontSize: '1.875rem', fontWeight: '700', color: '#111827', margin: 0 }}>{stat.value}</p>
                </div>
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
              </div>
            </div>
          ))}
        </div>

        {/* Filters */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          width: '100%',
          gap: '1rem',
          flexWrap: 'wrap'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', flex: 1 }}>
            <div style={{ position: 'relative', minWidth: '300px' }}>
              <Search style={{
                position: 'absolute',
                left: '0.75rem',
                top: '50%',
                transform: 'translateY(-50%)',
                height: '1rem',
                width: '1rem',
                color: '#9ca3af'
              }} />
              <input
                type="text"
                placeholder="Search users..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                style={{
                  width: '100%',
                  padding: '0.75rem 0.75rem 0.75rem 2.5rem',
                  border: '1px solid #d1d5db',
                  borderRadius: '0.75rem',
                  fontSize: '0.875rem',
                  outline: 'none',
                  transition: 'all 0.2s',
                  backgroundColor: 'white'
                }}
              />
            </div>

            <select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              style={{
                padding: '0.75rem 1rem',
                border: '1px solid #d1d5db',
                borderRadius: '0.75rem',
                fontSize: '0.875rem',
                outline: 'none',
                backgroundColor: 'white'
              }}
            >
              <option value="all">All Types</option>
              <option value="User">Users</option>
              <option value="Developer">Developers</option>
              <option value="Admin">Admins</option>
            </select>

            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              style={{
                padding: '0.75rem 1rem',
                border: '1px solid #d1d5db',
                borderRadius: '0.75rem',
                fontSize: '0.875rem',
                outline: 'none',
                backgroundColor: 'white'
              }}
            >
              <option value="all">All Status</option>
              <option value="Verified">Verified</option>
              <option value="Pending">Pending</option>
              <option value="NotVerified">Not Verified</option>
              <option value="suspended">🚫 Suspended</option>
            </select>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
              style={{
                padding: '0.75rem 1rem',
                border: '1px solid #d1d5db',
                borderRadius: '0.75rem',
                fontSize: '0.875rem',
                outline: 'none',
                backgroundColor: 'white'
              }}
            >
              <option value="newest">Newest First</option>
              <option value="oldest">Oldest First</option>
              <option value="name">Name A-Z</option>
            </select>

            <button
              onClick={() => exportUsersToCSV(sortedUsers)}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '0.5rem',
                padding: '0.75rem 1rem',
                backgroundColor: '#f3f4f6',
                color: '#6b7280',
                border: 'none',
                borderRadius: '0.75rem',
                cursor: 'pointer',
                transition: 'all 0.2s'
              }}
            >
              <Download style={{ height: '1rem', width: '1rem' }} />
              Export
            </button>
          </div>
        </div>
      </div>

      {/* Users Table */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '1rem',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
        border: '1px solid #e5e7eb',
        overflow: 'hidden'
      }}>
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ backgroundColor: '#f9fafb', borderBottom: '1px solid #e5e7eb' }}>
                <th style={{ padding: '0.75rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>User</th>
                <th style={{ padding: '0.75rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Type</th>
                <th style={{ padding: '0.75rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Contact</th>
                <th style={{ padding: '0.75rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Verification</th>
                <th style={{ padding: '0.75rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Status</th>
                <th style={{ padding: '0.75rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Joined</th>
                <th style={{ padding: '0.75rem 1rem', textAlign: 'right', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {paginatedUsers.map((user) => {
                const TypeIcon = getTypeIcon(user.type);
                return (
                  <tr key={user.accountId} style={{ borderBottom: '1px solid #e5e7eb' }}>
                    <td style={{ padding: '1rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                        <div style={{
                          width: '2.5rem',
                          height: '2.5rem',
                          borderRadius: '50%',
                          background: user.isSuspended 
                            ? 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)'
                            : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                          color: 'white',
                          fontWeight: '600',
                          fontSize: '0.875rem',
                          position: 'relative'
                        }}>
                          {user.firstName[0]}{user.lastName[0]}
                          {user.isSuspended && (
                            <div style={{
                              position: 'absolute',
                              top: '-4px',
                              right: '-4px',
                              width: '1rem',
                              height: '1rem',
                              backgroundColor: '#dc2626',
                              borderRadius: '50%',
                              border: '2px solid white',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center'
                            }}>
                              <Ban style={{ height: '0.625rem', width: '0.625rem', color: 'white' }} />
                            </div>
                          )}
                        </div>
                        <div>
                          <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                            <p style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827', margin: 0 }}>
                              {user.firstName} {user.lastName}
                            </p>
                          </div>
                          <p style={{ fontSize: '0.75rem', color: '#6b7280', margin: 0 }}>
                            ID: #{user.accountId}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <div style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        padding: '0.25rem 0.75rem',
                        borderRadius: '0.5rem',
                        backgroundColor: user.type === 'Admin' ? '#ede9fe' : user.type === 'Developer' ? '#dbeafe' : '#f3f4f6',
                        color: user.type === 'Admin' ? '#7c3aed' : user.type === 'Developer' ? '#2563eb' : '#6b7280',
                        fontSize: '0.75rem',
                        fontWeight: '500'
                      }}>
                        <TypeIcon style={{ height: '0.875rem', width: '0.875rem' }} />
                        {user.type}
                      </div>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.75rem', color: '#6b7280' }}>
                          <Mail style={{ height: '0.875rem', width: '0.875rem' }} />
                          {user.email}
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.75rem', color: '#6b7280' }}>
                          <Phone style={{ height: '0.875rem', width: '0.875rem' }} />
                          {user.phoneNumber}
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <div style={{ display: 'flex', gap: '0.5rem' }}>
                        <div style={{
                          padding: '0.25rem 0.5rem',
                          borderRadius: '0.375rem',
                          backgroundColor: user.emailVerified ? '#dcfce7' : '#fef2f2',
                          color: user.emailVerified ? '#059669' : '#dc2626',
                          fontSize: '0.625rem',
                          fontWeight: '500'
                        }}>
                          {user.emailVerified ? '✓ Email' : '✗ Email'}
                        </div>
                        <div style={{
                          padding: '0.25rem 0.5rem',
                          borderRadius: '0.375rem',
                          backgroundColor: user.phoneVerified ? '#dcfce7' : '#fef2f2',
                          color: user.phoneVerified ? '#059669' : '#dc2626',
                          fontSize: '0.625rem',
                          fontWeight: '500'
                        }}>
                          {user.phoneVerified ? '✓ Phone' : '✗ Phone'}
                        </div>
                      </div>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                        <div style={{
                          display: 'inline-block',
                          padding: '0.375rem 0.75rem',
                          borderRadius: '0.5rem',
                          backgroundColor: getStatusBg(user.status),
                          color: getStatusColor(user.status),
                          fontSize: '0.75rem',
                          fontWeight: '500'
                        }}>
                          {user.status === 'NotVerified' ? 'Not Verified' : user.status}
                        </div>
                        {user.isSuspended && (
                          <div style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.25rem',
                            padding: '0.375rem 0.75rem',
                            borderRadius: '0.5rem',
                            backgroundColor: '#fef3c7',
                            color: '#d97706',
                            fontSize: '0.75rem',
                            fontWeight: '500'
                          }}>
                            <Ban style={{ height: '0.75rem', width: '0.75rem' }} />
                            Suspended
                            {user.suspendedUntil && (
                              <span style={{ fontSize: '0.625rem', opacity: 0.8 }}>
                                until {new Date(user.suspendedUntil).toLocaleDateString()}
                              </span>
                            )}
                          </div>
                        )}
                      </div>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: 0 }}>
                        {new Date(user.createdAt).toLocaleDateString()}
                      </p>
                    </td>
                    <td style={{ padding: '1rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'flex-end', gap: '0.5rem' }}>
                        <button
                          onClick={() => fetchUserDetails(user)}
                          style={{
                            padding: '0.5rem 1rem',
                            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                            color: 'white',
                            border: 'none',
                            borderRadius: '0.5rem',
                            cursor: 'pointer',
                            fontSize: '0.875rem',
                            fontWeight: '500',
                            transition: 'all 0.2s',
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem'
                          }}
                          title="View Details & Actions"
                          onMouseEnter={(e) => {
                            e.currentTarget.style.transform = 'translateY(-1px)';
                            e.currentTarget.style.boxShadow = '0 4px 12px rgba(102, 126, 234, 0.4)';
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.transform = 'translateY(0)';
                            e.currentTarget.style.boxShadow = 'none';
                          }}
                        >
                          <Eye style={{ height: '1rem', width: '1rem' }} />
                          View Details
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        <div style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          marginTop: '1.5rem',
          flexWrap: 'wrap',
          gap: '1rem'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            gap: '0.75rem'
          }}>
            <span style={{
              fontSize: '0.875rem',
              color: '#6b7280',
              fontWeight: '500'
            }}>
              Users per page:
            </span>
            <div style={{
              display: 'flex',
              gap: '0.5rem'
            }}>
              {[10, 50, 100].map((value) => (
                <button
                  key={value}
                  onClick={() => {
                    setItemsPerPage(value);
                    setCurrentPage(1); // Reset to first page when changing items per page
                  }}
                  style={{
                    padding: '0.5rem 1rem',
                    borderRadius: '0.5rem',
                    border: itemsPerPage === value ? 'none' : '1px solid #e5e7eb',
                    background: itemsPerPage === value 
                      ? 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
                      : 'white',
                    color: itemsPerPage === value ? 'white' : '#6b7280',
                    fontSize: '0.875rem',
                    fontWeight: '500',
                    cursor: 'pointer',
                    transition: 'all 0.2s'
                  }}
                  onMouseEnter={(e) => {
                    if (itemsPerPage !== value) {
                      e.currentTarget.style.borderColor = '#667eea';
                      e.currentTarget.style.color = '#667eea';
                    }
                  }}
                  onMouseLeave={(e) => {
                    if (itemsPerPage !== value) {
                      e.currentTarget.style.borderColor = '#e5e7eb';
                      e.currentTarget.style.color = '#6b7280';
                    }
                  }}
                >
                  {value}
                </button>
              ))}
            </div>
          </div>
          
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
            onPageChange={setCurrentPage}
            itemsPerPage={itemsPerPage}
            totalItems={sortedUsers.length}
          />
        </div>

        {sortedUsers.length === 0 && (
          <div style={{
            textAlign: 'center',
            padding: '3rem 2rem'
          }}>
            <Users style={{
              margin: '0 auto 1rem auto',
              height: '3rem',
              width: '3rem',
              color: '#9ca3af'
            }} />
            <h3 style={{
              fontSize: '1.125rem',
              fontWeight: '600',
              color: '#111827',
              marginBottom: '0.5rem'
            }}>No users found</h3>
            <p style={{
              fontSize: '0.875rem',
              color: '#6b7280'
            }}>
              Try adjusting your filters to see more users.
            </p>
          </div>
        )}
      </div>

      {/* User Details Modal with Tabs */}
      {showDetailsModal && selectedUser && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          zIndex: 50,
          overflowY: 'auto',
          backgroundColor: 'rgba(0, 0, 0, 0.5)'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '100vh',
            padding: '1rem'
          }}>
            <div style={{
              backgroundColor: 'white',
              borderRadius: '1rem',
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
              maxWidth: '60rem',
              width: '100%',
              maxHeight: '90vh',
              overflowY: 'auto'
            }}>
              {/* Header */}
              <div style={{ padding: '2rem', paddingBottom: '1rem', borderBottom: '1px solid #e5e7eb' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '1.5rem' }}>
                  <div>
                    <h3 style={{
                      fontSize: '1.5rem',
                      fontWeight: '600',
                      color: '#111827',
                      marginBottom: '0.5rem'
                    }}>User Details</h3>
                    <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: 0 }}>
                      {selectedUser.firstName} {selectedUser.lastName} ({selectedUser.email})
                    </p>
                  </div>
                  <button
                    onClick={() => setShowDetailsModal(false)}
                    style={{
                      padding: '0.5rem',
                      backgroundColor: '#f3f4f6',
                      color: '#6b7280',
                      border: 'none',
                      borderRadius: '0.5rem',
                      cursor: 'pointer'
                    }}
                  >
                    <XCircle style={{ height: '1.25rem', width: '1.25rem' }} />
                  </button>
                </div>

                {/* Tabs */}
                <div style={{ display: 'flex', gap: '0.5rem', borderBottom: '2px solid #e5e7eb', marginTop: '1rem' }}>
                  <button
                    onClick={() => setDetailsTab('info')}
                    style={{
                      padding: '0.75rem 1.5rem',
                      backgroundColor: detailsTab === 'info' ? '#f8fafc' : 'transparent',
                      color: detailsTab === 'info' ? '#667eea' : '#6b7280',
                      border: 'none',
                      borderBottom: detailsTab === 'info' ? '2px solid #667eea' : '2px solid transparent',
                      cursor: 'pointer',
                      fontWeight: '500',
                      fontSize: '0.875rem',
                      transition: 'all 0.2s',
                      marginBottom: '-2px'
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <UserCheck style={{ height: '1rem', width: '1rem' }} />
                      User Info
                    </div>
                  </button>
                  <button
                    onClick={() => setDetailsTab('properties')}
                    style={{
                      padding: '0.75rem 1.5rem',
                      backgroundColor: detailsTab === 'properties' ? '#f8fafc' : 'transparent',
                      color: detailsTab === 'properties' ? '#667eea' : '#6b7280',
                      border: 'none',
                      borderBottom: detailsTab === 'properties' ? '2px solid #667eea' : '2px solid transparent',
                      cursor: 'pointer',
                      fontWeight: '500',
                      fontSize: '0.875rem',
                      transition: 'all 0.2s',
                      marginBottom: '-2px'
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <Home style={{ height: '1rem', width: '1rem' }} />
                      Properties ({userProperties.length})
                    </div>
                  </button>
                  <button
                    onClick={() => setDetailsTab('bids')}
                    style={{
                      padding: '0.75rem 1.5rem',
                      backgroundColor: detailsTab === 'bids' ? '#f8fafc' : 'transparent',
                      color: detailsTab === 'bids' ? '#667eea' : '#6b7280',
                      border: 'none',
                      borderBottom: detailsTab === 'bids' ? '2px solid #667eea' : '2px solid transparent',
                      cursor: 'pointer',
                      fontWeight: '500',
                      fontSize: '0.875rem',
                      transition: 'all 0.2s',
                      marginBottom: '-2px'
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <Target style={{ height: '1rem', width: '1rem' }} />
                      Bids ({userBids.length})
                    </div>
                  </button>
                  <button
                    onClick={() => setDetailsTab('auctions')}
                    style={{
                      padding: '0.75rem 1.5rem',
                      backgroundColor: detailsTab === 'auctions' ? '#f8fafc' : 'transparent',
                      color: detailsTab === 'auctions' ? '#667eea' : '#6b7280',
                      border: 'none',
                      borderBottom: detailsTab === 'auctions' ? '2px solid #667eea' : '2px solid transparent',
                      cursor: 'pointer',
                      fontWeight: '500',
                      fontSize: '0.875rem',
                      transition: 'all 0.2s',
                      marginBottom: '-2px'
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <Hammer style={{ height: '1rem', width: '1rem' }} />
                      Auctions ({userAuctions.length})
                    </div>
                  </button>
                </div>
              </div>

              {/* Tab Content */}
              <div style={{ padding: '2rem', minHeight: '400px' }}>
                {loadingDetails ? (
                  <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '300px' }}>
                    <div style={{
                      width: '3rem',
                      height: '3rem',
                      border: '4px solid #e2e8f0',
                      borderTop: '4px solid #667eea',
                      borderRadius: '50%',
                      animation: 'spin 1s linear infinite'
                    }} />
                  </div>
                ) : (
                  <>
                    {/* Info Tab */}
                    {detailsTab === 'info' && (
                      <div>
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
                          <h4 style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827', margin: 0 }}>
                            Account Information
                          </h4>
                          <button
                            onClick={() => {
                              setEditForm({
                                firstName: selectedUser.firstName,
                                lastName: selectedUser.lastName,
                                email: selectedUser.email,
                                phoneNumber: selectedUser.phoneNumber
                              });
                              setShowEditModal(true);
                            }}
                            style={{
                              display: 'flex',
                              alignItems: 'center',
                              gap: '0.5rem',
                              padding: '0.5rem 1rem',
                              backgroundColor: '#f3f4f6',
                              color: '#6b7280',
                              border: 'none',
                              borderRadius: '0.5rem',
                              cursor: 'pointer',
                              fontSize: '0.875rem',
                              fontWeight: '500'
                            }}
                          >
                            <Edit style={{ height: '1rem', width: '1rem' }} />
                            Edit Info
                          </button>
                        </div>

                        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1.5rem', marginBottom: '2rem' }}>
                          <div>
                            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', marginBottom: '0.5rem', textTransform: 'uppercase' }}>Full Name</label>
                            <p style={{ fontSize: '0.875rem', color: '#111827', margin: 0 }}>{selectedUser.firstName} {selectedUser.lastName}</p>
                          </div>
                          <div>
                            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', marginBottom: '0.5rem', textTransform: 'uppercase' }}>User Type</label>
                            <p style={{ fontSize: '0.875rem', color: '#111827', margin: 0 }}>{selectedUser.type}</p>
                          </div>
                          <div>
                            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', marginBottom: '0.5rem', textTransform: 'uppercase' }}>Email</label>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                              <p style={{ fontSize: '0.875rem', color: '#111827', margin: 0 }}>{selectedUser.email}</p>
                              {!selectedUser.emailVerified && (
                                <button
                                  onClick={() => handleVerifyEmailManually(selectedUser.accountId)}
                                  style={{
                                    padding: '0.25rem 0.5rem',
                                    backgroundColor: '#dcfce7',
                                    color: '#059669',
                                    border: 'none',
                                    borderRadius: '0.375rem',
                                    cursor: 'pointer',
                                    fontSize: '0.625rem',
                                    fontWeight: '600'
                                  }}
                                  title="Manually verify email"
                                >
                                  ✓ Verify
                                </button>
                              )}
                            </div>
                          </div>
                          <div>
                            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', marginBottom: '0.5rem', textTransform: 'uppercase' }}>Phone</label>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                              <p style={{ fontSize: '0.875rem', color: '#111827', margin: 0 }}>{selectedUser.phoneNumber}</p>
                              {!selectedUser.phoneVerified && (
                                <button
                                  onClick={() => handleVerifyPhoneManually(selectedUser.accountId)}
                                  style={{
                                    padding: '0.25rem 0.5rem',
                                    backgroundColor: '#dcfce7',
                                    color: '#059669',
                                    border: 'none',
                                    borderRadius: '0.375rem',
                                    cursor: 'pointer',
                                    fontSize: '0.625rem',
                                    fontWeight: '600'
                                  }}
                                  title="Manually verify phone"
                                >
                                  ✓ Verify
                                </button>
                              )}
                            </div>
                          </div>
                          <div>
                            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', marginBottom: '0.5rem', textTransform: 'uppercase' }}>Status</label>
                            <div style={{
                              display: 'inline-block',
                              padding: '0.375rem 0.75rem',
                              borderRadius: '0.5rem',
                              backgroundColor: getStatusBg(selectedUser.status),
                              color: getStatusColor(selectedUser.status),
                              fontSize: '0.75rem',
                              fontWeight: '500'
                            }}>
                              {selectedUser.status}
                            </div>
                          </div>
                          <div>
                            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', marginBottom: '0.5rem', textTransform: 'uppercase' }}>Joined</label>
                            <p style={{ fontSize: '0.875rem', color: '#111827', margin: 0 }}>{new Date(selectedUser.createdAt).toLocaleDateString()}</p>
                          </div>
                        </div>

                        {/* Suspension Info */}
                        {selectedUser.isSuspended && (
                          <div style={{
                            padding: '1rem',
                            backgroundColor: '#fef3c7',
                            borderRadius: '0.75rem',
                            marginBottom: '1.5rem',
                            border: '1px solid #f59e0b'
                          }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.5rem' }}>
                              <Ban style={{ height: '1.25rem', width: '1.25rem', color: '#d97706' }} />
                              <h4 style={{ fontSize: '1rem', fontWeight: '600', color: '#111827', margin: 0 }}>Account Suspended</h4>
                            </div>
                            <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: '0 0 0.5rem 0' }}>
                              {selectedUser.suspensionReason || 'Account suspended by administrator'}
                            </p>
                            {selectedUser.suspendedUntil && (
                              <p style={{ fontSize: '0.875rem', color: '#d97706', margin: 0, fontWeight: '500' }}>
                                Until: {new Date(selectedUser.suspendedUntil).toLocaleDateString()} at {new Date(selectedUser.suspendedUntil).toLocaleTimeString()}
                              </p>
                            )}
                          </div>
                        )}

                        {/* Action Buttons Section */}
                        <div>
                          <h4 style={{ fontSize: '1rem', fontWeight: '600', color: '#111827', marginBottom: '1rem' }}>
                            Account Actions
                          </h4>
                          
                          {/* Verification Actions */}
                          <div style={{ marginBottom: '1.5rem' }}>
                            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: '600', color: '#6b7280', marginBottom: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                              Verification
                            </label>
                            <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
                              {/* Email Verification */}
                              {!selectedUser.emailVerified && (
                                <button
                                  onClick={() => handleVerifyEmailManually(selectedUser.accountId)}
                                  style={{
                                    padding: '0.75rem 1.25rem',
                                    backgroundColor: '#dbeafe',
                                    color: '#2563eb',
                                    border: '2px solid #3b82f6',
                                    borderRadius: '0.5rem',
                                    cursor: 'pointer',
                                    fontSize: '0.875rem',
                                    fontWeight: '600',
                                    transition: 'all 0.2s',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '0.5rem'
                                  }}
                                  title="Verify email only"
                                >
                                  <Mail style={{ height: '1rem', width: '1rem' }} />
                                  Verify Email
                                </button>
                              )}
                              
                              {/* Phone Verification */}
                              {!selectedUser.phoneVerified && (
                                <button
                                  onClick={() => handleVerifyPhoneManually(selectedUser.accountId)}
                                  style={{
                                    padding: '0.75rem 1.25rem',
                                    backgroundColor: '#dbeafe',
                                    color: '#2563eb',
                                    border: '2px solid #3b82f6',
                                    borderRadius: '0.5rem',
                                    cursor: 'pointer',
                                    fontSize: '0.875rem',
                                    fontWeight: '600',
                                    transition: 'all 0.2s',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '0.5rem'
                                  }}
                                  title="Verify phone only"
                                >
                                  <Phone style={{ height: '1rem', width: '1rem' }} />
                                  Verify Phone
                                </button>
                              )}
                              
                              {/* Full Account Verification */}
                              {(selectedUser.status === 'Pending' || selectedUser.status === 'NotVerified') && (
                                <button
                                  onClick={() => {
                                    handleVerifyUser(selectedUser.accountId);
                                    setShowDetailsModal(false);
                                  }}
                                  style={{
                                    padding: '0.75rem 1.25rem',
                                    background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '0.5rem',
                                    cursor: 'pointer',
                                    fontSize: '0.875rem',
                                    fontWeight: '600',
                                    transition: 'all 0.2s',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '0.5rem'
                                  }}
                                  title="Verify entire account (status + email + phone)"
                                >
                                  <CheckCircle style={{ height: '1rem', width: '1rem' }} />
                                  Verify Full Account
                                </button>
                              )}
                              
                              {/* Reject User */}
                              {selectedUser.status === 'Pending' && (
                                <button
                                  onClick={() => {
                                    handleRejectUser(selectedUser.accountId);
                                    setShowDetailsModal(false);
                                  }}
                                  style={{
                                    padding: '0.75rem 1.25rem',
                                    backgroundColor: '#fef2f2',
                                    color: '#dc2626',
                                    border: '2px solid #ef4444',
                                    borderRadius: '0.5rem',
                                    cursor: 'pointer',
                                    fontSize: '0.875rem',
                                    fontWeight: '600',
                                    transition: 'all 0.2s',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '0.5rem'
                                  }}
                                >
                                  <XCircle style={{ height: '1rem', width: '1rem' }} />
                                  Reject User
                                </button>
                              )}
                            </div>
                          </div>
                          
                          {/* Account Management Actions */}
                          <div style={{ marginBottom: '1.5rem' }}>
                            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: '600', color: '#6b7280', marginBottom: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                              Account Management
                            </label>
                            <div style={{ display: 'flex', gap: '0.75rem', flexWrap: 'wrap' }}>
                              {/* Suspend/Unsuspend */}
                              {selectedUser.isSuspended ? (
                                <button
                                  onClick={() => {
                                    handleUnsuspendUser(selectedUser.accountId);
                                  }}
                                  style={{
                                    padding: '0.75rem 1.25rem',
                                    background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                                    color: 'white',
                                    border: 'none',
                                    borderRadius: '0.5rem',
                                    cursor: 'pointer',
                                    fontSize: '0.875rem',
                                    fontWeight: '600',
                                    transition: 'all 0.2s',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '0.5rem'
                                  }}
                                >
                                  <UserCheck style={{ height: '1rem', width: '1rem' }} />
                                  Unsuspend User
                                </button>
                              ) : (
                                <button
                                  onClick={() => {
                                    setShowDetailsModal(false);
                                    setShowSuspendModal(true);
                                  }}
                                  style={{
                                    padding: '0.75rem 1.25rem',
                                    backgroundColor: '#fef3c7',
                                    color: '#d97706',
                                    border: '2px solid #f59e0b',
                                    borderRadius: '0.5rem',
                                    cursor: 'pointer',
                                    fontSize: '0.875rem',
                                    fontWeight: '600',
                                    transition: 'all 0.2s',
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '0.5rem'
                                  }}
                                >
                                  <AlertTriangle style={{ height: '1rem', width: '1rem' }} />
                                  Suspend User
                                </button>
                              )}
                              
                              {/* Reset Password */}
                              <button
                                onClick={() => handleResetPassword(selectedUser.accountId)}
                                style={{
                                  padding: '0.75rem 1.25rem',
                                  backgroundColor: '#f3f4f6',
                                  color: '#374151',
                                  border: '2px solid #d1d5db',
                                  borderRadius: '0.5rem',
                                  cursor: 'pointer',
                                  fontSize: '0.875rem',
                                  fontWeight: '600',
                                  transition: 'all 0.2s',
                                  display: 'flex',
                                  alignItems: 'center',
                                  gap: '0.5rem'
                                }}
                              >
                                <Shield style={{ height: '1rem', width: '1rem' }} />
                                Reset Password
                              </button>
                            </div>
                          </div>
                          
                          {/* Danger Zone */}
                          <div>
                            <label style={{ display: 'block', fontSize: '0.75rem', fontWeight: '600', color: '#dc2626', marginBottom: '0.75rem', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
                              ⚠️ Danger Zone
                            </label>
                            <button
                              onClick={() => {
                                handleBanUser(selectedUser.accountId);
                                setShowDetailsModal(false);
                              }}
                              style={{
                                padding: '0.75rem 1.25rem',
                                background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                                color: 'white',
                                border: 'none',
                                borderRadius: '0.5rem',
                                cursor: 'pointer',
                                fontSize: '0.875rem',
                                fontWeight: '600',
                                transition: 'all 0.2s',
                                display: 'flex',
                                alignItems: 'center',
                                gap: '0.5rem'
                              }}
                            >
                              <Ban style={{ height: '1rem', width: '1rem' }} />
                              Ban/Delete User
                            </button>
                          </div>
                        </div>
                      </div>
                    )}

                    {/* Properties Tab */}
                    {detailsTab === 'properties' && (
                      <div>
                        <h4 style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827', marginBottom: '1rem' }}>
                          User's Properties ({userProperties.length})
                        </h4>
                        {userProperties.length > 0 ? (
                          <div style={{ display: 'grid', gap: '1rem' }}>
                            {userProperties.map((property: any) => {
                              const propId = property.propertyId || property.PropertyId;
                              const propName = property.name || property.Name || 'Unnamed Property';
                              const propLocation = property.location || property.Location || 'No location';
                              const propBedrooms = property.bedrooms || property.Bedrooms || 0;
                              const propBathrooms = property.bathrooms || property.Bathrooms || 0;
                              const propSquareFeet = property.squareFeet || property.SquareFeet || 0;
                              const propStatus = property.status || property.Status || 'Unknown';
                              const propCategory = property.category || property.Category || 'Residential';
                              const propYear = property.yearBuilt || property.YearBuilt || 'N/A';
                              
                              return (
                                <div key={propId} style={{
                                  padding: '1.5rem',
                                  border: '1px solid #e5e7eb',
                                  borderRadius: '0.75rem',
                                  backgroundColor: '#ffffff',
                                  boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)'
                                }}>
                                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '1rem' }}>
                                    <div style={{ flex: 1 }}>
                                      <h5 style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827', margin: '0 0 0.5rem 0' }}>
                                        {propName}
                                      </h5>
                                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', color: '#6b7280', marginBottom: '0.5rem' }}>
                                        <MapPin style={{ height: '1rem', width: '1rem' }} />
                                        {propLocation}
                                      </div>
                                      <div style={{ display: 'flex', gap: '0.5rem', marginBottom: '0.5rem' }}>
                                        <div style={{
                                          padding: '0.25rem 0.5rem',
                                          borderRadius: '0.375rem',
                                          backgroundColor: '#f3f4f6',
                                          fontSize: '0.75rem',
                                          color: '#6b7280'
                                        }}>
                                          {propCategory}
                                        </div>
                                        <div style={{
                                          padding: '0.25rem 0.5rem',
                                          borderRadius: '0.375rem',
                                          backgroundColor: '#f3f4f6',
                                          fontSize: '0.75rem',
                                          color: '#6b7280'
                                        }}>
                                          Built {propYear}
                                        </div>
                                      </div>
                                    </div>
                                    <div style={{
                                      padding: '0.375rem 0.75rem',
                                      borderRadius: '0.5rem',
                                      backgroundColor: propStatus === 'Approved' ? '#dcfce7' : propStatus === 'Pending' ? '#fef3c7' : '#fef2f2',
                                      color: propStatus === 'Approved' ? '#059669' : propStatus === 'Pending' ? '#d97706' : '#dc2626',
                                      fontSize: '0.75rem',
                                      fontWeight: '500'
                                    }}>
                                      {propStatus}
                                    </div>
                                  </div>
                                  <div style={{ 
                                    display: 'flex', 
                                    gap: '1.5rem', 
                                    paddingTop: '1rem',
                                    borderTop: '1px solid #e5e7eb',
                                    fontSize: '0.875rem', 
                                    color: '#6b7280' 
                                  }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                                      <Bed style={{ height: '1rem', width: '1rem' }} />
                                      <strong>{propBedrooms}</strong> beds
                                    </div>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                                      <Bath style={{ height: '1rem', width: '1rem' }} />
                                      <strong>{propBathrooms}</strong> baths
                                    </div>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                                      <Square style={{ height: '1rem', width: '1rem' }} />
                                      <strong>{propSquareFeet.toLocaleString()}</strong> sq ft
                                    </div>
                                  </div>
                                  
                                  {/* Approve/Reject Buttons for Pending Properties */}
                                  {propStatus === 'Pending' && (
                                    <div style={{ 
                                      display: 'flex', 
                                      gap: '0.75rem', 
                                      marginTop: '1rem',
                                      paddingTop: '1rem',
                                      borderTop: '1px solid #e5e7eb'
                                    }}>
                                      <button
                                        onClick={() => handleApproveProperty(propId)}
                                        style={{
                                          flex: 1,
                                          padding: '0.625rem 1rem',
                                          background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                                          color: 'white',
                                          border: 'none',
                                          borderRadius: '0.5rem',
                                          cursor: 'pointer',
                                          fontSize: '0.875rem',
                                          fontWeight: '600',
                                          transition: 'all 0.2s',
                                          display: 'flex',
                                          alignItems: 'center',
                                          justifyContent: 'center',
                                          gap: '0.5rem'
                                        }}
                                      >
                                        <CheckCircle style={{ height: '1rem', width: '1rem' }} />
                                        Approve Property
                                      </button>
                                      <button
                                        onClick={() => handleRejectProperty(propId)}
                                        style={{
                                          flex: 1,
                                          padding: '0.625rem 1rem',
                                          background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                                          color: 'white',
                                          border: 'none',
                                          borderRadius: '0.5rem',
                                          cursor: 'pointer',
                                          fontSize: '0.875rem',
                                          fontWeight: '600',
                                          transition: 'all 0.2s',
                                          display: 'flex',
                                          alignItems: 'center',
                                          justifyContent: 'center',
                                          gap: '0.5rem'
                                        }}
                                      >
                                        <XCircle style={{ height: '1rem', width: '1rem' }} />
                                        Reject Property
                                      </button>
                                    </div>
                                  )}
                                </div>
                              );
                            })}
                          </div>
                        ) : (
                          <div style={{
                            padding: '3rem',
                            textAlign: 'center',
                            backgroundColor: '#f9fafb',
                            borderRadius: '0.75rem',
                            color: '#6b7280'
                          }}>
                            <Home style={{ height: '3rem', width: '3rem', margin: '0 auto 1rem auto', color: '#9ca3af' }} />
                            <p style={{ margin: 0, fontSize: '1rem', fontWeight: '500' }}>No properties listed yet</p>
                            <p style={{ margin: '0.5rem 0 0 0', fontSize: '0.875rem' }}>This user hasn't created any properties</p>
                          </div>
                        )}
                      </div>
                    )}

                    {/* Bids Tab */}
                    {detailsTab === 'bids' && (
                      <div>
                        <h4 style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827', marginBottom: '1rem' }}>
                          Bidding History ({userBids.length} bids)
                        </h4>
                        {userBids.length > 0 ? (
                          <div style={{ 
                            border: '1px solid #e5e7eb', 
                            borderRadius: '0.75rem',
                            overflow: 'hidden',
                            backgroundColor: 'white'
                          }}>
                            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                              <thead style={{ backgroundColor: '#f9fafb' }}>
                                <tr>
                                  <th style={{ padding: '1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Property</th>
                                  <th style={{ padding: '1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Bid Amount</th>
                                  <th style={{ padding: '1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Status</th>
                                  <th style={{ padding: '1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase', letterSpacing: '0.05em' }}>Time</th>
                                </tr>
                              </thead>
                              <tbody>
                                {userBids.map((bid: any, index: number) => (
                                  <tr key={bid.bidId || index} style={{ borderTop: '1px solid #e5e7eb' }}>
                                    <td style={{ padding: '1rem' }}>
                                      <p style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827', margin: '0 0 0.25rem 0' }}>
                                        {bid.propertyName}
                                      </p>
                                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', fontSize: '0.75rem', color: '#6b7280' }}>
                                        <MapPin style={{ height: '0.75rem', width: '0.75rem' }} />
                                        {bid.propertyLocation}
                                      </div>
                                    </td>
                                    <td style={{ padding: '1rem' }}>
                                      <p style={{ fontSize: '1rem', fontWeight: '600', color: '#111827', margin: 0 }}>
                                        ${(bid.bidAmount || 0).toLocaleString()}
                                      </p>
                                    </td>
                                    <td style={{ padding: '1rem' }}>
                                      <div style={{
                                        display: 'inline-block',
                                        padding: '0.375rem 0.75rem',
                                        borderRadius: '0.5rem',
                                        backgroundColor: bid.status === 'won' ? '#dcfce7' : bid.status === 'active' ? '#dbeafe' : '#fef3c7',
                                        color: bid.status === 'won' ? '#059669' : bid.status === 'active' ? '#2563eb' : '#d97706',
                                        fontSize: '0.75rem',
                                        fontWeight: '500',
                                        textTransform: 'capitalize'
                                      }}>
                                        {bid.status}
                                      </div>
                                    </td>
                                    <td style={{ padding: '1rem', fontSize: '0.875rem', color: '#6b7280' }}>
                                      {new Date(bid.timestamp).toLocaleDateString()} {new Date(bid.timestamp).toLocaleTimeString()}
                                    </td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                          </div>
                        ) : (
                          <div style={{
                            padding: '3rem',
                            textAlign: 'center',
                            backgroundColor: '#f9fafb',
                            borderRadius: '0.75rem',
                            color: '#6b7280'
                          }}>
                            <Target style={{ height: '3rem', width: '3rem', margin: '0 auto 1rem auto', color: '#9ca3af' }} />
                            <p style={{ margin: 0, fontSize: '1rem', fontWeight: '500' }}>No bids placed yet</p>
                            <p style={{ margin: '0.5rem 0 0 0', fontSize: '0.875rem' }}>This user hasn't participated in any auctions</p>
                          </div>
                        )}
                      </div>
                    )}

                    {/* Auctions Tab */}
                    {detailsTab === 'auctions' && (
                      <div>
                        <h4 style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827', marginBottom: '1rem' }}>
                          User's Auctions ({userAuctions.length})
                        </h4>
                        {userAuctions.length > 0 ? (
                          <div style={{ display: 'grid', gap: '1rem' }}>
                            {userAuctions.map((auction: any) => {
                              const auctionId = auction.auctionId || auction.AuctionId;
                              const property = auction.property || auction.Property || {};
                              const propName = property.name || property.Name || 'Unknown Property';
                              const propLocation = property.location || property.Location || 'Unknown Location';
                              const startPrice = auction.startPrice || auction.StartPrice || 0;
                              const currentPrice = auction.currentPrice || auction.CurrentPrice || 0;
                              const bidCount = auction.bidCount || auction.BidCount || 0;
                              const status = (auction.status || auction.Status || 'Unknown').toLowerCase();
                              const startAt = auction.startAt || auction.StartAt;
                              const duration = auction.duration || auction.Duration || 0;
                              const endDate = startAt ? new Date(new Date(startAt).getTime() + duration * 3600000) : null;
                              
                              // Determine status badge
                              let statusBg, statusColor, statusText;
                              if (status === 'requested') {
                                statusBg = '#fef3c7'; statusColor = '#d97706'; statusText = 'Pending Approval';
                              } else if (status === 'active') {
                                statusBg = '#dcfce7'; statusColor = '#059669'; statusText = 'Active';
                              } else if (status === 'ended') {
                                statusBg = '#f3f4f6'; statusColor = '#6b7280'; statusText = 'Ended';
                              } else if (status === 'cancelled') {
                                statusBg = '#fef2f2'; statusColor = '#dc2626'; statusText = 'Cancelled';
                              } else {
                                statusBg = '#f3f4f6'; statusColor = '#6b7280'; statusText = status;
                              }
                              
                              return (
                                <div key={auctionId} style={{
                                  padding: '1.5rem',
                                  border: '1px solid #e5e7eb',
                                  borderRadius: '0.75rem',
                                  backgroundColor: '#ffffff',
                                  boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)'
                                }}>
                                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '1rem' }}>
                                    <div style={{ flex: 1 }}>
                                      <h5 style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827', margin: '0 0 0.5rem 0' }}>
                                        {propName}
                                      </h5>
                                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', color: '#6b7280', marginBottom: '0.75rem' }}>
                                        <MapPin style={{ height: '1rem', width: '1rem' }} />
                                        {propLocation}
                                      </div>
                                      <div style={{ display: 'flex', gap: '1rem', fontSize: '0.875rem', color: '#6b7280' }}>
                                        <div>
                                          <span style={{ fontWeight: '600', color: '#111827' }}>Start Price:</span> ${startPrice.toLocaleString()}
                                        </div>
                                        <div>
                                          <span style={{ fontWeight: '600', color: '#111827' }}>Current Price:</span> ${currentPrice.toLocaleString()}
                                        </div>
                                        <div>
                                          <span style={{ fontWeight: '600', color: '#111827' }}>Bids:</span> {bidCount}
                                        </div>
                                      </div>
                                    </div>
                                    <div style={{
                                      padding: '0.375rem 0.75rem',
                                      borderRadius: '0.5rem',
                                      backgroundColor: statusBg,
                                      color: statusColor,
                                      fontSize: '0.75rem',
                                      fontWeight: '500'
                                    }}>
                                      {statusText}
                                    </div>
                                  </div>
                                  
                                  {/* Auction Details */}
                                  <div style={{ 
                                    display: 'grid', 
                                    gridTemplateColumns: 'repeat(2, 1fr)',
                                    gap: '1rem', 
                                    padding: '1rem',
                                    backgroundColor: '#f9fafb',
                                    borderRadius: '0.5rem',
                                    marginBottom: status === 'requested' ? '1rem' : 0
                                  }}>
                                    <div>
                                      <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Start Date</div>
                                      <div style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>
                                        {startAt ? new Date(startAt).toLocaleDateString() : 'Not set'}
                                      </div>
                                    </div>
                                    <div>
                                      <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>End Date</div>
                                      <div style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>
                                        {endDate ? endDate.toLocaleDateString() : 'Not set'}
                                      </div>
                                    </div>
                                    <div>
                                      <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Duration</div>
                                      <div style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>
                                        {duration} hours
                                      </div>
                                    </div>
                                    <div>
                                      <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Auction ID</div>
                                      <div style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>
                                        #{auctionId}
                                      </div>
                                    </div>
                                  </div>
                                  
                                  {/* Approve/Reject Buttons for Requested Auctions */}
                                  {status === 'requested' && (
                                    <div style={{ 
                                      display: 'flex', 
                                      gap: '0.75rem', 
                                      marginTop: '1rem',
                                      paddingTop: '1rem',
                                      borderTop: '1px solid #e5e7eb'
                                    }}>
                                      <button
                                        onClick={() => handleApproveAuction(auctionId)}
                                        style={{
                                          flex: 1,
                                          padding: '0.625rem 1rem',
                                          background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                                          color: 'white',
                                          border: 'none',
                                          borderRadius: '0.5rem',
                                          cursor: 'pointer',
                                          fontSize: '0.875rem',
                                          fontWeight: '600',
                                          transition: 'all 0.2s',
                                          display: 'flex',
                                          alignItems: 'center',
                                          justifyContent: 'center',
                                          gap: '0.5rem'
                                        }}
                                      >
                                        <CheckCircle style={{ height: '1rem', width: '1rem' }} />
                                        Approve Auction
                                      </button>
                                      <button
                                        onClick={() => handleRejectAuction(auctionId)}
                                        style={{
                                          flex: 1,
                                          padding: '0.625rem 1rem',
                                          background: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)',
                                          color: 'white',
                                          border: 'none',
                                          borderRadius: '0.5rem',
                                          cursor: 'pointer',
                                          fontSize: '0.875rem',
                                          fontWeight: '600',
                                          transition: 'all 0.2s',
                                          display: 'flex',
                                          alignItems: 'center',
                                          justifyContent: 'center',
                                          gap: '0.5rem'
                                        }}
                                      >
                                        <XCircle style={{ height: '1rem', width: '1rem' }} />
                                        Reject Auction
                                      </button>
                                    </div>
                                  )}
                                </div>
                              );
                            })}
                          </div>
                        ) : (
                          <div style={{
                            padding: '3rem',
                            textAlign: 'center',
                            backgroundColor: '#f9fafb',
                            borderRadius: '0.75rem',
                            color: '#6b7280'
                          }}>
                            <Hammer style={{ height: '3rem', width: '3rem', margin: '0 auto 1rem auto', color: '#9ca3af' }} />
                            <p style={{ margin: 0, fontSize: '1rem', fontWeight: '500' }}>No auctions created yet</p>
                            <p style={{ margin: '0.5rem 0 0 0', fontSize: '0.875rem' }}>This user hasn't created any auctions for their properties</p>
                          </div>
                        )}
                      </div>
                    )}
                  </>
                )}
              </div>

              {/* Footer Actions */}
              <div style={{
                padding: '1.5rem 2rem',
                borderTop: '1px solid #e5e7eb',
                backgroundColor: '#f9fafb',
                display: 'flex',
                justifyContent: 'flex-end'
              }}>
                <button
                  onClick={() => setShowDetailsModal(false)}
                  style={{
                    padding: '0.75rem 1.5rem',
                    backgroundColor: '#f3f4f6',
                    color: '#374151',
                    border: '1px solid #d1d5db',
                    borderRadius: '0.5rem',
                    cursor: 'pointer',
                    fontWeight: '500'
                  }}
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Suspend User Modal */}
      {showSuspendModal && selectedUser && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          zIndex: 50,
          overflowY: 'auto',
          backgroundColor: 'rgba(0, 0, 0, 0.5)'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '100vh',
            padding: '1rem'
          }}>
            <div style={{
              backgroundColor: 'white',
              borderRadius: '1rem',
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
              maxWidth: '32rem',
              width: '100%'
            }}>
              <form onSubmit={handleSuspendUser}>
                <div style={{ padding: '2rem' }}>
                  <h3 style={{
                    fontSize: '1.5rem',
                    fontWeight: '600',
                    color: '#111827',
                    marginBottom: '1rem'
                  }}>Suspend User</h3>
                  
                  <p style={{ fontSize: '0.875rem', color: '#6b7280', marginBottom: '1.5rem' }}>
                    Suspend {selectedUser.firstName} {selectedUser.lastName}'s account
                  </p>
                  
                  <div style={{ marginBottom: '1.5rem' }}>
                    <label style={{
                      display: 'block',
                      fontSize: '0.875rem',
                      fontWeight: '500',
                      color: '#374151',
                      marginBottom: '0.5rem'
                    }}>Suspension Duration</label>
                    <select
                      value={suspensionDuration}
                      onChange={(e) => setSuspensionDuration(e.target.value)}
                      style={{
                        width: '100%',
                        padding: '0.75rem',
                        border: '1px solid #d1d5db',
                        borderRadius: '0.5rem',
                        fontSize: '0.875rem',
                        outline: 'none',
                        transition: 'all 0.2s',
                        backgroundColor: 'white'
                      }}
                      required
                    >
                      <option value="1">1 Day</option>
                      <option value="3">3 Days</option>
                      <option value="7">7 Days (1 Week)</option>
                      <option value="14">14 Days (2 Weeks)</option>
                      <option value="30">30 Days (1 Month)</option>
                      <option value="90">90 Days (3 Months)</option>
                      <option value="0">Indefinite (Until manually unsuspended)</option>
                    </select>
                  </div>
                  
                  <div>
                    <label style={{
                      display: 'block',
                      fontSize: '0.875rem',
                      fontWeight: '500',
                      color: '#374151',
                      marginBottom: '0.5rem'
                    }}>Reason for Suspension</label>
                    <textarea
                      value={suspensionReason}
                      onChange={(e) => setSuspensionReason(e.target.value)}
                      style={{
                        width: '100%',
                        padding: '0.75rem',
                        border: '1px solid #d1d5db',
                        borderRadius: '0.5rem',
                        fontSize: '0.875rem',
                        outline: 'none',
                        transition: 'all 0.2s',
                        resize: 'vertical',
                        minHeight: '4rem'
                      }}
                      placeholder="Enter reason for suspension (optional)"
                      rows={3}
                    />
                  </div>
                </div>
                
                <div style={{
                  backgroundColor: '#f9fafb',
                  padding: '1.5rem',
                  display: 'flex',
                  justifyContent: 'flex-end',
                  gap: '1rem',
                  borderTop: '1px solid #e5e7eb'
                }}>
                  <button
                    type="button"
                    onClick={() => {
                      setShowSuspendModal(false);
                      setSuspensionDuration('7');
                      setSuspensionReason('');
                    }}
                    style={{
                      padding: '0.75rem 1.5rem',
                      backgroundColor: '#f3f4f6',
                      color: '#374151',
                      border: '1px solid #d1d5db',
                      borderRadius: '0.5rem',
                      cursor: 'pointer',
                      transition: 'all 0.2s'
                    }}
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    style={{
                      padding: '0.75rem 1.5rem',
                      background: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
                      color: 'white',
                      border: 'none',
                      borderRadius: '0.5rem',
                      cursor: 'pointer',
                      transition: 'all 0.2s',
                      fontWeight: '500'
                    }}
                  >
                    Suspend User
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Edit User Modal */}
      {showEditModal && selectedUser && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          zIndex: 50,
          overflowY: 'auto',
          backgroundColor: 'rgba(0, 0, 0, 0.5)'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '100vh',
            padding: '1rem'
          }}>
            <div style={{
              backgroundColor: 'white',
              borderRadius: '1rem',
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
              maxWidth: '36rem',
              width: '100%'
            }}>
              <form onSubmit={handleEditUser}>
                <div style={{ padding: '2rem' }}>
                  <h3 style={{
                    fontSize: '1.5rem',
                    fontWeight: '600',
                    color: '#111827',
                    marginBottom: '1rem'
                  }}>Edit User Information</h3>
                  
                  <p style={{ fontSize: '0.875rem', color: '#6b7280', marginBottom: '1.5rem' }}>
                    Update {selectedUser.firstName} {selectedUser.lastName}'s account details
                  </p>
                  
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1rem' }}>
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>First Name</label>
                      <input
                        type="text"
                        value={editForm.firstName}
                        onChange={(e) => setEditForm({ ...editForm, firstName: e.target.value })}
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none'
                        }}
                        required
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Last Name</label>
                      <input
                        type="text"
                        value={editForm.lastName}
                        onChange={(e) => setEditForm({ ...editForm, lastName: e.target.value })}
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none'
                        }}
                        required
                      />
                    </div>
                    
                    <div style={{ gridColumn: 'span 2' }}>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Email</label>
                      <input
                        type="email"
                        value={editForm.email}
                        onChange={(e) => setEditForm({ ...editForm, email: e.target.value })}
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none'
                        }}
                        required
                      />
                    </div>
                    
                    <div style={{ gridColumn: 'span 2' }}>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Phone Number</label>
                      <input
                        type="tel"
                        value={editForm.phoneNumber}
                        onChange={(e) => setEditForm({ ...editForm, phoneNumber: e.target.value })}
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none'
                        }}
                        required
                      />
                    </div>
                  </div>
                </div>
                
                <div style={{
                  backgroundColor: '#f9fafb',
                  padding: '1.5rem',
                  display: 'flex',
                  justifyContent: 'flex-end',
                  gap: '1rem',
                  borderTop: '1px solid #e5e7eb'
                }}>
                  <button
                    type="button"
                    onClick={() => setShowEditModal(false)}
                    style={{
                      padding: '0.75rem 1.5rem',
                      backgroundColor: '#f3f4f6',
                      color: '#374151',
                      border: '1px solid #d1d5db',
                      borderRadius: '0.5rem',
                      cursor: 'pointer',
                      transition: 'all 0.2s'
                    }}
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    style={{
                      padding: '0.75rem 1.5rem',
                      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                      color: 'white',
                      border: 'none',
                      borderRadius: '0.5rem',
                      cursor: 'pointer',
                      transition: 'all 0.2s',
                      fontWeight: '500'
                    }}
                  >
                    Save Changes
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default UsersPage;

