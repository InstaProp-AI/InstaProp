import React, { useState, useEffect } from 'react';
import { useToast } from '../contexts/ToastContext';
import { MessageSquare, User, Clock, Users, Send, Folder, Building, ArrowLeft, BarChart3, ChevronDown } from 'lucide-react';
import { chatsApi, authApi } from '../services/api';

interface ChatMessage {
  messageId: number;
  senderId: number;
  senderName: string;
  content: string;
  createdAt: string;
  isRead: boolean;
  propertyId?: number;
  propertyName?: string;
  propertyLocation?: string;
  propertyImageUrl?: string;
}

interface Chat {
  chatId: number;
  userId: number;
  developerId: number;
  userName: string;
  developerName: string;
  projectId?: number;
  projectName?: string;
  salesMemberId?: number;
  salesMemberName?: string;
  lastMessage?: string;
  lastMessageAt: string;
  createdAt: string;
  isActive: boolean;
  unreadCount?: number;
  isSupportChat?: boolean;
  messages?: ChatMessage[];
}

interface ChatDetails extends Chat {
  messages: ChatMessage[];
}

interface DeveloperChatCount {
  developerId: number;
  developerName: string;
  email: string;
  chatCount: number;
}

interface ChatStats {
  totalChats: number;
  totalMessages: number;
  totalUsers: number;
  assignedChats: number;
  unassignedChats: number;
  totalSalesMembers: number;
}

interface SalesMember {
  accountId: number;
  firstName: string;
  lastName: string;
  email: string;
}

const ROLE_IDS = {
  ADMIN: 9823749823749823,
  DEVELOPER: 7823647823647823,
};

