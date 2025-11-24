export interface Account {
  accountId: string;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  // SECURITY: Use roleId (GUID) instead of type enum
  roleId: string; // GUID for Admin, Developer, User roles
  roleName: 'User' | 'Developer' | 'Admin'; // For display purposes only
  // Legacy: Keep type for backward compatibility during migration
  type?: 'User' | 'Developer' | 'Admin'; // Deprecated - use roleName instead
  status: 'NotVerified' | 'Pending' | 'Verified';
  emailVerified?: boolean;
  phoneVerified?: boolean;
  isSuspended?: boolean;
  suspendedUntil?: string;
  suspensionReason?: string;
  timeZone?: string; // User's preferred timezone (IANA timezone ID)
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

// Role ID constants (matching backend GUIDs)
export const ROLE_IDS = {
  USER: '89237489-2374-4923-8923-892374892374',
  DEVELOPER: '78236478-2364-4782-3647-823647823647',
  ADMIN: '98237498-2374-4982-3749-823749823749',
  SALES: '67235467-2354-4672-3546-723546723546',
} as const;

export interface Project {
  projectId: string;
  developerId?: string;
  name: string;
  description?: string;
  location?: string;
  country?: string; // ISO 3166-1 alpha-2 country code
  createdAt: string;
  updatedAt?: string;
  isActive?: boolean;
  status?: string;
  properties?: Property[];
}

export interface ParentProperty {
  parentPropertyId: string;
  projectName?: string;
  type?: string;
  bedrooms?: number;
  bathrooms?: number;
  areaSqm?: number;
  finishingType?: string;
}

export interface Property {
  propertyId: string;
  parentPropertyId?: string; // Link to parent property
  ownerId: string;
  projectId?: string;
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
  auctionId: string;
  propertyId: string;
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
  bidId: string;
  auctionId: string;
  bidderId: string;
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
  country?: string; // ISO 3166-1 alpha-2 country code
}

export interface UpdateProjectDto {
  name: string;
  description?: string;
  location?: string;
  country?: string; // ISO 3166-1 alpha-2 country code
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
  projectId?: string;
  type?: string; // 'Primary' or 'Resale' - optional for admin
}

export interface UserDocument {
  docId: string;
  userId: string;
  docType: string;
  imgUrl: string;
  uploadedAt: string;
}

export interface PropertyDocument {
  docId: string;
  propertyId: string;
  docType: string;
  imgUrl: string;
  uploadedAt: string;
}

export interface PropertyImage {
  propertyImageId: string;
  propertyId: string;
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

export interface SalesTeam {
  teamId: string;
  teamName: string;
  developerId: string;
  developerName?: string;
  developerEmail?: string;
  memberCount?: number;
  activeMemberCount?: number;
  createdAt: string;
  updatedAt?: string;
}

export interface TeamStats {
  totalMembers: number;
  activeMembers: number;
  totalAssignedUsers: number;
  totalChats: number;
  totalDealsFinished: number;
  totalRevenue: number;
  averageResponseTimeHours?: number;
  conversionRate: number;
}
