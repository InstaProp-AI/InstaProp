import axios from 'axios';
import { Account, Project, Property, DashboardStats, CreateProjectDto, UpdateProjectDto, CreatePropertyDto, UserDocument, PropertyDocument, PropertyImage, DeveloperPermissions, UpdatePermissionsDto, PaginatedResponse } from '../types';
import { convertAccount, convertProperty } from '../utils/converters';

// Determine API base URL based on environment
// In production (Railway), dashboard and API are served from the same domain, so use relative URL
// In development, use localhost
const getApiBaseUrl = (): string => {
  // Check if we're in development mode (Vite sets this)
  if (import.meta.env.DEV) {
    // Development: use localhost
    return import.meta.env.VITE_API_BASE_URL || 'http://localhost:5284/api';
  }
  
  // Production: use relative URL since dashboard and API are on the same domain
  // Railway serves both from the same container, so /api will work
  return '/api';
};

const API_BASE_URL = getApiBaseUrl();

// Log API configuration (only in development)
if (import.meta.env.DEV) {
  console.log('🔧 API Configuration:', {
    mode: import.meta.env.MODE,
    baseURL: API_BASE_URL,
    isDev: import.meta.env.DEV,
  });
}

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
    console.log('🔑 Token found and added to request:', {
      url: config.url,
      method: config.method,
      fullUrl: `${config.baseURL}${config.url}`,
      hasToken: !!token
    });
  } else {
    console.warn('⚠️ No token found in localStorage for request:', config.url);
  }
  return config;
}, (error) => {
  console.error('❌ Request interceptor error:', error);
  return Promise.reject(error);
});

