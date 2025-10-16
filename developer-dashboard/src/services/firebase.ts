import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getAuth, signInAnonymously } from 'firebase/auth';
import { getMessaging, isSupported } from 'firebase/messaging';

// Pulled from Flutter firebase_options.dart to enable real-time chat
const firebaseConfig = {
  apiKey: "AIzaSyDkpQ8vZ5kQxJ3xQN0YH1X3nZxJ8kV5kQx",
  authDomain: "property-flipper-5164d.firebaseapp.com",
  projectId: "property-flipper-5164d",
  storageBucket: "property-flipper-5164d.appspot.com",
  messagingSenderId: "897302032475",
  appId: "1:897302032475:web:abc123def456"
};

// Check if Firebase is configured
const isFirebaseConfigured = firebaseConfig.apiKey && 
                              firebaseConfig.projectId && 
                              firebaseConfig.apiKey.length > 0;

// Initialize Firebase
let app: any = null;
let db: any = null;
let messaging: any = null;

if (isFirebaseConfigured) {
  try {
    console.log('🔥 Starting Firebase initialization...');
    app = initializeApp(firebaseConfig);
    console.log('✅ Firebase app initialized');
    
    // Initialize Firestore immediately (synchronous)
    db = getFirestore(app);
    console.log('✅ Firestore db created');
    
    // Sign in anonymously (async, but doesn't block db usage)
    const auth = getAuth(app);
    signInAnonymously(auth)
      .then(() => {
        console.log('✅ Firebase anonymous auth completed');
        console.log('✅ Firestore ready with auth - db available:', !!db);
      })
      .catch((error) => {
        console.error('❌ Anonymous auth failed:', error);
        console.warn('⚠️ Firestore will work but may have permission issues');
      });
    
    // Initialize messaging if supported
    isSupported().then((supported) => {
      if (supported) {
        messaging = getMessaging(app);
        console.log('✅ Firebase Messaging initialized');
      } else {
        console.warn('⚠️ Firebase Messaging not supported in this browser');
      }
    });
  } catch (error) {
    console.error('❌ Error initializing Firebase:', error);
    console.warn('⚠️ Dashboard will work without Firestore, using API fallback');
    db = null;
  }
} else {
  console.warn('⚠️ Firebase not configured - Dashboard will use API fallback (this is OK!)');
  console.log('💡 To enable real-time updates: Add your Firebase config to firebase.ts');
}

export { app, db, messaging };
export default app;
