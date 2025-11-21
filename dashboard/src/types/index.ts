export interface Account {
  accountId: number;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  // SECURITY: Use roleId (non-guessable 64-bit ID) instead of type enum
  roleId: number; // e.g., 9823749823749823 for Admin, 7823647823647823 for Developer, 8923748923748923 for User
  roleName: 'User' | 'Developer' | 'Admin'; // For display purposes only
  // Legacy: Keep type for backward compatibility during migration
  type?: 'User' | 'Developer' | 'Admin'; // Deprecated - use roleName instead
  status: 'NotVerified' | 'Pending' | 'Verified';
  emailVerified?: boolean;
  phoneVerified?: boolean;
  isSuspended?: boolean;
  suspendedUntil?: string;
  suspensionReason?: string;
  createdAt: string;
  updatedAt?: string;
}

export interface PaginationInfo {
  page: number;
  pageSize: number;
  totalCount: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: PaginationInfo;
}

// Role ID constants (matching backend)
export const ROLE_IDS = {
  USER: 8923748923748923,
  DEVELOPER: 7823647823647823,
  ADMIN: 9823749823749823,
} as const;

export interface Project {
  projectId: number;
  developerId?: number;
  name: string;
  description?: string;
  location?: string;
  createdAt: string;
  updatedAt?: string;
  isActive?: boolean;
  status?: string;
  properties?: Property[];
}

export interface ParentProperty {
  parentPropertyId: number;
  projectName?: string;
  type?: string;
  bedrooms?: number;
  bathrooms?: number;
  areaSqm?: number;
  finishingType?: string;
}

export interface Property {
  propertyId: number;
  parentPropertyId?: number; // Link to parent property
  ownerId: number;
  projectId?: number;
  name: string;
  description?: string;
  location?: string;
  type: 'Resale' | 'Primary';
  status: 'NotApproved' | 'Pending' | 'Approved';
  isApproved?: boolean; // Computed field from status
  bedrooms: number;
  bathrooms: number;
  squareFeet: number;
  yearBuilt: number;
  category?: string;
  imageUrl: string;
  createdAt: string;
  updatedAt?: string;
  owner?: Account;
  project?: Project;
  parentProperty?: ParentProperty; // Parent property information
  auctions?: Auction[];
}

export interface Auction {
  auctionId: number;
  propertyId: number;
  startPrice: number;
  currentPrice: number;
  startAt: string;
  duration: number;
  buyNowPrice?: number;
  status: string;
  bidCount: number;
  createdAt: string;
  property?: Property;
}

export interface Bid {
  bidId: number;
  auctionId: number;
  bidderId: number;
  bidAmount: number;
  createdAt: string;
  bidder?: Account;
  auction?: Auction;
}

export interface DashboardStats {
  users: {
    total: number;
    verified: number;
    pending: number;
    notVerified: number;
    developers: number;
    admins: number;
  };
  properties: {
    total: number;
    approved: number;
    pending: number;
    notApproved: number;
  };
  auctions: {
    total: number;
    active: number;
    ended: number;
  };
  bids: {
    total: number;
    averageValue?: number;
  };
  revenue: {
    total: number;
    monthly: number;
  };
}

export interface CreateProjectDto {
  name: string;
  description?: string;
  location?: string;
}

export interface UpdateProjectDto {
  name: string;
  description?: string;
  location?: string;
}

export interface CreatePropertyDto {
  name: string;
  description?: string;
  location?: string;
  startingPrice: number;
  bedrooms: number;
  bathrooms: number;
  squareFeet: number;
  yearBuilt: number;
  category?: string;
  imageUrl: string;
  projectId?: number;
  type?: string; // 'Primary' or 'Resale' - optional for admin
}

export interface UserDocument {
  docId: number;
  userId: number;
  docType: string;
  imgUrl: string;
  uploadedAt: string;
}

export interface PropertyDocument {
  docId: number;
  propertyId: number;
  docType: string;
  imgUrl: string;
  uploadedAt: string;
}

export interface PropertyImage {
  propertyImageId: number;
  propertyId: number;
  imageUrl: string;
  imageType: string;
  isMainImage: boolean;
  displayOrder: number;
  createdAt: string;
}

// Developer Permission Types
export enum FeaturePermission {
  // Default features (always enabled for developers)
  Projects = 'Projects',
  Properties = 'Properties',
  Analytics = 'Analytics',
  
  // Optional features (admin-configurable)
  Communities = 'Communities',
  News = 'News',
  Auctions = 'Auctions',
  Leaderboard = 'Leaderboard',
  Notifications = 'Notifications',
  PriceHistory = 'PriceHistory',
  FullAnalytics = 'FullAnalytics',
  Rewards = 'Rewards',
  Valuation = 'Valuation',
  Chats = 'Chats'
}

export type FeatureName = 
  | 'Projects'
  | 'Properties'
  | 'Analytics'
  | 'Communities'
  | 'News'
  | 'Auctions'
  | 'Leaderboard'
  | 'Notifications'
  | 'PriceHistory'
  | 'FullAnalytics'
  | 'Rewards'
  | 'Valuation'
  | 'Chats';

export interface DeveloperPermissions {
  [key: string]: boolean;
}

export interface UpdatePermissionsDto {
  permissions: DeveloperPermissions;
}
