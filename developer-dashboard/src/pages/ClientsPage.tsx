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
  AlertCircle, 
  MoreVertical,
  UserPlus,
  Building,
  Home,
  Hammer,
  BarChart3,
  Download,
  Upload,
  Send,
  MessageCircle
} from 'lucide-react';

interface Client {
  clientId: number;
  firstName: string;
  lastName: string;
  email: string;
  phone: string;
  company?: string;
  location: string;
  joinDate: string;
  status: 'active' | 'inactive' | 'premium';
  totalBids: number;
  totalSpent: number;
  averageBid: number;
  lastActivity: string;
  propertiesWon: number;
  propertiesInterested: number;
  rating: number;
  notes?: string;
  avatar?: string;
}

interface ClientActivity {
  id: number;
  clientId: number;
  type: 'bid' | 'win' | 'interest' | 'contact';
  description: string;
  timestamp: string;
  amount?: number;
}

const ClientsPage: React.FC = () => {
  const [clients, setClients] = useState<Client[]>([]);
  const [activities, setActivities] = useState<ClientActivity[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [sortBy, setSortBy] = useState('name');
  const [selectedClient, setSelectedClient] = useState<Client | null>(null);

  const [newClient, setNewClient] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    company: '',
    location: '',
    notes: ''
  });

  useEffect(() => {
    // Simulate API calls
    setTimeout(() => {
      setClients([
        {
          clientId: 1,
          firstName: 'John',
          lastName: 'Smith',
          email: 'john.smith@email.com',
          phone: '+1 (555) 123-4567',
          company: 'Smith Investments LLC',
          location: 'New York, NY',
          joinDate: '2024-01-15',
          status: 'premium',
          totalBids: 25,
          totalSpent: 1250000,
          averageBid: 50000,
          lastActivity: '2024-01-20',
          propertiesWon: 3,
          propertiesInterested: 8,
          rating: 4.8,
          notes: 'High-value client, prefers luxury properties',
          avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop&crop=face'
        },
        {
          clientId: 2,
          firstName: 'Sarah',
          lastName: 'Johnson',
          email: 'sarah.johnson@email.com',
          phone: '+1 (555) 234-5678',
          location: 'Los Angeles, CA',
          joinDate: '2024-01-10',
          status: 'active',
          totalBids: 15,
          totalSpent: 750000,
          averageBid: 50000,
          lastActivity: '2024-01-19',
          propertiesWon: 2,
          propertiesInterested: 5,
          rating: 4.5,
          notes: 'First-time investor, very responsive'
        },
        {
          clientId: 3,
          firstName: 'Mike',
          lastName: 'Wilson',
          email: 'mike.wilson@email.com',
          phone: '+1 (555) 345-6789',
          company: 'Wilson Real Estate',
          location: 'Chicago, IL',
          joinDate: '2024-01-05',
          status: 'active',
          totalBids: 8,
          totalSpent: 400000,
          averageBid: 50000,
          lastActivity: '2024-01-18',
          propertiesWon: 1,
          propertiesInterested: 3,
          rating: 4.2,
          notes: 'Commercial property specialist'
        }
      ]);

      setActivities([
        {
          id: 1,
          clientId: 1,
          type: 'bid',
          description: 'Placed bid on Modern Downtown Loft',
          timestamp: '2024-01-20T10:30:00Z',
          amount: 520000
        },
        {
          id: 2,
          clientId: 1,
          type: 'win',
          description: 'Won auction for Luxury Beach House',
          timestamp: '2024-01-19T15:45:00Z',
          amount: 1350000
        },
        {
          id: 3,
          clientId: 2,
          type: 'interest',
          description: 'Viewed Commercial Office Space',
          timestamp: '2024-01-19T09:15:00Z'
        },
        {
          id: 4,
          clientId: 3,
          type: 'contact',
          description: 'Called about upcoming auctions',
          timestamp: '2024-01-18T14:20:00Z'
        }
      ]);

      setLoading(false);
    }, 1000);
  }, []);

  const handleCreateClient = (e: React.FormEvent) => {
    e.preventDefault();
    const client: Client = {
      clientId: clients.length + 1,
      ...newClient,
      joinDate: new Date().toISOString().split('T')[0],
      status: 'active',
      totalBids: 0,
      totalSpent: 0,
      averageBid: 0,
      lastActivity: new Date().toISOString().split('T')[0],
      propertiesWon: 0,
      propertiesInterested: 0,
      rating: 0
    };
    setClients([...clients, client]);
    setShowCreateModal(false);
    setNewClient({
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      company: '',
      location: '',
      notes: ''
    });
  };

  const handleDeleteClient = (clientId: number) => {
    setClients(clients.filter(c => c.clientId !== clientId));
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'premium': return '#8b5cf6';
      case 'active': return '#10b981';
      case 'inactive': return '#6b7280';
      default: return '#6b7280';
    }
  };

  const getStatusBg = (status: string) => {
    switch (status) {
      case 'premium': return '#ede9fe';
      case 'active': return '#dcfce7';
      case 'inactive': return '#f3f4f6';
      default: return '#f3f4f6';
    }
  };

  const filteredClients = clients.filter(client => {
    const matchesSearch = 
      client.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      client.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      client.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      client.location.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || client.status === filterStatus;
    
    return matchesSearch && matchesStatus;
  });

  const sortedClients = [...filteredClients].sort((a, b) => {
    switch (sortBy) {
      case 'name':
        return `${a.firstName} ${a.lastName}`.localeCompare(`${b.firstName} ${b.lastName}`);
      case 'joinDate':
        return new Date(b.joinDate).getTime() - new Date(a.joinDate).getTime();
      case 'totalSpent':
        return b.totalSpent - a.totalSpent;
      case 'rating':
        return b.rating - a.rating;
      default:
        return 0;
    }
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
          }}>Clients</h1>
          <p style={{
            fontSize: '1.125rem',
            color: '#6b7280',
            margin: 0
          }}>
            Manage your client relationships and track their activity
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
                placeholder="Search clients..."
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

            {/* Filters */}
            <button
              onClick={() => setShowFilters(!showFilters)}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                padding: '0.75rem 1rem',
                backgroundColor: showFilters ? '#667eea' : '#f3f4f6',
                color: showFilters ? 'white' : '#6b7280',
                border: 'none',
                borderRadius: '0.75rem',
                cursor: 'pointer',
                transition: 'all 0.2s'
              }}
            >
              <Filter style={{ height: '1rem', width: '1rem' }} />
              Filters
            </button>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
            {/* Sort */}
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
              <option value="name">Name A-Z</option>
              <option value="joinDate">Join Date</option>
              <option value="totalSpent">Total Spent</option>
              <option value="rating">Rating</option>
            </select>

            {/* New Client Button */}
            <button
              onClick={() => setShowCreateModal(true)}
              style={{
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
                transition: 'all 0.2s',
                boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
              }}
            >
              <Plus style={{ height: '1.25rem', width: '1.25rem' }} />
              New Client
            </button>
          </div>
        </div>

        {/* Filters Panel */}
        {showFilters && (
          <div style={{
            width: '100%',
            backgroundColor: 'white',
            borderRadius: '1rem',
            padding: '1.5rem',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
            border: '1px solid #e5e7eb',
            display: 'flex',
            gap: '2rem',
            flexWrap: 'wrap'
          }}>
            <div>
              <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '500', color: '#374151', marginBottom: '0.5rem' }}>
                Status
              </label>
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                style={{
                  padding: '0.5rem 0.75rem',
                  border: '1px solid #d1d5db',
                  borderRadius: '0.5rem',
                  fontSize: '0.875rem',
                  outline: 'none',
                  backgroundColor: 'white'
                }}
              >
                <option value="all">All Clients</option>
                <option value="premium">Premium</option>
                <option value="active">Active</option>
                <option value="inactive">Inactive</option>
              </select>
            </div>
          </div>
        )}
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
            title: 'Total Clients',
            value: clients.length,
            icon: Users,
            color: '#3b82f6',
            bgColor: '#dbeafe'
          },
          {
            title: 'Premium Clients',
            value: clients.filter(c => c.status === 'premium').length,
            icon: Star,
            color: '#8b5cf6',
            bgColor: '#ede9fe'
          },
          {
            title: 'Total Revenue',
            value: `$${clients.reduce((sum, c) => sum + c.totalSpent, 0).toLocaleString()}`,
            icon: DollarSign,
            color: '#10b981',
            bgColor: '#dcfce7'
          },
          {
            title: 'Avg Rating',
            value: (clients.reduce((sum, c) => sum + c.rating, 0) / Math.max(clients.length, 1)).toFixed(1),
            icon: Award,
            color: '#f59e0b',
            bgColor: '#fef3c7'
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

      {/* Clients Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(400px, 1fr))',
        gap: '1.5rem'
      }}>
        {sortedClients.map((client) => (
          <div key={client.clientId} style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            padding: '1.5rem',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
            border: '1px solid #e5e7eb',
            transition: 'all 0.3s ease',
            position: 'relative'
          }}>
            {/* Client Header */}
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '1rem'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div style={{
                  width: '3rem',
                  height: '3rem',
                  borderRadius: '50%',
                  background: client.avatar 
                    ? `url(${client.avatar})` 
                    : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  backgroundSize: 'cover',
                  backgroundPosition: 'center',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: 'white',
                  fontWeight: '600',
                  fontSize: '1.125rem'
                }}>
                  {!client.avatar && `${client.firstName[0]}${client.lastName[0]}`}
                </div>
                <div>
                  <h3 style={{
                    fontSize: '1.125rem',
                    fontWeight: '600',
                    color: '#111827',
                    margin: '0 0 0.25rem 0'
                  }}>
                    {client.firstName} {client.lastName}
                  </h3>
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    marginBottom: '0.25rem'
                  }}>
                    <div style={{
                      padding: '0.25rem 0.5rem',
                      borderRadius: '0.375rem',
                      fontSize: '0.75rem',
                      fontWeight: '500',
                      backgroundColor: getStatusBg(client.status),
                      color: getStatusColor(client.status)
                    }}>
                      {client.status.toUpperCase()}
                    </div>
                    {client.status === 'premium' && (
                      <Star style={{ height: '1rem', width: '1rem', color: '#8b5cf6' }} />
                    )}
                  </div>
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.25rem',
                    fontSize: '0.875rem',
                    color: '#6b7280'
                  }}>
                    <Star style={{ height: '0.875rem', width: '0.875rem', color: '#f59e0b' }} />
                    {client.rating.toFixed(1)}
                  </div>
                </div>
              </div>
              <button style={{
                padding: '0.5rem',
                backgroundColor: '#f3f4f6',
                color: '#6b7280',
                border: 'none',
                borderRadius: '0.5rem',
                cursor: 'pointer',
                transition: 'all 0.2s'
              }}>
                <MoreVertical style={{ height: '1rem', width: '1rem' }} />
              </button>
            </div>

            {/* Contact Info */}
            <div style={{ marginBottom: '1rem' }}>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                fontSize: '0.875rem',
                color: '#6b7280',
                marginBottom: '0.25rem'
              }}>
                <Mail style={{ height: '1rem', width: '1rem' }} />
                {client.email}
              </div>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                fontSize: '0.875rem',
                color: '#6b7280',
                marginBottom: '0.25rem'
              }}>
                <Phone style={{ height: '1rem', width: '1rem' }} />
                {client.phone}
              </div>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                fontSize: '0.875rem',
                color: '#6b7280'
              }}>
                <MapPin style={{ height: '1rem', width: '1rem' }} />
                {client.location}
              </div>
            </div>

            {/* Stats */}
            <div style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(2, 1fr)',
              gap: '1rem',
              marginBottom: '1rem',
              padding: '1rem',
              backgroundColor: '#f8fafc',
              borderRadius: '0.75rem'
            }}>
              <div>
                <div style={{ fontSize: '1.25rem', fontWeight: '700', color: '#111827' }}>
                  ${client.totalSpent.toLocaleString()}
                </div>
                <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>Total Spent</div>
              </div>
              <div>
                <div style={{ fontSize: '1.25rem', fontWeight: '700', color: '#111827' }}>
                  {client.totalBids}
                </div>
                <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>Total Bids</div>
              </div>
              <div>
                <div style={{ fontSize: '1.25rem', fontWeight: '700', color: '#111827' }}>
                  {client.propertiesWon}
                </div>
                <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>Properties Won</div>
              </div>
              <div>
                <div style={{ fontSize: '1.25rem', fontWeight: '700', color: '#111827' }}>
                  {client.propertiesInterested}
                </div>
                <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>Interested</div>
              </div>
            </div>

            {/* Action Buttons */}
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between'
            }}>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
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
                  fontSize: '0.875rem',
                  transition: 'all 0.2s'
                }}>
                  <MessageCircle style={{ height: '1rem', width: '1rem' }} />
                  Message
                </button>
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
                  fontSize: '0.875rem',
                  transition: 'all 0.2s'
                }}>
                  <Eye style={{ height: '1rem', width: '1rem' }} />
                  View
                </button>
              </div>
              <div style={{ display: 'flex', gap: '0.5rem' }}>
                <button style={{
                  padding: '0.5rem',
                  backgroundColor: '#f3f4f6',
                  color: '#6b7280',
                  border: 'none',
                  borderRadius: '0.5rem',
                  cursor: 'pointer',
                  transition: 'all 0.2s'
                }} title="Edit Client">
                  <Edit style={{ height: '1rem', width: '1rem' }} />
                </button>
                <button 
                  onClick={() => handleDeleteClient(client.clientId)}
                  style={{
                    padding: '0.5rem',
                    backgroundColor: '#fef2f2',
                    color: '#dc2626',
                    border: 'none',
                    borderRadius: '0.5rem',
                    cursor: 'pointer',
                    transition: 'all 0.2s'
                  }} title="Delete Client">
                  <Trash2 style={{ height: '1rem', width: '1rem' }} />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Empty State */}
      {sortedClients.length === 0 && (
        <div style={{
          textAlign: 'center',
          padding: '4rem 2rem',
          backgroundColor: 'white',
          borderRadius: '1rem',
          boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
          border: '1px solid #e5e7eb'
        }}>
          <Users style={{
            margin: '0 auto 1rem auto',
            height: '4rem',
            width: '4rem',
            color: '#9ca3af'
          }} />
          <h3 style={{
            fontSize: '1.25rem',
            fontWeight: '600',
            color: '#111827',
            marginBottom: '0.5rem'
          }}>No clients found</h3>
          <p style={{
            fontSize: '0.875rem',
            color: '#6b7280',
            marginBottom: '2rem'
          }}>
            {searchTerm || filterStatus !== 'all' 
              ? 'Try adjusting your filters to see more clients.'
              : 'Get started by adding your first client.'
            }
          </p>
          <button
            onClick={() => setShowCreateModal(true)}
            style={{
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
              transition: 'all 0.2s',
              boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
            }}
          >
            <Plus style={{ height: '1.25rem', width: '1.25rem' }} />
            Add Client
          </button>
        </div>
      )}

      {/* Create Client Modal */}
      {showCreateModal && (
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
              maxWidth: '48rem',
              width: '100%',
              maxHeight: '90vh',
              overflowY: 'auto'
            }}>
              <form onSubmit={handleCreateClient}>
                <div style={{ padding: '2rem' }}>
                  <h3 style={{
                    fontSize: '1.5rem',
                    fontWeight: '600',
                    color: '#111827',
                    marginBottom: '1.5rem'
                  }}>Add New Client</h3>
                  
                  <div style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
                    gap: '1.5rem'
                  }}>
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>First Name *</label>
                      <input
                        type="text"
                        required
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newClient.firstName}
                        onChange={(e) => setNewClient({ ...newClient, firstName: e.target.value })}
                        placeholder="Enter first name"
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Last Name *</label>
                      <input
                        type="text"
                        required
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newClient.lastName}
                        onChange={(e) => setNewClient({ ...newClient, lastName: e.target.value })}
                        placeholder="Enter last name"
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Email *</label>
                      <input
                        type="email"
                        required
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newClient.email}
                        onChange={(e) => setNewClient({ ...newClient, email: e.target.value })}
                        placeholder="Enter email address"
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Phone *</label>
                      <input
                        type="tel"
                        required
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newClient.phone}
                        onChange={(e) => setNewClient({ ...newClient, phone: e.target.value })}
                        placeholder="Enter phone number"
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Company</label>
                      <input
                        type="text"
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newClient.company}
                        onChange={(e) => setNewClient({ ...newClient, company: e.target.value })}
                        placeholder="Enter company name"
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Location *</label>
                      <input
                        type="text"
                        required
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newClient.location}
                        onChange={(e) => setNewClient({ ...newClient, location: e.target.value })}
                        placeholder="Enter location"
                      />
                    </div>
                    
                    <div style={{ gridColumn: 'span 2' }}>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Notes</label>
                      <textarea
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
                        rows={3}
                        value={newClient.notes}
                        onChange={(e) => setNewClient({ ...newClient, notes: e.target.value })}
                        placeholder="Enter any additional notes"
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
                    onClick={() => setShowCreateModal(false)}
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
                    Add Client
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

export default ClientsPage;

