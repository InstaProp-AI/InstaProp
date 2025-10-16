import api from './api';

export interface DeveloperAnalytics {
  totalProjects: number;
  totalProperties: number;
  activeAuctions: number;
  soldProperties: number;
  totalRevenue: number;
  totalBids: number;
  chatInquiries: number;
  chatConversionRate: number;
  propertyAnalytics: PropertyAnalytics[];
}

export interface PropertyAnalytics {
  propertyId: number;
  propertyName: string;
  propertyLocation: string;
  views: number;
  chatInquiries: number;
  totalBids: number;
  currentPrice: number;
  status: string;
}

export interface DeveloperProfile {
  developerId: number;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  bio?: string;
  companyName?: string;
  profileImageUrl?: string;
  rating: number;
  totalRatings: number;
  portfolioDescription?: string;
  activeProjectsCount: number;
  totalPropertiesCount: number;
  soldPropertiesCount: number;
  ratings: DeveloperRating[];
}

export interface DeveloperRating {
  ratingId: number;
  userId: number;
  userName: string;
  rating: number;
  comment?: string;
  ratingType: string;
  createdAt: string;
}

export interface ProjectWithProperties {
  projectId: number;
  name: string;
  description?: string;
  location?: string;
  createdAt: string;
  isActive: boolean;
  propertiesCount: number;
  properties: PropertySummary[];
}

export interface PropertySummary {
  propertyId: number;
  name: string;
  location?: string;
  imageUrl: string;
  status: string;
  type?: string; // Primary or Resale
  bedrooms: number;
  bathrooms: number;
  squareFeet?: number;
}

export const developerApi = {
  // Get developer analytics
  getAnalytics: async (): Promise<DeveloperAnalytics> => {
    const response = await api.get<DeveloperAnalytics>('developer/analytics');
    return response.data;
  },

  // Get developer's projects with properties
  getProjects: async (): Promise<ProjectWithProperties[]> => {
    const response = await api.get<ProjectWithProperties[]>('developer/projects');
    return response.data;
  },

  // Get developer's standalone properties (ownerId == developerId)
  getProperties: async (): Promise<PropertySummary[]> => {
    const response = await api.get<PropertySummary[]>('developer/properties');
    return response.data;
  },

  // Create a new project (developer-scoped)
  createProject: async (data: { name: string; description?: string; location?: string; }): Promise<void> => {
    await api.post('project', data);
  },

  // Update a project (developer can update own project)
  updateProject: async (projectId: number, data: { name: string; description?: string; location?: string; }): Promise<void> => {
    await api.put(`project/${projectId}`, data);
  },

  // Create a new property (owned by developer)
  createProperty: async (data: {
    name: string;
    description?: string;
    location?: string;
    projectId?: number;
    bedrooms: number;
    bathrooms: number;
    squareFeet: number;
    yearBuilt: number;
    category?: string;
    imageUrl?: string;
    type?: string; // 'Primary' or 'Resale'
  }): Promise<number> => {
    const response = await api.post('property', data);
    const body = response.data || {};
    return body.propertyId || body.PropertyId;
  },

  // Update property (only editable when not approved)
  updateProperty: async (propertyId: number, data: {
    name: string;
    description?: string;
    location?: string;
  }): Promise<void> => {
    await api.put(`property/${propertyId}`, data);
  },

  // Request an auction for a property owned by the developer
  requestAuction: async (data: {
    propertyId: number;
    startPrice: number;
    startAt: string; // ISO string
    duration: number; // hours
    buyNowPrice?: number;
  }): Promise<void> => {
    await api.post('auction/request', data);
  },

  // Get developer profile
  getProfile: async (developerId: number): Promise<DeveloperProfile> => {
    const response = await api.get<DeveloperProfile>(`developer/profile/${developerId}`);
    return response.data;
  },

  // Update developer profile
  updateProfile: async (data: {
    bio?: string;
    companyName?: string;
    profileImageUrl?: string;
    portfolioDescription?: string;
  }): Promise<void> => {
    await api.put('developer/profile', data);
  },
};

