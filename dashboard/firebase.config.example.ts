// Copy this file to: dashboard/src/services/firebase.ts
// Then replace the values with your actual Firebase configuration

import { initializeApp } from 'firebase/app';
import { getFirestore } from 'firebase/firestore';
import { getMessaging, isSupported } from 'firebase/messaging';

// Your web app's Firebase configuration
// Get these values from: Firebase Console > Project Settings > General > Your apps > Web app
const firebaseConfig = {
  apiKey: "AIza...",  // Your API Key
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789012",
  appId: "1:123456789012:web:abcdef123456"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Initialize messaging (optional for push notifications)
let messaging;
isSupported().then((supported) => {
  if (supported) {
    messaging = getMessaging(app);
  }
});

export { app, db, messaging };
export default app;

