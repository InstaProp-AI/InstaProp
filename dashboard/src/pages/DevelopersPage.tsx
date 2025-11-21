import React, { useState, useEffect } from 'react';
import { 
  Users, 
  Search, 
  Filter, 
  Mail, 
  Phone, 
  MapPin, 
  Calendar, 
  Edit, 
  Shield,
  CheckCircle,
  XCircle,
  Settings,
  Eye,
  Building,
  TrendingUp,
  Award,
  MoreVertical,
  Download
} from 'lucide-react';
import { Account, DeveloperPermissions, FeatureName, ROLE_IDS } from '../types';
import { usersApi, permissionsApi, propertiesApi, projectsApi, api } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import Pagination from '../components/Pagination';

const DevelopersPage: React.FC = () => {
  const toast = useToast();
  const [developers, setDevelopers] = useState<Account[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(10);
  const [totalCount, setTotalCount] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [selectedDeveloper, setSelectedDeveloper] = useState<Account | null>(null);
  const [showPermissionsModal, setShowPermissionsModal] = useState(false);
  const [developerPermissions, setDeveloperPermissions] = useState<DeveloperPermissions | null>(null);
  const [loadingPermissions, setLoadingPermissions] = useState(false);
  const [developerStats, setDeveloperStats] = useState<Map<number, { properties: number; projects: number }>>(new Map());

  useEffect(() => {
    fetchDevelopers();
  }, [currentPage, itemsPerPage]);

  const fetchDevelopers = async () => {
    try {
      setLoading(true);
      // Use dedicated developers endpoint
      const response = await api.get(`/admin/developers?page=${currentPage}&pageSize=${itemsPerPage}`);
      const paginatedResponse = response.data;
      
      setDevelopers(paginatedResponse.data || []);
      setTotalCount(paginatedResponse.pagination?.totalCount || 0);
      setTotalPages(paginatedResponse.pagination?.totalPages || 0);
      
      // Fetch stats for each developer
      fetchDeveloperStats(paginatedResponse.data || []);
      
      if (currentPage === 1 && paginatedResponse.pagination?.totalCount > 0) {
        toast.success(`Loaded ${paginatedResponse.pagination.totalCount} total developers`);
      }
    } catch (error: any) {
      console.error('Error fetching developers:', error);
      toast.error(error?.response?.data?.message || 'Failed to load developers');
    } finally {
      setLoading(false);
    }
  };

  const fetchDeveloperStats = async (devs: Account[]) => {
    const statsMap = new Map<number, { properties: number; projects: number }>();
    
    for (const dev of devs) {
      try {
        const [propertiesRes, projectsRes] = await Promise.all([
          propertiesApi.getProperties('Developer').catch(() => []),
          projectsApi.getProjects().catch(() => [])
        ]);
        
        const properties = Array.isArray(propertiesRes) ? propertiesRes : [];
        const projects = Array.isArray(projectsRes) ? projectsRes : [];
        
        // Filter for this developer's data
        const devProperties = properties.filter((p: any) => p.ownerId === dev.accountId);
        const devProjects = projects.filter((p: any) => p.developerId === dev.accountId);
        
        statsMap.set(dev.accountId, {
          properties: devProperties.length,
          projects: devProjects.length
        });
      } catch (error) {
        console.error(`Error fetching stats for developer ${dev.accountId}:`, error);
        statsMap.set(dev.accountId, { properties: 0, projects: 0 });
      }
    }
    
    setDeveloperStats(statsMap);
  };

  const handleOpenPermissions = async (developer: Account) => {
    setSelectedDeveloper(developer);
    setShowPermissionsModal(true);
    
    try {
      setLoadingPermissions(true);
      const permissions = await permissionsApi.getDeveloperPermissions(developer.accountId);
      setDeveloperPermissions(permissions);
    } catch (error: any) {
      console.error('Error loading permissions:', error);
      toast.error(error?.response?.data?.message || 'Failed to load permissions');
    } finally {
      setLoadingPermissions(false);
    }
  };

  const handleSavePermissions = async () => {
    if (!selectedDeveloper || !developerPermissions) return;

    try {
      setLoadingPermissions(true);
      await permissionsApi.updateDeveloperPermissions(selectedDeveloper.accountId, developerPermissions);
      toast.success('Permissions updated successfully!');
      setShowPermissionsModal(false);
    } catch (error: any) {
      console.error('Error saving permissions:', error);
      toast.error(error?.response?.data?.message || 'Failed to save permissions');
    } finally {
      setLoadingPermissions(false);
    }
  };

  const filteredDevelopers = developers.filter(dev => {
    const matchesSearch = 
      !searchTerm ||
      dev.firstName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      dev.lastName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      dev.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      dev.phoneNumber.includes(searchTerm);
    const matchesStatus = filterStatus === 'all' 
      ? true 
      : filterStatus === 'suspended' 
        ? Boolean(dev.isSuspended) === true 
        : dev.status === filterStatus;
    
    return matchesSearch && matchesStatus;
  });

  const optionalFeatures: FeatureName[] = [
    'Communities', 'News', 'Auctions', 'Leaderboard', 'Notifications', 
    'PriceHistory', 'FullAnalytics', 'Rewards', 'Valuation', 'Chats'
  ];

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '50vh' }}>
        <div style={{
          width: '3rem',
          height: '3rem',
          border: '3px solid #e2e8f0',
          borderTop: '3px solid #667eea',
          borderRadius: '50%',
          animation: 'spin 1s linear infinite'
        }} />
        <style>{`@keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }`}</style>
      </div>
    );
  }

  return (
    <div style={{ padding: '2rem' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h1 style={{ fontSize: '1.875rem', fontWeight: '700', color: '#111827', marginBottom: '0.5rem' }}>
            Developers Management
          </h1>
          <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>
            Manage developers and configure their feature permissions
          </p>
        </div>
      </div>

      {/* Filters */}
      <div style={{
        display: 'flex',
        gap: '1rem',
        marginBottom: '1.5rem',
        padding: '1rem',
        backgroundColor: 'white',
        borderRadius: '0.75rem',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
      }}>
        <div style={{ flex: 1, position: 'relative' }}>
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
            placeholder="Search developers..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            style={{
              width: '100%',
              padding: '0.5rem 0.75rem 0.5rem 2.5rem',
              border: '1px solid #d1d5db',
              borderRadius: '0.5rem',
              fontSize: '0.875rem',
              outline: 'none',
              transition: 'all 0.2s'
            }}
            onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
            onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
          />
        </div>
        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          style={{
            padding: '0.5rem 1rem',
            border: '1px solid #d1d5db',
            borderRadius: '0.5rem',
            fontSize: '0.875rem',
            outline: 'none',
            cursor: 'pointer'
          }}
        >
          <option value="all">All Status</option>
          <option value="Verified">Verified</option>
          <option value="Pending">Pending</option>
          <option value="NotVerified">Not Verified</option>
          <option value="suspended">Suspended</option>
        </select>
      </div>

      {/* Developers List */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '0.75rem',
        boxShadow: '0 1px 3px rgba(0,0,0,0.1)',
        overflow: 'hidden'
      }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ backgroundColor: '#f9fafb', borderBottom: '2px solid #e5e7eb' }}>
              <th style={{ padding: '0.75rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase' }}>Developer</th>
              <th style={{ padding: '0.75rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase' }}>Contact</th>
              <th style={{ padding: '0.75rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase' }}>Stats</th>
              <th style={{ padding: '0.75rem 1rem', textAlign: 'left', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase' }}>Status</th>
              <th style={{ padding: '0.75rem 1rem', textAlign: 'right', fontSize: '0.75rem', fontWeight: '500', color: '#6b7280', textTransform: 'uppercase' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {filteredDevelopers.map((dev) => {
              const stats = developerStats.get(dev.accountId) || { properties: 0, projects: 0 };
              return (
                <tr key={dev.accountId} style={{ borderBottom: '1px solid #e5e7eb' }}>
                  <td style={{ padding: '1rem' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                      <div style={{
                        width: '2.5rem',
                        height: '2.5rem',
                        borderRadius: '50%',
                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        color: 'white',
                        fontWeight: '600',
                        fontSize: '0.875rem'
                      }}>
                        {dev.firstName[0]}{dev.lastName[0]}
                      </div>
                      <div>
                        <div style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827' }}>
                          {dev.firstName} {dev.lastName}
                        </div>
                        <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>
                          ID: #{dev.accountId}
                        </div>
                      </div>
                    </div>
                  </td>
                  <td style={{ padding: '1rem' }}>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '0.25rem', fontSize: '0.75rem', color: '#6b7280' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <Mail style={{ height: '0.875rem', width: '0.875rem' }} />
                        {dev.email}
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <Phone style={{ height: '0.875rem', width: '0.875rem' }} />
                        {dev.phoneNumber}
                      </div>
                    </div>
                  </td>
                  <td style={{ padding: '1rem' }}>
                    <div style={{ display: 'flex', gap: '1rem', fontSize: '0.75rem' }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', color: '#2563eb' }}>
                        <Building style={{ height: '0.875rem', width: '0.875rem' }} />
                        <span style={{ fontWeight: '500' }}>{stats.projects}</span> Projects
                      </div>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.25rem', color: '#059669' }}>
                        <TrendingUp style={{ height: '0.875rem', width: '0.875rem' }} />
                        <span style={{ fontWeight: '500' }}>{stats.properties}</span> Properties
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
                      backgroundColor: dev.status === 'Verified' ? '#dcfce7' : dev.isSuspended ? '#fef2f2' : '#fef3c7',
                      color: dev.status === 'Verified' ? '#059669' : dev.isSuspended ? '#dc2626' : '#d97706',
                      fontSize: '0.75rem',
                      fontWeight: '500'
                    }}>
                      {dev.isSuspended ? (
                        <>
                          <XCircle style={{ height: '0.875rem', width: '0.875rem' }} />
                          Suspended
                        </>
                      ) : (
                        <>
                          <CheckCircle style={{ height: '0.875rem', width: '0.875rem' }} />
                          {dev.status}
                        </>
                      )}
                    </div>
                  </td>
                  <td style={{ padding: '1rem', textAlign: 'right' }}>
                    <button
                      onClick={() => handleOpenPermissions(dev)}
                      style={{
                        display: 'inline-flex',
                        alignItems: 'center',
                        gap: '0.5rem',
                        padding: '0.5rem 1rem',
                        backgroundColor: '#667eea',
                        color: 'white',
                        border: 'none',
                        borderRadius: '0.5rem',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        cursor: 'pointer',
                        transition: 'all 0.2s'
                      }}
                      onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#5568d3'}
                      onMouseLeave={(e) => e.currentTarget.style.backgroundColor = '#667eea'}
                    >
                      <Shield style={{ height: '1rem', width: '1rem' }} />
                      Permissions
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        {filteredDevelopers.length === 0 && (
          <div style={{ textAlign: 'center', padding: '3rem 2rem' }}>
            <Users style={{ margin: '0 auto 1rem auto', height: '3rem', width: '3rem', color: '#9ca3af' }} />
            <h3 style={{ fontSize: '1.125rem', fontWeight: '600', color: '#111827', marginBottom: '0.5rem' }}>
              No developers found
            </h3>
            <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>
              {searchTerm ? 'Try adjusting your search criteria' : 'No developers have been registered yet'}
            </p>
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
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

      {/* Permissions Modal */}
      {showPermissionsModal && selectedDeveloper && (
        <div style={{
          position: 'fixed',
          inset: 0,
          backgroundColor: 'rgba(0,0,0,0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 1000,
          padding: '1rem'
        }} onClick={() => setShowPermissionsModal(false)}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '0.75rem',
            maxWidth: '600px',
            width: '100%',
            maxHeight: '90vh',
            overflow: 'auto',
            boxShadow: '0 20px 25px -5px rgba(0,0,0,0.1)'
          }} onClick={(e) => e.stopPropagation()}>
            <div style={{ padding: '1.5rem', borderBottom: '1px solid #e5e7eb' }}>
              <h2 style={{ fontSize: '1.5rem', fontWeight: '600', color: '#111827', marginBottom: '0.5rem' }}>
                Manage Permissions
              </h2>
              <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>
                {selectedDeveloper.firstName} {selectedDeveloper.lastName} ({selectedDeveloper.email})
              </p>
            </div>

            <div style={{ padding: '1.5rem' }}>
              {loadingPermissions ? (
                <div style={{ display: 'flex', justifyContent: 'center', padding: '2rem' }}>
                  <div style={{
                    width: '2rem',
                    height: '2rem',
                    border: '3px solid #e2e8f0',
                    borderTop: '3px solid #667eea',
                    borderRadius: '50%',
                    animation: 'spin 1s linear infinite'
                  }} />
                </div>
              ) : (
                <>
                  <div style={{
                    backgroundColor: '#dbeafe',
                    borderRadius: '0.75rem',
                    border: '2px solid #3b82f6',
                    padding: '1rem',
                    marginBottom: '1.5rem'
                  }}>
                    <p style={{ fontSize: '0.875rem', color: '#1e40af', margin: 0 }}>
                      <strong>Default Features:</strong> Projects, Properties, and Analytics are always enabled for all developers.
                    </p>
                  </div>

                  <div style={{ display: 'grid', gap: '1rem' }}>
                    {optionalFeatures.map((feature) => (
                      <label
                        key={feature}
                        style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          padding: '1rem',
                          backgroundColor: '#ffffff',
                          border: '1px solid #e5e7eb',
                          borderRadius: '0.5rem',
                          cursor: 'pointer',
                          transition: 'all 0.2s'
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.backgroundColor = '#f9fafb'}
                        onMouseLeave={(e) => e.currentTarget.style.backgroundColor = '#ffffff'}
                      >
                        <div>
                          <div style={{ fontWeight: '500', color: '#111827', marginBottom: '0.25rem' }}>
                            {feature}
                          </div>
                          <div style={{ fontSize: '0.75rem', color: '#6b7280' }}>
                            Allow this developer to access {feature}
                          </div>
                        </div>
                        <input
                          type="checkbox"
                          checked={developerPermissions?.[feature] || false}
                          onChange={(e) => {
                            setDeveloperPermissions(prev => ({
                              ...prev!,
                              [feature]: e.target.checked
                            }));
                          }}
                          style={{
                            width: '1.25rem',
                            height: '1.25rem',
                            accentColor: '#667eea',
                            cursor: 'pointer'
                          }}
                        />
                      </label>
                    ))}
                  </div>

                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '1rem', marginTop: '2rem' }}>
                    <button
                      onClick={() => setShowPermissionsModal(false)}
                      style={{
                        padding: '0.75rem 1.5rem',
                        backgroundColor: '#f3f4f6',
                        color: '#374151',
                        border: '1px solid #d1d5db',
                        borderRadius: '0.5rem',
                        cursor: 'pointer',
                        fontSize: '0.875rem',
                        fontWeight: '500'
                      }}
                    >
                      Cancel
                    </button>
                    <button
                      onClick={handleSavePermissions}
                      disabled={loadingPermissions}
                      style={{
                        padding: '0.75rem 1.5rem',
                        background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                        color: 'white',
                        border: 'none',
                        borderRadius: '0.5rem',
                        cursor: loadingPermissions ? 'not-allowed' : 'pointer',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        opacity: loadingPermissions ? 0.7 : 1
                      }}
                    >
                      {loadingPermissions ? 'Saving...' : 'Save Permissions'}
                    </button>
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DevelopersPage;

