import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { DeveloperPermissions } from '../types';
import { permissionsApi, authApi } from '../services/api';
import { Account } from '../types';

interface PermissionContextType {
  permissions: DeveloperPermissions | null;
  loading: boolean;
  hasPermission: (featureName: string) => boolean;
  refreshPermissions: () => Promise<void>;
}

const PermissionContext = createContext<PermissionContextType | undefined>(undefined);

export const PermissionProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [permissions, setPermissions] = useState<DeveloperPermissions | null>(null);
  const [loading, setLoading] = useState(true);
  const [user, setUser] = useState<Account | null>(null);

  const loadPermissions = useCallback(async () => {
    try {
      setLoading(true);
      
      // Check if user is authenticated first
      const token = localStorage.getItem('authToken');
      if (!token) {
        setPermissions(null);
        setLoading(false);
        return;
      }
      
      // Get current user to check role
      const currentUser = await authApi.getCurrentAccount();
      setUser(currentUser);
      
      // Admins have all permissions - check roleName first, then roleId, then legacy type
      const isAdmin = currentUser.roleName === 'Admin' || currentUser.roleId === '98237498-2374-4982-3749-823749823749' || currentUser.type === 'Admin';
      const isDeveloper = currentUser.roleName === 'Developer' || currentUser.roleId === '78236478-2364-7823-0000-000000000000' || currentUser.type === 'Developer';
      
      if (isAdmin) {
        // Admin has all features enabled
        const allPermissions: DeveloperPermissions = {
          Projects: true,
          Properties: true,
          Analytics: true,
          // Communities removed
          News: true,
          Auctions: true,
          Leaderboard: true,
          Notifications: true,
          PriceHistory: true,
          FullAnalytics: true,
          Rewards: true,
          Valuation: true,
          Chats: true,
        };
        setPermissions(allPermissions);
        setLoading(false);
        return;
      }
      
      // For developers, fetch their permissions
      if (isDeveloper) {
        try {
          const perms = await permissionsApi.getMyPermissions();
          setPermissions(perms);
        } catch (permError) {
          console.error('Error fetching developer permissions:', permError);
          // Set default permissions for developers on error
          setPermissions({
            Projects: true,
            Properties: true,
            Analytics: true,
          });
        }
        setLoading(false);
        return;
      }
      
      // Other roles have no permissions
      setPermissions(null);
      setLoading(false);
    } catch (error) {
      console.error('Error loading permissions:', error);
      setPermissions(null);
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadPermissions();
  }, [loadPermissions]);

  const hasPermission = useCallback((featureName: string): boolean => {
    // Admins always have permission - check roleName first, then roleId, then legacy type
    if (user) {
      const isAdmin = user.roleName === 'Admin' || user.roleId === '98237498-2374-4982-3749-823749823749' || user.type === 'Admin';
      if (isAdmin) return true;
    }
    
    // Default features are always accessible for developers
    if (featureName === 'Projects' || featureName === 'Properties' || featureName === 'Analytics') {
      return true;
    }
    
    // Check permissions for optional features
    if (!permissions) {
      return false;
    }
    
    return permissions[featureName] === true;
  }, [permissions, user]);

  const refreshPermissions = useCallback(async () => {
    await loadPermissions();
  }, [loadPermissions]);

  return (
    <PermissionContext.Provider value={{ permissions, loading, hasPermission, refreshPermissions }}>
      {children}
    </PermissionContext.Provider>
  );
};

export const usePermissions = (): PermissionContextType => {
  const context = useContext(PermissionContext);
  if (context === undefined) {
    throw new Error('usePermissions must be used within a PermissionProvider');
  }
  return context;
};

