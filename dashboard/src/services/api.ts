import axios from 'axios';
import { Account, Project, Property, DashboardStats, CreateProjectDto, UpdateProjectDto, CreatePropertyDto, UserDocument, PropertyDocument, PropertyImage } from '../types';
import { convertAccount, convertProperty } from '../utils/converters';

const API_BASE_URL = 'http://localhost:5284/api';

const api = axios.create({
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
    
    if (status === 401) {
      console.warn('🔒 Unauthorized - Clearing token and redirecting to login');
      localStorage.removeItem('authToken');
      window.location.href = '/';
    }
    
    return Promise.reject(error);
  }
);

// Auth API
export const authApi = {
  login: async (email: string, password: string) => {
    const response = await api.post('/account/login', { email, password });
    return response.data;
  },
  
  getCurrentAccount: async (): Promise<Account> => {
    const response = await api.get('/account/me');
    return response.data;
  },
};

// Users/Accounts API - Using Admin endpoints
export const usersApi = {
  getAllUsers: async (): Promise<Account[]> => {
    const response = await api.get('/admin/users');
    return response.data;
  },
  
  getUser: async (id: number): Promise<Account> => {
    const response = await api.get(`/admin/users/${id}`);
    return response.data;
  },
  
  verifyUser: async (id: number): Promise<void> => {
    await api.put(`/admin/users/${id}/verify`);
  },
  
  rejectUser: async (id: number): Promise<void> => {
    await api.put(`/admin/users/${id}/reject`);
  },
  
  banUser: async (id: number): Promise<void> => {
    await api.delete(`/admin/users/${id}`);
  },

  suspendUser: async (id: number, suspendedUntil: string | null, reason: string): Promise<void> => {
    await api.put(`/admin/users/${id}/suspend`, {
      suspendedUntil,
      reason
    });
  },

  unsuspendUser: async (id: number): Promise<void> => {
    await api.put(`/admin/users/${id}/unsuspend`);
  },

  updateUser: async (id: number, data: { firstName?: string; lastName?: string; email?: string; phoneNumber?: string }): Promise<void> => {
    await api.put(`/admin/users/${id}/update`, data);
  },

  verifyEmail: async (id: number): Promise<void> => {
    console.log(`📧 API: Sending PUT request to /admin/users/${id}/verify-email`);
    const response = await api.put(`/admin/users/${id}/verify-email`);
    console.log('📧 API: Email verification response:', response.data);
    return response.data;
  },

  verifyPhone: async (id: number): Promise<void> => {
    console.log(`📱 API: Sending PUT request to /admin/users/${id}/verify-phone`);
    const response = await api.put(`/admin/users/${id}/verify-phone`);
    console.log('📱 API: Phone verification response:', response.data);
    return response.data;
  },

  changeUserType: async (id: number, type: 'User' | 'Developer' | 'Admin'): Promise<void> => {
    const typeValue = type === 'Admin' ? 2 : type === 'Developer' ? 1 : 0;
    await api.put(`/admin/users/${id}/change-type`, { type: typeValue });
  },

  resetPassword: async (id: number): Promise<void> => {
    await api.put(`/admin/users/${id}/reset-password`);
  },
};

// Projects API
export const projectsApi = {
  getProjects: async (): Promise<Project[]> => {
    const response = await api.get('/project');
    return response.data;
  },
  
  getProject: async (id: number): Promise<Project> => {
    const response = await api.get(`/project/${id}`);
    return response.data;
  },
  
  createProject: async (data: CreateProjectDto): Promise<Project> => {
    const response = await api.post('/project', data);
    return response.data;
  },
  
  updateProject: async (id: number, data: UpdateProjectDto): Promise<void> => {
    await api.put(`/project/${id}`, data);
  },
  
  deleteProject: async (id: number): Promise<void> => {
    await api.delete(`/project/${id}`);
  },
  
  getProjectProperties: async (id: number): Promise<Property[]> => {
    const response = await api.get(`/project/${id}/properties`);
    return response.data;
  },
};