// Handle 401 errors (unauthorized) - redirect to login
// AND convert backend numeric enums to strings
api.interceptors.response.use(
  (response) => {
    console.log('✅ API Response:', response.config.url, response.status);
    
    const url = response.config.url || '';
    
    // Convert user/account data (arrays)
    if (url.includes('/admin/users') || url.includes('/account')) {
      const convertUserData = (userData: any) => {
        const converted = convertAccount(userData);
        
        // If user details with properties and bids, convert those too
        if (userData.properties && Array.isArray(userData.properties)) {
          converted.properties = userData.properties.map(convertProperty);
        }
        if (userData.bids && Array.isArray(userData.bids)) {
          converted.bids = userData.bids.map((bid: any) => ({
            ...bid,
            auction: bid.auction ? {
              ...bid.auction,
              property: bid.auction.property ? convertProperty(bid.auction.property) : null
            } : null
          }));
        }
        
        return converted;
      };
      
      if (Array.isArray(response.data)) {
        response.data = response.data.map(convertUserData);
      } else if (response.data && typeof response.data === 'object') {
        response.data = convertUserData(response.data);
      }
    }
    
    // Convert property data (arrays)
    if (url.includes('/properties') || url.includes('/property/')) {
      if (Array.isArray(response.data)) {
        response.data = response.data.map(convertProperty);
      } else if (response.data && typeof response.data === 'object') {
        response.data = convertProperty(response.data);
      }
    }
    
    // Convert auction data (has property inside)
    if (url.includes('/auctions') || url.includes('/auction/')) {
      const convertAuction = (auction: any) => {
        try {
          const prop = auction.property || auction.Property;
          
          // Helper function to safely calculate endAt
          const calculateEndAt = () => {
            if (auction.endAt || auction.EndAt) {
              return auction.endAt || auction.EndAt;
            }
            
            const startAt = auction.startAt || auction.StartAt;
            const duration = auction.duration || auction.Duration;
            
            if (!startAt || !duration) {
              return null;
            }
            
            try {
              const startDate = new Date(startAt);
              if (isNaN(startDate.getTime())) {
                return null;
              }
              return new Date(startDate.getTime() + duration * 3600000).toISOString();
            } catch (e) {
              console.warn('Failed to calculate endAt for auction:', e);
              return null;
            }
          };
          
          return {
            ...auction,
            // Normalize field names to camelCase
            auctionId: auction.auctionId || auction.AuctionId,
            propertyId: auction.propertyId || auction.PropertyId,
            startPrice: auction.startPrice || auction.StartPrice,
            currentPrice: auction.currentPrice || auction.CurrentPrice,
            startAt: auction.startAt || auction.StartAt || null,
            duration: auction.duration || auction.Duration,
            buyNowPrice: auction.buyNowPrice || auction.BuyNowPrice,
            status: auction.status || auction.Status,
            bidCount: auction.bidCount || auction.BidCount,
            createdAt: auction.createdAt || auction.CreatedAt || null,
            // Add computed endAt if not present
            endAt: calculateEndAt(),
            property: prop ? convertProperty(prop) : null
          };
        } catch (error) {
          console.error('Error converting auction:', error, auction);
          // Return minimal safe version
          return {
            ...auction,
            auctionId: auction.auctionId || auction.AuctionId,
            propertyId: auction.propertyId || auction.PropertyId,
            startPrice: auction.startPrice || auction.StartPrice || 0,
            currentPrice: auction.currentPrice || auction.CurrentPrice || 0,
            startAt: null,
            duration: auction.duration || auction.Duration || 0,
            status: auction.status || auction.Status || 'Unknown',
            endAt: null,
            property: null
          };
        }
      };
      
      if (Array.isArray(response.data)) {
        response.data = response.data.map(convertAuction);
      } else if (response.data && typeof response.data === 'object') {
        response.data = convertAuction(response.data);
      }
    }
    
    // Convert bid data (has bidder and auction inside)
    if (url.includes('/bids') || url.includes('/bid/')) {
      const convertBid = (bid: any) => {
        try {
          const bidder = bid.bidder || bid.Bidder;
          const auction = bid.auction || bid.Auction;
          const convertedBidder = bidder ? convertAccount(bidder) : null;
          
          // Helper function to safely calculate endAt
          const calculateEndAt = (auction: any) => {
            if (auction.endAt || auction.EndAt) {
              return auction.endAt || auction.EndAt;
            }
            
            const startAt = auction.startAt || auction.StartAt;
            const duration = auction.duration || auction.Duration;
            
            if (!startAt || !duration) {
              return null;
            }
            
            try {
              const startDate = new Date(startAt);
              if (isNaN(startDate.getTime())) {
                return null;
              }
              return new Date(startDate.getTime() + duration * 3600000).toISOString();
            } catch (e) {
              console.warn('Failed to calculate endAt for auction:', e);
              return null;
            }
          };
          
          return {
            ...bid,
            // Normalize field names to camelCase
            bidId: bid.bidId || bid.BidId,
            auctionId: bid.auctionId || bid.AuctionId,
            bidderId: bid.bidderId || bid.BidderId,
            bidAmount: bid.bidAmount || bid.BidAmount,
            createdAt: bid.createdAt || bid.CreatedAt || null,
            // Computed fields for display
            bidderName: convertedBidder ? `${convertedBidder.firstName} ${convertedBidder.lastName}` : 'Unknown',
            bidderEmail: convertedBidder?.email || '',
            propertyName: auction?.property?.name || auction?.Property?.Name || 'Unknown Property',
            propertyLocation: auction?.property?.location || auction?.Property?.Location || 'Unknown Location',
            timestamp: bid.createdAt || bid.CreatedAt || null,
            bidder: convertedBidder,
            auction: auction ? {
              ...auction,
              auctionId: auction.auctionId || auction.AuctionId,
              propertyId: auction.propertyId || auction.PropertyId,
              startPrice: auction.startPrice || auction.StartPrice,
              currentPrice: auction.currentPrice || auction.CurrentPrice,
              startAt: auction.startAt || auction.StartAt || null,
              duration: auction.duration || auction.Duration,
              status: auction.status || auction.Status,
              endAt: calculateEndAt(auction),
              property: auction.property || auction.Property ? convertProperty(auction.property || auction.Property) : null
            } : null
          };
        } catch (error) {
          console.error('Error converting bid:', error, bid);
          // Return a minimal safe version of the bid
          return {
            ...bid,
            bidId: bid.bidId || bid.BidId,
            auctionId: bid.auctionId || bid.AuctionId,
            bidderId: bid.bidderId || bid.BidderId,
            bidAmount: bid.bidAmount || bid.BidAmount || 0,
            createdAt: null,
            timestamp: null,
            bidder: null,
            auction: null
          };
        }
      };
      
      if (Array.isArray(response.data)) {
        response.data = response.data.map(convertBid);
      } else if (response.data && typeof response.data === 'object') {
        response.data = convertBid(response.data);
      }
    }
    
    return response;
  },
  (error) => {
    const status = error.response?.status;
    const url = error.config?.url;
    
    console.error('❌ API Error:', {
      url,
      status,
      message: error.message,
      data: error.response?.data
    });
    
    // Handle 403 Forbidden - Access denied
    if (status === 403) {
      console.error('🚫 403 Forbidden: You do not have permission to access this resource.');
      console.error('   Current endpoint:', url);
    }
    
    if (status === 401) {
      // Don't redirect on login endpoint errors - let the login page handle it
      const isLoginEndpoint = url?.includes('/account/login');
      if (!isLoginEndpoint) {
        console.warn('🔒 Unauthorized - Clearing token and redirecting to login');
        localStorage.removeItem('authToken');
        localStorage.removeItem('currentAccount');
        window.location.href = '/';
      }
    }
    
    return Promise.reject(error);
  }
);

