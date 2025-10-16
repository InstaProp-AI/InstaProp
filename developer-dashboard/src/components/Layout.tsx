import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { 
  LayoutDashboard, 
  FolderOpen, 
  Home, 
  Menu, 
  X, 
  LogOut,
  User,
  Settings,
  Bell,
  Search,
  BarChart3,
  Users,
  Hammer,
  Calendar,
  TrendingUp,
  DollarSign,
  FileText,
  MessageSquare
} from 'lucide-react';
import { Account } from '../types';

interface LayoutProps {
  user: Account;
  onLogout: () => void;
  children: React.ReactNode;
}

const Layout: React.FC<LayoutProps> = ({ user, onLogout, children }) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const location = useLocation();

  // DEVELOPER DASHBOARD - Only show developer-relevant navigation
  const navigation = [
    { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard, color: 'bg-blue-500' },
    { name: 'Projects', href: '/projects', icon: FolderOpen, color: 'bg-teal-500' },
    { name: 'Properties', href: '/properties', icon: Home, color: 'bg-purple-500' },
    { name: 'Chats', href: '/chats', icon: MessageSquare, color: 'bg-pink-500' },
    { name: 'Analytics', href: '/analytics', icon: BarChart3, color: 'bg-indigo-500' },
    { name: 'Profile', href: '/profile', icon: User, color: 'bg-gray-500' },
  ];

  return (
    <>
      <style>{`
        .sidebar-gradient {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .card-hover {
          transition: all 0.3s ease;
        }
        .card-hover:hover {
          transform: translateY(-2px);
          box-shadow: 0 10px 25px rgba(0,0,0,0.15);
        }
        .nav-item {
          transition: all 0.2s ease;
        }
        .nav-item:hover {
          transform: translateX(4px);
        }
        .nav-item.active {
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white;
          box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
        }
        @media (min-width: 1024px) {
          .desktop-sidebar {
            display: flex !important;
          }
          .mobile-menu-button {
            display: none !important;
          }
          .main-content {
            padding-left: 16rem !important;
          }
        }
        @media (max-width: 1023px) {
          .desktop-sidebar {
            display: none !important;
          }
          .mobile-menu-button {
            display: block !important;
          }
          .main-content {
            padding-left: 0 !important;
          }
        }
      `}</style>
      
      <div style={{ minHeight: '100vh', backgroundColor: '#f8fafc' }}>
        {/* Mobile sidebar overlay */}
        {sidebarOpen && (
          <div 
            style={{
              position: 'fixed',
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              backgroundColor: 'rgba(0, 0, 0, 0.5)',
              zIndex: 50
            }}
            onClick={() => setSidebarOpen(false)}
          />
        )}

        {/* Mobile sidebar */}
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          height: '100vh',
          width: '16rem',
          backgroundColor: 'white',
          zIndex: 50,
          transform: sidebarOpen ? 'translateX(0)' : 'translateX(-100%)',
          transition: 'transform 0.3s ease',
          boxShadow: '0 10px 25px rgba(0,0,0,0.1)'
        }}>
          <div style={{ padding: '1.5rem' }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: '2rem' }}>
              <div>
                <h1 style={{
                  fontSize: '1.5rem',
                  fontWeight: 'bold',
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent'
                }}>Property Flipper</h1>
                <p style={{ fontSize: '0.875rem', color: '#6b7280', margin: 0 }}>Developer Dashboard</p>
              </div>
              <button
                onClick={() => setSidebarOpen(false)}
                style={{
                  padding: '0.5rem',
                  borderRadius: '0.5rem',
                  border: 'none',
                  backgroundColor: '#f3f4f6',
                  cursor: 'pointer'
                }}
              >
                <X style={{ height: '1.25rem', width: '1.25rem' }} />
              </button>
            </div>
            <nav>
              {navigation.map((item) => {
                const isActive = location.pathname === item.href;
                return (
                  <Link
                    key={item.name}
                    to={item.href}
                    className={`nav-item ${isActive ? 'active' : ''}`}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      padding: '0.75rem 1rem',
                      marginBottom: '0.5rem',
                      borderRadius: '0.75rem',
                      textDecoration: 'none',
                      color: isActive ? 'white' : '#6b7280',
                      backgroundColor: isActive ? 'transparent' : 'transparent'
                    }}
                    onClick={() => setSidebarOpen(false)}
                  >
                    <div style={{
                      width: '2rem',
                      height: '2rem',
                      borderRadius: '0.5rem',
                      backgroundColor: isActive ? 'rgba(255,255,255,0.2)' : '#f3f4f6',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      marginRight: '0.75rem'
                    }}>
                      <item.icon style={{ 
                        height: '1.25rem', 
                        width: '1.25rem',
                        color: isActive ? 'white' : '#6b7280'
                      }} />
                    </div>
                    <span style={{ fontWeight: '500', fontSize: '0.875rem' }}>{item.name}</span>
                  </Link>
                );
              })}
            </nav>
          </div>
        </div>

        {/* Desktop sidebar */}
        <div className="desktop-sidebar" style={{ 
          display: 'none',
          flexShrink: 0
        }}>
          <div style={{ 
            display: 'flex', 
            flexDirection: 'column', 
            width: '16rem',
            position: 'fixed',
            top: 0,
            left: 0,
            height: '100vh',
            zIndex: 40,
            background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            boxShadow: '0 10px 25px rgba(0,0,0,0.1)'
          }}>
            <div style={{
              flex: 1,
              display: 'flex',
              flexDirection: 'column',
              paddingTop: '1.5rem',
              paddingBottom: '1rem',
              overflowY: 'auto'
            }}>
              <div style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'flex-start',
                flexShrink: 0,
                paddingLeft: '1.5rem',
                paddingRight: '1.5rem',
                marginBottom: '2rem'
              }}>
                <h1 style={{
                  fontSize: '1.5rem',
                  fontWeight: 'bold',
                  color: 'white'
                }}>Property Flipper</h1>
                <p style={{
                  fontSize: '0.875rem',
                  color: 'rgba(255,255,255,0.8)',
                  margin: 0,
                  marginTop: '0.25rem'
                }}>Developer Dashboard</p>
              </div>
              <nav style={{ paddingLeft: '0.75rem', paddingRight: '0.75rem' }}>
                {navigation.map((item) => {
                  const isActive = location.pathname === item.href;
                  return (
                    <Link
                      key={item.name}
                      to={item.href}
                      className={`nav-item ${isActive ? 'active' : ''}`}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        padding: '0.75rem 1rem',
                        marginBottom: '0.5rem',
                        borderRadius: '0.75rem',
                        textDecoration: 'none',
                        color: isActive ? 'white' : 'rgba(255,255,255,0.8)',
                        backgroundColor: isActive ? 'rgba(255,255,255,0.2)' : 'transparent'
                      }}
                    >
                      <div style={{
                        width: '2rem',
                        height: '2rem',
                        borderRadius: '0.5rem',
                        backgroundColor: isActive ? 'rgba(255,255,255,0.2)' : 'rgba(255,255,255,0.1)',
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        marginRight: '0.75rem'
                      }}>
                        <item.icon style={{ 
                          height: '1.25rem', 
                          width: '1.25rem',
                          color: 'white'
                        }} />
                      </div>
                      <span style={{ fontWeight: '500', fontSize: '0.875rem' }}>{item.name}</span>
                    </Link>
                  );
                })}
              </nav>
            </div>
            <div style={{
              flexShrink: 0,
              display: 'flex',
              borderTop: '1px solid rgba(255,255,255,0.1)',
              padding: '1.5rem'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', width: '100%' }}>
                <div style={{ flexShrink: 0 }}>
                  <div style={{
                    height: '2.5rem',
                    width: '2.5rem',
                    borderRadius: '50%',
                    background: 'rgba(255,255,255,0.2)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <User style={{ height: '1.5rem', width: '1.5rem', color: 'white' }} />
                  </div>
                </div>
                <div style={{ marginLeft: '0.75rem', flex: 1 }}>
                  <p style={{ fontSize: '0.875rem', fontWeight: '500', color: 'white', margin: 0 }}>
                    {user.firstName} {user.lastName}
                  </p>
                  <p style={{ fontSize: '0.75rem', color: 'rgba(255,255,255,0.7)', margin: 0 }}>
                    {user.type === 'Developer' ? 'Developer' : 'Administrator'}
                  </p>
                </div>
                <button
                  onClick={onLogout}
                  style={{
                    padding: '0.5rem',
                    borderRadius: '0.5rem',
                    border: 'none',
                    backgroundColor: 'rgba(255,255,255,0.1)',
                    color: 'white',
                    cursor: 'pointer',
                    transition: 'all 0.2s'
                  }}
                  title="Logout"
                >
                  <LogOut style={{ height: '1rem', width: '1rem' }} />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Main content */}
        <div className="main-content" style={{ 
          paddingLeft: '16rem', 
          display: 'flex', 
          flexDirection: 'column', 
          flex: 1,
          minHeight: '100vh'
        }}>
          {/* Top navigation bar */}
          <div className="mobile-menu-button" style={{
            position: 'sticky',
            top: 0,
            zIndex: 10,
            display: 'block',
            backgroundColor: 'white',
            borderBottom: '1px solid #e5e7eb',
            padding: '1rem 1.5rem',
            boxShadow: '0 1px 3px rgba(0,0,0,0.1)'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <div style={{ display: 'flex', alignItems: 'center' }}>
                <button
                  type="button"
                  style={{
                    height: '2.5rem',
                    width: '2.5rem',
                    display: 'inline-flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    borderRadius: '0.5rem',
                    color: '#6b7280',
                    backgroundColor: '#f3f4f6',
                    border: 'none',
                    cursor: 'pointer',
                    transition: 'all 0.2s',
                    marginRight: '1rem'
                  }}
                  onClick={() => setSidebarOpen(true)}
                >
                  <Menu style={{ height: '1.25rem', width: '1.25rem' }} />
                </button>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
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
                      placeholder="Search properties, projects, clients..."
                      style={{
                        padding: '0.5rem 0.75rem 0.5rem 2.5rem',
                        border: '1px solid #d1d5db',
                        borderRadius: '0.5rem',
                        fontSize: '0.875rem',
                        width: '20rem',
                        outline: 'none',
                        transition: 'all 0.2s'
                      }}
                    />
                  </div>
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <button style={{
                  padding: '0.5rem',
                  borderRadius: '0.5rem',
                  border: 'none',
                  backgroundColor: '#f3f4f6',
                  color: '#6b7280',
                  cursor: 'pointer',
                  position: 'relative'
                }}>
                  <Bell style={{ height: '1.25rem', width: '1.25rem' }} />
                  <div style={{
                    position: 'absolute',
                    top: '0.25rem',
                    right: '0.25rem',
                    height: '0.5rem',
                    width: '0.5rem',
                    backgroundColor: '#ef4444',
                    borderRadius: '50%'
                  }} />
                </button>
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                  <div style={{
                    height: '2rem',
                    width: '2rem',
                    borderRadius: '50%',
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                  }}>
                    <User style={{ height: '1rem', width: '1rem', color: 'white' }} />
                  </div>
                  <div>
                    <p style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827', margin: 0 }}>
                      {user.firstName} {user.lastName}
                    </p>
                    <p style={{ fontSize: '0.75rem', color: '#6b7280', margin: 0 }}>
                      {user.type === 'Developer' ? 'Developer' : 'Administrator'}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <main style={{ flex: 1 }}>
            <div style={{ padding: '1.5rem 0' }}>
              <div style={{
                maxWidth: '80rem',
                margin: '0 auto',
                paddingLeft: '1.5rem',
                paddingRight: '1.5rem'
              }}>
                {children}
              </div>
            </div>
          </main>
        </div>
      </div>
    </>
  );
};

export default Layout;