// Properties API - Using Admin endpoints
export const propertiesApi = {
  getProperties: async (): Promise<Property[]> => {
    const response = await api.get('/Property');
    return response.data;
  },
  
  getProperty: async (id: number): Promise<Property> => {
    const response = await api.get(`/property/${id}`);
    return response.data;
  },
  
  createProperty: async (data: CreatePropertyDto): Promise<Property> => {
    const response = await api.post('/property', data);
    return response.data;
  },
  
  updateProperty: async (id: number, data: Partial<CreatePropertyDto & { projectId?: number | null }>): Promise<void> => {
    // Use admin endpoint for updating property details including projectId
    await api.put(`/admin/properties/${id}/update`, data);
  },
  
  deleteProperty: async (id: number): Promise<void> => {
    await api.delete(`/property/${id}`);
  },
  
  approveProperty: async (id: number): Promise<void> => {
    await api.put(`/admin/properties/${id}/approve`);
  },
  
  rejectProperty: async (id: number): Promise<void> => {
    await api.put(`/admin/properties/${id}/reject`);
  },
};

// Dashboard API - Using Admin endpoints
export const dashboardApi = {
  getStats: async (): Promise<DashboardStats> => {
    const response = await api.get('/admin/stats');
    return response.data;
  },
  
  getAnalytics: async () => {
    const response = await api.get('/admin/analytics');
    return response.data;
  },
};

// Auctions API - Using Admin endpoints
export const auctionsApi = {
  getAllAuctions: async () => {
    const response = await api.get('/admin/auctions');
    return response.data;
  },
  
  getAuction: async (id: number) => {
    const response = await api.get(`/auction/${id}`);
    return response.data;
  },
  
  startAuction: async (id: number) => {
    await api.put(`/admin/auctions/${id}/start`);
  },
  
  endAuction: async (id: number) => {
    await api.put(`/admin/auctions/${id}/end`);
  },
  
  cancelAuction: async (id: number) => {
    await api.delete(`/auction/${id}`);
  },
  
  approveAuction: async (id: number) => {
    await api.put(`/auction/${id}/status`, { status: 'Approved' });
  },
  
  rejectAuction: async (id: number) => {
    await api.put(`/auction/${id}/status`, { status: 'Rejected' });
  },

  relistAuction: async (id: number, data: {
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
  
  getBidsForAuction: async (auctionId: number) => {
    const response = await api.get(`/bids/by-auction/${auctionId}`);
    return response.data;
  },
  
  getBiddersForAuction: async (auctionId: number) => {
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
  uploadUserDocument: async (file: File, docType: string): Promise<{ message: string; docId: number; url: string }> => {
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
  
  getUserDocuments: async (userId: number): Promise<UserDocument[]> => {
    console.log(`🔵 documentsApi.getUserDocuments called with userId: ${userId}`);
    const response = await api.get(`/document/user/${userId}`);
    console.log(`🔵 documentsApi.getUserDocuments response:`, response.data);
    console.log(`🔵 Response type:`, Array.isArray(response.data) ? 'Array' : typeof response.data);
    console.log(`🔵 Response length:`, response.data?.length);
    return response.data;
  },
  
  deleteUserDocument: async (docId: number): Promise<void> => {
    await api.delete(`/document/user/${docId}`);
  },
  
  // Property Documents
  uploadPropertyDocument: async (propertyId: number, file: File, docType: string): Promise<{ message: string; docId: number; url: string }> => {
    const formData = new FormData();
    formData.append('file', file);
    formData.append('docType', docType);
    
    const response = await api.post(`/document/property/${propertyId}/upload`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    });
    return response.data;
  },
  
  getPropertyDocuments: async (propertyId: number): Promise<PropertyDocument[]> => {
    const response = await api.get(`/document/property/${propertyId}`);
    return response.data;
  },
  
  deletePropertyDocument: async (docId: number): Promise<void> => {
    await api.delete(`/document/property/document/${docId}`);
  },
  
  // Property Images
  uploadPropertyImage: async (
    propertyId: number, 
    file: File, 
    imageType: string,
    isMainImage: boolean = false,
    displayOrder: number = 0
  ): Promise<{ message: string; imageId: number; url: string }> => {
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
  
  getPropertyImages: async (propertyId: number): Promise<PropertyImage[]> => {
    const response = await api.get(`/document/property/${propertyId}/images`);
    return response.data;
  },
  
  deletePropertyImage: async (imageId: number): Promise<void> => {
    await api.delete(`/document/property/image/${imageId}`);
  },
  
  // Statistics (Admin only)
  getDocumentStatistics: async () => {
    const response = await api.get('/document/statistics');
    return response.data;
  },
};

export default api;