// Helper function to get current user role
const getCurrentUserRole = (): 'Admin' | 'Developer' | null => {
  try {
    const token = localStorage.getItem('authToken');
    if (!token) return null;
    // Try to get from stored account info (if available)
    const accountStr = localStorage.getItem('currentAccount');
    if (accountStr) {
      const account = JSON.parse(accountStr);
      return account.type === 'Admin' || account.type === 'Developer' ? account.type : null;
    }
    // If not stored, we'll need to fetch it - but for now return null
    // Components should pass the user role explicitly
    return null;
  } catch {
    return null;
  }
};

// Auth API
export const authApi = {
  login: async (email: string, password: string) => {
    const response = await api.post('/account/login', { email, password });
    // Store account info for role-based access
    if (response.data && response.data.account) {
      localStorage.setItem('currentAccount', JSON.stringify(response.data.account));
    }
    return response.data;
  },
  
  getCurrentAccount: async (): Promise<Account> => {
    const response = await api.get('/account/me');
    // Store account info for role-based access
    if (response.data) {
      localStorage.setItem('currentAccount', JSON.stringify(response.data));
    }
    return response.data;
  },
};

// Users/Accounts API - Using Admin endpoints
export const usersApi = {
  // Get user statistics (total counts)
  getUserStatistics: async (): Promise<{
    total: number;
    verified: number;
    pending: number;
    notVerified: number;
    suspended: number;
  }> => {
    const response = await api.get('/admin/stats');
    return response.data.users;
  },
  
  getAllUsers: async (page: number = 1, pageSize: number = 10): Promise<PaginatedResponse<Account>> => {
    const response = await api.get(`/admin/users?page=${page}&pageSize=${pageSize}`);
    return response.data;
  },
  
  getUser: async (id: string): Promise<Account> => {
    const response = await api.get(`/admin/users/${id}`);
    return response.data;
  },
  
  verifyUser: async (id: string): Promise<void> => {
    await api.put(`/admin/users/${id}/verify`);
  },
  
  rejectUser: async (id: string): Promise<void> => {
    await api.put(`/admin/users/${id}/reject`);
  },
  
  banUser: async (id: string): Promise<void> => {
    await api.delete(`/admin/users/${id}`);
  },

  suspendUser: async (id: string, suspendedUntil: string | null, reason: string): Promise<void> => {
    await api.put(`/admin/users/${id}/suspend`, {
      suspendedUntil,
      reason
    });
  },

  unsuspendUser: async (id: string): Promise<void> => {
    await api.put(`/admin/users/${id}/unsuspend`);
  },

  updateUser: async (id: string, data: { firstName?: string; lastName?: string; email?: string; phoneNumber?: string }): Promise<void> => {
    await api.put(`/admin/users/${id}/update`, data);
  },

  verifyEmail: async (id: string): Promise<void> => {
    console.log(`📧 API: Sending PUT request to /admin/users/${id}/verify-email`);
    const response = await api.put(`/admin/users/${id}/verify-email`);
    console.log('📧 API: Email verification response:', response.data);
    return response.data;
  },

  verifyPhone: async (id: string): Promise<void> => {
    console.log(`📱 API: Sending PUT request to /admin/users/${id}/verify-phone`);
    const response = await api.put(`/admin/users/${id}/verify-phone`);
    console.log('📱 API: Phone verification response:', response.data);
    return response.data;
  },

  changeUserType: async (id: string, type: 'User' | 'Developer' | 'Admin'): Promise<void> => {
    const typeValue = type === 'Admin' ? 2 : type === 'Developer' ? 1 : 0;
    await api.put(`/admin/users/${id}/change-type`, { type: typeValue });
  },

  resetPassword: async (id: string): Promise<void> => {
    await api.put(`/admin/users/${id}/reset-password`);
  },
};

