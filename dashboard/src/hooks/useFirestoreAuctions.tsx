import { useEffect, useState } from 'react';
import { FirestoreService, FirestoreAuction } from '../services/firestore';

interface UseFirestoreAuctionsOptions {
  activeOnly?: boolean;
  onError?: (error: Error) => void;
}

/**
 * React hook for listening to Firestore auctions in real-time
 */
export const useFirestoreAuctions = (options: UseFirestoreAuctionsOptions = {}) => {
  const { activeOnly = false, onError } = options;
  const [auctions, setAuctions] = useState<FirestoreAuction[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    setLoading(true);
    
    // Set up real-time listener (will immediately error if Firestore not configured)
    const unsubscribe = activeOnly 
      ? FirestoreService.listenToActiveAuctions(
          (updatedAuctions) => {
            console.log('📊 Firestore auctions updated:', updatedAuctions.length);
            setAuctions(updatedAuctions);
            setLoading(false);
            setError(null);
          },
          (err) => {
            console.warn('⚠️ Firestore not available:', err.message);
            setError(err);
            setLoading(false);
            onError?.(err);
          }
        )
      : FirestoreService.listenToAllAuctions(
          (updatedAuctions) => {
            console.log('📊 Firestore auctions updated:', updatedAuctions.length);
            setAuctions(updatedAuctions);
            setLoading(false);
            setError(null);
          },
          (err) => {
            console.warn('⚠️ Firestore not available:', err.message);
            setError(err);
            setLoading(false);
            onError?.(err);
          }
        );

    // Cleanup listener on unmount
    return () => {
      if (unsubscribe) {
        console.log('🔌 Unsubscribing from Firestore auctions');
        unsubscribe();
      }
    };
  }, [activeOnly, onError]);

  return {
    auctions,
    loading,
    error,
    isConnected: !error && !loading
  };
};

/**
 * Hook for listening to a single auction
 */
export const useFirestoreAuction = (
  auctionId: number | null,
  onError?: (error: Error) => void
) => {
  const [auction, setAuction] = useState<FirestoreAuction | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!auctionId) {
      setLoading(false);
      return;
    }

    setLoading(true);
    
    const unsubscribe = FirestoreService.listenToAuction(
      auctionId,
      (updatedAuction) => {
        console.log(`📊 Auction ${auctionId} updated:`, updatedAuction);
        setAuction(updatedAuction);
        setLoading(false);
        setError(null);
      },
      (err) => {
        console.error(`❌ Error listening to auction ${auctionId}:`, err);
        setError(err);
        setLoading(false);
        onError?.(err);
      }
    );

    return () => {
      console.log(`🔌 Unsubscribing from auction ${auctionId}`);
      unsubscribe();
    };
  }, [auctionId, onError]);

  return {
    auction,
    loading,
    error,
    isConnected: !error && !loading
  };
};

/**
 * Hook for listening to auction bids
 */
export const useFirestoreAuctionBids = (
  auctionId: number | null,
  onError?: (error: Error) => void
) => {
  const [bids, setBids] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    if (!auctionId) {
      setLoading(false);
      return;
    }

    setLoading(true);
    
    const unsubscribe = FirestoreService.listenToAuctionBids(
      auctionId,
      (updatedBids) => {
        console.log(`💰 Bids for auction ${auctionId} updated:`, updatedBids.length);
        setBids(updatedBids);
        setLoading(false);
        setError(null);
      },
      (err) => {
        console.error(`❌ Error listening to bids for auction ${auctionId}:`, err);
        setError(err);
        setLoading(false);
        onError?.(err);
      }
    );

    return () => {
      console.log(`🔌 Unsubscribing from bids for auction ${auctionId}`);
      unsubscribe();
    };
  }, [auctionId, onError]);

  return {
    bids,
    loading,
    error
  };
};

export default useFirestoreAuctions;

