import React, { useState, useEffect, useRef } from 'react';
import api from '../services/api';
import { chatFirestore, ChatMessage } from '../services/chatFirestore';
import ChatMessageBubble from '../components/ChatMessageBubble';
import PropertyShareModal from '../components/PropertyShareModal';
import { Send, Home } from 'lucide-react';
import { useFirebase } from '../hooks/useFirebase';

interface Chat {
  chatId: number;
  userId: number;
  userName: string;
  developerId: number;
  developerName: string;
  projectId?: number;
  projectName?: string;
}

interface DeveloperChatWindowProps {
  chat: Chat;
  onMessageSent: () => void;
}

interface MessageWithDetails extends ChatMessage {
  senderName?: string;
  propertyName?: string;
  propertyLocation?: string;
  propertyImageUrl?: string;
}

const DeveloperChatWindow: React.FC<DeveloperChatWindowProps> = ({ chat, onMessageSent }) => {
  const [messages, setMessages] = useState<MessageWithDetails[]>([]);
  const [messageText, setMessageText] = useState('');
  const [sending, setSending] = useState(false);
  const [showPropertyModal, setShowPropertyModal] = useState(false);
  const [selectedPropertyId, setSelectedPropertyId] = useState<number | null>(null);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const currentUserId = parseInt(localStorage.getItem('userId') || '0');
  const { isReady: firebaseReady, isAuthenticated } = useFirebase();

  useEffect(() => {
    loadMessages();
    markAsRead();
  }, [chat.chatId]);

  // Separate effect for Firestore subscription - only when Firebase is ready and authenticated
  useEffect(() => {
    if (!firebaseReady || !isAuthenticated) {
      console.log('⏳ Waiting for Firebase auth... Ready:', firebaseReady, 'Authenticated:', isAuthenticated);
      return;
    }

    console.log('🔥 Firebase ready! Setting up Firestore listener for chat:', chat.chatId);
    const unsubscribe = chatFirestore.subscribeToMessages(
      chat.chatId,
      (firestoreMessages) => {
        console.log('🔥 Firestore update received:', firestoreMessages.length, 'messages');
        // Merge with existing messages, avoiding duplicates
        setMessages((prev) => {
          const existingIds = prev.map(m => m.messageId);
          const newMessages = firestoreMessages.filter(m => !existingIds.includes(m.messageId));
          console.log('📨 New messages to add:', newMessages.length);
          const merged = [...prev, ...newMessages as MessageWithDetails[]].sort(
            (a, b) => new Date(a.createdAt).getTime() - new Date(b.createdAt).getTime()
          );
          return merged;
        });
        // Refresh chat list metadata (lastMessage, timestamps, unread) instantly
        onMessageSent();
      },
      (error) => {
        console.error('❌ Firestore subscription error:', error);
      }
    );

    return () => {
      console.log('🧹 Cleaning up Firestore listener for chat:', chat.chatId);
      unsubscribe();
    };
  }, [chat.chatId, firebaseReady, isAuthenticated]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const loadMessages = async () => {
    try {
      // Use relative path; baseURL already includes /api
      const response = await api.get(`chat/${chat.chatId}`);
      setMessages(response.data.messages || []);
    } catch (error) {
      console.error('Error loading messages:', error);
    }
  };

  const markAsRead = async () => {
    try {
      await api.put(`chat/${chat.chatId}/read`);
    } catch (error) {
      console.error('Error marking as read:', error);
    }
  };

  const sendMessage = async () => {
    if (!messageText.trim() && !selectedPropertyId) return;

    setSending(true);
    try {
      const response = await api.post(`chat/${chat.chatId}/message`, {
        content: messageText.trim() || '(Shared a property)',
        propertyId: selectedPropertyId,
      });

      setMessages([...messages, response.data]);
      setMessageText('');
      setSelectedPropertyId(null);
      onMessageSent();
    } catch (error) {
      console.error('Error sending message:', error);
    } finally {
      setSending(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const handlePropertySelected = (propertyId: number) => {
    setSelectedPropertyId(propertyId);
    setShowPropertyModal(false);
  };

  return (
    <div className="flex flex-col h-full">
      {/* Header */}
      <div className="bg-white border-b p-4">
        <h3 className="text-lg font-bold">{chat.userName}</h3>
        {chat.projectName && (
          <p className="text-sm text-gray-500">{chat.projectName}</p>
        )}
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-gray-50">
        {messages.map((message, idx) => (
          <ChatMessageBubble
            key={`${message.messageId || 'm'}-${idx}`}
            message={message}
            isOwn={message.senderId === currentUserId}
          />
        ))}
        <div ref={messagesEndRef} />
      </div>

      {/* Property Preview if selected */}
      {selectedPropertyId && (
        <div className="bg-blue-50 border-t border-blue-200 p-2 flex items-center justify-between">
          <span className="text-sm text-blue-900">Property selected to share</span>
          <button
            onClick={() => setSelectedPropertyId(null)}
            className="text-blue-600 hover:text-blue-800"
          >
            Remove
          </button>
        </div>
      )}

      {/* Input */}
      <div className="bg-white border-t p-4">
        <div className="flex items-end gap-2">
          <button
            onClick={() => setShowPropertyModal(true)}
            className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg"
          >
            <Home className="w-6 h-6" />
          </button>
          
          <textarea
            value={messageText}
            onChange={(e) => setMessageText(e.target.value)}
            onKeyDown={handleKeyPress}
            placeholder="Type a message..."
            className="flex-1 p-2 border rounded-lg resize-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            rows={1}
          />
          
          <button
            onClick={sendMessage}
            disabled={sending || (!messageText.trim() && !selectedPropertyId)}
            className="p-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {sending ? (
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-white"></div>
            ) : (
              <Send className="w-6 h-6" />
            )}
          </button>
        </div>
      </div>

      {/* Property Share Modal */}
      {showPropertyModal && (
        <PropertyShareModal
          onClose={() => setShowPropertyModal(false)}
          onSelect={handlePropertySelected}
        />
      )}
    </div>
  );
};

export default DeveloperChatWindow;

