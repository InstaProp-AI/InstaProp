export interface Account {
  accountId: number;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  type: 'User' | 'Developer' | 'Admin';
  status: 'NotVerified' | 'Pending' | 'Verified';
  emailVerified?: boolean;
  phoneVerified?: boolean;
  isSuspended?: boolean;
  suspendedUntil?: string;
  suspensionReason?: string;
  createdAt: string;
  updatedAt?: string;
}

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

export interface Property {
  propertyId: number;
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
