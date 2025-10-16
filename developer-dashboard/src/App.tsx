import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Account } from './types';
import { authApi } from './services/api';
import { ToastProvider } from './contexts/ToastContext';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import UsersPage from './pages/UsersPage';
import ProjectsPage from './pages/ProjectsPage';
import PropertiesPage from './pages/PropertiesPage';
import AuctionsPage from './pages/AuctionsPage';
import AnalyticsPage from './pages/AnalyticsPage';
import SettingsPage from './pages/SettingsPage';
import NotificationDashboardPage from './pages/NotificationDashboardPage';
import DocumentsPage from './pages/DocumentsPage';
import DeveloperHomePage from './pages/DeveloperHomePage';
import DeveloperProjectsPage from './pages/DeveloperProjectsPage';
import DeveloperPropertiesPage from './pages/DeveloperPropertiesPage';
import DeveloperChatsPage from './pages/DeveloperChatsPage';
import DeveloperAnalyticsPage from './pages/DeveloperAnalyticsPage';
import DeveloperProfilePage from './pages/DeveloperProfilePage';
import Layout from './components/Layout';

function App() {
  const [user, setUser] = useState<Account | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      const token = localStorage.getItem('authToken');
      if (token) {
        try {
          const account = await authApi.getCurrentAccount();
          // ONLY allow Developer accounts (not Admin, not User)
          if (account.type === 'Developer') {
            setUser(account);
          } else {
            localStorage.removeItem('authToken');
            alert('This dashboard is only for developers. Please use the admin dashboard for admin accounts.');
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
    // Ensure userId is persisted for chat alignment
    if (account?.accountId) {
      localStorage.setItem('userId', String(account.accountId));
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('authToken');
    localStorage.removeItem('userId');
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

  // ONLY DEVELOPERS ALLOWED - redirect to home on load
  return (
    <ToastProvider>
      <Router>
        <Layout user={user} onLogout={handleLogout}>
          <Routes>
            {/* Default redirect to dashboard */}
            <Route path="/" element={<Navigate to="/dashboard" replace />} />

            {/* Developer-Only Routes */}
            <Route path="/dashboard" element={<DeveloperHomePage />} />
            <Route path="/projects" element={<DeveloperProjectsPage />} />
            <Route path="/properties" element={<DeveloperPropertiesPage />} />
            <Route path="/chats" element={<DeveloperChatsPage />} />
            <Route path="/analytics" element={<DeveloperAnalyticsPage />} />
            <Route path="/profile" element={<DeveloperProfilePage />} />

            {/* Fallback */}
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Routes>
        </Layout>
      </Router>
    </ToastProvider>
  );
}

export default App;