// Sales API
export const salesApi = {
  // Get all sales team members
  getSalesTeamMembers: async (): Promise<Account[]> => {
    const response = await api.get('/admin/users', {
      params: { roleId: '67235467-2354-6723-0000-000000000000', pageSize: 1000 } // Sales role ID, large page size to get all
    });
    // Handle paginated response structure
    const users = response.data?.data || response.data?.items || response.data || [];
    return Array.isArray(users) ? users : [];
  },

  // Get developers list (for admin dropdown)
  getDevelopers: async (): Promise<Account[]> => {
    const response = await api.get('/admin/users', {
      params: { roleId: '78236478-2364-7823-0000-000000000000', pageSize: 1000 } // Developer role ID, large page size to get all
    });
    // Handle paginated response structure
    const users = response.data?.data || response.data?.items || response.data || [];
    return Array.isArray(users) ? users : [];
  },

  // Create sales account
  createSalesAccount: async (data: {
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber?: string;
    phone?: string; // Accept both phone and phoneNumber for compatibility
    password: string;
    developerId?: string; // Required for admin, auto-assigned for developer
    teamId?: string; // Optional sales team ID
  }): Promise<Account> => {
    // Use phoneNumber if provided, otherwise fall back to phone
    const phoneNumber = data.phoneNumber || data.phone;
    if (!phoneNumber) {
      throw new Error('Phone number is required');
    }
    
    // ASP.NET Core by default uses camelCase JSON serialization
    // The backend model binding will map camelCase to PascalCase properties
    const requestData: any = {
      firstName: data.firstName,
      lastName: data.lastName,
      email: data.email,
      phoneNumber: phoneNumber,
      password: data.password,
    };
    // Include developerId if provided
    if (data.developerId !== undefined) {
      requestData.developerId = data.developerId;
    }
    // Include teamId if provided
    if (data.teamId !== undefined) {
      requestData.salesTeamId = data.teamId;
    }
    const response = await api.post('/account/signup-sales', requestData);
    return response.data.account || response.data;
  },

  // Update sales account
  updateSalesAccount: async (id: string, data: {
    firstName?: string;
    lastName?: string;
    email?: string;
    phoneNumber?: string;
    developerId?: string;
  }): Promise<void> => {
    const updateData: any = {
      firstName: data.firstName,
      lastName: data.lastName,
      email: data.email,
      phoneNumber: data.phoneNumber,
    };
    // Include AssignedDeveloperId if provided
    if (data.developerId !== undefined) {
      updateData.assignedDeveloperId = data.developerId;
    }
    await api.put(`/admin/users/${id}/update`, updateData);
  },

  // Delete sales account
  deleteSalesAccount: async (id: string): Promise<void> => {
    await api.delete(`/admin/users/${id}`);
  },

  // Sales Team API
  getSalesTeams: async (): Promise<any[]> => {
    const response = await api.get('/SalesTeam');
    return response.data || [];
  },

  getSalesTeam: async (id: string): Promise<any> => {
    const response = await api.get(`/SalesTeam/${id}`);
    return response.data;
  },

  getTeamMembers: async (teamId: string): Promise<Account[]> => {
    const response = await api.get(`/SalesTeam/${teamId}/members`);
    return response.data || [];
  },

  getTeamStats: async (teamId: string): Promise<any> => {
    const response = await api.get(`/SalesTeam/${teamId}/stats`);
    return response.data;
  },

  getDeveloperTeams: async (developerId: string): Promise<any[]> => {
    const response = await api.get(`/SalesTeam/developers/${developerId}/teams`);
    return response.data || [];
  },

  createSalesTeam: async (data: { teamName?: string; developerId: string }): Promise<any> => {
    const response = await api.post('/SalesTeam', data);
    return response.data;
  },

  updateSalesTeam: async (id: string, data: { teamName?: string; developerId?: string }): Promise<any> => {
    const response = await api.put(`/SalesTeam/${id}`, data);
    return response.data;
  },

  deleteSalesTeam: async (id: string): Promise<void> => {
    await api.delete(`/SalesTeam/${id}`);
  },
};

