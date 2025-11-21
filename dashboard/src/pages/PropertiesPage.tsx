import React, { useState, useEffect } from 'react';
import { 
  Plus, 
  Search, 
  Filter, 
  MapPin, 
  Bed, 
  Bath, 
  Square, 
  Calendar, 
  Edit, 
  Trash2, 
  CheckCircle, 
  XCircle,
  Eye,
  Star,
  DollarSign,
  Clock,
  Users,
  Home,
  Building,
  TrendingUp,
  AlertCircle,
  MoreVertical,
  Download,
  Upload,
  LayoutGrid,
  List
} from 'lucide-react';
import { Property, Project, Account } from '../types';
import { propertiesApi, projectsApi, auctionsApi, bidsApi, authApi } from '../services/api';
import { withTimeout } from '../utils/apiTimeout';
import { exportPropertiesToCSV } from '../utils/export';
import { useToast } from '../contexts/ToastContext';
import Pagination from '../components/Pagination';
import PropertyDocumentsManager from '../components/PropertyDocumentsManager';

const PropertiesPage: React.FC = () => {
  const toast = useToast();
  const [properties, setProperties] = useState<Property[]>([]);
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<Account | null>(null);
  const [userRole, setUserRole] = useState<'Admin' | 'Developer' | null>(null);
  const [userLoadError, setUserLoadError] = useState<string | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [selectedProperty, setSelectedProperty] = useState<any>(null);
  const [loadingDetails, setLoadingDetails] = useState(false);
  const [showFilters, setShowFilters] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [filterProject, setFilterProject] = useState('all');
  const [sortBy, setSortBy] = useState('newest');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [gridColumns, setGridColumns] = useState(4);
  const [totalCount, setTotalCount] = useState(0);
  const [totalPages, setTotalPages] = useState(0);

  const [newProperty, setNewProperty] = useState({
    name: '',
    description: '',
    location: '',
    bedrooms: 0,
    bathrooms: 0,
    squareFeet: 0,
    yearBuilt: new Date().getFullYear(),
    category: 'Residential',
    projectId: undefined as number | undefined,
    imageUrl: '',
    type: 'Resale' as string | undefined // Optional for admin
  });

  useEffect(() => {
    // Get current user to determine role with timeout
    const loadUser = async () => {
      try {
        const currentUser = await withTimeout(
          authApi.getCurrentAccount(),
          5000,
          'Unable to load user information. The server may be slow or unavailable.'
        );
        setUser(currentUser);
        // Check roleName first (from backend), then roleId, then legacy type
        const isAdmin = currentUser.roleName === 'Admin' || currentUser.roleId === 9823749823749823 || currentUser.type === 'Admin';
        const isDeveloper = currentUser.roleName === 'Developer' || currentUser.roleId === 7823647823647823 || currentUser.type === 'Developer';
        const role = isAdmin ? 'Admin' : (isDeveloper ? 'Developer' : null);
        setUserRole(role);
        setUserLoadError(null);
        if (!role) {
          setUserLoadError('Your account does not have permission to access properties. Please contact an administrator.');
          console.error('Current user role:', { roleName: currentUser.roleName, roleId: currentUser.roleId, type: currentUser.type });
          setLoading(false);
        }
      } catch (error: any) {
        console.error('Error loading user:', error);
        setUserLoadError(error.message || 'Unable to load user information. Please refresh the page or log in again.');
        setLoading(false);
      }
    };
    loadUser();
    
    // Fallback: if userRole is still null after 5 seconds, show error
    const timeoutId = setTimeout(() => {
      if (userRole === null && !userLoadError) {
        setUserLoadError('Unable to load user information. Please refresh the page or log in again.');
        setLoading(false);
      }
    }, 5000);
    
    return () => clearTimeout(timeoutId);
  }, []);

  useEffect(() => {
    if (userRole) {
    fetchProperties();
    fetchProjects();
    }
  }, [userRole, currentPage, itemsPerPage]);

  const fetchProperties = async () => {
    if (!userRole) return;
    try {
      setLoading(true);
      // Pass user role to API for role-based endpoint selection with pagination
      const response = await withTimeout(
        propertiesApi.getProperties(userRole, currentPage, itemsPerPage),
        10000,
        'Request took too long. The server may be slow or unavailable. Please try again.'
      );
      
      if (userRole === 'Admin' && 'data' in response && 'pagination' in response) {
        // Admin: paginated response
        const paginatedResponse = response as any;
        setProperties(paginatedResponse.data || []);
        setTotalCount(paginatedResponse.pagination.totalCount || 0);
        setTotalPages(paginatedResponse.pagination.totalPages || 0);
        if (currentPage === 1) {
          toast.success(`Loaded ${paginatedResponse.pagination.totalCount} total properties (page ${paginatedResponse.pagination.page} of ${paginatedResponse.pagination.totalPages})`);
        }
      } else {
        // Developer: array response (non-paginated)
        const data = response as Property[];
      setProperties(data);
        setTotalCount(data.length);
        setTotalPages(1);
      toast.success(`Loaded ${data.length} properties`);
      }
    } catch (error: any) {
      console.error('Error fetching properties:', error);
      let errorMessage = 'Failed to load properties';
      if (error.message && error.message.includes('timed out')) {
        errorMessage = error.message;
      } else if (error.message && error.message.includes('Cannot connect')) {
        errorMessage = 'Cannot connect to server. Please check your connection and ensure the API is running.';
      } else {
        errorMessage = error?.response?.data?.message || error.message || errorMessage;
      }
      toast.error(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const fetchProjects = async () => {
    try {
      const data = await withTimeout(
        projectsApi.getProjects(),
        10000,
        'Request took too long. The server may be slow or unavailable.'
      );
      setProjects(data);
    } catch (error: any) {
      console.error('Error fetching projects:', error);
      const errorMessage = error.message || 'Failed to load projects';
      toast.error(errorMessage);
    }
  };

  const handleApproveProperty = async (propertyId: number) => {
    if (!userRole) return;
    try {
      await propertiesApi.approveProperty(propertyId, userRole);
      toast.success('Property approved successfully!');
      fetchProperties();
    } catch (error: any) {
      console.error('Error approving property:', error);
      toast.error(error?.response?.data?.message || error?.message || 'Failed to approve property');
    }
  };

  const handleRejectProperty = async (propertyId: number) => {
    if (!userRole) return;
    if (window.confirm('Are you sure you want to reject this property?')) {
      try {
        await propertiesApi.rejectProperty(propertyId, userRole);
        toast.success('Property rejected successfully!');
        fetchProperties();
      } catch (error: any) {
        console.error('Error rejecting property:', error);
        toast.error(error?.response?.data?.message || error?.message || 'Failed to reject property');
      }
    }
  };

  const handleDeleteProperty = async (propertyId: number) => {
    if (window.confirm('Are you sure you want to delete this property? This action cannot be undone.')) {
      try {
        await propertiesApi.deleteProperty(propertyId);
        toast.success('Property deleted successfully!');
        fetchProperties();
      } catch (error: any) {
        console.error('Error deleting property:', error);
        toast.error(error?.response?.data?.message || 'Failed to delete property');
      }
    }
  };

  const handleViewDetails = async (propertyId: number) => {
    try {
      setLoadingDetails(true);
      setShowDetailsModal(true);
      
      console.log('🏠 Fetching details for property:', propertyId);
      
      // Fetch full property details with owner and auctions
      const propertyData = await propertiesApi.getProperty(propertyId);
      console.log('🏠 Property data received:', propertyData);
      
      // If property has auctions, get bid details for each
      let auctionsWithBids: any[] = [];
      if (propertyData.auctions && propertyData.auctions.length > 0) {
        console.log('🔨 Property has', propertyData.auctions.length, 'auction(s)');
        
        auctionsWithBids = await Promise.all(
          propertyData.auctions.map(async (auction: any) => {
            try {
              const bids = await bidsApi.getBidsForAuction(auction.auctionId || auction.AuctionId);
              const sortedBids = (bids || []).sort((a: any, b: any) => 
                (b.bidAmount || b.BidAmount || 0) - (a.bidAmount || a.BidAmount || 0)
              );
              
              return {
                ...auction,
                bids: sortedBids,
                highestBid: sortedBids[0] || null
              };
            } catch (error) {
              console.warn('Failed to fetch bids for auction:', auction.auctionId);
              return {
                ...auction,
                bids: [],
                highestBid: null
              };
            }
          })
        );
      }
      
      setSelectedProperty({
        ...propertyData,
        auctions: auctionsWithBids
      });
      
      toast.success('Property details loaded!');
    } catch (error: any) {
      console.error('❌ Error fetching property details:', error);
      toast.error('Failed to load property details');
      setShowDetailsModal(false);
    } finally {
      setLoadingDetails(false);
    }
  };


  const handleCreateProperty = (e: React.FormEvent) => {
    e.preventDefault();
    const property: Property = {
      propertyId: properties.length + 1,
      ...newProperty,
      type: 'Resale' as 'Resale' | 'Primary',
      status: 'Pending',
      ownerId: 1,
      isApproved: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };
    setProperties([...properties, property]);
    setShowCreateModal(false);
    setNewProperty({
      name: '',
      description: '',
      location: '',
      bedrooms: 0,
      bathrooms: 0,
      squareFeet: 0,
      yearBuilt: new Date().getFullYear(),
      category: 'Residential',
      projectId: undefined,
      imageUrl: '',
      type: 'Resale'
    });
  };


  const filteredProperties = properties.filter(property => {
    const matchesSearch = property.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (property.location?.toLowerCase() || '').includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === 'all' || 
                         (filterStatus === 'approved' && property.status === 'Approved') ||
                         (filterStatus === 'pending' && property.status === 'Pending');
    const matchesProject = filterProject === 'all' || 
                          property.projectId?.toString() === filterProject;
    
    return matchesSearch && matchesStatus && matchesProject;
  });

  const sortedProperties = [...filteredProperties].sort((a, b) => {
    switch (sortBy) {
      case 'newest':
        return new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime();
      case 'oldest':
        return new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime();
      case 'sqft-high':
        return b.squareFeet - a.squareFeet;
      case 'sqft-low':
        return a.squareFeet - b.squareFeet;
      case 'name':
        return a.name.localeCompare(b.name);
      default:
        return 0;
    }
  });

  // Client-side filtering and sorting on current page only (server-side pagination already handled)
  // Note: For Admin, pagination is server-side. For Developers, all their properties are shown.
  // Filtering is done on the current page of properties only
  const paginatedProperties = sortedProperties;

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
          }}>Properties Management</h1>
          <p style={{
            fontSize: '1.125rem',
            color: '#6b7280',
            margin: 0
          }}>
            Review, approve, and manage all property listings
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
                placeholder="Search properties..."
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
              <option value="newest">Newest First</option>
              <option value="oldest">Oldest First</option>
              <option value="sqft-high">Size: Large to Small</option>
              <option value="sqft-low">Size: Small to Large</option>
              <option value="name">Name A-Z</option>
            </select>

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

            <button
              onClick={() => exportPropertiesToCSV(sortedProperties)}
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
                <option value="all">All Properties</option>
                <option value="approved">Approved</option>
                <option value="pending">Pending</option>
              </select>
            </div>
            <div>
              <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '500', color: '#374151', marginBottom: '0.5rem' }}>
                Project
              </label>
              <select
                value={filterProject}
                onChange={(e) => setFilterProject(e.target.value)}
                style={{
                  padding: '0.5rem 0.75rem',
                  border: '1px solid #d1d5db',
                  borderRadius: '0.5rem',
                  fontSize: '0.875rem',
                  outline: 'none',
                  backgroundColor: 'white'
                }}
              >
                <option value="all">All Projects</option>
                {projects.map(project => (
                  <option key={project.projectId} value={project.projectId}>
                    {project.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
        )}
      </div>

      {/* Properties Grid View */}
      {viewMode === 'grid' && (
        <div style={{
          display: 'grid',
          gridTemplateColumns: `repeat(${gridColumns}, 1fr)`,
          gap: '1.5rem',
          alignItems: 'stretch'
        }}>
          {paginatedProperties.map((property) => (
          <div key={property.propertyId} style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            overflow: 'hidden',
            boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
            border: '1px solid #e5e7eb',
            transition: 'all 0.3s ease',
            background: 'linear-gradient(135deg, #ffffff 0%, #f8fafc 100%)',
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
                src={property.imageUrl || 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&h=300&fit=crop'}
                alt={property.name}
                style={{
                  width: '100%',
                  height: '100%',
                  objectFit: 'cover'
                }}
              />
              <div style={{
                position: 'absolute',
                top: '1rem',
                right: '1rem',
                display: 'flex',
                flexDirection: 'column',
                gap: '0.5rem',
                alignItems: 'flex-end'
              }}>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  <div style={{
                    padding: '0.25rem 0.75rem',
                    borderRadius: '0.5rem',
                    fontSize: '0.75rem',
                    fontWeight: '500',
                    backgroundColor: property.isApproved ? '#dcfce7' : '#fef3c7',
                    color: property.isApproved ? '#166534' : '#92400e'
                  }}>
                    {property.isApproved ? 'Approved' : 'Pending'}
                  </div>
                  <div style={{
                    padding: '0.25rem 0.75rem',
                    borderRadius: '0.5rem',
                    fontSize: '0.75rem',
                    fontWeight: '500',
                    backgroundColor: '#dbeafe',
                    color: '#1e40af'
                  }}>
                    {property.type}
                  </div>
                </div>
                {property.projectId && (
                  <div style={{
                    padding: '0.25rem 0.75rem',
                    borderRadius: '0.5rem',
                    fontSize: '0.75rem',
                    fontWeight: '600',
                    backgroundColor: '#fef3c7',
                    color: '#92400e',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.25rem',
                    boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
                  }}>
                    <Building style={{ height: '0.875rem', width: '0.875rem' }} />
                    {projects.find(p => p.projectId === property.projectId)?.name || 'Project'}
                  </div>
                )}
                {property.parentPropertyId && (
                  <div style={{
                    padding: '0.25rem 0.75rem',
                    borderRadius: '0.5rem',
                    fontSize: '0.75rem',
                    fontWeight: '600',
                    backgroundColor: '#e0e7ff',
                    color: '#4338ca',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.25rem',
                    boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
                  }}>
                    <Home style={{ height: '0.875rem', width: '0.875rem' }} />
                    Parent Property
                  </div>
                )}
              </div>
            </div>
            
              {/* Property Details */}
            <div style={{ padding: '1.5rem', flex: 1, display: 'flex', flexDirection: 'column' }}>
              <div style={{ marginBottom: '1rem' }}>
                <h3 style={{
                  fontSize: '1.25rem',
                  fontWeight: '600',
                  color: '#111827',
                  marginBottom: '0.5rem'
                }}>{property.name}</h3>
                {property.description && (
                  <p style={{
                    fontSize: '0.875rem',
                    color: '#6b7280',
                    lineHeight: '1.4',
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical',
                    overflow: 'hidden',
                    marginBottom: '0.5rem'
                  }}>{property.description}</p>
                )}
                {property.location && (
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    fontSize: '0.875rem',
                    color: '#6b7280',
                    marginBottom: '0.5rem'
                  }}>
                    <MapPin style={{ height: '1rem', width: '1rem', marginRight: '0.25rem' }} />
                    {property.location}
                  </div>
                )}
                {/* Parent Property Information */}
                {property.parentProperty && (
                  <div style={{
                    marginTop: '0.75rem',
                    padding: '0.75rem',
                    backgroundColor: '#e0e7ff',
                    borderRadius: '0.5rem',
                    border: '1px solid #c7d2fe'
                  }}>
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      fontSize: '0.875rem',
                      fontWeight: '600',
                      color: '#4338ca',
                      marginBottom: '0.5rem'
                    }}>
                      <Home style={{ height: '1rem', width: '1rem', marginRight: '0.5rem' }} />
                      Parent Property Information
                    </div>
                    <div style={{
                      fontSize: '0.75rem',
                      color: '#6366f1',
                      display: 'grid',
                      gridTemplateColumns: 'repeat(2, 1fr)',
                      gap: '0.5rem'
                    }}>
                      {property.parentProperty.projectName && (
                        <div>
                          <strong>Project:</strong> {property.parentProperty.projectName}
                        </div>
                      )}
                      {property.parentProperty.type && (
                        <div>
                          <strong>Type:</strong> {property.parentProperty.type}
                        </div>
                      )}
                      {property.parentProperty.bedrooms !== undefined && (
                        <div>
                          <strong>Bedrooms:</strong> {property.parentProperty.bedrooms}
                        </div>
                      )}
                      {property.parentProperty.bathrooms !== undefined && (
                        <div>
                          <strong>Bathrooms:</strong> {property.parentProperty.bathrooms}
                        </div>
                      )}
                      {property.parentProperty.areaSqm !== undefined && (
                        <div>
                          <strong>Area:</strong> {property.parentProperty.areaSqm} sqm
                        </div>
                      )}
                      {property.parentProperty.finishingType && (
                        <div>
                          <strong>Finishing:</strong> {property.parentProperty.finishingType}
                        </div>
                      )}
                    </div>
                  </div>
                )}
                {/* Owner Information */}
                {property.owner && (
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                    fontSize: '0.875rem',
                    color: '#6b7280',
                    marginTop: '0.5rem',
                    padding: '0.5rem',
                    backgroundColor: '#f8fafc',
                    borderRadius: '0.5rem'
                  }}>
                    <Users style={{ height: '1rem', width: '1rem', marginRight: '0.5rem' }} />
                    <span><strong>Owner:</strong> {property.owner.firstName} {property.owner.lastName}</span>
                  </div>
                )}
              </div>

              {/* Property Specs */}
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '1rem',
                marginBottom: '1rem',
                fontSize: '0.875rem',
                color: '#6b7280'
              }}>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <Bed style={{ height: '1rem', width: '1rem', marginRight: '0.25rem' }} />
                  {property.bedrooms} beds
                </div>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <Bath style={{ height: '1rem', width: '1rem', marginRight: '0.25rem' }} />
                  {property.bathrooms} baths
                </div>
                <div style={{ display: 'flex', alignItems: 'center' }}>
                  <Square style={{ height: '1rem', width: '1rem', marginRight: '0.25rem' }} />
                  {property.squareFeet.toLocaleString()} sq ft
                </div>
              </div>

              {/* Property Info and Stats */}
              <div style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                marginBottom: '1rem',
                paddingBottom: '1rem',
                borderBottom: '1px solid #e5e7eb'
              }}>
                <div>
                  <div style={{
                    fontSize: '1.125rem',
                    fontWeight: '600',
                    color: '#111827',
                    marginBottom: '0.25rem'
                  }}>
                    {property.category || 'Residential'}
                  </div>
                  <div style={{
                    fontSize: '0.75rem',
                    color: '#6b7280'
                  }}>
                    Property Type
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <div style={{
                    fontSize: '0.875rem',
                    color: '#6b7280',
                    marginBottom: '0.25rem'
                  }}>
                    Built {property.yearBuilt}
                  </div>
                  <div style={{
                    fontSize: '0.75rem',
                    color: '#6b7280'
                  }}>
                    Listed {new Date(property.createdAt).toLocaleDateString()}
                  </div>
                </div>
              </div>

              {/* Action Buttons */}
              <div style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                marginTop: 'auto'
              }}>
                <div style={{ display: 'flex', gap: '0.5rem' }}>
                  {!property.isApproved && userRole === 'Admin' && (
                    <>
                      <button
                        onClick={() => handleApproveProperty(property.propertyId)}
                        style={{
                          color: '#059669',
                          backgroundColor: '#dcfce7',
                          border: 'none',
                          cursor: 'pointer',
                          padding: '0.5rem',
                          borderRadius: '0.5rem',
                          transition: 'all 0.2s'
                        }}
                        title="Approve Property"
                      >
                        <CheckCircle style={{ height: '1rem', width: '1rem' }} />
                      </button>
                      <button
                        onClick={() => handleRejectProperty(property.propertyId)}
                        style={{
                          color: '#dc2626',
                          backgroundColor: '#fef2f2',
                          border: 'none',
                          cursor: 'pointer',
                          padding: '0.5rem',
                          borderRadius: '0.5rem',
                          transition: 'all 0.2s'
                        }}
                        title="Reject Property"
                      >
                        <XCircle style={{ height: '1rem', width: '1rem' }} />
                      </button>
                    </>
                  )}
                  <button 
                    onClick={() => handleDeleteProperty(property.propertyId)}
                    style={{
                      color: '#dc2626',
                      backgroundColor: '#fef2f2',
                      border: 'none',
                      cursor: 'pointer',
                      padding: '0.5rem',
                      borderRadius: '0.5rem',
                      transition: 'all 0.2s'
                    }} title="Delete Property">
                    <Trash2 style={{ height: '1rem', width: '1rem' }} />
                  </button>
                </div>
                <button 
                  onClick={() => handleViewDetails(property.propertyId)}
                  style={{
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    color: 'white',
                    fontSize: '0.875rem',
                    fontWeight: '500',
                    padding: '0.5rem 1rem',
                    borderRadius: '0.5rem',
                    border: 'none',
                    cursor: 'pointer',
                    transition: 'all 0.2s',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem'
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

      {/* Properties List View */}
      {viewMode === 'list' && (
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          gap: '1rem'
        }}>
          {paginatedProperties.map((property) => (
            <div key={property.propertyId} style={{
              backgroundColor: 'white',
              borderRadius: '1rem',
              overflow: 'hidden',
              boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
              border: '1px solid #e5e7eb',
              transition: 'all 0.3s ease',
              display: 'flex',
              minHeight: '200px'
            }}>
              {/* Property Image - Left Side */}
              <div style={{
                position: 'relative',
                width: '300px',
                flexShrink: 0,
                overflow: 'hidden'
              }}>
                <img
                  src={property.imageUrl || 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=400&h=300&fit=crop'}
                  alt={property.name}
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
                  display: 'flex',
                  flexDirection: 'column',
                  gap: '0.5rem'
                }}>
                  <div style={{
                    padding: '0.25rem 0.75rem',
                    borderRadius: '0.5rem',
                    fontSize: '0.75rem',
                    fontWeight: '500',
                    backgroundColor: property.isApproved ? '#dcfce7' : '#fef3c7',
                    color: property.isApproved ? '#166534' : '#92400e'
                  }}>
                    {property.isApproved ? 'Approved' : 'Pending'}
                  </div>
                  <div style={{
                    padding: '0.25rem 0.75rem',
                    borderRadius: '0.5rem',
                    fontSize: '0.75rem',
                    fontWeight: '500',
                    backgroundColor: '#dbeafe',
                    color: '#1e40af'
                  }}>
                    {property.type}
                  </div>
                  {property.projectId && (
                    <div style={{
                      padding: '0.25rem 0.75rem',
                      borderRadius: '0.5rem',
                      fontSize: '0.75rem',
                      fontWeight: '600',
                      backgroundColor: '#fef3c7',
                      color: '#92400e',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.25rem',
                      boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
                    }}>
                      <Building style={{ height: '0.875rem', width: '0.875rem' }} />
                      {projects.find(p => p.projectId === property.projectId)?.name || 'Project'}
                    </div>
                  )}
                </div>
              </div>
              
              {/* Property Details - Right Side */}
              <div style={{ padding: '1.5rem', flex: 1, display: 'flex', flexDirection: 'column' }}>
                <div style={{ flex: 1 }}>
                  <h3 style={{
                    fontSize: '1.5rem',
                    fontWeight: '600',
                    color: '#111827',
                    marginBottom: '0.5rem'
                  }}>{property.name}</h3>
                  
                  {property.location && (
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      fontSize: '0.875rem',
                      color: '#6b7280',
                      marginBottom: '1rem'
                    }}>
                      <MapPin style={{ height: '1rem', width: '1rem', marginRight: '0.5rem' }} />
                      {property.location}
                    </div>
                  )}
                  
                  {property.description && (
                    <p style={{
                      fontSize: '0.875rem',
                      color: '#6b7280',
                      lineHeight: '1.5',
                      marginBottom: '1rem'
                    }}>{property.description}</p>
                  )}
                  
                  {/* Owner Information */}
                  {property.owner && (
                    <div style={{
                      display: 'flex',
                      alignItems: 'center',
                      fontSize: '0.875rem',
                      color: '#6b7280',
                      marginBottom: '1rem',
                      padding: '0.75rem',
                      backgroundColor: '#f8fafc',
                      borderRadius: '0.5rem'
                    }}>
                      <Users style={{ height: '1rem', width: '1rem', marginRight: '0.5rem', color: '#667eea' }} />
                      <span><strong>Owner:</strong> {property.owner.firstName} {property.owner.lastName} ({property.owner.email})</span>
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
                      <strong style={{ color: '#111827' }}>{property.bedrooms}</strong>&nbsp;beds
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                      <Bath style={{ height: '1.25rem', width: '1.25rem', marginRight: '0.5rem', color: '#667eea' }} />
                      <strong style={{ color: '#111827' }}>{property.bathrooms}</strong>&nbsp;baths
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                      <Square style={{ height: '1.25rem', width: '1.25rem', marginRight: '0.5rem', color: '#667eea' }} />
                      <strong style={{ color: '#111827' }}>{property.squareFeet.toLocaleString()}</strong>&nbsp;sq ft
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center' }}>
                      <Calendar style={{ height: '1.25rem', width: '1.25rem', marginRight: '0.5rem', color: '#667eea' }} />
                      <strong style={{ color: '#111827' }}>{property.yearBuilt}</strong>
                    </div>
                    <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center' }}>
                      <Building style={{ height: '1.25rem', width: '1.25rem', marginRight: '0.5rem', color: '#667eea' }} />
                      <strong style={{ color: '#111827' }}>{property.category || 'Residential'}</strong>
                    </div>
                  </div>
                </div>

                {/* Action Buttons */}
                <div style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  paddingTop: '1rem',
                  borderTop: '1px solid #e5e7eb'
                }}>
                  <div style={{ display: 'flex', gap: '0.5rem' }}>
                    {!property.isApproved && userRole === 'Admin' && (
                      <>
                        <button
                          onClick={() => handleApproveProperty(property.propertyId)}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            color: '#059669',
                            backgroundColor: '#dcfce7',
                            border: 'none',
                            cursor: 'pointer',
                            padding: '0.5rem 1rem',
                            borderRadius: '0.5rem',
                            fontSize: '0.875rem',
                            fontWeight: '500',
                            transition: 'all 0.2s'
                          }}
                        >
                          <CheckCircle style={{ height: '1rem', width: '1rem' }} />
                          Approve
                        </button>
                        <button
                          onClick={() => handleRejectProperty(property.propertyId)}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            color: '#dc2626',
                            backgroundColor: '#fef2f2',
                            border: 'none',
                            cursor: 'pointer',
                            padding: '0.5rem 1rem',
                            borderRadius: '0.5rem',
                            fontSize: '0.875rem',
                            fontWeight: '500',
                            transition: 'all 0.2s'
                          }}
                        >
                          <XCircle style={{ height: '1rem', width: '1rem' }} />
                          Reject
                        </button>
                      </>
                    )}
                    <button
                      onClick={() => handleDeleteProperty(property.propertyId)}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        color: '#dc2626',
                        backgroundColor: '#fef2f2',
                        border: 'none',
                        cursor: 'pointer',
                        padding: '0.5rem 1rem',
                        borderRadius: '0.5rem',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        transition: 'all 0.2s'
                      }}
                    >
                      <Trash2 style={{ height: '1rem', width: '1rem' }} />
                      Delete
                    </button>
                  </div>
                  <button 
                    onClick={() => handleViewDetails(property.propertyId)}
                    style={{
                      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                      color: 'white',
                      fontSize: '0.875rem',
                      fontWeight: '500',
                      padding: '0.5rem 1.5rem',
                      borderRadius: '0.5rem',
                      border: 'none',
                      cursor: 'pointer',
                      transition: 'all 0.2s',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem'
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
      {sortedProperties.length > 0 && (
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
              Properties per page:
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
          
          {userRole === 'Admin' && (
          <Pagination
            currentPage={currentPage}
            totalPages={totalPages}
              onPageChange={(page) => {
                setCurrentPage(page);
                window.scrollTo({ top: 0, behavior: 'smooth' });
              }}
            itemsPerPage={itemsPerPage}
              totalItems={totalCount}
          />
          )}
        </div>
      )}

      {/* Empty State */}
      {sortedProperties.length === 0 && (
        <div style={{
          textAlign: 'center',
          padding: '4rem 2rem',
          backgroundColor: 'white',
          borderRadius: '1rem',
          boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
          border: '1px solid #e5e7eb'
        }}>
          <Home style={{
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
          }}>No properties found</h3>
          <p style={{
            fontSize: '0.875rem',
            color: '#6b7280',
            marginBottom: '2rem'
          }}>
            {searchTerm || filterStatus !== 'all' || filterProject !== 'all' 
              ? 'Try adjusting your filters to see more properties.'
              : 'Get started by creating your first property listing.'
            }
          </p>
          <button
            onClick={() => {
              setFilterStatus('all');
              setFilterProject('all');
              setSearchTerm('');
            }}
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
            Clear Filters
          </button>
        </div>
      )}

      {/* Create Property Modal - Removed for admin dashboard */}
      {false && showCreateModal && (
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
              <form onSubmit={handleCreateProperty}>
                <div style={{ padding: '2rem' }}>
                  <h3 style={{
                    fontSize: '1.5rem',
                    fontWeight: '600',
                    color: '#111827',
                    marginBottom: '1.5rem'
                  }}>Create New Property</h3>
                  
                  <div style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
                    gap: '1.5rem'
                  }}>
                    <div style={{ gridColumn: 'span 2' }}>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Property Name *</label>
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
                        value={newProperty.name}
                        onChange={(e) => setNewProperty({ ...newProperty, name: e.target.value })}
                        placeholder="Enter property name"
                      />
                    </div>
                    
                    <div style={{ gridColumn: 'span 2' }}>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Description</label>
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
                        value={newProperty.description}
                        onChange={(e) => setNewProperty({ ...newProperty, description: e.target.value })}
                        placeholder="Describe the property"
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Location</label>
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
                        value={newProperty.location}
                        onChange={(e) => setNewProperty({ ...newProperty, location: e.target.value })}
                        placeholder="City, State"
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Bedrooms *</label>
                      <input
                        type="number"
                        required
                        min="0"
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newProperty.bedrooms}
                        onChange={(e) => setNewProperty({ ...newProperty, bedrooms: Number(e.target.value) })}
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Bathrooms *</label>
                      <input
                        type="number"
                        required
                        min="0"
                        step="0.5"
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newProperty.bathrooms}
                        onChange={(e) => setNewProperty({ ...newProperty, bathrooms: Number(e.target.value) })}
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Square Feet *</label>
                      <input
                        type="number"
                        required
                        min="0"
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newProperty.squareFeet}
                        onChange={(e) => setNewProperty({ ...newProperty, squareFeet: Number(e.target.value) })}
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Year Built *</label>
                      <input
                        type="number"
                        required
                        min="1800"
                        max={new Date().getFullYear()}
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newProperty.yearBuilt}
                        onChange={(e) => setNewProperty({ ...newProperty, yearBuilt: Number(e.target.value) })}
                      />
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Category</label>
                      <select
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
                        value={newProperty.category}
                        onChange={(e) => setNewProperty({ ...newProperty, category: e.target.value })}
                      >
                        <option value="Residential">Residential</option>
                        <option value="Commercial">Commercial</option>
                        <option value="Condo">Condo</option>
                        <option value="Townhouse">Townhouse</option>
                      </select>
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Project</label>
                      <select
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
                        value={newProperty.projectId || ''}
                        onChange={(e) => setNewProperty({ ...newProperty, projectId: e.target.value ? Number(e.target.value) : undefined })}
                      >
                        <option value="">No Project</option>
                        {projects.map((project) => (
                          <option key={project.projectId} value={project.projectId}>
                            {project.name}
                          </option>
                        ))}
                      </select>
                    </div>
                    
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Property Type (Optional)</label>
                      <select
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
                        value={newProperty.type || 'Resale'}
                        onChange={(e) => setNewProperty({ ...newProperty, type: e.target.value })}
                      >
                        <option value="Primary">Primary (New Construction)</option>
                        <option value="Resale">Resale (Existing Property)</option>
                      </select>
                    </div>
                    
                    <div style={{ gridColumn: 'span 2' }}>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>Image URL</label>
                      <input
                        type="url"
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newProperty.imageUrl}
                        onChange={(e) => setNewProperty({ ...newProperty, imageUrl: e.target.value })}
                        placeholder="https://example.com/image.jpg"
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
                    Create Property
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Property Details Modal */}
      {showDetailsModal && selectedProperty && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          zIndex: 50,
          overflowY: 'auto',
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '1rem'
        }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
            maxWidth: '70rem',
            width: '100%',
            maxHeight: '90vh',
            overflowY: 'auto'
          }}>
            {loadingDetails ? (
              <div style={{ padding: '3rem', textAlign: 'center' }}>
                <div style={{ fontSize: '1.5rem', color: '#667eea' }}>Loading property details...</div>
              </div>
            ) : (
              <div>
                {/* Property Image - Full Width at Top */}
                <div style={{
                  position: 'relative',
                  width: '100%',
                  height: '400px',
                  overflow: 'hidden',
                  borderRadius: '1rem 1rem 0 0'
                }}>
                  <img
                    src={selectedProperty.imageUrl || 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=1200&h=600&fit=crop'}
                    alt={selectedProperty.name}
                    style={{
                      width: '100%',
                      height: '100%',
                      objectFit: 'cover'
                    }}
                  />
                  <div style={{
                    position: 'absolute',
                    top: '1.5rem',
                    right: '1.5rem',
                    display: 'flex',
                    gap: '0.75rem'
                  }}>
                    <button
                      onClick={() => setShowDetailsModal(false)}
                      style={{
                        padding: '0.75rem',
                        backgroundColor: 'rgba(255, 255, 255, 0.95)',
                        border: 'none',
                        borderRadius: '0.5rem',
                        cursor: 'pointer',
                        transition: 'all 0.2s',
                        boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
                      }}
                    >
                      <XCircle style={{ height: '1.5rem', width: '1.5rem', color: '#6b7280' }} />
                    </button>
                  </div>
                  <div style={{
                    position: 'absolute',
                    bottom: 0,
                    left: 0,
                    right: 0,
                    background: 'linear-gradient(to top, rgba(0,0,0,0.7), transparent)',
                    padding: '2rem 2rem 1.5rem 2rem'
                  }}>
                    <h2 style={{
                      fontSize: '2rem',
                      fontWeight: '700',
                      color: 'white',
                      margin: '0 0 0.5rem 0',
                      textShadow: '0 2px 4px rgba(0,0,0,0.3)'
                    }}>{selectedProperty.name}</h2>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                      <MapPin style={{ height: '1.25rem', width: '1.25rem', color: 'white' }} />
                      <span style={{ fontSize: '1.125rem', color: 'white', textShadow: '0 2px 4px rgba(0,0,0,0.3)' }}>{selectedProperty.location}</span>
                    </div>
                  </div>
                </div>

                <div style={{ padding: '2rem' }}>
                  {/* Status Badge */}
                  <div style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
                    <span style={{
                      padding: '0.5rem 1rem',
                      borderRadius: '0.5rem',
                      fontSize: '0.875rem',
                      fontWeight: '600',
                      backgroundColor: selectedProperty.status === 'Approved' ? '#dcfce7' : 
                                     selectedProperty.status === 'Pending' ? '#fef3c7' : '#fef2f2',
                      color: selectedProperty.status === 'Approved' ? '#059669' : 
                             selectedProperty.status === 'Pending' ? '#d97706' : '#dc2626'
                    }}>
                      {selectedProperty.status === 'Approved' && <CheckCircle style={{ height: '1rem', width: '1rem', display: 'inline', marginRight: '0.25rem' }} />}
                      {selectedProperty.status === 'Pending' && <Clock style={{ height: '1rem', width: '1rem', display: 'inline', marginRight: '0.25rem' }} />}
                      {selectedProperty.status === 'NotApproved' && <XCircle style={{ height: '1rem', width: '1rem', display: 'inline', marginRight: '0.25rem' }} />}
                      {selectedProperty.status}
                    </span>
                    <span style={{
                      padding: '0.5rem 1rem',
                      borderRadius: '0.5rem',
                      fontSize: '0.875rem',
                      fontWeight: '600',
                      backgroundColor: '#dbeafe',
                      color: '#1e40af'
                    }}>
                      {selectedProperty.type}
                    </span>
                  </div>

                  {/* Grid Layout for Property Info, Owner Info, Project, and Parent Property */}
                  <div style={{
                    display: 'grid',
                    gridTemplateColumns: '1fr 1fr',
                    gap: '1.5rem',
                    marginBottom: '2rem'
                  }}>
                  {/* Property Information */}
                  <div style={{
                    padding: '1.5rem',
                    backgroundColor: '#f8fafc',
                    borderRadius: '0.75rem',
                    border: '1px solid #e5e7eb'
                  }}>
                    <h3 style={{
                      fontSize: '1.25rem',
                      fontWeight: '600',
                      color: '#111827',
                      marginBottom: '1rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem'
                    }}>
                      <Home style={{ height: '1.25rem', width: '1.25rem', color: '#667eea' }} />
                      Property Details
                    </h3>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                      <div style={{ display: 'flex', gap: '1.5rem' }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <Bed style={{ height: '1.25rem', width: '1.25rem', color: '#667eea' }} />
                          <span style={{ fontSize: '1rem', fontWeight: '600', color: '#111827' }}>{selectedProperty.bedrooms}</span>
                          <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>Beds</span>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <Bath style={{ height: '1.25rem', width: '1.25rem', color: '#667eea' }} />
                          <span style={{ fontSize: '1rem', fontWeight: '600', color: '#111827' }}>{selectedProperty.bathrooms}</span>
                          <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>Baths</span>
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <Square style={{ height: '1.25rem', width: '1.25rem', color: '#667eea' }} />
                          <span style={{ fontSize: '1rem', fontWeight: '600', color: '#111827' }}>{selectedProperty.squareFeet.toLocaleString()}</span>
                          <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>sq ft</span>
                        </div>
                      </div>
                      <div style={{ paddingTop: '0.75rem', borderTop: '1px solid #e5e7eb' }}>
                        <div style={{ marginBottom: '0.5rem' }}>
                          <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>Type: </span>
                          <span style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>{selectedProperty.type}</span>
                        </div>
                        <div style={{ marginBottom: '0.5rem' }}>
                          <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>Category: </span>
                          <span style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>{selectedProperty.category}</span>
                        </div>
                        <div style={{ marginBottom: '0.5rem' }}>
                          <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>Year Built: </span>
                          <span style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>{selectedProperty.yearBuilt}</span>
                        </div>
                        <div>
                          <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>Listed: </span>
                          <span style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>{new Date(selectedProperty.createdAt).toLocaleDateString()}</span>
                        </div>
                      </div>
                      {selectedProperty.description && (
                        <div style={{ paddingTop: '0.75rem', borderTop: '1px solid #e5e7eb' }}>
                          <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280', lineHeight: '1.5' }}>
                            {selectedProperty.description}
                          </p>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Owner Information */}
                  <div style={{
                    padding: '1.5rem',
                    backgroundColor: '#f0fdf4',
                    borderRadius: '0.75rem',
                    border: '1px solid #bbf7d0'
                  }}>
                    <h3 style={{
                      fontSize: '1.25rem',
                      fontWeight: '600',
                      color: '#111827',
                      marginBottom: '1rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem'
                    }}>
                      <Users style={{ height: '1.25rem', width: '1.25rem', color: '#059669' }} />
                      Owner Information
                    </h3>
                    {selectedProperty.owner ? (
                      <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                        <div>
                          <div style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827', marginBottom: '0.25rem' }}>
                            {selectedProperty.owner.firstName} {selectedProperty.owner.lastName}
                          </div>
                          <div style={{ fontSize: '0.875rem', color: '#059669', fontWeight: '500' }}>
                            {selectedProperty.owner.type}
                          </div>
                        </div>
                        <div style={{ paddingTop: '0.75rem', borderTop: '1px solid #bbf7d0' }}>
                          <div style={{ marginBottom: '0.5rem' }}>
                            <span style={{ fontSize: '0.875rem', color: '#047857' }}>Email: </span>
                            <span style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>{selectedProperty.owner.email}</span>
                          </div>
                          {selectedProperty.owner.phoneNumber && (
                            <div style={{ marginBottom: '0.5rem' }}>
                              <span style={{ fontSize: '0.875rem', color: '#047857' }}>Phone: </span>
                              <span style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>{selectedProperty.owner.phoneNumber}</span>
                            </div>
                          )}
                          <div style={{ marginBottom: '0.5rem' }}>
                            <span style={{ fontSize: '0.875rem', color: '#047857' }}>Status: </span>
                            <span style={{
                              fontSize: '0.75rem',
                              fontWeight: '600',
                              padding: '0.25rem 0.5rem',
                              borderRadius: '0.25rem',
                              backgroundColor: selectedProperty.owner.status === 'Verified' ? '#dcfce7' : '#fef3c7',
                              color: selectedProperty.owner.status === 'Verified' ? '#059669' : '#d97706'
                            }}>
                              {selectedProperty.owner.status}
                            </span>
                          </div>
                        </div>
                      </div>
                    ) : (
                      <p style={{ margin: 0, fontSize: '0.875rem', color: '#6b7280' }}>Owner information not available</p>
                    )}
                  </div>

                  {/* Project Assignment */}
                  <div style={{
                    padding: '1.5rem',
                    backgroundColor: '#fef3c7',
                    borderRadius: '0.75rem',
                    border: '2px solid #f59e0b',
                    boxShadow: '0 4px 6px -1px rgba(245, 158, 11, 0.2)'
                  }}>
                    <h3 style={{
                      fontSize: '1.25rem',
                      fontWeight: '600',
                      color: '#111827',
                      marginBottom: '0.5rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem'
                    }}>
                      <Building style={{ height: '1.25rem', width: '1.25rem', color: '#d97706' }} />
                      📁 Project Assignment
                    </h3>
                    <p style={{
                      fontSize: '0.75rem',
                      color: '#92400e',
                      marginBottom: '1rem',
                      fontStyle: 'italic'
                    }}>
                      Assign this property to a project for better organization
                    </p>
                    <div style={{ marginBottom: '1rem' }}>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#92400e',
                        marginBottom: '0.5rem'
                      }}>
                        Select Project
                      </label>
                      <select
                        value={selectedProperty.projectId || ''}
                        onChange={async (e) => {
                          // Backend expects: 0 or negative to detach, positive number to assign
                          const newProjectId = e.target.value ? Number(e.target.value) : 0;
                          try {
                            await propertiesApi.updateProperty(selectedProperty.propertyId, {
                              projectId: newProjectId
                            });
                            setSelectedProperty({
                              ...selectedProperty,
                              projectId: newProjectId === 0 ? undefined : newProjectId
                            });
                            if (newProjectId === 0) {
                              toast.success('Property removed from project successfully!');
                            } else {
                              toast.success('Property assigned to project successfully!');
                            }
                            fetchProperties();
                          } catch (error: any) {
                            console.error('Error updating property project:', error);
                            toast.error(error?.response?.data?.message || 'Failed to update property project');
                          }
                        }}
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #fbbf24',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          fontWeight: '500',
                          outline: 'none',
                          backgroundColor: 'white',
                          color: '#111827',
                          cursor: 'pointer',
                          transition: 'all 0.2s'
                        }}
                      >
                        <option value="">No Project (Unassigned)</option>
                        {projects.map((project) => (
                          <option key={project.projectId} value={project.projectId}>
                            {project.name}
                          </option>
                        ))}
                      </select>
                    </div>
                    {selectedProperty.projectId ? (
                      <div style={{
                        padding: '0.75rem',
                        backgroundColor: '#fefce8',
                        borderRadius: '0.5rem',
                        border: '1px solid #fde68a'
                      }}>
                        <div style={{ fontSize: '0.75rem', color: '#92400e', fontWeight: '600', marginBottom: '0.25rem' }}>
                          Currently Assigned To:
                        </div>
                        <div style={{ fontSize: '0.875rem', fontWeight: '700', color: '#111827' }}>
                          {projects.find(p => p.projectId === selectedProperty.projectId)?.name || 'Unknown Project'}
                        </div>
                      </div>
                    ) : (
                      <div style={{
                        padding: '0.75rem',
                        backgroundColor: 'white',
                        borderRadius: '0.5rem',
                        border: '1px solid #fde68a',
                        textAlign: 'center'
                      }}>
                        <div style={{ fontSize: '0.875rem', color: '#92400e', fontStyle: 'italic' }}>
                          This property is not assigned to any project
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Parent Property Information */}
                  {selectedProperty.parentPropertyId && selectedProperty.parentProperty && (
                    <div style={{
                      padding: '1.5rem',
                      backgroundColor: '#e0e7ff',
                      borderRadius: '0.75rem',
                      border: '2px solid #6366f1',
                      boxShadow: '0 4px 6px -1px rgba(99, 102, 241, 0.2)',
                      gridColumn: 'span 2' // Span full width
                    }}>
                      <h3 style={{
                        fontSize: '1.25rem',
                        fontWeight: '600',
                        color: '#111827',
                        marginBottom: '1rem',
                        display: 'flex',
                        alignItems: 'center',
                        gap: '0.5rem'
                      }}>
                        <Home style={{ height: '1.25rem', width: '1.25rem', color: '#4338ca' }} />
                        Parent Property Information
                      </h3>
                      <div style={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                        gap: '1rem',
                        marginBottom: '1rem'
                      }}>
                        {selectedProperty.parentProperty.projectName && (
                          <div>
                            <div style={{ fontSize: '0.75rem', color: '#4338ca', fontWeight: '600', marginBottom: '0.25rem' }}>
                              Project Name
                            </div>
                            <div style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>
                              {selectedProperty.parentProperty.projectName}
                            </div>
                          </div>
                        )}
                        {selectedProperty.parentProperty.type && (
                          <div>
                            <div style={{ fontSize: '0.75rem', color: '#4338ca', fontWeight: '600', marginBottom: '0.25rem' }}>
                              Property Type
                            </div>
                            <div style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>
                              {selectedProperty.parentProperty.type}
                            </div>
                          </div>
                        )}
                        {selectedProperty.parentProperty.bedrooms !== undefined && (
                          <div>
                            <div style={{ fontSize: '0.75rem', color: '#4338ca', fontWeight: '600', marginBottom: '0.25rem' }}>
                              Bedrooms
                            </div>
                            <div style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>
                              {selectedProperty.parentProperty.bedrooms}
                            </div>
                          </div>
                        )}
                        {selectedProperty.parentProperty.bathrooms !== undefined && (
                          <div>
                            <div style={{ fontSize: '0.75rem', color: '#4338ca', fontWeight: '600', marginBottom: '0.25rem' }}>
                              Bathrooms
                            </div>
                            <div style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>
                              {selectedProperty.parentProperty.bathrooms}
                            </div>
                          </div>
                        )}
                        {selectedProperty.parentProperty.areaSqm !== undefined && (
                          <div>
                            <div style={{ fontSize: '0.75rem', color: '#4338ca', fontWeight: '600', marginBottom: '0.25rem' }}>
                              Area
                            </div>
                            <div style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>
                              {selectedProperty.parentProperty.areaSqm} sqm
                            </div>
                          </div>
                        )}
                        {selectedProperty.parentProperty.finishingType && (
                          <div>
                            <div style={{ fontSize: '0.75rem', color: '#4338ca', fontWeight: '600', marginBottom: '0.25rem' }}>
                              Finishing Type
                            </div>
                            <div style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>
                              {selectedProperty.parentProperty.finishingType}
                            </div>
                          </div>
                        )}
                      </div>
                      <div style={{
                        padding: '0.75rem',
                        backgroundColor: 'white',
                        borderRadius: '0.5rem',
                        border: '1px solid #c7d2fe'
                      }}>
                        <div style={{ fontSize: '0.75rem', color: '#4338ca', fontWeight: '600', marginBottom: '0.25rem' }}>
                          Parent Property ID
                        </div>
                        <div style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827' }}>
                          #{selectedProperty.parentPropertyId}
                        </div>
                      </div>
                    </div>
                  )}
                </div>

                {/* Auction Information */}
                {selectedProperty.auctions && selectedProperty.auctions.length > 0 ? (
                  <div style={{
                    padding: '1.5rem',
                    backgroundColor: '#eff6ff',
                    borderRadius: '0.75rem',
                    border: '1px solid #dbeafe',
                    marginBottom: '2rem'
                  }}>
                    <h3 style={{
                      fontSize: '1.25rem',
                      fontWeight: '600',
                      color: '#111827',
                      marginBottom: '1.5rem',
                      display: 'flex',
                      alignItems: 'center',
                      gap: '0.5rem'
                    }}>
                      <DollarSign style={{ height: '1.25rem', width: '1.25rem', color: '#3b82f6' }} />
                      Auction Information ({selectedProperty.auctions.length} auction{selectedProperty.auctions.length > 1 ? 's' : ''})
                    </h3>
                    {selectedProperty.auctions.map((auction: any, index: number) => {
                      const startAt = new Date(auction.startAt || auction.StartAt);
                      const duration = auction.duration || auction.Duration || 0;
                      const endAt = new Date(startAt.getTime() + duration * 3600000);
                      const isActive = auction.status === 'Active' && new Date() >= startAt && new Date() <= endAt;
                      const isEnded = auction.status === 'Ended' || (auction.status === 'Active' && new Date() > endAt);
                      
                      return (
                        <div key={index} style={{
                          padding: '1.25rem',
                          backgroundColor: 'white',
                          borderRadius: '0.5rem',
                          marginBottom: index < selectedProperty.auctions.length - 1 ? '1rem' : 0,
                          border: '1px solid #dbeafe'
                        }}>
                          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'start', marginBottom: '1rem' }}>
                            <div>
                              <div style={{ fontSize: '0.875rem', color: '#6b7280', marginBottom: '0.25rem' }}>Auction #{auction.auctionId || auction.AuctionId}</div>
                              <span style={{
                                fontSize: '0.75rem',
                                fontWeight: '600',
                                padding: '0.25rem 0.75rem',
                                borderRadius: '0.25rem',
                                backgroundColor: isActive ? '#dcfce7' : isEnded ? '#f3f4f6' : '#fef3c7',
                                color: isActive ? '#059669' : isEnded ? '#6b7280' : '#d97706'
                              }}>
                                {isActive ? '🔴 LIVE' : isEnded ? 'ENDED' : auction.status}
                              </span>
                            </div>
                            <div style={{ textAlign: 'right' }}>
                              <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Current Price</div>
                              <div style={{ fontSize: '1.5rem', fontWeight: '700', color: '#3b82f6' }}>
                                ${(auction.currentPrice || auction.CurrentPrice || 0).toLocaleString()}
                              </div>
                            </div>
                          </div>
                          
                          <div style={{
                            display: 'grid',
                            gridTemplateColumns: 'repeat(3, 1fr)',
                            gap: '1rem',
                            padding: '1rem',
                            backgroundColor: '#f8fafc',
                            borderRadius: '0.5rem'
                          }}>
                            <div>
                              <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Starting Price</div>
                              <div style={{ fontSize: '1rem', fontWeight: '600', color: '#111827' }}>
                                ${(auction.startPrice || auction.StartPrice || 0).toLocaleString()}
                              </div>
                            </div>
                            <div>
                              <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Total Bids</div>
                              <div style={{ fontSize: '1rem', fontWeight: '600', color: '#111827' }}>
                                {auction.bidCount || auction.BidCount || 0}
                              </div>
                            </div>
                            <div>
                              <div style={{ fontSize: '0.75rem', color: '#6b7280', marginBottom: '0.25rem' }}>Duration</div>
                              <div style={{ fontSize: '1rem', fontWeight: '600', color: '#111827' }}>
                                {duration} hours
                              </div>
                            </div>
                          </div>
                          
                          <div style={{ marginTop: '1rem', display: 'flex', gap: '1rem', fontSize: '0.875rem' }}>
                            <div>
                              <span style={{ color: '#6b7280' }}>Starts: </span>
                              <span style={{ fontWeight: '600', color: '#111827' }}>{startAt.toLocaleString()}</span>
                            </div>
                            <div>
                              <span style={{ color: '#6b7280' }}>Ends: </span>
                              <span style={{ fontWeight: '600', color: '#111827' }}>{endAt.toLocaleString()}</span>
                            </div>
                          </div>
                          
                          {/* Highest Bid */}
                          {auction.highestBid && (
                            <div style={{
                              marginTop: '1rem',
                              padding: '0.75rem',
                              backgroundColor: '#dcfce7',
                              borderRadius: '0.5rem',
                              display: 'flex',
                              alignItems: 'center',
                              gap: '0.5rem'
                            }}>
                              <Star style={{ height: '1.25rem', width: '1.25rem', color: '#059669' }} />
                              <div>
                                <div style={{ fontSize: '0.75rem', color: '#059669', fontWeight: '600', textTransform: 'uppercase' }}>
                                  Highest Bidder
                                </div>
                                <div style={{ fontSize: '0.875rem', fontWeight: '700', color: '#059669' }}>
                                  {auction.highestBid.bidderName || 
                                   (auction.highestBid.Bidder ? `${auction.highestBid.Bidder.FirstName} ${auction.highestBid.Bidder.LastName}` :
                                   (auction.highestBid.bidder ? `${auction.highestBid.bidder.firstName || auction.highestBid.bidder.FirstName} ${auction.highestBid.bidder.lastName || auction.highestBid.bidder.LastName}` : 'Unknown'))}
                                </div>
                              </div>
                            </div>
                          )}
                          
                          {/* Bids List */}
                          {auction.bids && auction.bids.length > 0 && (
                            <div style={{ marginTop: '1rem' }}>
                              <div style={{ fontSize: '0.875rem', fontWeight: '600', color: '#111827', marginBottom: '0.5rem' }}>
                                Recent Bids ({auction.bids.length})
                              </div>
                              <div style={{ maxHeight: '200px', overflowY: 'auto', border: '1px solid #e5e7eb', borderRadius: '0.5rem' }}>
                                {auction.bids.slice(0, 5).map((bid: any, bidIndex: number) => (
                                  <div key={bidIndex} style={{
                                    padding: '0.75rem',
                                    borderBottom: bidIndex < Math.min(auction.bids.length, 5) - 1 ? '1px solid #e5e7eb' : 'none',
                                    backgroundColor: bidIndex === 0 ? '#f0fdf4' : 'white',
                                    display: 'flex',
                                    justifyContent: 'space-between',
                                    alignItems: 'center'
                                  }}>
                                    <div>
                                      <div style={{ fontSize: '0.875rem', fontWeight: bidIndex === 0 ? '600' : '400', color: '#111827' }}>
                                        {bid.bidderName || 
                                         (bid.Bidder ? `${bid.Bidder.FirstName} ${bid.Bidder.LastName}` :
                                         (bid.bidder ? `${bid.bidder.firstName || bid.bidder.FirstName} ${bid.bidder.lastName || bid.bidder.LastName}` : 'Unknown'))}
                                      </div>
                                      <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>
                                        {new Date(bid.createdAt || bid.CreatedAt).toLocaleString()}
                                      </div>
                                    </div>
                                    <div style={{ fontSize: '1rem', fontWeight: '700', color: bidIndex === 0 ? '#059669' : '#111827' }}>
                                      ${(bid.bidAmount || bid.BidAmount || 0).toLocaleString()}
                                    </div>
                                  </div>
                                ))}
                              </div>
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div style={{
                    padding: '2rem',
                    textAlign: 'center',
                    backgroundColor: '#f9fafb',
                    borderRadius: '0.75rem',
                    border: '2px dashed #e5e7eb',
                    marginBottom: '2rem'
                  }}>
                    <Clock style={{ height: '3rem', width: '3rem', color: '#d1d5db', margin: '0 auto 1rem' }} />
                    <p style={{ margin: 0, fontSize: '1rem', fontWeight: '600', color: '#6b7280' }}>No Active Auctions</p>
                    <p style={{ margin: '0.5rem 0 0 0', fontSize: '0.875rem', color: '#9ca3af' }}>
                      This property is not currently listed in any auctions
                    </p>
                  </div>
                )}

                {/* Property Documents & Images Section */}
                <div style={{
                  padding: '1.5rem',
                  backgroundColor: '#fef3c7',
                  borderRadius: '0.75rem',
                  border: '2px solid #fbbf24',
                  marginBottom: '2rem'
                }}>
                  <h3 style={{
                    fontSize: '1.25rem',
                    fontWeight: '600',
                    color: '#111827',
                    marginBottom: '1rem',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem'
                  }}>
                    📄 Property Documents & Images
                  </h3>
                  <p style={{
                    fontSize: '0.875rem',
                    color: '#92400e',
                    marginBottom: '1rem'
                  }}>
                    Review uploaded property documents, title deeds, legal papers, and property images
                  </p>
                  <PropertyDocumentsManager 
                    propertyId={selectedProperty.propertyId}
                    propertyName={selectedProperty.name}
                  />
                </div>

                {/* Action Buttons Footer */}
                <div style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  paddingTop: '1.5rem',
                  marginTop: '1.5rem',
                  borderTop: '2px solid #e5e7eb'
                }}>
                  <div style={{ display: 'flex', gap: '0.75rem' }}>
                    {!selectedProperty.isApproved && userRole === 'Admin' && (
                      <>
                        <button
                          onClick={() => {
                            handleApproveProperty(selectedProperty.propertyId);
                            setShowDetailsModal(false);
                          }}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            padding: '0.75rem 1.5rem',
                            backgroundColor: '#059669',
                            color: 'white',
                            border: 'none',
                            borderRadius: '0.5rem',
                            cursor: 'pointer',
                            fontSize: '0.875rem',
                            fontWeight: '600',
                            transition: 'all 0.2s',
                            boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
                          }}
                        >
                          <CheckCircle style={{ height: '1.25rem', width: '1.25rem' }} />
                          Approve Property
                        </button>
                        <button
                          onClick={() => {
                            handleRejectProperty(selectedProperty.propertyId);
                            setShowDetailsModal(false);
                          }}
                          style={{
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem',
                            padding: '0.75rem 1.5rem',
                            backgroundColor: '#dc2626',
                            color: 'white',
                            border: 'none',
                            borderRadius: '0.5rem',
                            cursor: 'pointer',
                            fontSize: '0.875rem',
                            fontWeight: '600',
                            transition: 'all 0.2s',
                            boxShadow: '0 2px 4px rgba(0,0,0,0.1)'
                          }}
                        >
                          <XCircle style={{ height: '1.25rem', width: '1.25rem' }} />
                          Reject Property
                        </button>
                      </>
                    )}
                  </div>
                  <button
                    onClick={() => setShowDetailsModal(false)}
                    style={{
                      padding: '0.75rem 2rem',
                      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                      color: 'white',
                      border: 'none',
                      borderRadius: '0.5rem',
                      cursor: 'pointer',
                      fontSize: '1rem',
                      fontWeight: '600',
                      transition: 'all 0.2s',
                      boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
                    }}
                  >
                    Close
                  </button>
                </div>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
};

export default PropertiesPage;