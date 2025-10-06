import React, { useState, useEffect } from 'react';
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
  Zap
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
  status: 'upcoming' | 'active' | 'ended' | 'cancelled';
  startTime: string;
  endTime: string;
  highestBidder?: string;
  description: string;
  bedrooms: number;
  bathrooms: number;
  squareFeet: number;
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
  const [auctions, setAuctions] = useState<Auction[]>([]);
  const [bids, setBids] = useState<Bid[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedAuction, setSelectedAuction] = useState<Auction | null>(null);
  const [showBidModal, setShowBidModal] = useState(false);
  const [newBidAmount, setNewBidAmount] = useState(0);
  const [filterStatus, setFilterStatus] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    // Simulate API calls
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
  }, []);

  const handleStartAuction = (auctionId: number) => {
    setAuctions(auctions.map(auction => 
      auction.auctionId === auctionId 
        ? { ...auction, status: 'active' as const }
        : auction
    ));
  };

  const handleEndAuction = (auctionId: number) => {
    setAuctions(auctions.map(auction => 
      auction.auctionId === auctionId 
        ? { ...auction, status: 'ended' as const }
        : auction
    ));
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
      case 'active': return '#10b981';
      case 'upcoming': return '#3b82f6';
      case 'ended': return '#6b7280';
      case 'cancelled': return '#ef4444';
      default: return '#6b7280';
    }
  };

  const getStatusBg = (status: string) => {
    switch (status) {
      case 'active': return '#dcfce7';
      case 'upcoming': return '#dbeafe';
      case 'ended': return '#f3f4f6';
      case 'cancelled': return '#fef2f2';
      default: return '#f3f4f6';
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
          }}>Auctions</h1>
          <p style={{
            fontSize: '1.125rem',
            color: '#6b7280',
            margin: 0
          }}>
            Manage live auctions and track bidding activity
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
              <option value="active">Active</option>
              <option value="upcoming">Upcoming</option>
              <option value="ended">Ended</option>
            </select>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
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
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
        gap: '1.5rem',
        marginBottom: '2rem'
      }}>
        {[
          {
            title: 'Active Auctions',
            value: auctions.filter(a => a.status === 'active').length,
            icon: Hammer,
            color: '#10b981',
            bgColor: '#dcfce7'
          },
          {
            title: 'Total Bids',
            value: bids.length,
            icon: Target,
            color: '#3b82f6',
            bgColor: '#dbeafe'
          },
          {
            title: 'Total Revenue',
            value: `$${auctions.reduce((sum, a) => sum + a.currentBid, 0).toLocaleString()}`,
            icon: DollarSign,
            color: '#f59e0b',
            bgColor: '#fef3c7'
          },
          {
            title: 'Avg Bid Amount',
            value: `$${Math.round(auctions.reduce((sum, a) => sum + a.currentBid, 0) / Math.max(auctions.length, 1)).toLocaleString()}`,
            icon: TrendingUp,
            color: '#8b5cf6',
            bgColor: '#ede9fe'
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

      {/* Auctions Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))',
        gap: '1.5rem'
      }}>
        {filteredAuctions.map((auction) => (
          <div key={auction.auctionId} style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            overflow: 'hidden',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
            border: '1px solid #e5e7eb',
            transition: 'all 0.3s ease',
            position: 'relative'
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
                  {auction.status.toUpperCase()}
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
            <div style={{ padding: '1.5rem' }}>
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
              </div>

              {/* Action Buttons */}
              <div style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between'
              }}>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  {auction.status === 'upcoming' && (
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
                    <>
                      <button
                        onClick={() => {
                          setSelectedAuction(auction);
                          setNewBidAmount(auction.currentBid + 1000);
                          setShowBidModal(true);
                        }}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem',
                          padding: '0.5rem 1rem',
                          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                          color: 'white',
                          border: 'none',
                          borderRadius: '0.5rem',
                          cursor: 'pointer',
                          fontSize: '0.875rem',
                          fontWeight: '500'
                        }}
                      >
                        <DollarSign style={{ height: '1rem', width: '1rem' }} />
                        Bid
                      </button>
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
                    </>
                  )}
                </div>
                <button style={{
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
                  View
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

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
    </div>
  );
};

export default AuctionsPage;

