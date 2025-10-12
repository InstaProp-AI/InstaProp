import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getMessaging, isSupported } from 'firebase/messaging';

// Your web app's Firebase configuration
// TODO: Replace with your actual Firebase config from Firebase Console
// Leave as-is to disable Firebase (dashboard will use API fallback)
const firebaseConfig = {
  apiKey: "",  // Empty = Firebase disabled
  authDomain: "",
  projectId: "",
  storageBucket: "",
  messagingSenderId: "",
  appId: ""
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
    app = initializeApp(firebaseConfig);
    db = getFirestore(app);
    console.log('✅ Firebase initialized successfully');
    
    // Initialize messaging if supported (not supported in all browsers)
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