// Projects API - Role-based (backend handles authorization)
export const projectsApi = {
  // Backend /project endpoint already handles role-based filtering
  // Admin: all projects, Developer: only their projects
  getProjects: async (): Promise<Project[]> => {
    const response = await api.get('/project');
    return response.data;
  },
  
  getProjectsByDeveloper: async (developerId: string): Promise<Project[]> => {
    const response = await api.get(`/project/by-developer/${developerId}`);
    return response.data;
  },
  
  getProject: async (id: string): Promise<Project> => {
    const response = await api.get(`/project/${id}`);
    return response.data;
  },
  
  createProject: async (data: CreateProjectDto): Promise<Project> => {
    const response = await api.post('/project', data);
    return response.data;
  },
  
  updateProject: async (id: string, data: UpdateProjectDto): Promise<void> => {
    await api.put(`/project/${id}`, data);
  },
  
  deleteProject: async (id: string): Promise<void> => {
    await api.delete(`/project/${id}`);
  },
  
  getProjectProperties: async (id: string): Promise<Property[]> => {
    const response = await api.get(`/project/${id}/properties`);
    return response.data;
  },
};

// Properties API - Role-based endpoints
export const propertiesApi = {
  // Get properties based on user role with pagination
  // Admin: all properties (paginated), Developer: only their properties
  getProperties: async (userRole?: 'Admin' | 'Developer', page: number = 1, pageSize: number = 10): Promise<Property[] | PaginatedResponse<Property>> => {
    const role = userRole || getCurrentUserRole();
    if (role === 'Developer') {
      // Developer: get only their properties (where OwnerId == developerId)
      const response = await api.get('/developer/properties');
      return response.data;
    } else {
      // Admin: get paginated properties
      const response = await api.get(`/admin/properties?page=${page}&pageSize=${pageSize}`);
    return response.data;
    }
  },
  
  getProperty: async (id: string): Promise<Property> => {
    const response = await api.get(`/property/${id}`);
    return response.data;
  },
  
  createProperty: async (data: CreatePropertyDto): Promise<Property> => {
    const response = await api.post('/property', data);
    return response.data;
  },
  
  updateProperty: async (id: string, data: Partial<CreatePropertyDto & { projectId?: string | null }>, userRole?: 'Admin' | 'Developer'): Promise<void> => {
    const role = userRole || getCurrentUserRole();
    if (role === 'Admin') {
      // Admin can use admin endpoint
    await api.put(`/admin/properties/${id}/update`, data);
    } else {
      // Developer uses standard property endpoint
      await api.put(`/property/${id}`, data);
    }
  },
  
  deleteProperty: async (id: string): Promise<void> => {
    await api.delete(`/property/${id}`);
  },
  
  // Admin-only functions
  approveProperty: async (id: string, userRole?: 'Admin' | 'Developer'): Promise<void> => {
    const role = userRole || getCurrentUserRole();
    if (role !== 'Admin') {
      throw new Error('Only admins can approve properties');
    }
    await api.put(`/admin/properties/${id}/approve`);
  },
  
  rejectProperty: async (id: string, userRole?: 'Admin' | 'Developer'): Promise<void> => {
    const role = userRole || getCurrentUserRole();
    if (role !== 'Admin') {
      throw new Error('Only admins can reject properties');
    }
    await api.put(`/admin/properties/${id}/reject`);
  },
};

// Dashboard API - Role-based endpoints
export const dashboardApi = {
  getStats: async (userRole?: 'Admin' | 'Developer'): Promise<DashboardStats | any> => {
    const role = userRole || getCurrentUserRole();
    if (role === 'Developer') {
      // Developer: get their analytics
      const response = await api.get('/developer/analytics');
      return response.data;
    } else {
      // Admin: get admin stats from /admin/stats (matches DashboardController structure)
      const response = await api.get('/admin/stats');
      return response.data;
    }
  },
  
  getAnalytics: async (userRole?: 'Admin' | 'Developer') => {
    const role = userRole || getCurrentUserRole();
    if (role === 'Developer') {
      // Developer: get their analytics
      const response = await api.get('/developer/analytics');
      return response.data;
    } else {
      // Admin: get admin analytics from /admin/analytics
      const response = await api.get('/admin/analytics');
      return response.data;
    }
  },
};

