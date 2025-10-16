import { 
  collection, 
  doc, 
  onSnapshot, 
  query, 
  where, 
  orderBy, 
  limit,
  Unsubscribe,
  Timestamp
} from 'firebase/firestore';
import { db } from './firebase';

export interface FirestoreAuction {
  auctionId: number;
  propertyId: number;
  startPrice: number;
  currentPrice: number;
  startAt: string | Timestamp;
  duration: number;
  buyNowPrice?: number;
  bidCount: number;
  status: string;
  createdAt: string | Timestamp;
  updatedAt?: string | Timestamp;
  property?: {
    propertyId: number;
    name: string;
    description?: string;
    location?: string;
    imageUrl?: string;
    type?: string;
    status?: string;
    bedrooms?: number;
    bathrooms?: number;
    squareFeet?: number;
    yearBuilt?: number;
  };
}

export interface FirestoreBid {
  bidId: number;
  auctionId: number;
  bidderId: number;
  bidAmount: number;
  bidder?: {
    accountId: number;
    firstName: string;
    lastName: string;
    email: string;
  };
  createdAt: string | Timestamp;
}

export interface FirestoreNotification {
  notificationId: number;
  userId: number;
  title: string;
  message: string;
  type: string;
  isRead: boolean;
  auctionId?: number;
  propertyId?: number;
  createdAt: string | Timestamp;
  readAt?: string | Timestamp;
}

/**
 * Firestore Service for real-time data synchronization
 */
export class FirestoreService {
  
  // Check if Firestore is available
  private static isAvailable(): boolean {
    return db !== null && db !== undefined;
  }

  // ============================================
  // AUCTION LISTENERS
  // ============================================

  /**
   * Listen to all auctions in real-time
   */
  static listenToAllAuctions(
    callback: (auctions: FirestoreAuction[]) => void,
    onError?: (error: Error) => void
  ): Unsubscribe {
    // Check if Firestore is available
    if (!this.isAvailable()) {
      console.warn('⚠️ Firestore not available - returning empty unsubscribe');
      onError?.(new Error('Firestore not configured'));
      return () => {}; // Return empty unsubscribe
    }

    try {
      const auctionsRef = collection(db, 'auctions');
      
      return onSnapshot(
        auctionsRef,
        (snapshot) => {
          const auctions: FirestoreAuction[] = [];
          snapshot.forEach((doc) => {
            auctions.push(doc.data() as FirestoreAuction);
          });
          callback(auctions);
        },
        (error) => {
          console.error('Error listening to auctions:', error);
          onError?.(error);
        }
      );
    } catch (error) {
      console.error('Error setting up auction listener:', error);
      onError?.(error as Error);
      return () => {}; // Return empty unsubscribe function
    }
  }

  /**
   * Listen to a specific auction in real-time
   */
  static listenToAuction(
    auctionId: number,
    callback: (auction: FirestoreAuction | null) => void,
    onError?: (error: Error) => void
  ): Unsubscribe {
    if (!this.isAvailable()) {
      onError?.(new Error('Firestore not configured'));
      return () => {};
    }

    try {
      const auctionRef = doc(db, 'auctions', auctionId.toString());
      
      return onSnapshot(
        auctionRef,
        (snapshot) => {
          if (snapshot.exists()) {
            callback(snapshot.data() as FirestoreAuction);
          } else {
            callback(null);
          }
        },
        (error) => {
          console.error(`Error listening to auction ${auctionId}:`, error);
          onError?.(error);
        }
      );
    } catch (error) {
      console.error('Error setting up auction listener:', error);
      onError?.(error as Error);
      return () => {};
    }
  }

  /**
   * Listen to active auctions only
   */
  static listenToActiveAuctions(
    callback: (auctions: FirestoreAuction[]) => void,
    onError?: (error: Error) => void
  ): Unsubscribe {
    if (!this.isAvailable()) {
      onError?.(new Error('Firestore not configured'));
      return () => {};
    }

    try {
      const auctionsRef = collection(db, 'auctions');
      const q = query(auctionsRef, where('status', '==', 'Active'));
      
      return onSnapshot(
        q,
        (snapshot) => {
          const auctions: FirestoreAuction[] = [];
          snapshot.forEach((doc) => {
            auctions.push(doc.data() as FirestoreAuction);
          });
          callback(auctions);
        },
        (error) => {
          console.error('Error listening to active auctions:', error);
          onError?.(error);
        }
      );
    } catch (error) {
      console.error('Error setting up active auctions listener:', error);
      onError?.(error as Error);
      return () => {};
    }
  }

  // ============================================
  // BID LISTENERS
  // ============================================

  /**
   * Listen to bids for a specific auction in real-time
   */
  static listenToAuctionBids(
    auctionId: number,
    callback: (bids: FirestoreBid[]) => void,
    onError?: (error: Error) => void
  ): Unsubscribe {
    try {
      const bidsRef = collection(db, 'auctions', auctionId.toString(), 'bids');
      const q = query(bidsRef, orderBy('createdAt', 'desc'));
      
      return onSnapshot(
        q,
        (snapshot) => {
          const bids: FirestoreBid[] = [];
          snapshot.forEach((doc) => {
            bids.push(doc.data() as FirestoreBid);
          });
          callback(bids);
        },
        (error) => {
          console.error(`Error listening to bids for auction ${auctionId}:`, error);
          onError?.(error);
        }
      );
    } catch (error) {
      console.error('Error setting up bid listener:', error);
      onError?.(error as Error);
      return () => {};
    }
  }

  // ============================================
  // NOTIFICATION LISTENERS
  // ============================================

  /**
   * Listen to notifications for a specific user
   */
  static listenToUserNotifications(
    userId: number,
    callback: (notifications: FirestoreNotification[]) => void,
    onError?: (error: Error) => void
  ): Unsubscribe {
    try {
      const notificationsRef = collection(db, 'users', userId.toString(), 'notifications');
      const q = query(notificationsRef, orderBy('createdAt', 'desc'), limit(50));
      
      return onSnapshot(
        q,
        (snapshot) => {
          const notifications: FirestoreNotification[] = [];
          snapshot.forEach((doc) => {
            notifications.push(doc.data() as FirestoreNotification);
          });
          callback(notifications);
        },
        (error) => {
          console.error(`Error listening to notifications for user ${userId}:`, error);
          onError?.(error);
        }
      );
    } catch (error) {
      console.error('Error setting up notification listener:', error);
      onError?.(error as Error);
      return () => {};
    }
  }

  /**
   * Listen to unread notification count
   */
  static listenToUnreadCount(
    userId: number,
    callback: (count: number) => void,
    onError?: (error: Error) => void
  ): Unsubscribe {
    try {
      const notificationsRef = collection(db, 'users', userId.toString(), 'notifications');
      const q = query(notificationsRef, where('isRead', '==', false));
      
      return onSnapshot(
        q,
        (snapshot) => {
          callback(snapshot.size);
        },
        (error) => {
          console.error(`Error listening to unread count for user ${userId}:`, error);
          onError?.(error);
        }
      );
    } catch (error) {
      console.error('Error setting up unread count listener:', error);
      onError?.(error as Error);
      return () => {};
    }
  }

  // ============================================
  // UTILITY METHODS
  // ============================================

  /**
   * Check if Firestore is available
   */
  static async isAvailable(): Promise<boolean> {
    try {
      // Try to access Firestore
      const testRef = collection(db, '_test');
      return true;
    } catch (error) {
      console.error('Firestore is not available:', error);
      return false;
    }
  }
}

export default FirestoreService;

