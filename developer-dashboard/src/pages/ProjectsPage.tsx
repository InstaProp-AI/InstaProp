import React, { useState, useEffect } from 'react';
import { Plus, FolderOpen, MapPin, Calendar, Edit, Trash2 } from 'lucide-react';
import { Project, CreateProjectDto } from '../types';
import { projectsApi } from '../services/api';

const ProjectsPage: React.FC = () => {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [newProject, setNewProject] = useState<CreateProjectDto>({
    name: '',
    description: '',
    location: '',
  });

  useEffect(() => {
    fetchProjects();
  }, []);

  const fetchProjects = async () => {
    try {
      const data = await projectsApi.getProjects();
      setProjects(data);
    } catch (error) {
      console.error('Failed to fetch projects:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateProject = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await projectsApi.createProject(newProject);
      setNewProject({ name: '', description: '', location: '' });
      setShowCreateModal(false);
      fetchProjects();
    } catch (error) {
      console.error('Failed to create project:', error);
    }
  };

  const handleDeleteProject = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this project?')) {
      try {
        await projectsApi.deleteProject(id);
        fetchProjects();
      } catch (error) {
        console.error('Failed to delete project:', error);
      }
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-32 w-32 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div>
      <div style={{
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'flex-start',
        justifyContent: 'space-between',
        marginBottom: '2rem',
        '@media (min-width: 640px)': {
          flexDirection: 'row',
          alignItems: 'center'
        }
      }}>
        <div>
          <h1 style={{
            fontSize: '1.875rem',
            fontWeight: 'bold',
            color: '#111827',
            marginBottom: '0.25rem'
          }}>Projects</h1>
          <p style={{
            marginTop: '0.25rem',
            fontSize: '0.875rem',
            color: '#6b7280'
          }}>
            Manage your development projects
          </p>
        </div>
        <div style={{
          marginTop: '1rem',
          '@media (min-width: 640px)': { marginTop: 0 }
        }}>
          <button
            onClick={() => setShowCreateModal(true)}
            style={{
              display: 'inline-flex',
              alignItems: 'center',
              background: 'linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%)',
              color: 'white',
              fontWeight: '500',
              padding: '0.5rem 1rem',
              borderRadius: '0.5rem',
              border: 'none',
              cursor: 'pointer',
              transition: 'all 0.2s',
              boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.05)'
            }}
          >
            <Plus style={{ height: '1rem', width: '1rem', marginRight: '0.5rem' }} />
            New Project
          </button>
        </div>
      </div>

      {/* Projects Grid */}
      <div style={{
        display: 'grid',
        gridTemplateColumns: 'repeat(auto-fit, minmax(350px, 1fr))',
        gap: '1.5rem'
      }}>
        {projects.map((project) => (
          <div key={project.projectId} style={{
            backgroundColor: 'white',
            borderRadius: '0.75rem',
            padding: '1.5rem',
            boxShadow: '0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06)',
            border: '1px solid #e5e7eb',
            transition: 'all 0.3s ease',
            background: 'linear-gradient(135deg, #ffffff 0%, #f8fafc 100%)'
          }}>
            <div style={{
              display: 'flex',
              alignItems: 'flex-start',
              justifyContent: 'space-between'
            }}>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', marginBottom: '0.5rem' }}>
                  <FolderOpen style={{ height: '1.25rem', width: '1.25rem', color: '#2563eb', marginRight: '0.5rem' }} />
                  <h3 style={{
                    fontSize: '1.125rem',
                    fontWeight: '500',
                    color: '#111827'
                  }}>{project.name}</h3>
                </div>
                {project.description && (
                  <p style={{
                    marginTop: '0.5rem',
                    fontSize: '0.875rem',
                    color: '#6b7280',
                    lineHeight: '1.4'
                  }}>{project.description}</p>
                )}
                {project.location && (
                  <div style={{
                    marginTop: '0.5rem',
                    display: 'flex',
                    alignItems: 'center',
                    fontSize: '0.875rem',
                    color: '#6b7280'
                  }}>
                    <MapPin style={{ height: '1rem', width: '1rem', marginRight: '0.25rem' }} />
                    {project.location}
                  </div>
                )}
                <div style={{
                  marginTop: '0.5rem',
                  display: 'flex',
                  alignItems: 'center',
                  fontSize: '0.875rem',
                  color: '#6b7280'
                }}>
                  <Calendar style={{ height: '1rem', width: '1rem', marginRight: '0.25rem' }} />
                  Created {new Date(project.createdAt).toLocaleDateString()}
                </div>
                <div style={{
                  marginTop: '0.5rem',
                  fontSize: '0.875rem',
                  color: '#6b7280',
                  fontWeight: '500'
                }}>
                  {project.properties.length} properties
                </div>
              </div>
              <div style={{ display: 'flex', gap: '0.5rem', marginLeft: '1rem' }}>
                <button style={{
                  color: '#9ca3af',
                  backgroundColor: 'transparent',
                  border: 'none',
                  cursor: 'pointer',
                  padding: '0.25rem',
                  borderRadius: '0.25rem',
                  transition: 'all 0.2s'
                }}>
                  <Edit style={{ height: '1rem', width: '1rem' }} />
                </button>
                <button 
                  onClick={() => handleDeleteProject(project.projectId)}
                  style={{
                    color: '#9ca3af',
                    backgroundColor: 'transparent',
                    border: 'none',
                    cursor: 'pointer',
                    padding: '0.25rem',
                    borderRadius: '0.25rem',
                    transition: 'all 0.2s'
                  }}
                >
                  <Trash2 style={{ height: '1rem', width: '1rem' }} />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      {projects.length === 0 && (
        <div style={{
          textAlign: 'center',
          padding: '3rem 0'
        }}>
          <FolderOpen style={{
            margin: '0 auto',
            height: '3rem',
            width: '3rem',
            color: '#9ca3af'
          }} />
          <h3 style={{
            marginTop: '0.5rem',
            fontSize: '0.875rem',
            fontWeight: '500',
            color: '#111827'
          }}>No projects</h3>
          <p style={{
            marginTop: '0.25rem',
            fontSize: '0.875rem',
            color: '#6b7280'
          }}>Get started by creating a new project.</p>
          <div style={{ marginTop: '1.5rem' }}>
            <button
              onClick={() => setShowCreateModal(true)}
              style={{
                display: 'inline-flex',
                alignItems: 'center',
                background: 'linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%)',
                color: 'white',
                fontWeight: '500',
                padding: '0.5rem 1rem',
                borderRadius: '0.5rem',
                border: 'none',
                cursor: 'pointer',
                transition: 'all 0.2s',
                boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.05)'
              }}
            >
              <Plus style={{ height: '1rem', width: '1rem', marginRight: '0.5rem' }} />
              New Project
            </button>
          </div>
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
          overflowY: 'auto'
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            minHeight: '100vh',
            paddingTop: '1rem',
            paddingLeft: '1rem',
            paddingRight: '1rem',
            paddingBottom: '5rem',
            textAlign: 'center'
          }}>
            <div 
              style={{
                position: 'fixed',
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
                backgroundColor: 'rgba(75, 85, 99, 0.75)',
                transition: 'opacity 0.3s'
              }} 
              onClick={() => setShowCreateModal(false)} 
            />
            <div style={{
              display: 'inline-block',
              verticalAlign: 'bottom',
              backgroundColor: 'white',
              borderRadius: '0.5rem',
              textAlign: 'left',
              overflow: 'hidden',
              boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)',
              transform: 'translateY(0)',
              transition: 'all 0.3s',
              maxWidth: '32rem',
              width: '100%'
            }}>
              <form onSubmit={handleCreateProject}>
                <div style={{
                  backgroundColor: 'white',
                  paddingLeft: '1rem',
                  paddingTop: '1.25rem',
                  paddingBottom: '1rem',
                  paddingRight: '1rem'
                }}>
                  <h3 style={{
                    fontSize: '1.125rem',
                    fontWeight: '500',
                    color: '#111827',
                    marginBottom: '1rem'
                  }}>Create New Project</h3>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151'
                      }}>Project Name</label>
                      <input
                        type="text"
                        required
                        style={{
                          width: '100%',
                          padding: '0.5rem 0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s',
                          marginTop: '0.25rem'
                        }}
                        value={newProject.name}
                        onChange={(e) => setNewProject({ ...newProject, name: e.target.value })}
                      />
                    </div>
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151'
                      }}>Description</label>
                      <textarea
                        style={{
                          width: '100%',
                          padding: '0.5rem 0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s',
                          marginTop: '0.25rem',
                          resize: 'vertical'
                        }}
                        rows={3}
                        value={newProject.description}
                        onChange={(e) => setNewProject({ ...newProject, description: e.target.value })}
                      />
                    </div>
                    <div>
                      <label style={{
                        display: 'block',
                        fontSize: '0.875rem',
                        fontWeight: '500',
                        color: '#374151'
                      }}>Location</label>
                      <input
                        type="text"
                        style={{
                          width: '100%',
                          padding: '0.5rem 0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          transition: 'all 0.2s',
                          marginTop: '0.25rem'
                        }}
                        value={newProject.location}
                        onChange={(e) => setNewProject({ ...newProject, location: e.target.value })}
                      />
                    </div>
                  </div>
                </div>
                <div style={{
                  backgroundColor: '#f9fafb',
                  paddingLeft: '1rem',
                  paddingTop: '0.75rem',
                  paddingBottom: '0.75rem',
                  paddingRight: '1rem',
                  display: 'flex',
                  flexDirection: 'row-reverse',
                  gap: '0.75rem'
                }}>
                  <button type="submit" style={{
                    background: 'linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%)',
                    color: 'white',
                    fontWeight: '500',
                    padding: '0.5rem 1rem',
                    borderRadius: '0.5rem',
                    border: 'none',
                    cursor: 'pointer',
                    transition: 'all 0.2s',
                    boxShadow: '0 1px 2px 0 rgba(0, 0, 0, 0.05)',
                    width: '100%'
                  }}>
                    Create Project
                  </button>
                  <button
                    type="button"
                    onClick={() => setShowCreateModal(false)}
                    style={{
                      backgroundColor: '#f3f4f6',
                      color: '#374151',
                      fontWeight: '500',
                      padding: '0.5rem 1rem',
                      borderRadius: '0.5rem',
                      border: '1px solid #d1d5db',
                      cursor: 'pointer',
                      transition: 'all 0.2s',
                      width: '100%'
                    }}
                  >
                    Cancel
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

export default ProjectsPage;
