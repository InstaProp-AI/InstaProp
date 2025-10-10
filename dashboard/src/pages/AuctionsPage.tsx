import React, { useState, useEffect } from 'react';
import { auctionsApi, bidsApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { useWebSocket } from '../hooks/useWebSocket';
import Pagination from '../components/Pagination';
import { 
  Hammer, 
  Clock, 
  Users, 
  DollarSign, 
  TrendingUp, 
  Eye,
  Calendar,
  MapPin,
  Bed,
  Bath,
  Square,
  Star,
  AlertCircle,
  CheckCircle,
  Play,
  Pause,
  StopCircle,
  MoreVertical,
  Filter,
  Search,
  Plus,
  BarChart3,
  Target,
  Award,
  Zap,
  XCircle,
  LayoutGrid,
  List,
  RefreshCw
} from 'lucide-react';

interface Auction {
  auctionId: number;
  propertyId: number;
  propertyName: string;
  propertyImage: string;
  location: string;
  startingPrice: number;
  currentBid: number;
  bidCount: number;
  status: 'requested' | 'starting-soon' | 'upcoming' | 'active' | 'ended' | 'cancelled';
  startTime: string;
  endTime: string;
  highestBidder?: string;
  description: string;
  bedrooms: number;
  bathrooms: number;
  squareFeet: number;
  ownerId?: number;
  ownerName?: string;
  duration?: number;
}

interface Bid {
  bidId: number;
  auctionId: number;
  bidderName: string;
  bidAmount: number;
  timestamp: string;
  isHighest: boolean;
}

const AuctionsPage: React.FC = () => {
  const toast = useToast();
  const [auctions, setAuctions] = useState<Auction[]>([]);
  const [bids, setBids] = useState<Bid[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedAuction, setSelectedAuction] = useState<Auction | null>(null);
  const [showBidModal, setShowBidModal] = useState(false);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [showRelistModal, setShowRelistModal] = useState(false);
  const [auctionBids, setAuctionBids] = useState<any[]>([]);
  const [newBidAmount, setNewBidAmount] = useState(0);
  const [filterStatus, setFilterStatus] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [gridColumns, setGridColumns] = useState(4);
  const [relistForm, setRelistForm] = useState({
    duration: 24,
    resetPrice: false,
    resetBids: false
  });

  // WebSocket for real-time auction updates
  const { isConnected, lastMessage } = useWebSocket({
    url: 'ws://localhost:5284/ws/auction',
    onMessage: (data) => {
      console.log('Received WebSocket update:', data);
      // Refresh auctions when update received
      fetchAuctions();
    },
    onError: (error) => {
      console.warn('WebSocket error (non-critical):', error);
    }
  });

  useEffect(() => {
    fetchAuctions();
  }, []);

  useEffect(() => {
    if (lastMessage) {
      // Handle real-time updates
      toast.info('Auction updated in real-time');
    }
  }, [lastMessage]);

  const getAuctionStatus = (auction: any) => {
    const now = new Date().getTime();
    const start = auction.startAt ? new Date(auction.startAt).getTime() : 0;
    const duration = auction.duration || 0;
    const end = start + (duration * 3600000);
    const status = auction.status?.toLowerCase() || '';
    
    // If backend says requested or cancelled, use that
    if (status === 'requested') return 'requested';
    if (status === 'cancelled') return 'cancelled';
    if (status === 'ended') return 'ended';
    
    // If active/past end time, it's ended
    if (status === 'active' && now > end) return 'ended';
    
    // If active and within time, it's live
    if (status === 'active' && now >= start && now <= end) return 'active';
    
    // Starting soon (within 48 hours)
    const hoursTillStart = (start - now) / (1000 * 60 * 60);
    if (start > now && hoursTillStart <= 48) return 'starting-soon';
    
    // Upcoming (more than 48 hours away)
    if (start > now) return 'upcoming';
    
    return 'upcoming';
  };

  const fetchAuctions = async () => {
    try {
      setLoading(true);
      console.log('🔨 Starting to fetch auctions from API...');
      console.log('🔨 API URL: http://localhost:5284/api/admin/auctions');
      
      const data = await auctionsApi.getAllAuctions();
      
      console.log('📋 Fetched auctions - Count:', data?.length || 0);
      console.log('📋 Raw auction data:', data);
      
      if (!data || data.length === 0) {
        console.warn('⚠️ No auctions found in database');
        setAuctions([]);
        toast.info('No auctions found in the system');
        setLoading(false);
        return;
      }
      
      console.log('📋 Sample auction structure:', data[0]);
      
      // Fetch bids for all auctions to get winners
      console.log('💰 Fetching bids for', data.length, 'auctions...');
      const allBidsPromises = data.map((auction: any) => 
        bidsApi.getBidsForAuction(auction.auctionId || auction.AuctionId)
          .catch((err) => {
            console.warn(`⚠️ Could not fetch bids for auction ${auction.auctionId}:`, err.message);
            return [];
          })
      );
      const allBidsResults = await Promise.all(allBidsPromises);
      console.log('💰 Bids fetched for all auctions');
      
      // Transform backend data to match frontend expectations
      const transformedAuctions = data.map((auction: any, index: number) => {
        const auctionBids = allBidsResults[index] || [];
        const sortedBids = auctionBids.sort((a: any, b: any) => 
          (b.bidAmount || b.BidAmount || 0) - (a.bidAmount || a.BidAmount || 0)
        );
        const highestBid = sortedBids[0];
        const winner = highestBid ? (
          highestBid.bidderName || 
          (highestBid.bidder ? `${highestBid.bidder.firstName} ${highestBid.bidder.lastName}` : null)
        ) : null;
        
        const startAt = auction.startAt || auction.StartAt;
        const duration = auction.duration || auction.Duration || 0;
        const endTime = auction.endAt || auction.EndAt || new Date(new Date(startAt).getTime() + duration * 3600000).toISOString();
        const computedStatus = getAuctionStatus(auction);
        
        return {
          auctionId: auction.auctionId || auction.AuctionId,
          propertyId: auction.propertyId || auction.PropertyId,
          propertyName: auction.property?.name || auction.Property?.Name || 'Unknown Property',
          propertyImage: auction.property?.imageUrl || auction.Property?.ImageUrl || 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&h=300&fit=crop',
          location: auction.property?.location || auction.Property?.Location || 'Unknown Location',
          startingPrice: auction.startPrice || auction.StartPrice || 0,
          currentBid: auction.currentPrice || auction.CurrentPrice || auction.startPrice || auction.StartPrice || 0,
          bidCount: auction.bidCount || auction.BidCount || 0,
          status: computedStatus,
          startTime: startAt,
          endTime: endTime,
          highestBidder: winner,
          description: auction.property?.description || auction.Property?.Description || '',
          bedrooms: auction.property?.bedrooms || auction.Property?.Bedrooms || 0,
          bathrooms: auction.property?.bathrooms || auction.Property?.Bathrooms || 0,
          squareFeet: auction.property?.squareFeet || auction.Property?.SquareFeet || 0,
          ownerId: auction.property?.ownerId || auction.Property?.OwnerId || null,
          ownerName: (() => {
            const owner = auction.property?.owner || auction.Property?.Owner;
            if (!owner) {
              console.warn('⚠️ No owner found for auction:', auction.auctionId, 'Property:', auction.property);
              return 'Unknown';
            }
            
            const firstName = owner.firstName || owner.FirstName || '';
            const lastName = owner.lastName || owner.LastName || '';
            const fullName = `${firstName} ${lastName}`.trim();
            
            console.log('👤 Owner for auction', auction.auctionId, ':', { owner, firstName, lastName, fullName });
            
            return fullName || 'Unknown';
          })(),
          duration: duration
        };
      });
      
      console.log('✅ Transformed auctions - Count:', transformedAuctions.length);
      console.log('✅ Sample transformed auction:', transformedAuctions[0]);
      
      setAuctions(transformedAuctions);
      toast.success(`Loaded ${transformedAuctions.length} auctions successfully!`);
    } catch (error: any) {
      console.error('❌ Error fetching auctions:', error);
      console.error('❌ Error details:', {
        message: error.message,
        response: error.response?.data,
        status: error.response?.status,
        config: error.config?.url
      });
      
      if (error.message?.includes('Network Error') || error.code === 'ERR_NETWORK') {
        toast.error('Cannot connect to API. Make sure the API is running on port 5284');
      } else {
        toast.error(error?.response?.data?.message || error.message || 'Failed to load auctions');
      }
      
      setAuctions([]);
    } finally {
      setLoading(false);
    }
  };

  // Old simulated data code - keeping for reference
  const oldFetchCode = () => {
    setTimeout(() => {
      setAuctions([
        {
          auctionId: 1,
          propertyId: 1,
          propertyName: 'Modern Downtown Loft',
          propertyImage: 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&h=300&fit=crop',
          location: 'Downtown, New York',
          startingPrice: 450000,
          currentBid: 520000,
          bidCount: 12,
          status: 'active',
          startTime: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
          endTime: new Date(Date.now() + 22 * 60 * 60 * 1000).toISOString(),
          highestBidder: 'John Smith',
          description: 'Stunning modern loft with panoramic city views',
          bedrooms: 2,
          bathrooms: 2,
          squareFeet: 1200
        },
        {
          auctionId: 2,
          propertyId: 2,
          propertyName: 'Luxury Beach House',
          propertyImage: 'https://images.unsplash.com/photo-1570129477492-45c003edd2be?w=400&h=300&fit=crop',
          location: 'Malibu, California',
          startingPrice: 1200000,
          currentBid: 1350000,
          bidCount: 8,
          status: 'active',
          startTime: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
          endTime: new Date(Date.now() + 23 * 60 * 60 * 1000).toISOString(),
          highestBidder: 'Sarah Johnson',
          description: 'Oceanfront property with private beach access',
          bedrooms: 4,
          bathrooms: 3,
          squareFeet: 2500
        },
        {
          auctionId: 3,
          propertyId: 3,
          propertyName: 'Commercial Office Space',
          propertyImage: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=400&h=300&fit=crop',
          location: 'Financial District, San Francisco',
          startingPrice: 800000,
          currentBid: 0,
          bidCount: 0,
          status: 'upcoming',
          startTime: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
          endTime: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
          description: 'Prime office space in business district',
          bedrooms: 0,
          bathrooms: 2,
          squareFeet: 3000
        }
      ]);

      setBids([
        {
          bidId: 1,
          auctionId: 1,
          bidderName: 'John Smith',
          bidAmount: 520000,
          timestamp: new Date(Date.now() - 5 * 60 * 1000).toISOString(),
          isHighest: true
        },
        {
          bidId: 2,
          auctionId: 1,
          bidderName: 'Mike Wilson',
          bidAmount: 510000,
          timestamp: new Date(Date.now() - 15 * 60 * 1000).toISOString(),
          isHighest: false
        },
        {
          bidId: 3,
          auctionId: 2,
          bidderName: 'Sarah Johnson',
          bidAmount: 1350000,
          timestamp: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
          isHighest: true
        }
      ]);

      setLoading(false);
    }, 1000);
  };

  const handleStartAuction = async (auctionId: number) => {
    try {
      await auctionsApi.startAuction(auctionId);
      toast.success('Auction started successfully!');
      fetchAuctions();
    } catch (error: any) {
      console.error('Error starting auction:', error);
      toast.error(error?.response?.data?.message || 'Failed to start auction');
    }
  };

  const handleEndAuction = async (auctionId: number) => {
    if (window.confirm('Are you sure you want to end this auction?')) {
      try {
        await auctionsApi.endAuction(auctionId);
        toast.success('Auction ended successfully!');
        fetchAuctions();
      } catch (error: any) {
        console.error('Error ending auction:', error);
        toast.error(error?.response?.data?.message || 'Failed to end auction');
      }
    }
  };

  const handleRelistAuction = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedAuction) return;

    try {
      await auctionsApi.relistAuction(selectedAuction.auctionId, {
        duration: relistForm.duration,
        resetPrice: relistForm.resetPrice,
        resetBids: relistForm.resetBids
      });
      
      toast.success('Auction relisted successfully!');
      setShowRelistModal(false);
      setRelistForm({ duration: 24, resetPrice: false, resetBids: false });
      fetchAuctions();
    } catch (error: any) {
      console.error('Error relisting auction:', error);
      toast.error(error?.response?.data?.message || 'Failed to relist auction');
    }
  };

  const openRelistModal = (auction: Auction) => {
    setSelectedAuction(auction);
    setRelistForm({
      duration: auction.duration || 24,
      resetPrice: false,
      resetBids: false
    });
    setShowRelistModal(true);
  };

  const handleApproveAuction = async (auctionId: number) => {
    try {
      await auctionsApi.approveAuction(auctionId);
      toast.success('Auction approved successfully!');
      fetchAuctions();
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
        fetchAuctions();
      } catch (error: any) {
        console.error('Error rejecting auction:', error);
        toast.error(error?.response?.data?.message || 'Failed to reject auction');
      }
    }
  };

  const handleViewDetails = async (auction: any) => {
    setSelectedAuction(auction);
    setShowDetailsModal(true);
    
    // Fetch bids for this auction
    try {
      console.log('📋 Fetching bids for auction:', auction.auctionId);
      const bidsData = await bidsApi.getBidsForAuction(auction.auctionId);
      console.log('📋 Bids data received:', bidsData);
      
      // Sort bids by amount descending (highest first)
      const sortedBids = (bidsData || []).sort((a: any, b: any) => 
        (b.bidAmount || b.BidAmount || 0) - (a.bidAmount || a.BidAmount || 0)
      );
      
      setAuctionBids(sortedBids);
      
      if (sortedBids.length > 0) {
        toast.success(`Loaded ${sortedBids.length} bid${sortedBids.length > 1 ? 's' : ''} for this auction`);
      }
    } catch (error: any) {
      console.error('❌ Error fetching auction bids:', error);
      console.error('❌ Error details:', error.response?.data);
      toast.error('Failed to load bids for this auction');
      setAuctionBids([]);
    }
  };

  const handlePlaceBid = (e: React.FormEvent) => {
    e.preventDefault();
    if (selectedAuction && newBidAmount > selectedAuction.currentBid) {
      const newBid: Bid = {
        bidId: bids.length + 1,
        auctionId: selectedAuction.auctionId,
        bidderName: 'Current User',
        bidAmount: newBidAmount,
        timestamp: new Date().toISOString(),
        isHighest: true
      };
      
      setBids([...bids, newBid]);
      setAuctions(auctions.map(auction => 
        auction.auctionId === selectedAuction.auctionId
          ? { 
              ...auction, 
              currentBid: newBidAmount,
              bidCount: auction.bidCount + 1,
              highestBidder: 'Current User'
            }
          : auction
      ));
      
      setShowBidModal(false);
      setNewBidAmount(0);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'requested': return '#f59e0b';
      case 'starting-soon': return '#8b5cf6';
      case 'active': return '#10b981';
      case 'upcoming': return '#3b82f6';
      case 'ended': return '#6b7280';
      case 'cancelled': return '#ef4444';
      default: return '#6b7280';
    }
  };

  const getStatusBg = (status: string) => {
    switch (status) {
      case 'requested': return '#fef3c7';
      case 'starting-soon': return '#ede9fe';
      case 'active': return '#dcfce7';
      case 'upcoming': return '#dbeafe';
      case 'ended': return '#f3f4f6';
      case 'cancelled': return '#fef2f2';
      default: return '#f3f4f6';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'requested': return 'REQUESTED';
      case 'starting-soon': return 'STARTING SOON';
      case 'active': return 'LIVE';
      case 'upcoming': return 'UPCOMING';
      case 'ended': return 'ENDED';
      case 'cancelled': return 'CANCELLED';
      default: return status.toUpperCase();
    }
  };

  const getTimeRemaining = (endTime: string) => {
    const now = new Date().getTime();
    const end = new Date(endTime).getTime();
    const diff = end - now;
    
    if (diff <= 0) return 'Ended';
    
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
    
    if (days > 0) return `${days}d ${hours}h`;
    if (hours > 0) return `${hours}h ${minutes}m`;
    return `${minutes}m`;
  };

  const filteredAuctions = auctions.filter(auction => {
    const matchesSearch = auction.propertyName.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         auction.location.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || auction.status === filterStatus;
    
    return matchesSearch && matchesStatus;
  });

  // Pagination
  const totalPages = Math.ceil(filteredAuctions.length / itemsPerPage);
  const paginatedAuctions = filteredAuctions.slice(
    (currentPage - 1) * itemsPerPage,
    currentPage * itemsPerPage
  );

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
          }}>Auctions Management</h1>
          <p style={{
            fontSize: '1.125rem',
            color: '#6b7280',
            margin: 0
          }}>
            Monitor, control, and manage all property auctions
          </p>
        </div>
        
        {/* Action Bar */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          width: '100%',
          gap: '1rem',
          flexWrap: 'wrap'
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', flex: 1 }}>
            {/* Search */}
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
                placeholder="Search auctions..."
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

            {/* Status Filter */}
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
              <option value="all">All Auctions</option>
              <option value="requested">🔔 Requested</option>
              <option value="starting-soon">🚀 Starting Soon</option>
              <option value="active">🔴 Live</option>
              <option value="upcoming">📅 Upcoming</option>
              <option value="ended">✅ Ended</option>
              <option value="cancelled">❌ Cancelled</option>
            </select>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            {/* View Toggle */}
            <div style={{
              display: 'flex',
              backgroundColor: '#f3f4f6',
              borderRadius: '0.75rem',
              padding: '0.25rem'
            }}>
              <button
                onClick={() => setViewMode('grid')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  padding: '0.5rem 1rem',
                  backgroundColor: viewMode === 'grid' ? 'white' : 'transparent',
                  color: viewMode === 'grid' ? '#667eea' : '#6b7280',
                  border: 'none',
                  borderRadius: '0.5rem',
                  cursor: 'pointer',
                  transition: 'all 0.2s',
                  fontWeight: viewMode === 'grid' ? '600' : '400',
                  boxShadow: viewMode === 'grid' ? '0 1px 3px rgba(0,0,0,0.1)' : 'none'
                }}
              >
                <LayoutGrid style={{ height: '1rem', width: '1rem' }} />
                Grid
              </button>
              <button
                onClick={() => setViewMode('list')}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  padding: '0.5rem 1rem',
                  backgroundColor: viewMode === 'list' ? 'white' : 'transparent',
                  color: viewMode === 'list' ? '#667eea' : '#6b7280',
                  border: 'none',
                  borderRadius: '0.5rem',
                  cursor: 'pointer',
                  transition: 'all 0.2s',
                  fontWeight: viewMode === 'list' ? '600' : '400',
                  boxShadow: viewMode === 'list' ? '0 1px 3px rgba(0,0,0,0.1)' : 'none'
                }}
              >
                <List style={{ height: '1rem', width: '1rem' }} />
                List
              </button>
            </div>

            {/* Grid Columns Selector - Only show when in grid mode */}
            {viewMode === 'grid' && (
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem'
              }}>
                <span style={{
                  fontSize: '0.875rem',
                  color: '#6b7280',
                  fontWeight: '500'
                }}>
                  Columns:
                </span>
                <div style={{
                  display: 'flex',
                  gap: '0.25rem',
                  backgroundColor: '#f3f4f6',
                  borderRadius: '0.5rem',
                  padding: '0.25rem'
                }}>
                  {[2, 3, 4, 5].map((cols) => (
                    <button
                      key={cols}
                      onClick={() => setGridColumns(cols)}
                      style={{
                        padding: '0.375rem 0.75rem',
                        backgroundColor: gridColumns === cols ? 'white' : 'transparent',
                        color: gridColumns === cols ? '#667eea' : '#6b7280',
                        border: 'none',
                        borderRadius: '0.375rem',
                        cursor: 'pointer',
                        transition: 'all 0.2s',
                        fontWeight: gridColumns === cols ? '600' : '400',
                        fontSize: '0.875rem',
                        boxShadow: gridColumns === cols ? '0 1px 3px rgba(0,0,0,0.1)' : 'none'
                      }}
                    >
                      {cols}
                    </button>
                  ))}
                </div>
              </div>
            )}

            <button style={{
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
            }}>
              <BarChart3 style={{ height: '1rem', width: '1rem' }} />
              Analytics
            </button>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '1rem',
        marginBottom: '2rem'
      }}>
        {[
          {
            title: 'Requested',
            value: auctions.filter(a => a.status === 'requested').length,
            icon: AlertCircle,
            color: '#f59e0b',
            bgColor: '#fef3c7'
          },
          {
            title: 'Starting Soon',
            value: auctions.filter(a => a.status === 'starting-soon').length,
            icon: Zap,
            color: '#8b5cf6',
            bgColor: '#ede9fe'
          },
          {
            title: 'Live Now',
            value: auctions.filter(a => a.status === 'active').length,
            icon: Hammer,
            color: '#10b981',
            bgColor: '#dcfce7'
          },
          {
            title: 'Upcoming',
            value: auctions.filter(a => a.status === 'upcoming').length,
            icon: Calendar,
            color: '#3b82f6',
            bgColor: '#dbeafe'
          },
          {
            title: 'Ended',
            value: auctions.filter(a => a.status === 'ended').length,
            icon: CheckCircle,
            color: '#6b7280',
            bgColor: '#f3f4f6'
          },
          {
            title: 'Total Revenue',
            value: `$${auctions.filter(a => a.status === 'ended').reduce((sum, a) => sum + a.currentBid, 0).toLocaleString()}`,
            icon: DollarSign,
            color: '#10b981',
            bgColor: '#dcfce7'
          }
        ].map((stat, index) => (
          <div key={index} style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            padding: '1.5rem',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
            border: '1px solid #e5e7eb',
            transition: 'all 0.3s ease'
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
            </div>
            <h3 style={{ fontSize: '2rem', fontWeight: 'bold', color: '#111827', margin: '0 0 0.25rem 0' }}>
              {stat.value}
            </h3>
            <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: 0 }}>{stat.title}</p>
          </div>
        ))}
      </div>

      {/* Auctions Grid View */}
      {viewMode === 'grid' && (
        <div style={{
          display: 'grid',
          gridTemplateColumns: `repeat(${gridColumns}, 1fr)`,
          gap: '1.5rem',
          alignItems: 'stretch'
        }}>
          {paginatedAuctions.map((auction) => (
          <div key={auction.auctionId} style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            overflow: 'hidden',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
            border: '1px solid #e5e7eb',
            transition: 'all 0.3s ease',
            position: 'relative',
            display: 'flex',
            flexDirection: 'column',
            height: '100%'
          }}>
            {/* Property Image */}
            <div style={{
              position: 'relative',
              width: '100%',
              height: '12rem',
              overflow: 'hidden'
            }}>
              <img
                src={auction.propertyImage}
                alt={auction.propertyName}
                style={{
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover'
                }}
              />
              <div style={{
                position: 'absolute',
                top: '1rem',
                left: '1rem',
                right: '1rem',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'flex-start'
              }}>
                <div style={{
                  padding: '0.5rem 1rem',
                  borderRadius: '0.5rem',
                  fontSize: '0.75rem',
                  fontWeight: '500',
                  backgroundColor: getStatusBg(auction.status),
                  color: getStatusColor(auction.status)
                }}>
                  {getStatusLabel(auction.status)}
                </div>
                <div style={{
                  padding: '0.5rem 1rem',
                  borderRadius: '0.5rem',
                  fontSize: '0.75rem',
                  fontWeight: '500',
                  backgroundColor: 'rgba(0,0,0,0.7)',
                  color: 'white',
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.25rem'
                }}>
                  <Clock style={{ height: '0.75rem', width: '0.75rem' }} />
                  {getTimeRemaining(auction.endTime)}
                </div>
              </div>
            </div>
            
            {/* Auction Details */}
            <div style={{ padding: '1.5rem', flex: 1, display: 'flex', flexDirection: 'column' }}>
              <div style={{ marginBottom: '1rem' }}>
                <h3 style={{
                  fontSize: '1.25rem',
                  fontWeight: '600',
                  color: '#111827',
                  marginBottom: '0.5rem'
                }}>{auction.propertyName}</h3>
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  fontSize: '0.875rem',
                  color: '#6b7280',
                  marginBottom: '0.5rem'
                }}>
                  <MapPin style={{ height: '1rem', width: '1rem', marginRight: '0.25rem' }} />
                  {auction.location}
                </div>
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '1rem',
                  fontSize: '0.875rem',
                  color: '#6b7280'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center' }}>
                    <Bed style={{ height: '1rem', width: '1rem', marginRight: '0.25rem' }} />
                    {auction.bedrooms} beds
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center' }}>
                    <Bath style={{ height: '1rem', width: '1rem', marginRight: '0.25rem' }} />
                    {auction.bathrooms} baths
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center' }}>
                    <Square style={{ height: '1rem', width: '1rem', marginRight: '0.25rem' }} />
                    {auction.squareFeet.toLocaleString()} sq ft
                  </div>
                </div>
              </div>

              {/* Bidding Info */}
              <div style={{
                backgroundColor: '#f8fafc',
                borderRadius: '0.75rem',
                padding: '1rem',
                marginBottom: '1rem'
              }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>Current Bid</span>
                  <span style={{ fontSize: '1.25rem', fontWeight: '700', color: '#111827' }}>
                    ${auction.currentBid.toLocaleString()}
                  </span>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Users style={{ height: '1rem', width: '1rem', color: '#6b7280' }} />
                    <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>
                      {auction.bidCount} bids
                    </span>
                  </div>
                  {auction.highestBidder && (
                    <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>
                      by {auction.highestBidder}
                    </span>
                  )}
                </div>
                {/* Winner Info for Ended Auctions */}
                {auction.status === 'ended' && auction.highestBidder && (
                  <div style={{
                    marginTop: '0.75rem',
                    padding: '0.75rem',
                    backgroundColor: '#dcfce7',
                    borderRadius: '0.5rem',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem'
                  }}>
                    <Award style={{ height: '1rem', width: '1rem', color: '#059669' }} />
                    <span style={{ fontSize: '0.875rem', fontWeight: '600', color: '#059669' }}>
                      Winner: {auction.highestBidder}
                    </span>
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              <div style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                gap: '0.5rem',
                flexWrap: 'wrap',
                marginTop: 'auto'
              }}>
                <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                  {auction.status === 'requested' && (
                    <>
                      <button
                        onClick={() => handleApproveAuction(auction.auctionId)}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem',
                          padding: '0.5rem 1rem',
                          backgroundColor: '#10b981',
                          color: 'white',
                          border: 'none',
                          borderRadius: '0.5rem',
                          cursor: 'pointer',
                          fontSize: '0.875rem',
                          fontWeight: '500'
                        }}
                      >
                        <CheckCircle style={{ height: '1rem', width: '1rem' }} />
                        Approve
                      </button>
                      <button
                        onClick={() => handleRejectAuction(auction.auctionId)}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem',
                          padding: '0.5rem 1rem',
                          backgroundColor: '#ef4444',
                          color: 'white',
                          border: 'none',
                          borderRadius: '0.5rem',
                          cursor: 'pointer',
                          fontSize: '0.875rem',
                          fontWeight: '500'
                        }}
                      >
                        <XCircle style={{ height: '1rem', width: '1rem' }} />
                        Reject
                      </button>
                    </>
                  )}
                  {(auction.status === 'upcoming' || auction.status === 'starting-soon') && (
                    <button
                      onClick={() => handleStartAuction(auction.auctionId)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        padding: '0.5rem 1rem',
                        backgroundColor: '#10b981',
                        color: 'white',
                        border: 'none',
                        borderRadius: '0.5rem',
                        cursor: 'pointer',
                        fontSize: '0.875rem',
                        fontWeight: '500'
                      }}
                    >
                      <Play style={{ height: '1rem', width: '1rem' }} />
                      Start
                    </button>
                  )}
                  {auction.status === 'active' && (
                    <button
                      onClick={() => handleEndAuction(auction.auctionId)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        padding: '0.5rem 1rem',
                        backgroundColor: '#ef4444',
                        color: 'white',
                        border: 'none',
                        borderRadius: '0.5rem',
                        cursor: 'pointer',
                        fontSize: '0.875rem',
                        fontWeight: '500'
                      }}
                    >
                      <StopCircle style={{ height: '1rem', width: '1rem' }} />
                      End
                    </button>
                  )}
                  {auction.status === 'ended' && (
                    <button
                      onClick={() => openRelistModal(auction)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        padding: '0.5rem 1rem',
                        background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                        color: 'white',
                        border: 'none',
                        borderRadius: '0.5rem',
                        cursor: 'pointer',
                        fontSize: '0.875rem',
                        fontWeight: '500'
                      }}
                    >
                      <RefreshCw style={{ height: '1rem', width: '1rem' }} />
                      Relist
                    </button>
                  )}
                </div>
                <button 
                  onClick={() => handleViewDetails(auction)}
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
                    fontSize: '0.875rem'
                  }}>
                  <Eye style={{ height: '1rem', width: '1rem' }} />
                  View Details
                </button>
              </div>
            </div>
          </div>
          ))}
        </div>
      )}

      {/* Auctions List View */}
      {viewMode === 'list' && (
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '1rem'
        }}>
          {paginatedAuctions.map((auction) => (
            <div key={auction.auctionId} style={{
              backgroundColor: 'white',
              borderRadius: '1rem',
              overflow: 'hidden',
              boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
              border: '1px solid #e5e7eb',
              transition: 'all 0.3s ease',
              display: 'flex',
              minHeight: '200px',
              position: 'relative'
            }}>
              {/* Property Image - Left Side */}
              <div style={{
                position: 'relative',
                width: '350px',
                flexShrink: 0,
                overflow: 'hidden'
              }}>
                <img
                  src={auction.propertyImage}
                  alt={auction.propertyName}
                  style={{
                    width: '100%',
                    height: '100%',
                    objectFit: 'cover'
                  }}
                />
                <div style={{
                  position: 'absolute',
                  top: '1rem',
                  left: '1rem',
                  right: '1rem',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'flex-start'
                }}>
                  <div style={{
                    padding: '0.5rem 1rem',
                    borderRadius: '0.5rem',
                    fontSize: '0.75rem',
                    fontWeight: '600',
                    backgroundColor: getStatusBg(auction.status),
                    color: getStatusColor(auction.status)
                  }}>
                    {getStatusLabel(auction.status)}
                  </div>
                  <div style={{
                    padding: '0.5rem 1rem',
                    borderRadius: '0.5rem',
                    fontSize: '0.75rem',
                    fontWeight: '600',
                    backgroundColor: 'rgba(0,0,0,0.7)',
                    color: 'white',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.25rem'
                  }}>
                    <Clock style={{ height: '0.75rem', width: '0.75rem' }} />
                    {getTimeRemaining(auction.endTime)}
                  </div>
                </div>
              </div>
              
              {/* Auction Details - Right Side */}
              <div style={{ padding: '1.5rem', flex: 1, display: 'flex', flexDirection: 'column' }}>
                <div style={{ flex: 1 }}>
                  <h3 style={{
                    fontSize: '1.5rem',
                    fontWeight: '600',
                    color: '#111827',
                    marginBottom: '0.5rem'
                  }}>{auction.propertyName}</h3>
                  
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    fontSize: '0.875rem',
                    color: '#6b7280',
                    marginBottom: '1rem'
                  }}>
                    <MapPin style={{ height: '1rem', width: '1rem', marginRight: '0.5rem' }} />
                    {auction.location}
                  </div>
                  
                  {auction.ownerName && (
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      fontSize: '0.875rem',
                      color: '#6b7280',
                      marginBottom: '1rem',
                      padding: '0.75rem',
                      backgroundColor: '#f0fdf4',
                      borderRadius: '0.5rem'
                    }}>
                      <Users style={{ height: '1rem', width: '1rem', marginRight: '0.5rem', color: '#059669' }} />
                      <span><strong>Owner:</strong> {auction.ownerName}</span>
                    </div>
                  )}
                  
                  {/* Property Specs */}
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '1.5rem',
                    marginBottom: '1rem',
                    fontSize: '0.875rem',
                    color: '#6b7280',
                    padding: '1rem',
                    backgroundColor: '#f8fafc',
                    borderRadius: '0.5rem'
                  }}>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                      <Bed style={{ height: '1.25rem', width: '1.25rem', marginRight: '0.5rem', color: '#667eea' }} />
                      <strong style={{ color: '#111827' }}>{auction.bedrooms}</strong>&nbsp;beds
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                      <Bath style={{ height: '1.25rem', width: '1.25rem', marginRight: '0.5rem', color: '#667eea' }} />
                      <strong style={{ color: '#111827' }}>{auction.bathrooms}</strong>&nbsp;baths
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                      <Square style={{ height: '1.25rem', width: '1.25rem', marginRight: '0.5rem', color: '#667eea' }} />
                      <strong style={{ color: '#111827' }}>{auction.squareFeet.toLocaleString()}</strong>&nbsp;sq ft
                    </div>
                  </div>
                  
                  {/* Bidding Info */}
                  <div style={{
                    display: 'grid',
                    gridTemplateColumns: '1fr 1fr',
                    gap: '1rem',
                    padding: '1rem',
                    backgroundColor: '#eff6ff',
                    borderRadius: '0.75rem',
                    marginBottom: '1rem'
                  }}>
                    <div>
                      <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Current Bid</div>
                      <div style={{ fontSize: '1.5rem', fontWeight: '700', color: '#3b82f6' }}>
                        ${auction.currentBid.toLocaleString()}
                      </div>
                    </div>
                    <div>
                      <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Starting Price</div>
                      <div style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827' }}>
                        ${auction.startingPrice.toLocaleString()}
                      </div>
                    </div>
                    <div>
                      <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Total Bids</div>
                      <div style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <Users style={{ height: '1rem', width: '1rem', color: '#667eea' }} />
                        {auction.bidCount} bids
                      </div>
                    </div>
                    <div>
                      <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Duration</div>
                      <div style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827' }}>
                        {auction.duration || 0} hours
                      </div>
                    </div>
                  </div>
                  
                  {/* Winner Info for Ended Auctions */}
                  {auction.status === 'ended' && auction.highestBidder && (
                    <div style={{
                      padding: '0.75rem',
                      backgroundColor: '#dcfce7',
                      borderRadius: '0.5rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                      marginBottom: '1rem'
                    }}>
                      <Award style={{ height: '1.25rem', width: '1.25rem', color: '#059669' }} />
                      <div>
                        <div style={{ fontSize: '0.75rem', color: '#059669', fontWeight: '600', textTransform: 'uppercase' }}>
                          Winner
                        </div>
                        <div style={{ fontSize: '0.875rem', fontWeight: '700', color: '#059669' }}>
                          {auction.highestBidder}
                        </div>
                      </div>
                    </div>
                  )}
                </div>

                {/* Action Buttons */}
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: '0.5rem',
                  flexWrap: 'wrap',
                  paddingTop: '1rem',
                  borderTop: '1px solid #e5e7eb'
                }}>
                  <div style={{ display: 'flex', gap: '0.5rem', flexWrap: 'wrap' }}>
                    {auction.status === 'requested' && (
                      <>
                        <button
                          onClick={() => handleApproveAuction(auction.auctionId)}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            padding: '0.5rem 1rem',
                            backgroundColor: '#10b981',
                            color: 'white',
                            border: 'none',
                            borderRadius: '0.5rem',
                            cursor: 'pointer',
                            fontSize: '0.875rem',
                            fontWeight: '500'
                          }}
                        >
                          <CheckCircle style={{ height: '1rem', width: '1rem' }} />
                          Approve
                        </button>
                        <button
                          onClick={() => handleRejectAuction(auction.auctionId)}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            padding: '0.5rem 1rem',
                            backgroundColor: '#ef4444',
                            color: 'white',
                            border: 'none',
                            borderRadius: '0.5rem',
                            cursor: 'pointer',
                            fontSize: '0.875rem',
                            fontWeight: '500'
                          }}
                        >
                          <XCircle style={{ height: '1rem', width: '1rem' }} />
                          Reject
                        </button>
                      </>
                    )}
                    {auction.status === 'active' && (
                      <button
                        onClick={() => handleEndAuction(auction.auctionId)}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem',
                          padding: '0.5rem 1rem',
                          backgroundColor: '#ef4444',
                          color: 'white',
                          border: 'none',
                          borderRadius: '0.5rem',
                          cursor: 'pointer',
                          fontSize: '0.875rem',
                          fontWeight: '500'
                        }}
                      >
                        <StopCircle style={{ height: '1rem', width: '1rem' }} />
                        End
                      </button>
                    )}
                    {auction.status === 'ended' && (
                      <button
                        onClick={() => openRelistModal(auction)}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem',
                          padding: '0.5rem 1rem',
                          background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                          color: 'white',
                          border: 'none',
                          borderRadius: '0.5rem',
                          cursor: 'pointer',
                          fontSize: '0.875rem',
                          fontWeight: '500'
                        }}
                      >
                        <RefreshCw style={{ height: '1rem', width: '1rem' }} />
                        Relist
                      </button>
                    )}
                  </div>
                  <button 
                    onClick={() => handleViewDetails(auction)}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem',
                      padding: '0.5rem 1.5rem',
                      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                      color: 'white',
                      border: 'none',
                      borderRadius: '0.5rem',
                      cursor: 'pointer',
                      fontSize: '0.875rem',
                      fontWeight: '500',
                      transition: 'all 0.2s'
                    }}>
                    <Eye style={{ height: '1rem', width: '1rem' }} />
                    View Details
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Pagination */}
      {filteredAuctions.length > 0 && (
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
              Auctions per page:
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
                    setCurrentPage(1);
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
            totalItems={filteredAuctions.length}
          />
        </div>
      )}

      {/* Auction Details Modal */}
      {showDetailsModal && selectedAuction && (
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
              <div style={{ padding: '2rem' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '1.5rem' }}>
                  <h3 style={{
                    fontSize: '1.5rem',
                    fontWeight: '600',
                    color: '#111827',
                    margin: 0
                  }}>Auction Details</h3>
                  <button
                    onClick={() => setShowDetailsModal(false)}
                    style={{
                      padding: '0.5rem',
                      backgroundColor: '#f3f4f6',
                      border: 'none',
                      borderRadius: '0.5rem',
                      cursor: 'pointer'
                    }}
                  >
                    <XCircle style={{ height: '1.5rem', width: '1.5rem' }} />
                  </button>
                </div>
                
                {/* Property & Auction Info */}
                <div style={{
                  display: 'grid',
                  gridTemplateColumns: '1fr 1fr',
                  gap: '1.5rem',
                  marginBottom: '2rem'
                }}>
                  <div style={{
                    padding: '1rem',
                    backgroundColor: '#f8fafc',
                    borderRadius: '0.75rem'
                  }}>
                    <h4 style={{ fontSize: '1rem', fontWeight: '600', color: '#111827', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <MapPin style={{ height: '1rem', width: '1rem', color: '#667eea' }} />
                      Property Information
                    </h4>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: '#111827', fontWeight: '600' }}>
                        {selectedAuction.propertyName}
                      </p>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <MapPin style={{ height: '0.875rem', width: '0.875rem' }} />
                        {selectedAuction.location}
                      </p>
                      <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
                        <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                          <Bed style={{ height: '0.875rem', width: '0.875rem' }} />
                          <strong>{selectedAuction.bedrooms}</strong> beds
                        </p>
                        <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                          <Bath style={{ height: '0.875rem', width: '0.875rem' }} />
                          <strong>{selectedAuction.bathrooms}</strong> baths
                        </p>
                        <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280', display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                          <Square style={{ height: '0.875rem', width: '0.875rem' }} />
                          <strong>{selectedAuction.squareFeet.toLocaleString()}</strong> sq ft
                        </p>
                      </div>
                      {selectedAuction.description && (
                        <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280', paddingTop: '0.5rem', borderTop: '1px solid #e5e7eb' }}>
                          {selectedAuction.description}
                        </p>
                      )}
                      {selectedAuction.ownerName && (
                        <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280', paddingTop: '0.5rem', borderTop: '1px solid #e5e7eb' }}>
                          <strong>Owner:</strong> {selectedAuction.ownerName}
                        </p>
                      )}
                    </div>
                  </div>
                  
                  <div style={{
                    padding: '1rem',
                    backgroundColor: selectedAuction.status === 'ended' && selectedAuction.highestBidder ? '#f0fdf4' : '#f8fafc',
                    borderRadius: '0.75rem',
                    border: selectedAuction.status === 'ended' && selectedAuction.highestBidder ? '2px solid #10b981' : 'none'
                  }}>
                    <h4 style={{ fontSize: '1rem', fontWeight: '600', color: '#111827', marginBottom: '1rem' }}>
                      Auction Information
                    </h4>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280' }}>
                        <strong>Status:</strong> <span style={{ 
                          padding: '0.25rem 0.5rem',
                          borderRadius: '0.25rem',
                          backgroundColor: getStatusBg(selectedAuction.status),
                          color: getStatusColor(selectedAuction.status),
                          fontWeight: '600'
                        }}>{getStatusLabel(selectedAuction.status)}</span>
                      </p>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280' }}>
                        <strong>Starting Price:</strong> ${selectedAuction.startingPrice.toLocaleString()}
                      </p>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280' }}>
                        <strong>Current Bid:</strong> ${selectedAuction.currentBid.toLocaleString()}
                      </p>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280' }}>
                        <strong>Total Bids:</strong> {selectedAuction.bidCount}
                      </p>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280' }}>
                        <strong>Duration:</strong> {selectedAuction.duration} hours
                      </p>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280' }}>
                        <strong>Start:</strong> {new Date(selectedAuction.startTime).toLocaleString()}
                      </p>
                      <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280' }}>
                        <strong>End:</strong> {new Date(selectedAuction.endTime).toLocaleString()}
                      </p>
                      {/* Winner Info */}
                      {selectedAuction.status === 'ended' && selectedAuction.highestBidder && (
                        <div style={{
                          marginTop: '0.5rem',
                          padding: '0.75rem',
                          backgroundColor: '#dcfce7',
                          borderRadius: '0.5rem',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem'
                        }}>
                          <Award style={{ height: '1.25rem', width: '1.25rem', color: '#059669' }} />
                          <div>
                            <div style={{ fontSize: '0.75rem', color: '#059669', fontWeight: '600', textTransform: 'uppercase' }}>
                              Winner
                            </div>
                            <div style={{ fontSize: '0.875rem', fontWeight: '700', color: '#059669' }}>
                              {selectedAuction.highestBidder}
                            </div>
                            <div style={{ fontSize: '0.75rem', color: '#059669' }}>
                              ${selectedAuction.currentBid.toLocaleString()}
                            </div>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Price Progress Chart */}
                <div style={{
                  padding: '1rem',
                  backgroundColor: '#f8fafc',
                  borderRadius: '0.75rem',
                  marginBottom: '1.5rem'
                }}>
                  <h4 style={{ fontSize: '1rem', fontWeight: '600', color: '#111827', marginBottom: '1rem' }}>
                    Price Progress
                  </h4>
                  <div style={{ position: 'relative', height: '2rem', backgroundColor: '#e5e7eb', borderRadius: '0.5rem', overflow: 'hidden' }}>
                    <div style={{
                      position: 'absolute',
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: `${selectedAuction.startingPrice > 0 ? Math.min((selectedAuction.currentBid / (selectedAuction.startingPrice * 1.5)) * 100, 100) : 0}%`,
                      background: 'linear-gradient(90deg, #10b981 0%, #059669 100%)',
                      transition: 'width 0.3s ease'
                    }} />
                    <div style={{
                      position: 'absolute',
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      color: 'white',
                      fontWeight: '600',
                      fontSize: '0.875rem',
                      textShadow: '0 1px 2px rgba(0,0,0,0.3)'
                    }}>
                      {selectedAuction.startingPrice > 0 
                        ? `+${Math.round(((selectedAuction.currentBid - selectedAuction.startingPrice) / selectedAuction.startingPrice) * 100)}%`
                        : '0%'
                      }
                    </div>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '0.5rem' }}>
                    <span style={{ fontSize: '0.75rem', color: '#6b7280' }}>
                      Start: ${selectedAuction.startingPrice.toLocaleString()}
                    </span>
                    <span style={{ fontSize: '0.75rem', color: '#6b7280' }}>
                      Current: ${selectedAuction.currentBid.toLocaleString()}
                    </span>
                  </div>
                </div>

                {/* Bidding Statistics */}
                {auctionBids.length > 0 && (
                  <div style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(4, 1fr)',
                    gap: '1rem',
                    marginBottom: '1.5rem'
                  }}>
                    <div style={{
                      padding: '1rem',
                      backgroundColor: '#eff6ff',
                      borderRadius: '0.5rem',
                      textAlign: 'center'
                    }}>
                      <div style={{ fontSize: '0.75rem', color: '#3b82f6', fontWeight: '600', marginBottom: '0.25rem' }}>
                        TOTAL BIDS
                      </div>
                      <div style={{ fontSize: '1.5rem', fontWeight: '700', color: '#1e40af' }}>
                        {auctionBids.length}
                      </div>
                    </div>
                    <div style={{
                      padding: '1rem',
                      backgroundColor: '#f0fdf4',
                      borderRadius: '0.5rem',
                      textAlign: 'center'
                    }}>
                      <div style={{ fontSize: '0.75rem', color: '#10b981', fontWeight: '600', marginBottom: '0.25rem' }}>
                        HIGHEST BID
                      </div>
                      <div style={{ fontSize: '1.5rem', fontWeight: '700', color: '#059669' }}>
                        ${Math.max(...auctionBids.map((b: any) => b.bidAmount || b.BidAmount || 0)).toLocaleString()}
                      </div>
                    </div>
                    <div style={{
                      padding: '1rem',
                      backgroundColor: '#fef3c7',
                      borderRadius: '0.5rem',
                      textAlign: 'center'
                    }}>
                      <div style={{ fontSize: '0.75rem', color: '#f59e0b', fontWeight: '600', marginBottom: '0.25rem' }}>
                        AVG BID
                      </div>
                      <div style={{ fontSize: '1.5rem', fontWeight: '700', color: '#d97706' }}>
                        ${Math.round(auctionBids.reduce((sum: number, b: any) => sum + (b.bidAmount || b.BidAmount || 0), 0) / auctionBids.length).toLocaleString()}
                      </div>
                    </div>
                    <div style={{
                      padding: '1rem',
                      backgroundColor: '#fae8ff',
                      borderRadius: '0.5rem',
                      textAlign: 'center'
                    }}>
                      <div style={{ fontSize: '0.75rem', color: '#a855f7', fontWeight: '600', marginBottom: '0.25rem' }}>
                        UNIQUE BIDDERS
                      </div>
                      <div style={{ fontSize: '1.5rem', fontWeight: '700', color: '#7e22ce' }}>
                        {new Set(auctionBids.map((b: any) => b.bidderId || b.BidderId)).size}
                      </div>
                    </div>
                  </div>
                )}

                {/* Bidders List */}
                <div>
                  <h4 style={{ fontSize: '1rem', fontWeight: '600', color: '#111827', marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <Users style={{ height: '1rem', width: '1rem', color: '#667eea' }} />
                    Bidding History ({auctionBids.length} bids)
                  </h4>
                  {auctionBids.length > 0 ? (
                    <div style={{
                      maxHeight: '400px',
                      overflowY: 'auto',
                      border: '1px solid #e5e7eb',
                      borderRadius: '0.5rem'
                    }}>
                      <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                        <thead style={{ backgroundColor: '#f9fafb', position: 'sticky', top: 0, zIndex: 1 }}>
                          <tr>
                            <th style={{ padding: '0.75rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '600', color: '#6b7280', borderBottom: '1px solid #e5e7eb', textTransform: 'uppercase' }}>Rank</th>
                            <th style={{ padding: '0.75rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '600', color: '#6b7280', borderBottom: '1px solid #e5e7eb', textTransform: 'uppercase' }}>Bidder</th>
                            <th style={{ padding: '0.75rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '600', color: '#6b7280', borderBottom: '1px solid #e5e7eb', textTransform: 'uppercase' }}>Email</th>
                            <th style={{ padding: '0.75rem', textAlign: 'right', fontSize: '0.75rem', fontWeight: '600', color: '#6b7280', borderBottom: '1px solid #e5e7eb', textTransform: 'uppercase' }}>Amount</th>
                            <th style={{ padding: '0.75rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '600', color: '#6b7280', borderBottom: '1px solid #e5e7eb', textTransform: 'uppercase' }}>Time</th>
                          </tr>
                        </thead>
                        <tbody>
                          {auctionBids.map((bid: any, index: number) => (
                            <tr key={bid.bidId || bid.BidId || index} style={{ 
                              backgroundColor: index === 0 ? '#f0fdf4' : (index % 2 === 0 ? '#f9fafb' : 'white'),
                              borderBottom: '1px solid #e5e7eb'
                            }}>
                              <td style={{ padding: '0.75rem', fontSize: '0.875rem', color: '#6b7280' }}>
                                {index === 0 ? (
                                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem' }}>
                                    <Award style={{ height: '1rem', width: '1rem', color: '#10b981' }} />
                                    <span style={{ fontWeight: '700', color: '#10b981' }}>1st</span>
                                  </div>
                                ) : (
                                  <span>{index + 1}</span>
                                )}
                              </td>
                              <td style={{ padding: '0.75rem', fontSize: '0.875rem', color: '#111827' }}>
                                <div style={{ fontWeight: index === 0 ? '600' : '400' }}>
                                  {bid.bidderName || (bid.bidder ? `${bid.bidder.firstName || bid.bidder.FirstName} ${bid.bidder.lastName || bid.bidder.LastName}` : 'Unknown')}
                                </div>
                              </td>
                              <td style={{ padding: '0.75rem', fontSize: '0.75rem', color: '#6b7280' }}>
                                {bid.bidder?.email || bid.bidder?.Email || bid.bidderEmail || '-'}
                              </td>
                              <td style={{ padding: '0.75rem', fontSize: '0.875rem', fontWeight: index === 0 ? '700' : '600', color: index === 0 ? '#10b981' : '#111827', textAlign: 'right' }}>
                                ${(bid.bidAmount || bid.BidAmount || 0).toLocaleString()}
                              </td>
                              <td style={{ padding: '0.75rem', fontSize: '0.875rem', color: '#6b7280' }}>
                                {new Date(bid.createdAt || bid.CreatedAt || bid.timestamp).toLocaleString()}
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
                      borderRadius: '0.5rem',
                      border: '2px dashed #e5e7eb'
                    }}>
                      <Users style={{ height: '3rem', width: '3rem', color: '#d1d5db', margin: '0 auto 1rem' }} />
                      <p style={{ margin: 0, color: '#6b7280', fontWeight: '500' }}>No bids placed yet</p>
                      <p style={{ margin: '0.5rem 0 0 0', color: '#9ca3af', fontSize: '0.875rem' }}>Be the first to place a bid on this property!</p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Bid Modal */}
      {showBidModal && selectedAuction && (
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
              <form onSubmit={handlePlaceBid}>
                <div style={{ padding: '2rem' }}>
                  <h3 style={{
                    fontSize: '1.5rem',
                    fontWeight: '600',
                    color: '#111827',
                    marginBottom: '1rem'
                  }}>Place a Bid</h3>
                  
                  <div style={{ marginBottom: '1.5rem' }}>
                    <h4 style={{ fontSize: '1.125rem', fontWeight: '500', color: '#111827', marginBottom: '0.5rem' }}>
                      {selectedAuction.propertyName}
                    </h4>
                    <p style={{ fontSize: '0.875rem', color: '#6b7280', marginBottom: '1rem' }}>
                      Current bid: ${selectedAuction.currentBid.toLocaleString()}
                    </p>
                  </div>
                  
                  <div>
                    <label style={{
                      display: 'block',
                      fontSize: '0.875rem',
                      fontWeight: '500',
                      color: '#374151',
                      marginBottom: '0.5rem'
                    }}>Your Bid Amount *</label>
                    <input
                      type="number"
                      required
                      min={selectedAuction.currentBid + 1}
                      style={{
                        width: '100%',
                        padding: '0.75rem',
                        border: '1px solid #d1d5db',
                        borderRadius: '0.5rem',
                        fontSize: '1.125rem',
                        fontWeight: '600',
                        outline: 'none',
                        transition: 'all 0.2s'
                      }}
                      value={newBidAmount}
                      onChange={(e) => setNewBidAmount(Number(e.target.value))}
                      placeholder="Enter bid amount"
                    />
                    <p style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '0.25rem' }}>
                      Minimum bid: ${(selectedAuction.currentBid + 1).toLocaleString()}
                    </p>
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
                    onClick={() => setShowBidModal(false)}
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
                    Place Bid
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Relist Auction Modal */}
      {showRelistModal && selectedAuction && (
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
              width: '100%',
              overflow: 'hidden'
            }}>
              <form onSubmit={handleRelistAuction}>
                {/* Modal Header */}
                <div style={{
                  background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                  padding: '1.5rem',
                  color: 'white'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem' }}>
                    <RefreshCw style={{ height: '1.5rem', width: '1.5rem' }} />
                    <h3 style={{ fontSize: '1.25rem', fontWeight: '600', margin: 0 }}>
                      Relist Auction
                    </h3>
                  </div>
                  <p style={{ fontSize: '0.875rem', margin: 0, opacity: 0.9 }}>
                    Relist "{selectedAuction.propertyName}" auction with new settings
                  </p>
                </div>

                {/* Modal Body */}
                <div style={{ padding: '1.5rem' }}>
                  <div style={{
                    padding: '1rem',
                    backgroundColor: '#fef3c7',
                    border: '1px solid #fde68a',
                    borderRadius: '0.75rem',
                    marginBottom: '1.5rem'
                  }}>
                    <div style={{ display: 'flex', alignItems: 'flex-start', gap: '0.5rem' }}>
                      <AlertCircle style={{ height: '1.25rem', width: '1.25rem', color: '#d97706', flexShrink: 0, marginTop: '0.125rem' }} />
                      <div>
                        <p style={{ fontSize: '0.875rem', color: '#92400e', fontWeight: '600', margin: '0 0 0.25rem 0' }}>
                          Warning
                        </p>
                        <p style={{ fontSize: '0.8125rem', color: '#92400e', margin: 0, lineHeight: '1.4' }}>
                          Relisting an auction will make it active again. Choose whether to reset the current price and existing bids.
                        </p>
                      </div>
                    </div>
                  </div>

                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                    {/* Duration */}
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>
                        Duration (hours) <span style={{ color: '#ef4444' }}>*</span>
                      </label>
                      <input
                        type="number"
                        required
                        min={1}
                        max={720}
                        style={{
                          width: '100%',
                          padding: '0.75rem 1rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.75rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={relistForm.duration}
                        onChange={(e) => setRelistForm({ ...relistForm, duration: Number(e.target.value) })}
                        onFocus={(e) => e.currentTarget.style.borderColor = '#10b981'}
                        onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
                      />
                      <p style={{ fontSize: '0.75rem', color: '#6b7280', margin: '0.25rem 0 0 0' }}>
                        The auction will run for this many hours
                      </p>
                    </div>

                    {/* Reset Options */}
                    <div style={{
                      padding: '1rem',
                      backgroundColor: '#f9fafb',
                      borderRadius: '0.75rem',
                      border: '1px solid #e5e7eb'
                    }}>
                      <div style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827', marginBottom: '0.75rem' }}>
                        Reset Options
                      </div>
                      
                      {/* Reset Price */}
                      <label style={{
                        display: 'flex',
                        alignItems: 'flex-start',
                        gap: '0.75rem',
                        marginBottom: '0.75rem',
                        cursor: 'pointer'
                      }}>
                        <input
                          type="checkbox"
                          checked={relistForm.resetPrice}
                          onChange={(e) => setRelistForm({ ...relistForm, resetPrice: e.target.checked })}
                          style={{
                            marginTop: '0.125rem',
                            width: '1rem',
                            height: '1rem',
                            cursor: 'pointer'
                          }}
                        />
                        <div>
                          <div style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>
                            Reset Current Price
                          </div>
                          <div style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '0.125rem' }}>
                            Reset current price back to starting price (${selectedAuction.startingPrice.toLocaleString()})
                          </div>
                        </div>
                      </label>

                      {/* Reset Bids */}
                      <label style={{
                        display: 'flex',
                        alignItems: 'flex-start',
                        gap: '0.75rem',
                        cursor: 'pointer'
                      }}>
                        <input
                          type="checkbox"
                          checked={relistForm.resetBids}
                          onChange={(e) => setRelistForm({ ...relistForm, resetBids: e.target.checked })}
                          style={{
                            marginTop: '0.125rem',
                            width: '1rem',
                            height: '1rem',
                            cursor: 'pointer'
                          }}
                        />
                        <div>
                          <div style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>
                            Reset All Bids
                          </div>
                          <div style={{ fontSize: '0.75rem', color: '#6b7280', marginTop: '0.125rem' }}>
                            Remove all existing bids ({selectedAuction.bidCount} bids) and start fresh
                          </div>
                        </div>
                      </label>
                    </div>

                    {/* Current Auction Info */}
                    <div style={{
                      padding: '1rem',
                      backgroundColor: '#f0fdf4',
                      border: '1px solid #dcfce7',
                      borderRadius: '0.75rem'
                    }}>
                      <div style={{ fontSize: '0.75rem', color: '#065f46', fontWeight: '600', textTransform: 'uppercase', marginBottom: '0.5rem' }}>
                        Current Auction Info
                      </div>
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.375rem', fontSize: '0.8125rem', color: '#065f46' }}>
                        <div>Starting Price: <strong>${selectedAuction.startingPrice.toLocaleString()}</strong></div>
                        <div>Current Bid: <strong>${selectedAuction.currentBid.toLocaleString()}</strong></div>
                        <div>Total Bids: <strong>{selectedAuction.bidCount}</strong></div>
                        {selectedAuction.highestBidder && (
                          <div>Winner: <strong>{selectedAuction.highestBidder}</strong></div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                {/* Modal Footer */}
                <div style={{
                  backgroundColor: '#f9fafb',
                  padding: '1rem 1.5rem',
                  display: 'flex',
                  gap: '0.75rem',
                  justifyContent: 'flex-end',
                  borderTop: '1px solid #e5e7eb'
                }}>
                  <button
                    type="button"
                    onClick={() => {
                      setShowRelistModal(false);
                      setRelistForm({ duration: 24, resetPrice: false, resetBids: false });
                    }}
                    style={{
                      padding: '0.75rem 1.5rem',
                      backgroundColor: '#f3f4f6',
                      color: '#374151',
                      fontWeight: '500',
                      fontSize: '0.875rem',
                      borderRadius: '0.75rem',
                      border: '1px solid #d1d5db',
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
                      background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                      color: 'white',
                      fontWeight: '500',
                      fontSize: '0.875rem',
                      borderRadius: '0.75rem',
                      border: 'none',
                      cursor: 'pointer',
                      transition: 'all 0.2s',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem'
                    }}
                  >
                    <RefreshCw style={{ height: '1rem', width: '1rem' }} />
                    Relist Auction
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

export default AuctionsPage;