// Developer API - Additional developer-specific endpoints
export const developerApi = {
  getAnalytics: async () => {
    const response = await api.get('/developer/analytics');
    return response.data;
  },
  
  getProperties: async () => {
    const response = await api.get('/developer/properties');
    return response.data;
  },
  
  getProjects: async () => {
    const response = await api.get('/developer/projects');
    return response.data;
  },
};

// Auctions API - Role-based endpoints
export const auctionsApi = {
  getAllAuctions: async (userRole?: 'Admin' | 'Developer') => {
    const role = userRole || getCurrentUserRole();
    if (role === 'Admin') {
      const response = await api.get('/admin/auctions');
      return response.data;
    } else {
      // Developers can see auctions for their properties
      // For now, use a general endpoint or filter client-side
      // Backend may need to add /developer/auctions endpoint
    const response = await api.get('/admin/auctions');
    return response.data;
    }
  },
  
  getAuction: async (id: string) => {
    const response = await api.get(`/auction/${id}`);
    return response.data;
  },
  
  startAuction: async (id: string) => {
    await api.put(`/admin/auctions/${id}/start`);
  },
  
  endAuction: async (id: string) => {
    await api.put(`/admin/auctions/${id}/end`);
  },
  
  cancelAuction: async (id: string) => {
    await api.delete(`/auction/${id}`);
  },
  
  approveAuction: async (id: string) => {
    await api.put(`/auction/${id}/status`, { status: 'Approved' });
  },
  
  rejectAuction: async (id: string) => {
    await api.put(`/auction/${id}/status`, { status: 'Rejected' });
  },

  relistAuction: async (id: string, data: {
    startAt?: string;
    duration: number;
    resetPrice: boolean;
    resetBids: boolean;
  }) => {
    const response = await api.post(`/auction/${id}/relist`, data);
    return response.data;
  },
};

// Bids API - Using Admin endpoints
export const bidsApi = {
  getAllBids: async () => {
    const response = await api.get('/admin/bids');
    return response.data;
  },
  
  getBidsForAuction: async (auctionId: string) => {
    const response = await api.get(`/bids/by-auction/${auctionId}`);
    return response.data;
  },
  
  getBiddersForAuction: async (auctionId: string) => {
    const response = await api.get(`/bids/bidders/${auctionId}`);
    return response.data;
  },
};

// Settings API
export const settingsApi = {
  getSettings: async () => {
    const response = await api.get('/settings');
    return response.data;
  },
  
  updateSettings: async (settings: any) => {
    const response = await api.put('/settings', settings);
    return response.data;
  },
  
  backupDatabase: async () => {
    const response = await api.post('/settings/backup-database');
    return response.data;
  },
  
  clearCache: async () => {
    const response = await api.post('/settings/clear-cache');
    return response.data;
  },
  
  getSystemInfo: async () => {
    const response = await api.get('/settings/system-info');
    return response.data;
  },
};

// Notifications API
export const notificationsApi = {
  getUserStats: async () => {
    const response = await api.get('/notification/admin/stats');
    return response.data;
  },
  
  getUsers: async (filter?: string) => {
    const url = filter ? `/notification/admin/users?filter=${filter}` : '/notification/admin/users';
    const response = await api.get(url);
    return response.data;
  },
  
  sendNotification: async (data: {
    targetType: string;
    title: string;
    message: string;
    userIds?: number[];
  }) => {
    const response = await api.post('/notification/admin/send', data);
    return response.data;
  },
  
  getNotificationHistory: async (page: number = 1, pageSize: number = 50) => {
    const response = await api.get(`/notification/admin/history?page=${page}&pageSize=${pageSize}`);
    return response.data;
  },
};

