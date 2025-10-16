import { useState, useEffect } from 'react';
import { db } from '../services/firebase';
import { getAuth } from 'firebase/auth';

export const useFirebase = () => {
  const [isReady, setIsReady] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    const checkFirebaseAuth = () => {
      if (!db) {
        console.log('⚠️ Firestore not available');
        setIsReady(false);
        return;
      }

      try {
        const auth = getAuth();
        
        // Listen for auth state changes
        const unsubscribe = auth.onAuthStateChanged((user) => {
          console.log('🔥 Auth state changed:', !!user);
          if (user) {
            console.log('✅ Firebase user authenticated:', user.uid);
            setIsAuthenticated(true);
            setIsReady(true);
          } else {
            console.log('⚠️ No Firebase user yet');
            setIsAuthenticated(false);
            // Give it a moment, auth might be in progress
            setTimeout(() => {
              if (auth.currentUser) {
                setIsAuthenticated(true);
                setIsReady(true);
              }
            }, 1000);
          }
        });

        return unsubscribe;
      } catch (error) {
        console.error('❌ Error checking Firebase auth:', error);
        setIsReady(false);
      }
    };

    checkFirebaseAuth();
  }, []);

  return { isReady, isAuthenticated, db };
};





