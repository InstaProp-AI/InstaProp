import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Account } from './types';
import { authApi } from './services/api';
import { ToastProvider } from './contexts/ToastContext';
import { PermissionProvider } from './contexts/PermissionContext';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import UsersPage from './pages/UsersPage';
import DevelopersPage from './pages/DevelopersPage';
import ProjectsPage from './pages/ProjectsPage';
import PropertiesPage from './pages/PropertiesPage';
import AuctionsPage from './pages/AuctionsPage';
import AnalyticsPage from './pages/AnalyticsPage';
import SettingsPage from './pages/SettingsPage';
import NotificationDashboardPage from './pages/NotificationDashboardPage';
import DocumentsPage from './pages/DocumentsPage';
// CommunitiesPage removed (community feature)
import NewsPage from './pages/NewsPage';
import ChatsPage from './pages/ChatsPage';
import LeaderboardPage from './pages/LeaderboardPage';
import RewardsPage from './pages/RewardsPage';
import ValuationPage from './pages/ValuationPage';
import SalesPage from './pages/SalesPage';
import Layout from './components/Layout';
import PermissionRoute from './components/PermissionRoute';
import { ROLE_IDS } from './types';

// Protected route component for admin-only pages - SECURITY: Uses non-guessable roleId
const AdminRoute: React.FC<{ user: Account | null; children: React.ReactNode }> = ({ user, children }) => {
  // Check roleId instead of type for security
  const isAdmin = user && (user.roleId === ROLE_IDS.ADMIN || user.roleName === 'Admin' || user.type === 'Admin');
  if (!isAdmin) {
    return (
      <div style={{ 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center', 
        minHeight: '50vh',
        flexDirection: 'column',
        gap: '1rem'
      }}>
        <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', color: '#ef4444' }}>Access Denied</h2>
        <p style={{ color: '#6b7280' }}>This page is only accessible to administrators.</p>
      </div>
    );
  }
  return <>{children}</>;
};

function App() {
  const [user, setUser] = useState<Account | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      const token = localStorage.getItem('authToken');
      if (token) {
        try {
          const account = await authApi.getCurrentAccount();
          // SECURITY: Check roleName first (from backend), then roleId, then legacy type
          const isAdmin = account.roleName === 'Admin' || account.roleId === ROLE_IDS.ADMIN || account.type === 'Admin';
          const isDeveloper = account.roleName === 'Developer' || account.roleId === ROLE_IDS.DEVELOPER || account.type === 'Developer';
          
          if (isAdmin || isDeveloper) {
            setUser(account);
          } else {
            console.error('Access denied - user role:', { roleName: account.roleName, roleId: account.roleId, type: account.type });
            localStorage.removeItem('authToken');
          }
        } catch (error) {
          localStorage.removeItem('authToken');
        }
      }
      setLoading(false);
    };

    checkAuth();
  }, []);

  const handleLogin = (account: Account) => {
    setUser(account);
  };

  const handleLogout = () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('currentAccount');
    setUser(null);
  };

  if (loading) {
    return (
      <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #dbeafe 0%, #e0e7ff 100%)' }}>
        <div style={{ 
          width: '128px', 
          height: '128px', 
          border: '2px solid #2563eb', 
          borderTop: '2px solid transparent', 
          borderRadius: '50%', 
          animation: 'spin 1s linear infinite' 
        }}></div>
        <style>{`
          @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
          }
        `}</style>
      </div>
    );
  }

  if (!user) {
    return <LoginPage onLogin={handleLogin} />;
  }

  return (
    <ToastProvider>
      <PermissionProvider>
      <Router>
        <Layout user={user} onLogout={handleLogout}>
          <Routes>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<DashboardPage />} />
              <Route path="/users" element={<AdminRoute user={user}><UsersPage /></AdminRoute>} />
              <Route path="/developers" element={<AdminRoute user={user}><DevelopersPage /></AdminRoute>} />
            <Route path="/sales" element={<SalesPage />} />
            <Route path="/projects" element={<ProjectsPage />} />
            <Route path="/properties" element={<PropertiesPage />} />
              {/* Optional features - protected by permissions */}
              {/* Communities route removed */}
              <Route path="/news" element={<PermissionRoute featureName="News"><NewsPage /></PermissionRoute>} />
              <Route path="/auctions" element={<PermissionRoute featureName="Auctions"><AuctionsPage /></PermissionRoute>} />
              <Route path="/chats" element={<PermissionRoute featureName="Chats"><ChatsPage /></PermissionRoute>} />
              <Route path="/leaderboard" element={<PermissionRoute featureName="Leaderboard"><LeaderboardPage /></PermissionRoute>} />
              <Route path="/rewards" element={<PermissionRoute featureName="Rewards"><RewardsPage /></PermissionRoute>} />
              <Route path="/valuation" element={<PermissionRoute featureName="Valuation"><ValuationPage /></PermissionRoute>} />
              {/* Admin-only and default features */}
            <Route path="/documents" element={<DocumentsPage />} />
              <Route path="/notifications" element={<AdminRoute user={user}><NotificationDashboardPage /></AdminRoute>} />
            <Route path="/analytics" element={<AnalyticsPage />} />
            <Route path="/settings" element={<SettingsPage />} />
          </Routes>
        </Layout>
      </Router>
      </PermissionProvider>
    </ToastProvider>
  );
}

export default App;