// Documents API
export const documentsApi = {
  // User Documents (KYC)
  uploadUserDocument: async (file: File, docType: string): Promise<{ message: string; docId: string; url: string }> => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('docType', docType);
    
    const response = await api.post('/document/user/upload', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    });
    return response.data;
  },
  
  getMyDocuments: async (): Promise<UserDocument[]> => {
    const response = await api.get('/document/user/my-documents');
    return response.data;
  },
  
  getUserDocuments: async (userId: string): Promise<UserDocument[]> => {
    console.log(`🔵 documentsApi.getUserDocuments called with userId: ${userId}`);
    const response = await api.get(`/document/user/${userId}`);
    console.log(`🔵 documentsApi.getUserDocuments response:`, response.data);
    console.log(`🔵 Response type:`, Array.isArray(response.data) ? 'Array' : typeof response.data);
    console.log(`🔵 Response length:`, response.data?.length);
    return response.data;
  },
  
  deleteUserDocument: async (docId: string): Promise<void> => {
    await api.delete(`/document/user/${docId}`);
  },
  
  // Property Documents
  uploadPropertyDocument: async (propertyId: string, file: File, docType: string): Promise<{ message: string; docId: string; url: string }> => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('docType', docType);
    
    const response = await api.post(`/document/property/${propertyId}/upload`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    });
    return response.data;
  },
  
  getPropertyDocuments: async (propertyId: string): Promise<PropertyDocument[]> => {
    const response = await api.get(`/document/property/${propertyId}`);
    return response.data;
  },
  
  deletePropertyDocument: async (docId: string): Promise<void> => {
    await api.delete(`/document/property/document/${docId}`);
  },
  
  // Property Images
  uploadPropertyImage: async (
    propertyId: string, 
    file: File, 
    imageType: string,
    isMainImage: boolean = false,
    displayOrder: number = 0
  ): Promise<{ message: string; imageId: string; url: string }> => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('imageType', imageType);
    formData.append('isMainImage', isMainImage.toString());
    formData.append('displayOrder', displayOrder.toString());
    
    const response = await api.post(`/document/property/${propertyId}/upload-image`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    });
    return response.data;
  },
  
  getPropertyImages: async (propertyId: string): Promise<PropertyImage[]> => {
    const response = await api.get(`/document/property/${propertyId}/images`);
    return response.data;
  },
  
  deletePropertyImage: async (imageId: string): Promise<void> => {
    await api.delete(`/document/property/image/${imageId}`);
  },
  
  // Statistics (Admin only)
  getDocumentStatistics: async () => {
    const response = await api.get('/document/statistics');
    return response.data;
  },
};

// Developer Permissions API
export const permissionsApi = {
  // Get current developer's permissions
  getMyPermissions: async (): Promise<DeveloperPermissions> => {
    const response = await api.get('/developerpermission/my-permissions');
    return response.data;
  },
  
  // Admin: Get developer permissions
  getDeveloperPermissions: async (developerId: string): Promise<DeveloperPermissions> => {
    const response = await api.get(`/admin/developers/${developerId}/permissions`);
    return response.data;
  },
  
  // Admin: Update developer permissions
  updateDeveloperPermissions: async (developerId: string, permissions: DeveloperPermissions): Promise<DeveloperPermissions> => {
    const response = await api.put(`/admin/developers/${developerId}/permissions`, {
      Permissions: permissions
    });
    return response.data.permissions || response.data;
  },
  
  // Admin: Initialize developer permissions (create default records)
  initializeDeveloperPermissions: async (developerId: string): Promise<DeveloperPermissions> => {
    const response = await api.post(`/admin/developers/${developerId}/permissions/initialize`);
    return response.data.permissions || response.data;
  },
  
  // Admin: Get all developer permissions
  getAllDeveloperPermissions: async (): Promise<Record<string, DeveloperPermissions>> => {
    const response = await api.get('/admin/developers/permissions/all');
    return response.data;
  },
};


// Admin Seeding API
export const adminSeedingApi = {
  seedDeveloperNews: async () => {
    const response = await api.post('/admin/seed-developer-news');
    return response.data;
  },
  seedChats: async () => {
    const response = await api.post('/admin/seed-chats');
    return response.data;
  },
};

// News API
export const newsApi = {
  getNews: async (page: number = 1, pageSize: number = 10, developerId?: string) => {
    const params = new URLSearchParams({
      page: page.toString(),
      pageSize: pageSize.toString(),
    });
    if (developerId !== undefined) {
      params.append('developerId', developerId.toString());
    }
    const response = await api.get(`/news?${params.toString()}`);
    return response.data;
  },
  
  getDevelopersWithNews: async () => {
    const response = await api.get('/news/developers');
    return response.data;
  },
  
  getNewsById: async (id: string) => {
    const response = await api.get(`/news/${id}`);
    return response.data;
  },
  
  getLatestNews: async (count: number = 3) => {
    const response = await api.get(`/news/latest?count=${count}`);
    return response.data;
  },
  
  searchNews: async (query: string, page: number = 1, pageSize: number = 10) => {
    const response = await api.get(`/news/search?query=${encodeURIComponent(query)}&page=${page}&pageSize=${pageSize}`);
    return response.data;
  },
  
  createNews: async (data: any) => {
    const response = await api.post('/news', data);
    return response.data;
  },
  
  updateNews: async (id: string, data: any) => {
    await api.put(`/news/${id}`, data);
  },
  
  deleteNews: async (id: string) => {
    await api.delete(`/news/${id}`);
  },
};