const ChatsPage: React.FC = () => {
  const toast = useToast();
  
  const [chats, setChats] = useState<Chat[]>([]);
  const [selectedChat, setSelectedChat] = useState<ChatDetails | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [sendingMessage, setSendingMessage] = useState(false);
  const [messageInput, setMessageInput] = useState('');
  const [currentUser, setCurrentUser] = useState<any>(null);
  
  // Admin folder view state
  const [developers, setDevelopers] = useState<DeveloperChatCount[]>([]);
  const [currentView, setCurrentView] = useState<'folders' | 'chats'>('folders');
  const [selectedDeveloper, setSelectedDeveloper] = useState<DeveloperChatCount | null>(null);
  const [selectedDeveloperId, setSelectedDeveloperId] = useState<number | undefined>(undefined);
  
  // Stats state
  const [stats, setStats] = useState<ChatStats | null>(null);
  
  // Sales members for assignment
  const [salesMembers, setSalesMembers] = useState<SalesMember[]>([]);
  const [assigningSalesMember, setAssigningSalesMember] = useState(false);

  // Fetch current user and initialize view
  useEffect(() => {
    const loadData = async () => {
      try {
        setLoading(true);
        const user = await authApi.getCurrentAccount();
        setCurrentUser(user);
        
        const isAdmin = user.roleId === ROLE_IDS.ADMIN || user.roleName === 'Admin';
        const isDeveloper = user.roleId === ROLE_IDS.DEVELOPER || user.roleName === 'Developer';
        
        if (isAdmin) {
          setCurrentView('folders');
          await fetchDevelopers();
          await fetchStats();
        } else if (isDeveloper) {
          setCurrentView('chats');
          setSelectedDeveloperId(user.accountId);
          await fetchChats(user.accountId);
          await fetchStats(user.accountId);
        }
      } catch (error: any) {
        console.error('Error loading data:', error);
        toast.error(error?.response?.data?.message || 'Failed to load chats');
      } finally {
        setLoading(false);
      }
    };
    loadData();
  }, []);

  // Fetch chats when developer is selected
  useEffect(() => {
    if (currentView === 'chats' && selectedDeveloperId !== undefined) {
      fetchChats(selectedDeveloperId);
      fetchStats(selectedDeveloperId);
      if (selectedDeveloperId) {
        fetchSalesMembers(selectedDeveloperId);
      }
    }
  }, [currentView, selectedDeveloperId]);

  const fetchDevelopers = async () => {
    try {
      const data = await chatsApi.getDevelopersWithChats();
      setDevelopers(data || []);
    } catch (error: any) {
      console.error('Error fetching developers:', error);
      toast.error(error?.response?.data?.message || 'Failed to load developers');
    }
  };

  const fetchChats = async (developerId?: number) => {
    try {
      const data = await chatsApi.getChats(developerId);
      setChats(data || []);
    } catch (error: any) {
      console.error('Error fetching chats:', error);
      toast.error(error?.response?.data?.message || 'Failed to load conversations');
    }
  };

  const fetchStats = async (developerId?: number) => {
    try {
      const data = await chatsApi.getChatStats(developerId);
      setStats(data);
    } catch (error: any) {
      console.error('Error fetching stats:', error);
    }
  };

  const fetchSalesMembers = async (developerId: number) => {
    try {
      const data = await chatsApi.getSalesMembersForDeveloper(developerId);
      setSalesMembers(data || []);
    } catch (error: any) {
      console.error('Error fetching sales members:', error);
    }
  };

  const handleFolderClick = (developerId: number) => {
    setSelectedDeveloperId(developerId);
    setCurrentView('chats');
    const developer = developers.find(dev => dev.developerId === developerId);
    setSelectedDeveloper(developer || null);
  };

  const handleBackToFolders = () => {
    setCurrentView('folders');
    setSelectedDeveloper(null);
    setSelectedDeveloperId(undefined);
    setSelectedChat(null);
    fetchStats();
  };

  const handleSelectChat = async (chat: Chat) => {
    try {
      setLoadingMessages(true);
      const chatDetails: ChatDetails = await chatsApi.getChat(chat.chatId);
      setSelectedChat(chatDetails);
      
      // Fetch sales members for this developer
      if (chatDetails.developerId) {
        await fetchSalesMembers(chatDetails.developerId);
      }
      
      // Mark messages as read
      if (chatDetails.messages && chatDetails.messages.length > 0) {
        await chatsApi.markAsRead(chat.chatId);
        setChats(prevChats => 
          prevChats.map(c => 
            c.chatId === chat.chatId 
              ? { ...c, unreadCount: 0 }
              : c
          )
        );
      }
    } catch (error: any) {
      console.error('Error fetching chat details:', error);
      toast.error(error?.response?.data?.message || 'Failed to load chat messages');
    } finally {
      setLoadingMessages(false);
    }
  };

  const handleAssignSalesMember = async (chatId: number, salesMemberId: number | null) => {
    try {
      setAssigningSalesMember(true);
      const result = await chatsApi.assignSalesMember(chatId, salesMemberId);
      
      // Update chat in list
      setChats(prevChats =>
        prevChats.map(chat =>
          chat.chatId === chatId
            ? {
                ...chat,
                salesMemberId: result.salesMemberId || undefined,
                salesMemberName: result.salesMemberName || undefined
              }
            : chat
        )
      );
      
      // Update selected chat if it's the same
      if (selectedChat && selectedChat.chatId === chatId) {
        setSelectedChat({
          ...selectedChat,
          salesMemberId: result.salesMemberId || undefined,
          salesMemberName: result.salesMemberName || undefined
        });
      }
      
      toast.success(salesMemberId ? 'Sales member assigned' : 'Sales member unassigned');
    } catch (error: any) {
      console.error('Error assigning sales member:', error);
      toast.error(error?.response?.data?.message || 'Failed to assign sales member');
    } finally {
      setAssigningSalesMember(false);
    }
  };

  const handleSendMessage = async () => {
    if (!selectedChat || !messageInput.trim()) {
      return;
    }

    try {
      setSendingMessage(true);
      const newMessage = await chatsApi.sendMessage(selectedChat.chatId, {
        content: messageInput.trim()
      });

      if (selectedChat.messages) {
        setSelectedChat({
          ...selectedChat,
          messages: [...selectedChat.messages, newMessage],
          lastMessage: newMessage.content,
          lastMessageAt: newMessage.createdAt
        });
      }

      setChats(prevChats =>
        prevChats.map(chat =>
          chat.chatId === selectedChat.chatId
            ? {
                ...chat,
                lastMessage: newMessage.content,
                lastMessageAt: newMessage.createdAt
              }
            : chat
        )
      );

      setMessageInput('');
      toast.success('Message sent');
    } catch (error: any) {
      console.error('Error sending message:', error);
      toast.error(error?.response?.data?.message || 'Failed to send message');
    } finally {
      setSendingMessage(false);
    }
  };

  const handleKeyPress = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSendMessage();
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '50vh' }}>
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );
  }

  const isAdmin = currentUser?.roleId === ROLE_IDS.ADMIN || currentUser?.roleName === 'Admin';

  // Render Folders View (Admin only)
  if (isAdmin && currentView === 'folders') {
    return (
      <div className="p-6">
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">Chats Management</h1>
          <p className="text-gray-600">Select a developer to view their chats</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {developers.map((developer) => (
            <div
              key={developer.developerId}
              onClick={() => handleFolderClick(developer.developerId)}
              style={{
                backgroundColor: 'white',
                borderRadius: '0.75rem',
                boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
                padding: '1.5rem',
                cursor: 'pointer',
                transition: 'all 0.2s',
                border: '2px solid transparent',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = '#667eea';
                e.currentTarget.style.boxShadow = '0 4px 12px rgba(102, 126, 234, 0.2)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = 'transparent';
                e.currentTarget.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
              }}
            >
              <div style={{ display: 'flex', alignItems: 'start', gap: '1rem', marginBottom: '1rem' }}>
                <div style={{
                  height: '4rem',
                  width: '4rem',
                  borderRadius: '0.5rem',
                  background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  boxShadow: '0 4px 6px rgba(16, 185, 129, 0.3)',
                }}>
                  <Building style={{ height: '2rem', width: '2rem', color: 'white' }} />
                </div>
                <div style={{ flex: 1 }}>
                  <h3 style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#111827', marginBottom: '0.25rem' }}>
                    {developer.developerName}
                  </h3>
                  <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>{developer.email}</p>
                </div>
              </div>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                paddingTop: '1rem',
                borderTop: '1px solid #e5e7eb',
              }}>
                <MessageSquare style={{ height: '1rem', width: '1rem', color: '#10b981' }} />
                <span style={{ fontSize: '0.875rem', color: '#10b981', fontWeight: '500' }}>
                  {developer.chatCount} chats
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  // Render Chats View (Developer or Admin viewing specific developer)
  return (
    <div className="p-6">
      <div className="mb-6">
        <div className="flex items-center justify-between">
          <div>
            {isAdmin && (
              <button
                onClick={handleBackToFolders}
                className="flex items-center gap-2 text-gray-600 hover:text-gray-900 mb-2"
              >
                <ArrowLeft className="h-4 w-4" />
                Back to Developers
              </button>
            )}
            <h1 className="text-3xl font-bold text-gray-900 mb-2">Chats</h1>
            <p className="text-gray-600">
              {isAdmin && selectedDeveloper ? `${selectedDeveloper.developerName}'s conversations` : 'Manage your conversations'}
            </p>
          </div>
        </div>
      </div>

      {/* Analytics Section */}
      {stats && (
        <div className="mb-6 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white rounded-lg shadow p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Total Chats</p>
                <p className="text-2xl font-bold text-gray-900">{stats.totalChats}</p>
              </div>
              <MessageSquare className="h-8 w-8 text-blue-600" />
            </div>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Total Messages</p>
                <p className="text-2xl font-bold text-gray-900">{stats.totalMessages}</p>
              </div>
              <BarChart3 className="h-8 w-8 text-green-600" />
            </div>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Total Users</p>
                <p className="text-2xl font-bold text-gray-900">{stats.totalUsers}</p>
              </div>
              <User className="h-8 w-8 text-purple-600" />
            </div>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Sales Members</p>
                <p className="text-2xl font-bold text-gray-900">{stats.totalSalesMembers}</p>
              </div>
              <Users className="h-8 w-8 text-orange-600" />
            </div>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Assigned</p>
                <p className="text-2xl font-bold text-green-600">{stats.assignedChats}</p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-lg shadow p-4">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">Unassigned</p>
                <p className="text-2xl font-bold text-red-600">{stats.unassignedChats}</p>
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Chat List */}
        <div className="lg:col-span-1 bg-white rounded-lg shadow">
          <div className="p-4 border-b">
            <h2 className="font-semibold">Conversations</h2>
          </div>
          <div className="divide-y max-h-[calc(100vh-450px)] overflow-y-auto">
            {chats.length === 0 ? (
              <div className="p-4 text-center text-gray-500">
                <MessageSquare className="mx-auto h-8 w-8 mb-2 text-gray-400" />
                <p>No chats found</p>
              </div>
            ) : (
              chats.map((chat) => (
                <div
                  key={chat.chatId}
                  onClick={() => handleSelectChat(chat)}
                  className={`p-4 hover:bg-gray-50 transition-colors border-b last:border-b-0 cursor-pointer ${
                    selectedChat?.chatId === chat.chatId ? 'bg-blue-50' : ''
                  }`}
                >
                  <div className="flex items-center justify-between mb-2">
                    <div className="flex items-start gap-3 flex-1 min-w-0">
                      <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
                        <User className="h-5 w-5 text-blue-600" />
                      </div>
                      <div className="flex-1 min-w-0 overflow-hidden">
                        <p className="font-medium break-words line-clamp-1 mb-1">
                          {chat.userName || chat.projectName || 'Unknown User'}
                        </p>
                        <p className="text-sm text-gray-500 break-words line-clamp-2">
                          {chat.lastMessage || 'No messages'}
                        </p>
                      </div>
                    </div>
                    {chat.lastMessageAt && (
                      <div className="text-xs text-gray-400 flex items-center gap-1 ml-2 flex-shrink-0">
                        <Clock className="h-3 w-3" />
                        {new Date(chat.lastMessageAt).toLocaleDateString()}
                      </div>
                    )}
                  </div>
                  <div className="flex items-center justify-between mt-2 gap-2">
                    <div className="flex items-center gap-2 flex-1 min-w-0">
                      {chat.salesMemberName ? (
                        <div className="flex items-center gap-2 text-xs text-gray-600 bg-blue-50 px-2 py-1 rounded flex-shrink-0">
                          <Users className="h-3 w-3 text-blue-600 flex-shrink-0" />
                          <span className="text-blue-700 break-words line-clamp-1">{chat.salesMemberName}</span>
                        </div>
                      ) : (
                        <span className="text-xs text-gray-400 flex-shrink-0">Unassigned</span>
                      )}
                    </div>
                    {chat.unreadCount && chat.unreadCount > 0 && (
                      <span className="bg-blue-600 text-white text-xs rounded-full px-2 py-0.5 flex-shrink-0">
                        {chat.unreadCount}
                      </span>
                    )}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Chat View */}
        <div className="lg:col-span-2 bg-white rounded-lg shadow flex flex-col">
          {selectedChat ? (
            <>
              <div className="p-4 border-b flex-shrink-0">
                <div className="flex justify-between items-center mb-2">
                  <div>
                    <h2 className="text-xl font-semibold">
                      {selectedChat.projectName || selectedChat.userName || 'Chat'}
                    </h2>
                    <p className="text-sm text-gray-500">with {selectedChat.userName}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between mt-3">
                  <div className="flex items-center gap-2">
                    <span className="text-sm text-gray-600">Assign to:</span>
                    <div className="relative">
                      <select
                        value={selectedChat.salesMemberId || ''}
                        onChange={(e) => handleAssignSalesMember(selectedChat.chatId, e.target.value ? parseInt(e.target.value) : null)}
                        disabled={assigningSalesMember}
                        className="text-sm border border-gray-300 rounded px-3 py-1 pr-8 appearance-none bg-white hover:bg-gray-50 focus:outline-none focus:ring-1 focus:ring-blue-500 disabled:opacity-50"
                      >
                        <option value="">Unassigned</option>
                        {salesMembers.map((member) => (
                          <option key={member.accountId} value={member.accountId}>
                            {member.firstName} {member.lastName}
                          </option>
                        ))}
                        {/* If assigned sales member is not in the list, add them */}
                        {selectedChat.salesMemberId && selectedChat.salesMemberName && 
                         !salesMembers.find(m => m.accountId === selectedChat.salesMemberId) && (
                          <option value={selectedChat.salesMemberId}>
                            {selectedChat.salesMemberName}
                          </option>
                        )}
                      </select>
                      <ChevronDown className="absolute right-2 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400 pointer-events-none" />
                    </div>
                  </div>
                </div>
              </div>

              {/* Messages */}
              <div className="flex-1 overflow-y-auto p-6 space-y-4 min-h-0">
                {loadingMessages ? (
                  <div className="flex items-center justify-center h-full">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
                  </div>
                ) : selectedChat.messages && selectedChat.messages.length > 0 ? (
                  selectedChat.messages.map((message) => {
                    const isFromDeveloper = message.senderId === selectedChat.developerId;
                    return (
                      <div key={message.messageId} className="flex flex-col gap-2">
                        <div className="flex justify-between text-sm text-gray-500">
                          <span className="font-medium">{message.senderName}</span>
                          <span>{new Date(message.createdAt).toLocaleString()}</span>
                        </div>
                        <div
                          className={`rounded-lg p-3 ${
                            isFromDeveloper
                              ? 'bg-blue-50 ml-8'
                              : 'bg-gray-50 mr-8'
                          }`}
                        >
                          <p className="whitespace-pre-wrap">{message.content}</p>
                          {message.propertyName && (
                            <div className="mt-2 p-2 bg-white rounded border">
                              <p className="font-medium text-sm">{message.propertyName}</p>
                              {message.propertyLocation && (
                                <p className="text-xs text-gray-500">{message.propertyLocation}</p>
                              )}
                            </div>
                          )}
                          {!message.isRead && isFromDeveloper && (
                            <span className="text-xs text-blue-600 mt-1 block">Unread</span>
                          )}
                        </div>
                      </div>
                    );
                  })
                ) : (
                  <p className="text-gray-500 text-center py-8">No messages in this chat</p>
                )}
              </div>

              {/* Message Input */}
              <div className="p-4 border-t flex-shrink-0">
                <div className="flex gap-2">
                  <textarea
                    value={messageInput}
                    onChange={(e) => setMessageInput(e.target.value)}
                    onKeyPress={handleKeyPress}
                    placeholder="Type your message..."
                    className="flex-1 border border-gray-300 rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                    rows={2}
                    disabled={sendingMessage}
                  />
                  <button
                    onClick={handleSendMessage}
                    disabled={!messageInput.trim() || sendingMessage}
                    className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed flex items-center gap-2 transition-colors"
                  >
                    {sendingMessage ? (
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                    ) : (
                      <Send className="h-4 w-4" />
                    )}
                    Send
                  </button>
                </div>
              </div>
            </>
          ) : (
            <div className="flex items-center justify-center h-full min-h-[400px] text-gray-500">
              <div className="text-center">
                <MessageSquare className="mx-auto h-12 w-12 mb-4 text-gray-400" />
                <p>Select a chat to view messages</p>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ChatsPage;
