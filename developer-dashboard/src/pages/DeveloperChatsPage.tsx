import React, { useState, useEffect } from 'react';
import api from '../services/api';
import { MessageSquare, Search, Clock } from 'lucide-react';
import DeveloperChatWindow from './DeveloperChatWindow';
import ChatNotificationBadge from '../components/ChatNotificationBadge';

interface Chat {
  chatId: number;
  userId: number;
  userName: string;
  developerId: number;
  developerName: string;
  projectId?: number;
  projectName?: string;
  createdAt: string;
  lastMessageAt: string;
  isActive: boolean;
  lastMessage?: string;
  unreadCount: number;
}

const DeveloperChatsPage: React.FC = () => {
  const [chats, setChats] = useState<Chat[]>([]);
  const [selectedChat, setSelectedChat] = useState<Chat | null>(null);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadChats();
  }, []);

  const loadChats = async () => {
    try {
      // Use relative path; baseURL already includes /api
      const response = await api.get<Chat[]>('chat');
      setChats(response.data);
    } catch (error) {
      console.error('Error loading chats:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredChats = chats.filter(
    (chat) =>
      chat.userName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      chat.lastMessage?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const formatTime = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);

    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffMins < 1440) return `${Math.floor(diffMins / 60)}h ago`;
    return date.toLocaleDateString();
  };

  return (
    <div className="flex bg-gray-50 h-[calc(110vh-140px)]">
      {/* Chat List Sidebar */}
      <div className="w-1/3 bg-white border-r flex flex-col">
        {/* Header */}
        <div className="p-4 border-b">
          <h2 className="text-2xl font-bold mb-4">Messages</h2>
          
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-2.5 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search conversations..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>

        {/* Chat List - non-scrollable preview */}
        <div className="flex-1 overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center h-full">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            </div>
          ) : filteredChats.length === 0 ? (
            <div className="flex flex-col items-center justify-center h-full text-gray-400">
              <MessageSquare className="w-16 h-16 mb-4" />
              <p>No conversations yet</p>
            </div>
          ) : (
            filteredChats.map((chat) => (
              <div
                key={chat.chatId}
                onClick={() => setSelectedChat(chat)}
                className={`p-4 border-b cursor-pointer hover:bg-gray-50 ${
                  selectedChat?.chatId === chat.chatId ? 'bg-blue-50' : ''
                }`}
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <h3 className={`font-semibold ${chat.unreadCount > 0 ? 'font-bold' : ''}`}>
                        {chat.userName}
                      </h3>
                      {chat.unreadCount > 0 && (
                        <ChatNotificationBadge count={chat.unreadCount} />
                      )}
                    </div>
                    {chat.projectName && (
                      <p className="text-xs text-gray-500 italic">{chat.projectName}</p>
                    )}
                    <p className={`text-sm mt-1 truncate ${
                      chat.unreadCount > 0 ? 'text-gray-900 font-medium' : 'text-gray-600'
                    }`}>
                      {chat.lastMessage || 'No messages yet'}
                    </p>
                  </div>
                  <div className="flex items-center gap-2 text-xs text-gray-500">
                    <Clock className="w-3 h-3" />
                    {formatTime(chat.lastMessageAt)}
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* Chat Window */}
      <div className="flex-1 h-full overflow-hidden">
        {selectedChat ? (
          <DeveloperChatWindow 
            chat={selectedChat} 
            onMessageSent={loadChats}
          />
        ) : (
          <div className="flex items-center justify-center h-full text-gray-400">
            <div className="text-center">
              <MessageSquare className="w-24 h-24 mx-auto mb-4" />
              <p className="text-xl">Select a conversation to start messaging</p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default DeveloperChatsPage;