// Chats API
export const chatsApi = {
  getChats: async (developerId?: string) => {
    const params = new URLSearchParams();
    if (developerId !== undefined) {
      params.append('developerId', developerId.toString());
    }
    const url = params.toString() ? `/chat?${params.toString()}` : '/chat';
    const response = await api.get(url);
    return response.data;
  },
  
  getChat: async (chatId: string) => {
    const response = await api.get(`/chat/${chatId}`);
    return response.data;
  },
  
  createChat: async (data: any) => {
    const response = await api.post('/chat', data);
    return response.data;
  },
  
  sendMessage: async (chatId: string, data: any) => {
    const response = await api.post(`/chat/${chatId}/message`, data);
    return response.data;
  },
  
  markAsRead: async (chatId: string) => {
    await api.put(`/chat/${chatId}/read`);
  },
  
  assignSalesMember: async (chatId: string, salesMemberId: string | null) => {
    const response = await api.put(`/chat/${chatId}/assign`, { salesMemberId });
    return response.data;
  },
  
  getDevelopersWithChats: async () => {
    const response = await api.get('/chat/developers');
    return response.data;
  },
  
  getChatStats: async (developerId?: string) => {
    const params = developerId !== undefined ? `?developerId=${developerId}` : '';
    const response = await api.get(`/chat/stats${params}`);
    return response.data;
  },
  
  getSalesMembersForDeveloper: async (developerId: string) => {
    const response = await api.get(`/chat/${developerId}/sales-members`);
    return response.data;
  },
};

// Leaderboard API
export const leaderboardApi = {
  getLeaderboard: async () => {
    const response = await api.get('/leaderboard');
    return response.data;
  },
  
  getHighlights: async () => {
    const response = await api.get('/leaderboard/highlights');
    return response.data;
  },
};

// Price History API
export const priceHistoryApi = {
  getPriceHistoryForProperty: async (propertyId: string) => {
    const response = await api.get(`/pricehistory/${propertyId}`);
    return response.data;
  },

  getPropertyPriceHistoryBundle: async (propertyId: string) => {
    const response = await api.get(`/pricehistory/${propertyId}/bundle`);
    return response.data;
  },

  getPropertyPriceStatistics: async (propertyId: string) => {
    const response = await api.get(`/pricehistory/${propertyId}/stats`);
    return response.data;
  },

  createPriceHistory: async (data: any) => {
    const response = await api.post('/pricehistory', data);
    return response.data;
  },

  updatePriceHistory: async (priceHistoryId: string, data: any) => {
    await api.put(`/pricehistory/${priceHistoryId}`, data);
  },
};

// Rewards API (Redemption)
export const rewardsApi = {
  redeem: async (data: any) => {
    const response = await api.post('/redemption/redeem', data);
    return response.data;
  },
  
  getRedemptionHistory: async () => {
    const response = await api.get('/redemption/history');
    return response.data;
  },
};

// Valuation API
export const valuationApi = {
  calculate: async (data: any) => {
    const response = await api.post('/valuation/calculate', data);
    return response.data;
  },
  
  calculateAI: async (data: any) => {
    const response = await api.post('/valuation/calculate-ai', data);
    return response.data;
  },
  
  getValuationHistory: async () => {
    const response = await api.get('/valuation/history');
    return response.data;
  },
};

// Property Financials API
export const propertyFinancialsApi = {
  getPropertyFinancials: async (propertyId: string, marketValue?: number) => {
    const params = marketValue ? `?marketValue=${marketValue}` : '';
    const response = await api.get(`/property/${propertyId}/financials${params}`);
    return response.data;
  },
};

// Gold Comparison API
export const goldApi = {
  compareWithProperty: async (propertyId: string, propertyPrice?: number) => {
    let url = `/goldprice/compare-property?propertyId=${propertyId}`;
    if (propertyPrice) {
      url += `&propertyPrice=${propertyPrice}`;
    }
    const response = await api.get(url);
    return response.data;
  },
};

export default api;
