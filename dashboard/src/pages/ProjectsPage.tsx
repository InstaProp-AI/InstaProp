import React, { useState, useEffect } from 'react';
import { 
  Plus, 
  FolderOpen, 
  MapPin, 
  Calendar, 
  Edit, 
  Trash2,
  Eye,
  Home,
  TrendingUp,
  DollarSign,
  Users,
  BarChart3,
  CheckCircle,
  XCircle,
  Clock,
  Search,
  Filter,
  Download,
  RefreshCw,
  Building,
  Hammer,
  ChevronRight,
  AlertCircle
} from 'lucide-react';
import { Project, Property } from '../types';
import { projectsApi, propertiesApi, authApi } from '../services/api';
import { withTimeout } from '../utils/apiTimeout';
import { useToast } from '../contexts/ToastContext';

const ProjectsPage: React.FC = () => {
  const toast = useToast();
  const [projects, setProjects] = useState<Project[]>([]);
  const [properties, setProperties] = useState<Property[]>([]);
  const [loading, setLoading] = useState(true);
  const [userRole, setUserRole] = useState<'Admin' | 'Developer' | null>(null);
  const [userLoadError, setUserLoadError] = useState<string | null>(null);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showDetailsModal, setShowDetailsModal] = useState(false);
  const [selectedProject, setSelectedProject] = useState<Project | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [gridColumns, setGridColumns] = useState(4);
  
  // Property filters in details modal
  const [propertySearchTerm, setPropertySearchTerm] = useState('');
  const [propertyStatusFilter, setPropertyStatusFilter] = useState('all');
  const [propertyBedroomsFilter, setPropertyBedroomsFilter] = useState('all');
  
  const [newProject, setNewProject] = useState({
    name: '',
    description: '',
    location: '',
  });

  const [editProject, setEditProject] = useState({
    name: '',
    description: '',
    location: '',
  });

  useEffect(() => {
    // Get current user to determine role with timeout
    const loadUser = async () => {
      try {
        setLoading(true);
        setUserLoadError(null);
        
        const currentUser = await withTimeout(
          authApi.getCurrentAccount(),
          10000,
          'Unable to load user information. The server may be slow or unavailable.'
        );
        
        // Check roleName first (from backend), then roleId, then legacy type
        const isAdmin = currentUser.roleName === 'Admin' || currentUser.roleId === 9823749823749823 || currentUser.type === 'Admin';
        const isDeveloper = currentUser.roleName === 'Developer' || currentUser.roleId === 7823647823647823 || currentUser.type === 'Developer';
        const role = isAdmin ? 'Admin' : (isDeveloper ? 'Developer' : null);
        
        setUserRole(role);
        setUserLoadError(null);
        
        if (!role) {
          setUserLoadError('Your account does not have permission to access projects. Please contact an administrator.');
          console.error('Current user role:', { roleName: currentUser.roleName, roleId: currentUser.roleId, type: currentUser.type });
          setLoading(false);
        }
      } catch (error: any) {
        console.error('Error loading user:', error);
        
        // Check if it's a 401 (unauthorized) or token issue
        if (error.response?.status === 401 || error.message?.includes('401') || error.message?.includes('Unauthorized')) {
          setUserLoadError('Your session has expired. Please refresh the page or log in again.');
          // Clear token if invalid
          localStorage.removeItem('authToken');
        } else if (error.response?.status === 403 || error.message?.includes('403')) {
          setUserLoadError('You do not have permission to access this page. Please contact an administrator.');
        } else {
          setUserLoadError(error.message || 'Unable to load user information. Please refresh the page or log in again.');
        }
        
        setUserRole(null);
        setLoading(false);
      }
    };
    
    loadUser();
  }, []);

  useEffect(() => {
    if (userRole) {
      fetchData();
    }
  }, [userRole]);

  const fetchData = async () => {
    if (!userRole) return;
    try {
      setLoading(true);
      setUserLoadError(null); // Clear any previous errors
      
      const [projectsData, propertiesResponse] = await Promise.all([
        withTimeout(
          projectsApi.getProjects(),
          10000,
          'Request took too long. The server may be slow or unavailable.'
        ),
        withTimeout(
          propertiesApi.getProperties(userRole),
          10000,
          'Request took too long. The server may be slow or unavailable.'
        )
      ]);
      
      // Handle both paginated (Admin) and non-paginated (Developer) responses
      let propertiesData: Property[];
      if (userRole === 'Admin' && 'data' in propertiesResponse && 'pagination' in propertiesResponse) {
        propertiesData = (propertiesResponse as any).data || [];
      } else {
        propertiesData = propertiesResponse as Property[];
      }
      
      console.log('📁 Projects loaded:', projectsData.length);
      console.log('🏠 Properties loaded:', propertiesData.length);
      
      setProjects(projectsData);
      setProperties(propertiesData);
    } catch (error: any) {
      console.error('Error fetching data:', error);
      
      // Check if it's an authentication error
      if (error.response?.status === 401 || error.message?.includes('401') || error.message?.includes('Unauthorized')) {
        setUserLoadError('Your session has expired. Please refresh the page or log in again.');
        localStorage.removeItem('authToken');
        setUserRole(null);
      } else if (error.response?.status === 403 || error.message?.includes('403')) {
        setUserLoadError('You do not have permission to access this page. Please contact an administrator.');
      } else {
        let errorMessage = 'Failed to load data';
        if (error.message && error.message.includes('timed out')) {
          errorMessage = error.message;
        } else if (error.message && error.message.includes('Cannot connect')) {
          errorMessage = 'Cannot connect to server. Please check your connection and ensure the API is running.';
        } else {
          errorMessage = error?.response?.data?.message || error.message || errorMessage;
        }
        toast.error(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleCreateProject = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!newProject.name.trim()) {
      toast.error('Project name is required');
      return;
    }

    try {
      await projectsApi.createProject(newProject);
      toast.success('Project created successfully!');
      setNewProject({ name: '', description: '', location: '' });
      setShowCreateModal(false);
      fetchData();
    } catch (error: any) {
      console.error('Failed to create project:', error);
      toast.error(error?.response?.data?.message || 'Failed to create project');
    }
  };

  const handleEditProject = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!selectedProject || !editProject.name.trim()) {
      toast.error('Project name is required');
      return;
    }

    try {
      await projectsApi.updateProject(selectedProject.projectId, editProject);
      toast.success('Project updated successfully!');
      setShowEditModal(false);
      setSelectedProject(null);
      fetchData();
    } catch (error: any) {
      console.error('Failed to update project:', error);
      toast.error(error?.response?.data?.message || 'Failed to update project');
    }
  };

  const handleDeleteProject = async (project: Project) => {
    const projectProperties = getProjectProperties(project.projectId);
    
    if (projectProperties.length > 0) {
      if (!window.confirm(`This project has ${projectProperties.length} properties. Are you sure you want to delete it? The properties will not be deleted but will become unassigned.`)) {
        return;
      }
    } else {
      if (!window.confirm(`Are you sure you want to delete "${project.name}"?`)) {
        return;
      }
    }

    try {
      await projectsApi.deleteProject(project.projectId);
      toast.success('Project deleted successfully!');
      fetchData();
    } catch (error: any) {
        console.error('Failed to delete project:', error);
      toast.error(error?.response?.data?.message || 'Failed to delete project');
    }
  };

  const openEditModal = (project: Project) => {
    setSelectedProject(project);
    setEditProject({
      name: project.name,
      description: project.description || '',
      location: project.location || '',
    });
    setShowEditModal(true);
  };

  const openDetailsModal = (project: Project) => {
    setSelectedProject(project);
    setShowDetailsModal(true);
    // Reset filters when opening modal
    setPropertySearchTerm('');
    setPropertyStatusFilter('all');
    setPropertyBedroomsFilter('all');
  };

  const getProjectProperties = (projectId: number): Property[] => {
    return properties.filter(p => p.projectId === projectId);
  };

  const getUnassignedProperties = (): Property[] => {
    return properties.filter(p => !p.projectId);
  };

  const filterProperties = (props: Property[]): Property[] => {
    return props.filter(prop => {
      const matchesSearch = propertySearchTerm === '' || 
        prop.name?.toLowerCase().includes(propertySearchTerm.toLowerCase()) ||
        prop.location?.toLowerCase().includes(propertySearchTerm.toLowerCase());
      
      const matchesStatus = propertyStatusFilter === 'all' || prop.status === propertyStatusFilter;
      
      const matchesBedrooms = propertyBedroomsFilter === 'all' || 
        (propertyBedroomsFilter === '1' && prop.bedrooms === 1) ||
        (propertyBedroomsFilter === '2' && prop.bedrooms === 2) ||
        (propertyBedroomsFilter === '3' && prop.bedrooms === 3) ||
        (propertyBedroomsFilter === '4+' && (prop.bedrooms || 0) >= 4);
      
      return matchesSearch && matchesStatus && matchesBedrooms;
    });
  };

  const getProjectStats = (projectId: number) => {
    const projectProps = getProjectProperties(projectId);
    const approved = projectProps.filter(p => p.status === 'Approved').length;
    const pending = projectProps.filter(p => p.status === 'Pending').length;
    const totalValue = projectProps.reduce((sum, p) => sum + (p.squareFeet * 100), 0); // Rough estimate
    
    return {
      total: projectProps.length,
      approved,
      pending,
      totalValue
    };
  };

  const handleAttachProperty = async (propertyId: number, projectId: number) => {
    try {
      console.log(`📎 Attaching property ${propertyId} to project ${projectId}`);
      // Update property to assign it to the project
      await propertiesApi.updateProperty(propertyId, { projectId });
      toast.success('Property added to project successfully!');
      fetchData(); // Refresh data
    } catch (error: any) {
      console.error('❌ Failed to attach property:', error);
      console.error('Error details:', error?.response?.data);
      toast.error(error?.response?.data?.message || error?.response?.data?.error || 'Failed to attach property');
    }
  };

  const handleDetachProperty = async (propertyId: number) => {
    if (!window.confirm('Are you sure you want to remove this property from the project?')) {
      return;
    }

    try {
      // Update property to remove project assignment by setting projectId to 0 (backend interprets this as null)
      await propertiesApi.updateProperty(propertyId, { projectId: 0 });
      toast.success('Property detached from project successfully!');
      fetchData(); // Refresh data
    } catch (error: any) {
      console.error('Failed to detach property:', error);
      toast.error(error?.response?.data?.message || error?.response?.data?.error || 'Failed to detach property');
    }
  };

  // Filter projects
  const filteredProjects = projects.filter(project => {
    const matchesSearch = project.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         (project.location?.toLowerCase() || '').includes(searchTerm.toLowerCase());
    
    const stats = getProjectStats(project.projectId);
    const matchesStatus = filterStatus === 'all' ||
                         (filterStatus === 'active' && stats.total > 0) ||
                         (filterStatus === 'inactive' && stats.total === 0);
    
    return matchesSearch && matchesStatus;
  });

  // Show error if user cannot be loaded
  if (userLoadError) {
    return (
      <div style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        minHeight: '50vh',
        flexDirection: 'column',
        gap: '1rem',
        padding: '2rem'
      }}>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', color: '#ef4444' }}>Error Loading Projects</h2>
        <p style={{ color: '#6b7280', textAlign: 'center', maxWidth: '500px' }}>{userLoadError}</p>
        <button
          onClick={() => window.location.reload()}
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
          Refresh Page
        </button>
      </div>
    );
  }

  if (loading && !userRole) {
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
          }}>Projects Management</h1>
          <p style={{
            fontSize: '1.125rem',
            color: '#6b7280',
            margin: 0
          }}>
            Manage development projects and their properties
          </p>
        </div>

        {/* Action Buttons */}
        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: '1rem',
          width: '100%',
          flexWrap: 'wrap'
        }}>
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
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-2px)';
              e.currentTarget.style.boxShadow = '0 10px 15px -3px rgba(0, 0, 0, 0.1)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1)';
            }}
          >
            <Plus style={{ height: '1.25rem', width: '1.25rem' }} />
            New Project
          </button>

          <button
            onClick={fetchData}
            disabled={loading}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: '0.5rem',
              backgroundColor: '#f3f4f6',
              color: '#6b7280',
              fontWeight: '500',
              padding: '0.75rem 1rem',
              borderRadius: '0.75rem',
              border: 'none',
              cursor: loading ? 'not-allowed' : 'pointer',
              transition: 'all 0.2s',
              opacity: loading ? 0.6 : 1
            }}
          >
            <RefreshCw style={{ height: '1rem', width: '1rem' }} />
            Refresh
          </button>

          {/* Grid Columns Selector */}
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
        </div>
      </div>

      {/* Filters */}
      <div style={{
        backgroundColor: 'white',
        borderRadius: '1rem',
        padding: '1.5rem',
        marginBottom: '2rem',
        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
        border: '1px solid #e5e7eb'
      }}>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))',
          gap: '1rem'
        }}>
          {/* Search */}
          <div style={{ position: 'relative' }}>
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
              placeholder="Search projects..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              style={{
                width: '100%',
                paddingLeft: '2.5rem',
                paddingRight: '0.75rem',
                paddingTop: '0.75rem',
                paddingBottom: '0.75rem',
                border: '1px solid #d1d5db',
                borderRadius: '0.75rem',
                fontSize: '0.875rem',
                outline: 'none'
              }}
            />
          </div>

          {/* Status Filter */}
          <div style={{ position: 'relative' }}>
            <Filter style={{
              position: 'absolute',
              left: '0.75rem',
              top: '50%',
              transform: 'translateY(-50%)',
              height: '1rem',
              width: '1rem',
              color: '#9ca3af'
            }} />
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              style={{
                width: '100%',
                paddingLeft: '2.5rem',
                paddingRight: '0.75rem',
                paddingTop: '0.75rem',
                paddingBottom: '0.75rem',
                border: '1px solid #d1d5db',
                borderRadius: '0.75rem',
                fontSize: '0.875rem',
                outline: 'none',
                backgroundColor: 'white'
              }}
            >
              <option value="all">All Projects</option>
              <option value="active">Active (Has Properties)</option>
              <option value="inactive">Inactive (No Properties)</option>
            </select>
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
        gap: '1.5rem',
        marginBottom: '2rem'
      }}>
        {[
          {
            title: 'Total Projects',
            value: projects.length,
            icon: FolderOpen,
            color: '#667eea',
            bgColor: '#e0e7ff'
          },
          {
            title: 'Total Properties',
            value: properties.length,
            icon: Home,
            color: '#8b5cf6',
            bgColor: '#ede9fe'
          },
          {
            title: 'Active Projects',
            value: projects.filter(p => getProjectStats(p.projectId).total > 0).length,
            icon: TrendingUp,
            color: '#10b981',
            bgColor: '#dcfce7'
          },
          {
            title: 'Approved Properties',
            value: properties.filter(p => p.status === 'Approved').length,
            icon: CheckCircle,
            color: '#059669',
            bgColor: '#d1fae5'
          }
        ].map((stat, index) => (
          <div key={index} style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            padding: '1.5rem',
            boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
            border: '1px solid #e5e7eb'
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              marginBottom: '1rem'
            }}>
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
            <h3 style={{
              fontSize: '2rem',
              fontWeight: 'bold',
              color: '#111827',
              margin: '0 0 0.25rem 0'
            }}>
              {stat.value}
            </h3>
            <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: 0 }}>
              {stat.title}
            </p>
          </div>
        ))}
      </div>

      {/* Projects Grid */}
      {filteredProjects.length > 0 ? (
      <div style={{
        display: 'grid',
        gridTemplateColumns: `repeat(${gridColumns}, 1fr)`,
        gap: '1.5rem',
        alignItems: 'stretch'
      }}>
          {filteredProjects.map((project) => {
            const stats = getProjectStats(project.projectId);
            const projectProps = getProjectProperties(project.projectId);

            return (
              <div 
                key={project.projectId} 
                style={{
                  backgroundColor: 'white',
                  borderRadius: '1rem',
                  overflow: 'hidden',
                  boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)',
                  border: '1px solid #e5e7eb',
                  transition: 'all 0.3s ease',
                  display: 'flex',
                  flexDirection: 'column',
                  height: '100%'
                }}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = 'translateY(-4px)';
                  e.currentTarget.style.boxShadow = '0 20px 25px -5px rgba(0, 0, 0, 0.1)';
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = 'translateY(0)';
                  e.currentTarget.style.boxShadow = '0 4px 6px -1px rgba(0, 0, 0, 0.1)';
                }}
              >
                {/* Project Header */}
                <div style={{
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  padding: '1.5rem',
                  color: 'white'
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'flex-start',
              justifyContent: 'space-between'
            }}>
              <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.5rem' }}>
                        <FolderOpen style={{ height: '1.5rem', width: '1.5rem' }} />
                  <h3 style={{
                          fontSize: '1.25rem',
                          fontWeight: '600',
                          margin: 0
                        }}>
                          {project.name}
                        </h3>
                </div>
                {project.location && (
                  <div style={{
                    display: 'flex',
                    alignItems: 'center',
                          gap: '0.25rem',
                    fontSize: '0.875rem',
                          opacity: 0.9
                  }}>
                          <MapPin style={{ height: '0.875rem', width: '0.875rem' }} />
                    {project.location}
                  </div>
                )}
                    </div>
                    <div style={{ display: 'flex', gap: '0.5rem' }}>
                      <button
                        onClick={() => openEditModal(project)}
                        style={{
                          color: 'white',
                          backgroundColor: 'rgba(255, 255, 255, 0.2)',
                          border: 'none',
                          cursor: 'pointer',
                          padding: '0.5rem',
                          borderRadius: '0.5rem',
                          transition: 'all 0.2s',
                  display: 'flex',
                          alignItems: 'center'
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'rgba(255, 255, 255, 0.3)'}
                        onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'rgba(255, 255, 255, 0.2)'}
                      >
                        <Edit style={{ height: '1rem', width: '1rem' }} />
                      </button>
                      <button 
                        onClick={() => handleDeleteProject(project)}
                        style={{
                          color: 'white',
                          backgroundColor: 'rgba(239, 68, 68, 0.8)',
                          border: 'none',
                          cursor: 'pointer',
                          padding: '0.5rem',
                          borderRadius: '0.5rem',
                          transition: 'all 0.2s',
                          display: 'flex',
                          alignItems: 'center'
                        }}
                        onMouseEnter={(e) => e.currentTarget.style.backgroundColor = 'rgba(220, 38, 38, 0.9)'}
                        onMouseLeave={(e) => e.currentTarget.style.backgroundColor = 'rgba(239, 68, 68, 0.8)'}
                      >
                        <Trash2 style={{ height: '1rem', width: '1rem' }} />
                      </button>
                    </div>
                  </div>
                </div>

                {/* Project Body */}
                <div style={{ padding: '1.5rem', flex: 1, display: 'flex', flexDirection: 'column' }}>
                  {/* Description */}
                  {project.description && (
                    <p style={{
                  fontSize: '0.875rem',
                      color: '#6b7280',
                      lineHeight: '1.5',
                      marginBottom: '1rem'
                    }}>
                      {project.description}
                    </p>
                  )}

                  {/* Stats */}
                  <div style={{
                    display: 'grid',
                    gridTemplateColumns: 'repeat(2, 1fr)',
                    gap: '1rem',
                    marginBottom: '1rem'
                  }}>
                    <div style={{
                      padding: '0.75rem',
                      backgroundColor: '#f9fafb',
                      borderRadius: '0.5rem',
                      border: '1px solid #e5e7eb'
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
                        <Home style={{ height: '1rem', width: '1rem', color: '#667eea' }} />
                        <span style={{ fontSize: '0.75rem', color: '#6b7280', fontWeight: '500' }}>
                          Total Properties
                        </span>
                </div>
                      <div style={{ fontSize: '1.5rem', fontWeight: '700', color: '#111827' }}>
                        {stats.total}
                      </div>
                    </div>

                <div style={{
                      padding: '0.75rem',
                      backgroundColor: '#f0fdf4',
                      borderRadius: '0.5rem',
                      border: '1px solid #dcfce7'
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
                        <CheckCircle style={{ height: '1rem', width: '1rem', color: '#10b981' }} />
                        <span style={{ fontSize: '0.75rem', color: '#065f46', fontWeight: '500' }}>
                          Approved
                        </span>
                      </div>
                      <div style={{ fontSize: '1.5rem', fontWeight: '700', color: '#059669' }}>
                        {stats.approved}
                      </div>
                    </div>

                    <div style={{
                      padding: '0.75rem',
                      backgroundColor: '#fef3c7',
                      borderRadius: '0.5rem',
                      border: '1px solid #fde68a'
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
                        <Clock style={{ height: '1rem', width: '1rem', color: '#f59e0b' }} />
                        <span style={{ fontSize: '0.75rem', color: '#92400e', fontWeight: '500' }}>
                          Pending
                        </span>
                      </div>
                      <div style={{ fontSize: '1.5rem', fontWeight: '700', color: '#d97706' }}>
                        {stats.pending}
                      </div>
                    </div>

                    <div style={{
                      padding: '0.75rem',
                      backgroundColor: '#ede9fe',
                      borderRadius: '0.5rem',
                      border: '1px solid #ddd6fe'
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '0.25rem' }}>
                        <DollarSign style={{ height: '1rem', width: '1rem', color: '#8b5cf6' }} />
                        <span style={{ fontSize: '0.75rem', color: '#5b21b6', fontWeight: '500' }}>
                          Est. Value
                        </span>
                      </div>
                      <div style={{ fontSize: '1.25rem', fontWeight: '700', color: '#7c3aed' }}>
                        ${(stats.totalValue / 1000000).toFixed(1)}M
                      </div>
                    </div>
                  </div>

                  {/* Property Preview */}
                  {projectProps.length > 0 && (
                    <div style={{
                      marginTop: '1rem',
                      padding: '0.75rem',
                      backgroundColor: '#f9fafb',
                      borderRadius: '0.5rem',
                      border: '1px solid #e5e7eb'
                    }}>
                      <div style={{
                        fontSize: '0.75rem',
                  color: '#6b7280',
                        fontWeight: '600',
                        marginBottom: '0.5rem',
                        textTransform: 'uppercase',
                        letterSpacing: '0.05em'
                }}>
                        Properties in this project:
                </div>
                      <div style={{
                        display: 'flex',
                        flexDirection: 'column',
                        gap: '0.5rem',
                        maxHeight: '120px',
                        overflowY: 'auto'
                      }}>
                        {projectProps.slice(0, 3).map((prop) => (
                          <div key={prop.propertyId} style={{
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'space-between',
                            padding: '0.5rem',
                            backgroundColor: 'white',
                            borderRadius: '0.375rem',
                            fontSize: '0.8125rem'
                          }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                              <Building style={{ height: '0.875rem', width: '0.875rem', color: '#667eea' }} />
                              <span style={{ color: '#111827', fontWeight: '500' }}>{prop.name}</span>
              </div>
                            <span style={{
                              padding: '0.125rem 0.5rem',
                  borderRadius: '0.25rem',
                              fontSize: '0.6875rem',
                              fontWeight: '600',
                              backgroundColor: prop.status === 'Approved' ? '#dcfce7' : '#fef3c7',
                              color: prop.status === 'Approved' ? '#059669' : '#d97706'
                            }}>
                              {prop.status}
                            </span>
                          </div>
                        ))}
                        {projectProps.length > 3 && (
                          <div style={{
                            fontSize: '0.75rem',
                            color: '#6b7280',
                            fontStyle: 'italic',
                            textAlign: 'center'
                          }}>
                            +{projectProps.length - 3} more properties
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                  {/* Created Date */}
                  <div style={{
                    marginTop: '1rem',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                    fontSize: '0.75rem',
                    color: '#9ca3af'
                  }}>
                    <Calendar style={{ height: '0.875rem', width: '0.875rem' }} />
                    Created {new Date(project.createdAt).toLocaleDateString()}
                  </div>

                  {/* View Details Button */}
                <button 
                    onClick={() => openDetailsModal(project)}
                  style={{
                      width: '100%',
                      marginTop: 'auto',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '0.5rem',
                      padding: '0.75rem',
                      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                      color: 'white',
                      fontWeight: '500',
                      fontSize: '0.875rem',
                    border: 'none',
                      borderRadius: '0.5rem',
                    cursor: 'pointer',
                    transition: 'all 0.2s'
                  }}
                    onMouseEnter={(e) => {
                      e.currentTarget.style.transform = 'translateY(-2px)';
                      e.currentTarget.style.boxShadow = '0 4px 12px rgba(102, 126, 234, 0.4)';
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.transform = 'translateY(0)';
                      e.currentTarget.style.boxShadow = 'none';
                    }}
                  >
                    <Eye style={{ height: '1rem', width: '1rem' }} />
                    View Full Details
                </button>
              </div>
            </div>
            );
          })}
          </div>
      ) : (
        <div style={{
          textAlign: 'center',
          padding: '4rem 2rem',
          backgroundColor: 'white',
          borderRadius: '1rem',
          boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
          border: '1px solid #e5e7eb'
        }}>
          <FolderOpen style={{
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
          }}>
            {searchTerm || filterStatus !== 'all' ? 'No projects found' : 'No projects yet'}
          </h3>
          <p style={{
            fontSize: '0.875rem',
            color: '#6b7280',
            marginBottom: '2rem'
          }}>
            {searchTerm || filterStatus !== 'all' 
              ? 'Try adjusting your filters to see more projects.'
              : 'Get started by creating your first development project.'
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
            Create First Project
            </button>
        </div>
      )}

      {/* Create Project Modal */}
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
              maxWidth: '32rem',
              width: '100%',
              overflow: 'hidden'
            }}>
              <form onSubmit={handleCreateProject}>
                {/* Modal Header */}
                <div style={{
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  padding: '1.5rem',
                  color: 'white'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <FolderOpen style={{ height: '1.5rem', width: '1.5rem' }} />
                    <h3 style={{ fontSize: '1.25rem', fontWeight: '600', margin: 0 }}>
                      Create New Project
                    </h3>
                  </div>
                  <p style={{ fontSize: '0.875rem', margin: '0.5rem 0 0 0', opacity: 0.9 }}>
                    Add a new development project to manage properties
                  </p>
                </div>

                {/* Modal Body */}
                <div style={{ padding: '1.5rem' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>
                        Project Name <span style={{ color: '#ef4444' }}>*</span>
                      </label>
                      <input
                        type="text"
                        required
                        placeholder="Enter project name"
                        style={{
                          width: '100%',
                          padding: '0.75rem 1rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.75rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={newProject.name}
                        onChange={(e) => setNewProject({ ...newProject, name: e.target.value })}
                        onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                        onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
                      />
                    </div>

                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>
                        Description
                      </label>
                      <textarea
                        placeholder="Describe the project..."
                        style={{
                          width: '100%',
                          padding: '0.75rem 1rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.75rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s',
                          resize: 'vertical',
                          minHeight: '100px'
                        }}
                        rows={4}
                        value={newProject.description}
                        onChange={(e) => setNewProject({ ...newProject, description: e.target.value })}
                        onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                        onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
                      />
                    </div>

                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>
                        Location
                      </label>
                      <div style={{ position: 'relative' }}>
                        <MapPin style={{
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
                          placeholder="Enter location"
                        style={{
                          width: '100%',
                            paddingLeft: '2.5rem',
                            paddingRight: '1rem',
                            paddingTop: '0.75rem',
                            paddingBottom: '0.75rem',
                          border: '1px solid #d1d5db',
                            borderRadius: '0.75rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                            transition: 'all 0.2s'
                        }}
                        value={newProject.location}
                        onChange={(e) => setNewProject({ ...newProject, location: e.target.value })}
                          onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                          onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
                      />
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
                  justifyContent: 'flex-end'
                }}>
                  <button
                    type="button"
                    onClick={() => {
                      setShowCreateModal(false);
                      setNewProject({ name: '', description: '', location: '' });
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
                      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
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
                    <Plus style={{ height: '1rem', width: '1rem' }} />
                    Create Project
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Edit Project Modal */}
      {showEditModal && selectedProject && (
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
              <form onSubmit={handleEditProject}>
                {/* Modal Header */}
                <div style={{
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  padding: '1.5rem',
                  color: 'white'
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem' }}>
                    <Edit style={{ height: '1.5rem', width: '1.5rem' }} />
                    <h3 style={{ fontSize: '1.25rem', fontWeight: '600', margin: 0 }}>
                      Edit Project
                    </h3>
                  </div>
                  <p style={{ fontSize: '0.875rem', margin: '0.5rem 0 0 0', opacity: 0.9 }}>
                    Update project information
                  </p>
                </div>

                {/* Modal Body */}
                <div style={{ padding: '1.5rem' }}>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1.25rem' }}>
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>
                        Project Name <span style={{ color: '#ef4444' }}>*</span>
                      </label>
                      <input
                        type="text"
                        required
                        placeholder="Enter project name"
                        style={{
                          width: '100%',
                          padding: '0.75rem 1rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.75rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s'
                        }}
                        value={editProject.name}
                        onChange={(e) => setEditProject({ ...editProject, name: e.target.value })}
                        onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                        onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
                      />
                    </div>

                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>
                        Description
                      </label>
                      <textarea
                        placeholder="Describe the project..."
                        style={{
                          width: '100%',
                          padding: '0.75rem 1rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.75rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s',
                          resize: 'vertical',
                          minHeight: '100px'
                        }}
                        rows={4}
                        value={editProject.description}
                        onChange={(e) => setEditProject({ ...editProject, description: e.target.value })}
                        onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                        onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
                      />
                    </div>

                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '600',
                        color: '#374151',
                        marginBottom: '0.5rem'
                      }}>
                        Location
                      </label>
                      <div style={{ position: 'relative' }}>
                        <MapPin style={{
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
                          placeholder="Enter location"
                          style={{
                            width: '100%',
                            paddingLeft: '2.5rem',
                            paddingRight: '1rem',
                            paddingTop: '0.75rem',
                            paddingBottom: '0.75rem',
                            border: '1px solid #d1d5db',
                            borderRadius: '0.75rem',
                            fontSize: '0.875rem',
                            outline: 'none',
                            transition: 'all 0.2s'
                          }}
                          value={editProject.location}
                          onChange={(e) => setEditProject({ ...editProject, location: e.target.value })}
                          onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                          onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
                        />
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
                  justifyContent: 'flex-end'
                }}>
                  <button
                    type="button"
                    onClick={() => {
                      setShowEditModal(false);
                      setSelectedProject(null);
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
                      background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
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
                    <CheckCircle style={{ height: '1rem', width: '1rem' }} />
                    Update Project
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}

      {/* Project Details Modal */}
      {showDetailsModal && selectedProject && (
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
              maxWidth: '56rem',
              width: '100%',
              overflow: 'hidden',
              maxHeight: '90vh',
              display: 'flex',
              flexDirection: 'column'
            }}>
              {/* Modal Header */}
              <div style={{
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                padding: '1.5rem',
                color: 'white'
              }}>
                <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between' }}>
                  <div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem' }}>
                      <FolderOpen style={{ height: '1.75rem', width: '1.75rem' }} />
                      <h3 style={{ fontSize: '1.5rem', fontWeight: '600', margin: 0 }}>
                        {selectedProject.name}
                      </h3>
                    </div>
                    {selectedProject.location && (
                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', opacity: 0.9 }}>
                        <MapPin style={{ height: '1rem', width: '1rem' }} />
                        {selectedProject.location}
                      </div>
                    )}
                  </div>
                  <button
                    onClick={() => setShowDetailsModal(false)}
                    style={{
                      color: 'white',
                      backgroundColor: 'rgba(255, 255, 255, 0.2)',
                      border: 'none',
                      cursor: 'pointer',
                      padding: '0.5rem',
                      borderRadius: '0.5rem',
                      transition: 'all 0.2s',
                      fontSize: '1.5rem',
                      lineHeight: 1,
                      width: '2rem',
                      height: '2rem',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center'
                    }}
                  >
                    ×
                  </button>
                </div>
                {selectedProject.description && (
                  <p style={{ fontSize: '0.875rem', margin: '1rem 0 0 0', opacity: 0.95, lineHeight: '1.5' }}>
                    {selectedProject.description}
                  </p>
                )}
              </div>

              {/* Modal Body */}
              <div style={{ flex: 1, overflowY: 'auto', padding: '1.5rem' }}>
                {(() => {
                  const stats = getProjectStats(selectedProject.projectId);
                  const allProjectProps = getProjectProperties(selectedProject.projectId);
                  const allUnassignedProps = getUnassignedProperties();
                  
                  // Apply filters
                  const projectProps = filterProperties(allProjectProps);
                  const unassignedProps = filterProperties(allUnassignedProps);

                  return (
                    <>
                      {/* Stats Grid */}
                      <div style={{
                        display: 'grid',
                        gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))',
                        gap: '1rem',
                        marginBottom: '2rem'
                      }}>
                        {[
                          {
                            title: 'Total Properties',
                            value: stats.total,
                            icon: Home,
                            color: '#667eea',
                            bgColor: '#e0e7ff'
                          },
                          {
                            title: 'Approved',
                            value: stats.approved,
                            icon: CheckCircle,
                            color: '#10b981',
                            bgColor: '#dcfce7'
                          },
                          {
                            title: 'Pending',
                            value: stats.pending,
                            icon: Clock,
                            color: '#f59e0b',
                            bgColor: '#fef3c7'
                          },
                          {
                            title: 'Est. Value',
                            value: `$${(stats.totalValue / 1000000).toFixed(1)}M`,
                            icon: DollarSign,
                            color: '#8b5cf6',
                            bgColor: '#ede9fe'
                          }
                        ].map((stat, index) => (
                          <div key={index} style={{
                            padding: '1rem',
                            backgroundColor: stat.bgColor,
                            borderRadius: '0.75rem',
                            border: `1px solid ${stat.bgColor}`
                          }}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '0.75rem', marginBottom: '0.5rem' }}>
                              <stat.icon style={{ height: '1.25rem', width: '1.25rem', color: stat.color }} />
                              <span style={{ fontSize: '0.75rem', color: stat.color, fontWeight: '600', textTransform: 'uppercase' }}>
                                {stat.title}
                              </span>
                            </div>
                            <div style={{ fontSize: '1.75rem', fontWeight: '700', color: stat.color }}>
                              {stat.value}
                            </div>
                          </div>
                        ))}
                      </div>

                      {/* Search and Filters Section */}
                      <div style={{
                        backgroundColor: 'white',
                        borderRadius: '1rem',
                        padding: '1.5rem',
                        marginBottom: '2rem',
                        boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
                        border: '2px solid #e5e7eb'
                      }}>
                        <div style={{
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.75rem',
                          marginBottom: '1rem'
                        }}>
                          <Filter style={{ height: '1.25rem', width: '1.25rem', color: '#667eea' }} />
                          <h4 style={{
                            fontSize: '1.125rem',
                            fontWeight: '700',
                            color: '#111827',
                            margin: 0
                          }}>
                            Search & Filter Properties
                          </h4>
                        </div>
                        
                        <div style={{
                          display: 'grid',
                          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
                          gap: '1rem'
                        }}>
                          {/* Search */}
                          <div style={{ position: 'relative' }}>
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
                              value={propertySearchTerm}
                              onChange={(e) => setPropertySearchTerm(e.target.value)}
                              style={{
                                width: '100%',
                                paddingLeft: '2.5rem',
                                paddingRight: '0.75rem',
                                paddingTop: '0.75rem',
                                paddingBottom: '0.75rem',
                                border: '2px solid #d1d5db',
                                borderRadius: '0.75rem',
                                fontSize: '0.875rem',
                                outline: 'none',
                                transition: 'all 0.2s'
                              }}
                              onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                              onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
                            />
                          </div>

                          {/* Status Filter */}
                          <div style={{ position: 'relative' }}>
                            <select
                              value={propertyStatusFilter}
                              onChange={(e) => setPropertyStatusFilter(e.target.value)}
                              style={{
                                width: '100%',
                                padding: '0.75rem',
                                border: '2px solid #d1d5db',
                                borderRadius: '0.75rem',
                                fontSize: '0.875rem',
                                outline: 'none',
                                backgroundColor: 'white',
                                cursor: 'pointer',
                                transition: 'all 0.2s'
                              }}
                              onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                              onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
                            >
                              <option value="all">All Status</option>
                              <option value="Approved">✓ Approved</option>
                              <option value="Pending">⏱ Pending</option>
                              <option value="Rejected">✗ Rejected</option>
                            </select>
                          </div>

                          {/* Bedrooms Filter */}
                          <div style={{ position: 'relative' }}>
                            <select
                              value={propertyBedroomsFilter}
                              onChange={(e) => setPropertyBedroomsFilter(e.target.value)}
                              style={{
                                width: '100%',
                                padding: '0.75rem',
                                border: '2px solid #d1d5db',
                                borderRadius: '0.75rem',
                                fontSize: '0.875rem',
                                outline: 'none',
                                backgroundColor: 'white',
                                cursor: 'pointer',
                                transition: 'all 0.2s'
                              }}
                              onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                              onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
                            >
                              <option value="all">All Bedrooms</option>
                              <option value="1">1 Bedroom</option>
                              <option value="2">2 Bedrooms</option>
                              <option value="3">3 Bedrooms</option>
                              <option value="4+">4+ Bedrooms</option>
                            </select>
                          </div>

                          {/* Clear Filters Button */}
                          <button
                            onClick={() => {
                              setPropertySearchTerm('');
                              setPropertyStatusFilter('all');
                              setPropertyBedroomsFilter('all');
                            }}
                            style={{
                              padding: '0.75rem 1rem',
                              backgroundColor: '#f3f4f6',
                              color: '#6b7280',
                              border: '2px solid #d1d5db',
                              borderRadius: '0.75rem',
                              fontSize: '0.875rem',
                              fontWeight: '600',
                              cursor: 'pointer',
                              transition: 'all 0.2s',
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'center',
                              gap: '0.5rem'
                            }}
                            onMouseEnter={(e) => {
                              e.currentTarget.style.backgroundColor = '#e5e7eb';
                              e.currentTarget.style.borderColor = '#9ca3af';
                            }}
                            onMouseLeave={(e) => {
                              e.currentTarget.style.backgroundColor = '#f3f4f6';
                              e.currentTarget.style.borderColor = '#d1d5db';
                            }}
                          >
                            <XCircle style={{ height: '1rem', width: '1rem' }} />
                            Clear
                          </button>
                        </div>

                        {/* Results Counter */}
                        <div style={{
                          marginTop: '1rem',
                          padding: '0.75rem 1rem',
                          backgroundColor: '#f9fafb',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          color: '#6b7280',
                          display: 'flex',
                          alignItems: 'center',
                          gap: '0.5rem',
                          border: '1px solid #e5e7eb'
                        }}>
                          <BarChart3 style={{ height: '1rem', width: '1rem' }} />
                          <span>
                            Showing <strong style={{ color: '#667eea' }}>{projectProps.length}</strong> assigned 
                            {' & '}
                            <strong style={{ color: '#10b981' }}>{unassignedProps.length}</strong> available properties
                            {(propertySearchTerm || propertyStatusFilter !== 'all' || propertyBedroomsFilter !== 'all') && 
                              ` (filtered from ${allProjectProps.length + allUnassignedProps.length} total)`
                            }
                          </span>
                        </div>
                      </div>

                      {/* Add Properties Section - MOVED TO TOP */}
                      {(() => {
                        return unassignedProps.length > 0 ? (
                          <div style={{ marginBottom: '2rem' }}>
                            <div style={{
                              display: 'flex',
                              alignItems: 'center',
                              justifyContent: 'space-between',
                              marginBottom: '1rem',
                              paddingBottom: '1rem',
                              borderBottom: '2px solid #e5e7eb'
                            }}>
                              <h4 style={{
                                fontSize: '1.25rem',
                                fontWeight: '700',
                                color: '#111827',
                                margin: 0,
                                display: 'flex',
                                alignItems: 'center',
                                gap: '0.5rem'
                              }}>
                                <Plus style={{ height: '1.5rem', width: '1.5rem', color: '#10b981' }} />
                                Available Properties to Add
                              </h4>
                              <div style={{
                                padding: '0.5rem 1rem',
                                backgroundColor: '#dcfce7',
                                borderRadius: '0.5rem',
                                fontSize: '0.875rem',
                                fontWeight: '700',
                                color: '#10b981'
                              }}>
                                {unassignedProps.length} Available
                              </div>
                            </div>

                            <div style={{
                              display: 'flex',
                              gap: '1.25rem',
                              padding: '0.5rem',
                              backgroundColor: '#f0fdf4',
                              borderRadius: '0.75rem',
                              border: '1px solid #dcfce7',
                              overflowX: 'auto',
                              overflowY: 'hidden',
                              scrollBehavior: 'smooth'
                            }}>
                              {unassignedProps.map((prop) => (
                                <div key={prop.propertyId} style={{
                                  backgroundColor: 'white',
                                  border: '2px solid #e5e7eb',
                                  borderRadius: '0.875rem',
                                  overflow: 'hidden',
                                  transition: 'all 0.3s',
                                  position: 'relative',
                                  minWidth: '340px',
                                  maxWidth: '340px',
                                  flexShrink: 0
                                }}
                                onMouseEnter={(e) => {
                                  e.currentTarget.style.boxShadow = '0 10px 20px -5px rgba(16, 185, 129, 0.3)';
                                  e.currentTarget.style.transform = 'translateY(-2px)';
                                  e.currentTarget.style.borderColor = '#10b981';
                                }}
                                onMouseLeave={(e) => {
                                  e.currentTarget.style.boxShadow = 'none';
                                  e.currentTarget.style.transform = 'translateY(0)';
                                  e.currentTarget.style.borderColor = '#e5e7eb';
                                }}>
                                  {/* Badge - Available */}
                                  <div style={{
                                    position: 'absolute',
                                    top: '0.75rem',
                                    left: '0.75rem',
                                    backgroundColor: '#10b981',
                                    color: 'white',
                                    padding: '0.375rem 0.75rem',
                                    borderRadius: '0.5rem',
                                    fontSize: '0.6875rem',
                                    fontWeight: '700',
                                    zIndex: 10,
                                    boxShadow: '0 2px 8px rgba(0, 0, 0, 0.15)',
                                    textTransform: 'uppercase',
                                    letterSpacing: '0.05em'
                                  }}>
                                    ● Available
                                  </div>

                                  {/* Property Image */}
                                  <div style={{
                                    width: '100%',
                                    height: '200px',
                                    backgroundColor: prop.imageUrl ? '#000' : 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                                    backgroundImage: prop.imageUrl ? `url(${prop.imageUrl})` : 'none',
                                    backgroundSize: 'cover',
                                    backgroundPosition: 'center',
                                    display: 'flex',
                                    alignItems: 'center',
                                    justifyContent: 'center',
                                    position: 'relative',
                                    border: '2px solid #e5e7eb',
                                    borderBottom: 'none'
                                  }}>
                                    {!prop.imageUrl && (
                                      <div style={{ textAlign: 'center', color: 'white' }}>
                                        <Home style={{ height: '4rem', width: '4rem', marginBottom: '0.5rem' }} />
                                        <div style={{ fontSize: '1rem', fontWeight: '600' }}>No Image Available</div>
                                      </div>
                                    )}
                                  </div>

                                  <div style={{ padding: '1.5rem', backgroundColor: 'white' }}>
                                    {/* Property Header */}
                                    <div style={{ marginBottom: '1rem' }}>
                                      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '0.75rem' }}>
                                        <h5 style={{
                                          fontSize: '1.25rem',
                                          fontWeight: '700',
                                          color: '#111827',
                                          margin: 0,
                                          lineHeight: '1.3',
                                          flex: 1,
                                          paddingRight: '0.5rem'
                                        }}>
                                          {prop.name || 'Unnamed Property'}
                                        </h5>
                                        <span style={{
                                          padding: '0.5rem 0.875rem',
                                          borderRadius: '0.5rem',
                                          fontSize: '0.75rem',
                                          fontWeight: '700',
                                          backgroundColor: prop.status === 'Approved' ? '#dcfce7' : prop.status === 'Pending' ? '#fef3c7' : '#fee2e2',
                                          color: prop.status === 'Approved' ? '#059669' : prop.status === 'Pending' ? '#d97706' : '#dc2626',
                                          whiteSpace: 'nowrap'
                                        }}>
                                          {prop.status || 'Unknown'}
                                        </span>
                                      </div>
                                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.9375rem', color: '#6b7280', marginBottom: '0.5rem' }}>
                                        <MapPin style={{ height: '1rem', width: '1rem' }} />
                                        <strong>{prop.location || 'Location not specified'}</strong>
                                      </div>
                                    </div>

                                    {/* Property Details */}
                                    <div style={{
                                      display: 'flex',
                                      alignItems: 'center',
                                      gap: '1.25rem',
                                      padding: '1rem',
                                      backgroundColor: '#f9fafb',
                                      borderRadius: '0.75rem',
                                      marginBottom: '1rem',
                                      fontSize: '0.9375rem',
                                      fontWeight: '600',
                                      color: '#111827',
                                      border: '1px solid #e5e7eb'
                                    }}>
                                      <div style={{ display: 'flex', alignItems: 'center', gap: '0.375rem' }}>
                                        <Home style={{ height: '1.125rem', width: '1.125rem', color: '#10b981' }} />
                                        <span><strong>{prop.bedrooms || 0}</strong> bed</span>
                                      </div>
                                      <div style={{ color: '#d1d5db' }}>•</div>
                                      <div><strong>{prop.bathrooms || 0}</strong> bath</div>
                                      <div style={{ color: '#d1d5db' }}>•</div>
                                      <div><strong>{(prop.squareFeet || 0).toLocaleString()}</strong> sqft</div>
                                    </div>

                                    {/* Property Description Preview */}
                                    <div style={{
                                      padding: '1rem',
                                      backgroundColor: '#f9fafb',
                                      borderRadius: '0.5rem',
                                      marginBottom: '1rem',
                                      minHeight: '4rem',
                                      border: '1px solid #e5e7eb'
                                    }}>
                                      <div style={{ fontSize: '0.75rem', fontWeight: '700', color: '#6b7280', marginBottom: '0.5rem', textTransform: 'uppercase' }}>
                                        Description
                                      </div>
                                      <p style={{
                                        fontSize: '0.875rem',
                                        color: '#4b5563',
                                        lineHeight: '1.6',
                                        margin: 0,
                                        overflow: 'hidden',
                                        textOverflow: 'ellipsis',
                                        display: '-webkit-box',
                                        WebkitLineClamp: 2,
                                        WebkitBoxOrient: 'vertical'
                                      }}>
                                        {prop.description || 'No description available for this property.'}
                                      </p>
                                    </div>

                                    {/* Action Button */}
                                    <button
                                      onClick={() => handleAttachProperty(prop.propertyId, selectedProject.projectId)}
                                      style={{
                                        width: '100%',
                                        padding: '0.875rem 1rem',
                                        background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                                        color: 'white',
                                        border: 'none',
                                        borderRadius: '0.625rem',
                                        fontSize: '0.875rem',
                                        fontWeight: '700',
                                        cursor: 'pointer',
                                        transition: 'all 0.2s',
                                        display: 'flex',
                                        alignItems: 'center',
                                        justifyContent: 'center',
                                        gap: '0.5rem',
                                        textTransform: 'uppercase',
                                        letterSpacing: '0.025em',
                                        boxShadow: '0 2px 8px rgba(16, 185, 129, 0.3)'
                                      }}
                                      onMouseEnter={(e) => {
                                        e.currentTarget.style.transform = 'translateY(-2px)';
                                        e.currentTarget.style.boxShadow = '0 6px 16px rgba(16, 185, 129, 0.4)';
                                      }}
                                      onMouseLeave={(e) => {
                                        e.currentTarget.style.transform = 'translateY(0)';
                                        e.currentTarget.style.boxShadow = '0 2px 8px rgba(16, 185, 129, 0.3)';
                                      }}
                                    >
                                      <Plus style={{ height: '1rem', width: '1rem' }} />
                                      Add to Project
                                    </button>

                                    {/* Property Owner Info */}
                                    <div style={{
                                      marginTop: '0.75rem',
                                      padding: '0.875rem',
                                      backgroundColor: '#eff6ff',
                                      borderRadius: '0.5rem',
                                      fontSize: '0.875rem',
                                      color: '#1e40af',
                                      textAlign: 'center',
                                      border: '1px solid #dbeafe',
                                      fontWeight: '600'
                                    }}>
                                      <Users style={{ height: '1rem', width: '1rem', display: 'inline', marginRight: '0.375rem' }} />
                                      Owner: <strong>{prop.owner ? `${prop.owner.firstName} ${prop.owner.lastName}` : 'Unknown'}</strong>
                                    </div>
                                  </div>
                                </div>
                              ))}
                            </div>
                          </div>
                        ) : (
                          <div style={{
                            textAlign: 'center',
                            padding: '3rem 2rem',
                            backgroundColor: '#f0fdf4',
                            borderRadius: '0.75rem',
                            border: '2px dashed #86efac',
                            marginBottom: '2rem'
                          }}>
                            <AlertCircle style={{
                              margin: '0 auto 1rem auto',
                              height: '3rem',
                              width: '3rem',
                              color: '#10b981'
                            }} />
                            <h5 style={{
                              fontSize: '1.125rem',
                              fontWeight: '600',
                              color: '#111827',
                              marginBottom: '0.5rem'
                            }}>
                              {(propertySearchTerm || propertyStatusFilter !== 'all' || propertyBedroomsFilter !== 'all') 
                                ? 'No Available Properties Match Your Filters' 
                                : 'No Available Properties'}
                            </h5>
                            <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: 0 }}>
                              {(propertySearchTerm || propertyStatusFilter !== 'all' || propertyBedroomsFilter !== 'all')
                                ? 'Try adjusting your search or filters to see more properties.'
                                : 'All properties are currently assigned to projects.'}
                            </p>
                          </div>
                        );
                      })()}

                      {/* Properties Currently in Project */}
                      <div>
                        <div style={{
                          display: 'flex',
                          alignItems: 'center',
                          justifyContent: 'space-between',
                          marginBottom: '1rem',
                          paddingBottom: '1rem',
                          borderBottom: '2px solid #e5e7eb'
                        }}>
                          <h4 style={{
                            fontSize: '1.25rem',
                            fontWeight: '700',
                            color: '#111827',
                            margin: 0,
                            display: 'flex',
                            alignItems: 'center',
                            gap: '0.5rem'
                          }}>
                            <Building style={{ height: '1.5rem', width: '1.5rem', color: '#667eea' }} />
                            Properties Currently in this Project
                          </h4>
                          <div style={{
                            padding: '0.5rem 1rem',
                            backgroundColor: '#e0e7ff',
                            borderRadius: '0.5rem',
                            fontSize: '0.875rem',
                            fontWeight: '700',
                            color: '#667eea'
                          }}>
                            {projectProps.length} Properties
                          </div>
                        </div>

                        {projectProps.length > 0 ? (
                          <div style={{
                            display: 'flex',
                            gap: '1.25rem',
                            padding: '0.5rem',
                            backgroundColor: '#f9fafb',
                            borderRadius: '0.75rem',
                            border: '1px solid #e5e7eb',
                            overflowX: 'auto',
                            overflowY: 'hidden',
                            scrollBehavior: 'smooth'
                          }}>
                            {projectProps.map((prop) => (
                              <div key={prop.propertyId} style={{
                                backgroundColor: 'white',
                                border: '2px solid #e5e7eb',
                                borderRadius: '0.875rem',
                                overflow: 'hidden',
                                transition: 'all 0.3s',
                                position: 'relative',
                                minWidth: '340px',
                                maxWidth: '340px',
                                flexShrink: 0
                              }}
                              onMouseEnter={(e) => {
                                e.currentTarget.style.boxShadow = '0 10px 20px -5px rgba(0, 0, 0, 0.15)';
                                e.currentTarget.style.transform = 'translateY(-2px)';
                              }}
                              onMouseLeave={(e) => {
                                e.currentTarget.style.boxShadow = 'none';
                                e.currentTarget.style.transform = 'translateY(0)';
                              }}>
                                {/* Badge - Assigned */}
                                <div style={{
                                  position: 'absolute',
                                  top: '0.75rem',
                                  left: '0.75rem',
                                  backgroundColor: '#667eea',
                                  color: 'white',
                                  padding: '0.375rem 0.75rem',
                                  borderRadius: '0.5rem',
                                  fontSize: '0.6875rem',
                                  fontWeight: '700',
                                  zIndex: 10,
                                  boxShadow: '0 2px 8px rgba(0, 0, 0, 0.15)',
                                  textTransform: 'uppercase',
                                  letterSpacing: '0.05em'
                                }}>
                                  ✓ Assigned
                                </div>

                                {/* Property Image */}
                                <div style={{
                                  width: '100%',
                                  height: '200px',
                                  backgroundColor: prop.imageUrl ? '#000' : 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                                  backgroundImage: prop.imageUrl ? `url(${prop.imageUrl})` : 'none',
                                  backgroundSize: 'cover',
                                  backgroundPosition: 'center',
                                  display: 'flex',
                                  alignItems: 'center',
                                  justifyContent: 'center',
                                  position: 'relative',
                                  border: '2px solid #e5e7eb',
                                  borderBottom: 'none'
                                }}>
                                  {!prop.imageUrl && (
                                    <div style={{ textAlign: 'center', color: 'white' }}>
                                      <Home style={{ height: '4rem', width: '4rem', marginBottom: '0.5rem' }} />
                                      <div style={{ fontSize: '1rem', fontWeight: '600' }}>No Image Available</div>
                                    </div>
                                  )}
                                </div>

                                <div style={{ padding: '1.5rem', backgroundColor: 'white' }}>
                                  {/* Property Header */}
                                  <div style={{ marginBottom: '1rem' }}>
                                    <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '0.75rem' }}>
                                      <h5 style={{
                                        fontSize: '1.25rem',
                                        fontWeight: '700',
                                        color: '#111827',
                                        margin: 0,
                                        lineHeight: '1.3',
                                        flex: 1,
                                        paddingRight: '0.5rem'
                                      }}>
                                        {prop.name || 'Unnamed Property'}
                                      </h5>
                                      <span style={{
                                        padding: '0.5rem 0.875rem',
                                        borderRadius: '0.5rem',
                                        fontSize: '0.75rem',
                                        fontWeight: '700',
                                        backgroundColor: prop.status === 'Approved' ? '#dcfce7' : prop.status === 'Pending' ? '#fef3c7' : '#fee2e2',
                                        color: prop.status === 'Approved' ? '#059669' : prop.status === 'Pending' ? '#d97706' : '#dc2626',
                                        whiteSpace: 'nowrap'
                                      }}>
                                        {prop.status || 'Unknown'}
                                      </span>
                                    </div>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.9375rem', color: '#6b7280', marginBottom: '0.5rem' }}>
                                      <MapPin style={{ height: '1rem', width: '1rem' }} />
                                      <strong>{prop.location || 'Location not specified'}</strong>
                                    </div>
                                  </div>

                                  {/* Property Details - LARGER */}
                                  <div style={{
                                    display: 'flex',
                                    alignItems: 'center',
                                    gap: '1.25rem',
                                    padding: '1rem',
                                    backgroundColor: '#f9fafb',
                                    borderRadius: '0.75rem',
                                    marginBottom: '1rem',
                                    fontSize: '0.9375rem',
                                    fontWeight: '600',
                                    color: '#111827',
                                    border: '1px solid #e5e7eb'
                                  }}>
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '0.375rem' }}>
                                      <Home style={{ height: '1.125rem', width: '1.125rem', color: '#667eea' }} />
                                      <span><strong>{prop.bedrooms || 0}</strong> bed</span>
                                    </div>
                                    <div style={{ color: '#d1d5db' }}>•</div>
                                    <div><strong>{prop.bathrooms || 0}</strong> bath</div>
                                    <div style={{ color: '#d1d5db' }}>•</div>
                                    <div><strong>{(prop.squareFeet || 0).toLocaleString()}</strong> sqft</div>
                                  </div>

                                  {/* Property Description Preview */}
                                  <div style={{
                                    padding: '1rem',
                                    backgroundColor: '#f9fafb',
                                    borderRadius: '0.5rem',
                                    marginBottom: '1rem',
                                    minHeight: '4rem',
                                    border: '1px solid #e5e7eb'
                                  }}>
                                    <div style={{ fontSize: '0.75rem', fontWeight: '700', color: '#6b7280', marginBottom: '0.5rem', textTransform: 'uppercase' }}>
                                      Description
                                    </div>
                                    <p style={{
                                      fontSize: '0.875rem',
                                      color: '#4b5563',
                                      lineHeight: '1.6',
                                      margin: 0,
                                      overflow: 'hidden',
                                      textOverflow: 'ellipsis',
                                      display: '-webkit-box',
                                      WebkitLineClamp: 2,
                                      WebkitBoxOrient: 'vertical'
                                    }}>
                                      {prop.description || 'No description available for this property.'}
                                    </p>
                                  </div>

                                  {/* Action Button */}
                                  <button
                                    onClick={() => handleDetachProperty(prop.propertyId)}
                                    style={{
                                      width: '100%',
                                      padding: '0.875rem 1rem',
                                      backgroundColor: '#fff7ed',
                                      color: '#d97706',
                                      border: '2px solid #fde68a',
                                      borderRadius: '0.625rem',
                                      fontSize: '0.875rem',
                                      fontWeight: '700',
                                      cursor: 'pointer',
                                      transition: 'all 0.2s',
                                      display: 'flex',
                                      alignItems: 'center',
                                      justifyContent: 'center',
                                      gap: '0.5rem',
                                      textTransform: 'uppercase',
                                      letterSpacing: '0.025em'
                                    }}
                                    onMouseEnter={(e) => {
                                      e.currentTarget.style.backgroundColor = '#fef3c7';
                                      e.currentTarget.style.borderColor = '#f59e0b';
                                      e.currentTarget.style.transform = 'translateY(-1px)';
                                    }}
                                    onMouseLeave={(e) => {
                                      e.currentTarget.style.backgroundColor = '#fff7ed';
                                      e.currentTarget.style.borderColor = '#fde68a';
                                      e.currentTarget.style.transform = 'translateY(0)';
                                    }}
                                  >
                                    <XCircle style={{ height: '1rem', width: '1rem' }} />
                                    Remove from Project
                                  </button>

                                  {/* Property Owner Info - ALWAYS SHOW */}
                                  <div style={{
                                    marginTop: '0.75rem',
                                    padding: '0.875rem',
                                    backgroundColor: '#eff6ff',
                                    borderRadius: '0.5rem',
                                    fontSize: '0.875rem',
                                    color: '#1e40af',
                                    textAlign: 'center',
                                    border: '1px solid #dbeafe',
                                    fontWeight: '600'
                                  }}>
                                    <Users style={{ height: '1rem', width: '1rem', display: 'inline', marginRight: '0.375rem' }} />
                                    Owner: <strong>{prop.owner ? `${prop.owner.firstName} ${prop.owner.lastName}` : 'Unknown'}</strong>
                                  </div>
                                </div>
                              </div>
                            ))}
                          </div>
                        ) : (
                          <div style={{
                            textAlign: 'center',
                            padding: '4rem 2rem',
                            backgroundColor: '#f9fafb',
                            borderRadius: '0.75rem',
                            border: '2px dashed #d1d5db'
                          }}>
                            <AlertCircle style={{
                              margin: '0 auto 1rem auto',
                              height: '3.5rem',
                              width: '3.5rem',
                              color: '#9ca3af'
                            }} />
                            <h5 style={{
                              fontSize: '1.125rem',
                              fontWeight: '600',
                              color: '#111827',
                              marginBottom: '0.5rem'
                            }}>
                              {(propertySearchTerm || propertyStatusFilter !== 'all' || propertyBedroomsFilter !== 'all')
                                ? 'No Assigned Properties Match Your Filters'
                                : 'No Properties Yet'}
                            </h5>
                            <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: 0 }}>
                              {(propertySearchTerm || propertyStatusFilter !== 'all' || propertyBedroomsFilter !== 'all')
                                ? 'Try adjusting your search or filters to see more properties.'
                                : 'This project doesn\'t have any properties assigned yet. Scroll up to see available properties you can add.'}
                            </p>
                          </div>
                        )}
                      </div>

                      {/* Project Meta */}
                      <div style={{
                        marginTop: '2rem',
                        padding: '1rem',
                        backgroundColor: '#f9fafb',
                        borderRadius: '0.75rem',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        fontSize: '0.8125rem',
                        color: '#6b7280'
                      }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                          <Calendar style={{ height: '0.875rem', width: '0.875rem' }} />
                          Created: {new Date(selectedProject.createdAt).toLocaleDateString()}
                        </div>
                        {selectedProject.updatedAt && (
                          <div>
                            Last Updated: {new Date(selectedProject.updatedAt).toLocaleDateString()}
                          </div>
                        )}
                      </div>
                    </>
                  );
                })()}
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
                  onClick={() => setShowDetailsModal(false)}
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
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default ProjectsPage;
