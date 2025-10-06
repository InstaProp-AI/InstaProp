export interface Account {
  accountId: number;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  type: 'User' | 'Developer';
  isVerified: boolean;
  createdAt: string;
  updatedAt?: string;
}

export interface Project {
  projectId: number;
  developerId: number;
  name: string;
  description?: string;
  location?: string;
  createdAt: string;
  updatedAt?: string;
  isActive: boolean;
  properties: Property[];
}

export interface Property {
  propertyId: number;
  ownerId: number;
  projectId?: number;
  name: string;
  description?: string;
  location?: string;
  startingPrice: number;
  type: 'Resale' | 'Primary';
  isApproved: boolean;
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
}

export interface Auction {
  auctionId: number;
  propertyId: number;
  startAt: number;
  currentPrice: number;
  endAt: string;
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
  totalProperties: number;
  activeAuctions: number;
  totalBids: number;
  totalUsers: number;
  averageBidAmount: number;
  highestBid: number;
  propertiesThisMonth: number;
  auctionsThisMonth: number;
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
