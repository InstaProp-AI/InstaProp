import React from 'react';
import { usePermissions } from '../contexts/PermissionContext';

interface PermissionRouteProps {
  featureName: string;
  children: React.ReactNode;
}

/**
 * Protected route component that checks if user has permission for a specific feature
 * Shows access denied message if permission is missing
 */
const PermissionRoute: React.FC<PermissionRouteProps> = ({ featureName, children }) => {
  const { hasPermission, loading } = usePermissions();

  if (loading) {
    return (
      <div style={{ 
        display: 'flex', 
        alignItems: 'center', 
        justifyContent: 'center', 
        minHeight: '50vh',
        flexDirection: 'column',
        gap: '1rem'
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
        <p style={{ color: '#6b7280' }}>Loading permissions...</p>
      </div>
    );
  }

  if (!hasPermission(featureName)) {
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
        <p style={{ color: '#6b7280' }}>
          You do not have permission to access {featureName}. Please contact an administrator to enable this feature.
        </p>
      </div>
    );
  }

  return <>{children}</>;
};

export default PermissionRoute;

