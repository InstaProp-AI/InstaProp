import { collection, onSnapshot, doc, where } from 'firebase/firestore';
import { db } from './firebase';

export interface ChatMessage {
  messageId: number;
  chatId: number;
  senderId: number;
  content: string;
  propertyId?: number;
  createdAt: string;
  isRead: boolean;
  expiresAt: string;
}

export interface Chat {
  chatId: number;
  userId: number;
  developerId: number;
  projectId?: number;
  createdAt: string;
  lastMessageAt: string;
  isActive: boolean;
}

export const chatFirestore = {
  // Subscribe to chat messages in real-time
  subscribeToMessages: (
    chatId: number,
    onUpdate: (messages: ChatMessage[]) => void,
    onError?: (error: Error) => void
  ) => {
    console.log('🔥 chatFirestore.subscribeToMessages called for chat:', chatId);
    console.log('🔥 Firestore db available:', !!db);
    
    if (!db) {
      console.error('❌ Firestore db is not initialized');
      if (onError) onError(new Error('Firestore not initialized'));
      return () => {};
    }
    
    try {
      const messagesRef = collection(db, 'chats', chatId.toString(), 'messages');
      console.log('🔥 Messages collection ref created:', messagesRef.path);

      const unsubscribe = onSnapshot(
        messagesRef,
        (snapshot) => {
          console.log('🔥 Firestore snapshot received:', snapshot.size, 'messages');
          const messages: ChatMessage[] = [];
          snapshot.forEach((docSnap) => {
            const data: any = docSnap.data();
            const createdAt = data?.createdAt?.toDate ? data.createdAt.toDate().toISOString() : (data?.createdAt || new Date().toISOString());
            const expiresAt = data?.expiresAt?.toDate ? data.expiresAt.toDate().toISOString() : (data?.expiresAt || new Date().toISOString());
            // Robust numeric message id for deduping: prefer stored id; else derive from createdAt
            const tsNum = Date.parse(createdAt) || 0;
            const messageId = typeof data?.messageId === 'number' ? data.messageId : tsNum;
            messages.push({
              messageId,
              chatId: data?.chatId || chatId,
              senderId: data?.senderId || 0,
              content: data?.content || '',
              propertyId: data?.propertyId === 0 ? undefined : data?.propertyId,
              createdAt,
              isRead: !!data?.isRead,
              expiresAt,
            });
          });
          // Sort client-side by createdAt ascending
          messages.sort((a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime());
          console.log('🔥 Calling onUpdate with', messages.length, 'messages');
          onUpdate(messages);
        },
        (error) => {
          console.error('❌ Firestore snapshot error:', error);
          if (onError) onError(error);
        }
      );

      console.log('✅ Firestore listener attached successfully');
      return unsubscribe;
    } catch (error) {
      console.error('❌ Error setting up message subscription:', error);
      if (onError) onError(error as Error);
      return () => {}; // Return empty unsubscribe function
    }
  },

  // Subscribe to unread count for a specific chat
  subscribeToUnreadCount: (
    chatId: number,
    currentUserId: number,
    onUpdate: (count: number) => void
  ) => {
    try {
      const messagesRef = collection(db, 'chats', chatId.toString(), 'messages');
      const q = query(
        messagesRef,
        where('senderId', '!=', currentUserId),
        where('isRead', '==', false)
      );

      const unsubscribe = onSnapshot(q, (snapshot) => {
        onUpdate(snapshot.size);
      });

      return unsubscribe;
    } catch (error) {
      console.error('Error subscribing to unread count:', error);
      return () => {};
    }
  },

  // Subscribe to chat updates
  subscribeToChat: (
    chatId: number,
    onUpdate: (chat: Chat | null) => void
  ) => {
    try {
      const chatRef = doc(db, 'chats', chatId.toString());

      const unsubscribe = onSnapshot(chatRef, (snapshot) => {
        if (snapshot.exists()) {
          const data: any = snapshot.data();
          const createdAt = data?.createdAt?.toDate ? data.createdAt.toDate().toISOString() : (data?.createdAt || new Date().toISOString());
          const lastMessageAt = data?.lastMessageAt?.toDate ? data.lastMessageAt.toDate().toISOString() : (data?.lastMessageAt || new Date().toISOString());
          onUpdate({
            chatId: data?.chatId || chatId,
            userId: data?.userId || 0,
            developerId: data?.developerId || 0,
            projectId: data?.projectId === 0 ? undefined : data?.projectId,
            createdAt,
            lastMessageAt,
            isActive: data?.isActive ?? true,
          });
        } else {
          onUpdate(null);
        }
      });

      return unsubscribe;
    } catch (error) {
      console.error('Error subscribing to chat:', error);
      return () => {};
    }
  },
};

