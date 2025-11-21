import React, { useState, useEffect } from 'react';
import { useToast } from '../contexts/ToastContext';
import { MessageSquare, User, Clock, Users, ChevronDown } from 'lucide-react';

interface SalesMember {
  id: number;
  name: string;
  email: string;
}

interface ChatMessage {
  messageId: number;
  senderId: number;
  senderName: string;
  content: string;
  createdAt: string;
  isRead: boolean;
}

interface Chat {
  chatId: number;
  userId: number;
  developerId: number;
  userName: string;
  developerName: string;
  propertyName?: string;
  salesMemberId?: number;
  salesMemberName?: string;
  lastMessage: string;
  lastMessageAt: string;
  createdAt: string;
  isActive: boolean;
  messages: ChatMessage[];
}

const ChatsPage: React.FC = () => {
  const toast = useToast();
  
  // Mock sales members data (shared with SalesPage)
  const [salesMembers] = useState<SalesMember[]>([
    { id: 1, name: 'Ahmed Saleh', email: 'ahmed.saleh@example.com' },
    { id: 2, name: 'Sarah Mohamed', email: 'sarah.mohamed@example.com' },
    { id: 3, name: 'Mohamed Ali', email: 'mohamed.ali@example.com' },
    { id: 4, name: 'Fatma Hassan', email: 'fatma.hassan@example.com' },
    { id: 5, name: 'Omar Youssef', email: 'omar.youssef@example.com' }
  ]);
  
  // Demo chats with sales members already assigned
  const [chats, setChats] = useState<Chat[]>([
    {
      chatId: 1,
      userId: 101,
      developerId: 201,
      userName: 'Ahmed Hassan',
      developerName: 'Palm Hills Developments',
      propertyName: 'Luxury Villa in New Cairo',
      salesMemberId: 1,
      salesMemberName: 'Ahmed Saleh',
      lastMessage: 'Thank you for your interest. The villa has 4 bedrooms and a beautiful garden.',
      lastMessageAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
      createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
      isActive: true,
      messages: [
        {
          messageId: 1,
          senderId: 101,
          senderName: 'Ahmed Hassan',
          content: 'Hello, I\'m interested in this property. Can you tell me more about it?',
          createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 2,
          senderId: 201,
          senderName: 'Palm Hills Developments',
          content: 'Hello! Thank you for your interest. I\'d be happy to help you with this property.',
          createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000 + 30 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 3,
          senderId: 101,
          senderName: 'Ahmed Hassan',
          content: 'What is the current price for this unit?',
          createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000 + 60 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 4,
          senderId: 201,
          senderName: 'Palm Hills Developments',
          content: 'The current price is 5000000 EGP. We also offer flexible payment plans.',
          createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000 + 90 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 5,
          senderId: 201,
          senderName: 'Palm Hills Developments',
          content: 'Thank you for your interest. The villa has 4 bedrooms and a beautiful garden.',
          createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
          isRead: false
        }
      ]
    },
    {
      chatId: 2,
      userId: 102,
      developerId: 202,
      userName: 'Fatma Mohamed',
      developerName: 'Emaar Misr',
      propertyName: 'Apartment in Madinaty',
      salesMemberId: 2,
      salesMemberName: 'Sarah Mohamed',
      lastMessage: 'The unit is 1500 square feet. Would you like to see the floor plan?',
      lastMessageAt: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString(),
      createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
      isActive: true,
      messages: [
        {
          messageId: 6,
          senderId: 102,
          senderName: 'Fatma Mohamed',
          content: 'When will the project be completed?',
          createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 7,
          senderId: 202,
          senderName: 'Emaar Misr',
          content: 'The project is expected to be completed by December 2024. Construction is progressing well.',
          createdAt: new Date(Date.now() - 10 * 24 * 60 * 60 * 1000 + 45 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 8,
          senderId: 102,
          senderName: 'Fatma Mohamed',
          content: 'What\'s the square footage?',
          createdAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 9,
          senderId: 202,
          senderName: 'Emaar Misr',
          content: 'The unit is 1500 square feet. Would you like to see the floor plan?',
          createdAt: new Date(Date.now() - 5 * 60 * 60 * 1000).toISOString(),
          isRead: false
        }
      ]
    },
    {
      chatId: 3,
      userId: 103,
      developerId: 203,
      userName: 'Omar Youssef',
      developerName: 'SODIC',
      propertyName: 'Townhouse in Sheikh Zayed',
      salesMemberId: 3,
      salesMemberName: 'Mohamed Ali',
      lastMessage: 'Absolutely! I can schedule a site visit for you. When would be convenient?',
      lastMessageAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
      createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
      isActive: true,
      messages: [
        {
          messageId: 10,
          senderId: 103,
          senderName: 'Omar Youssef',
          content: 'Can I schedule a site visit?',
          createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 11,
          senderId: 203,
          senderName: 'SODIC',
          content: 'Absolutely! I can schedule a site visit for you. When would be convenient?',
          createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
          isRead: false
        }
      ]
    },
    {
      chatId: 4,
      userId: 104,
      developerId: 204,
      userName: 'Mona Ibrahim',
      developerName: 'Talaat Moustafa Group',
      propertyName: 'Penthouse in New Administrative Capital',
      salesMemberId: 4,
      salesMemberName: 'Fatma Hassan',
      lastMessage: 'Yes, financing is available through several partner banks. I can provide details.',
      lastMessageAt: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString(),
      createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
      isActive: true,
      messages: [
        {
          messageId: 12,
          senderId: 104,
          senderName: 'Mona Ibrahim',
          content: 'Is financing available?',
          createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 13,
          senderId: 204,
          senderName: 'Talaat Moustafa Group',
          content: 'Yes, financing is available through several partner banks. I can provide details.',
          createdAt: new Date(Date.now() - 3 * 60 * 60 * 1000).toISOString(),
          isRead: false
        }
      ]
    },
    {
      chatId: 5,
      userId: 105,
      developerId: 205,
      userName: 'Khaled Mostafa',
      developerName: 'Orascom Development',
      propertyName: 'Villa in Al Rehab City',
      salesMemberId: 5,
      salesMemberName: 'Omar Youssef',
      lastMessage: 'Yes, parking is included. Each unit comes with one or two parking spaces.',
      lastMessageAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
      createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
      isActive: true,
      messages: [
        {
          messageId: 14,
          senderId: 105,
          senderName: 'Khaled Mostafa',
          content: 'Is parking included?',
          createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 15,
          senderId: 205,
          senderName: 'Orascom Development',
          content: 'Yes, parking is included. Each unit comes with one or two parking spaces.',
          createdAt: new Date(Date.now() - 30 * 60 * 1000).toISOString(),
          isRead: false
        }
      ]
    },
    {
      chatId: 6,
      userId: 106,
      developerId: 201,
      userName: 'Yasmin Ahmed',
      developerName: 'Palm Hills Developments',
      propertyName: 'Apartment in 6th October City',
      salesMemberId: 1,
      salesMemberName: 'Ahmed Saleh',
      lastMessage: 'The property includes parking, 24/7 security, swimming pool, gym, and gardens.',
      lastMessageAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
      createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString(),
      isActive: true,
      messages: [
        {
          messageId: 16,
          senderId: 106,
          senderName: 'Yasmin Ahmed',
          content: 'What amenities are included?',
          createdAt: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 17,
          senderId: 201,
          senderName: 'Palm Hills Developments',
          content: 'The property includes parking, 24/7 security, swimming pool, gym, and gardens.',
          createdAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
          isRead: false
        }
      ]
    },
    {
      chatId: 7,
      userId: 107,
      developerId: 202,
      userName: 'Hany Sherif',
      developerName: 'Emaar Misr',
      propertyName: 'Duplex in New Cairo',
      // No sales member assigned (unassigned)
      lastMessage: 'Maintenance fees are approximately 80 EGP per square meter annually.',
      lastMessageAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
      createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
      isActive: true,
      messages: [
        {
          messageId: 18,
          senderId: 107,
          senderName: 'Hany Sherif',
          content: 'What are the maintenance fees?',
          createdAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 19,
          senderId: 202,
          senderName: 'Emaar Misr',
          content: 'Maintenance fees are approximately 80 EGP per square meter annually.',
          createdAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
          isRead: false
        }
      ]
    },
    {
      chatId: 8,
      userId: 108,
      developerId: 203,
      userName: 'Dina Mahmoud',
      developerName: 'SODIC',
      propertyName: 'Studio in Heliopolis',
      salesMemberId: 2,
      salesMemberName: 'Sarah Mohamed',
      lastMessage: 'The down payment is 15% of the total price, payable over 12 months.',
      lastMessageAt: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(),
      createdAt: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
      isActive: true,
      messages: [
        {
          messageId: 20,
          senderId: 108,
          senderName: 'Dina Mahmoud',
          content: 'What\'s the down payment requirement?',
          createdAt: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000).toISOString(),
          isRead: true
        },
        {
          messageId: 21,
          senderId: 203,
          senderName: 'SODIC',
          content: 'The down payment is 15% of the total price, payable over 12 months.',
          createdAt: new Date(Date.now() - 12 * 60 * 60 * 1000).toISOString(),
          isRead: false
        }
      ]
    }
  ]);
  
  const [selectedChat, setSelectedChat] = useState<Chat | null>(null);
  const [loading] = useState(false);
  
  // Track sales member assignments (can be changed)
  const [chatAssignments, setChatAssignments] = useState<Map<number, number>>(() => {
    const assignments = new Map<number, number>();
    chats.forEach(chat => {
      if (chat.salesMemberId) {
        assignments.set(chat.chatId, chat.salesMemberId);
      }
    });
    return assignments;
  });

  const handleSelectChat = (chat: Chat) => {
    setSelectedChat(chat);
  };

  const handleAssignSalesMember = (chatId: number, salesMemberId: number | null) => {
    if (salesMemberId === null) {
      const newAssignments = new Map(chatAssignments);
      newAssignments.delete(chatId);
      setChatAssignments(newAssignments);
      // Update the chat in state
      setChats(prevChats => prevChats.map(chat => 
        chat.chatId === chatId 
          ? { ...chat, salesMemberId: undefined, salesMemberName: undefined }
          : chat
      ));
      toast.success('Sales member unassigned');
    } else {
      setChatAssignments(new Map(chatAssignments.set(chatId, salesMemberId)));
      const salesMember = salesMembers.find(sm => sm.id === salesMemberId);
      // Update the chat in state
      setChats(prevChats => prevChats.map(chat => 
        chat.chatId === chatId 
          ? { ...chat, salesMemberId: salesMemberId, salesMemberName: salesMember?.name }
          : chat
      ));
      toast.success(`Assigned to ${salesMember?.name || 'sales member'}`);
    }
  };

  const getAssignedSalesMember = (chatId: number): SalesMember | null => {
    const assignmentId = chatAssignments.get(chatId);
    if (!assignmentId) {
      // Check if chat has salesMemberId in its data
      const chat = chats.find(c => c.chatId === chatId);
      if (chat?.salesMemberId) {
        return salesMembers.find(sm => sm.id === chat.salesMemberId) || null;
      }
      return null;
    }
    return salesMembers.find(sm => sm.id === assignmentId) || null;
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '50vh' }}>
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Chats</h1>
        <p className="text-gray-600">Manage your conversations</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-1 bg-white rounded-lg shadow">
          <div className="p-4 border-b">
            <h2 className="font-semibold">Conversations</h2>
          </div>
          <div className="divide-y">
            {chats.length === 0 ? (
              <div className="p-4 text-center text-gray-500">
                <MessageSquare className="mx-auto h-8 w-8 mb-2 text-gray-400" />
                <p>No chats found</p>
              </div>
            ) : (
              chats.map((chat) => {
                const assignedMember = getAssignedSalesMember(chat.chatId) || (chat.salesMemberId ? salesMembers.find(sm => sm.id === chat.salesMemberId) : null);
                return (
                  <div
                    key={chat.chatId}
                    className="p-4 hover:bg-gray-50 transition-colors border-b last:border-b-0"
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div
                        onClick={() => handleSelectChat(chat)}
                        className="flex items-start gap-3 flex-1 cursor-pointer"
                      >
                        <div className="w-10 h-10 rounded-full bg-blue-100 flex items-center justify-center flex-shrink-0">
                          <User className="h-5 w-5 text-blue-600" />
                        </div>
                        <div className="flex-1 min-w-0 overflow-hidden">
                          <p className="font-medium break-words line-clamp-2 mb-1">{chat.userName || chat.propertyName || 'Unknown'}</p>
                          <p className="text-sm text-gray-500 break-words line-clamp-2">{chat.lastMessage || 'No messages'}</p>
                        </div>
                      </div>
                      {chat.lastMessageAt && (
                        <div className="text-xs text-gray-400 flex items-center gap-1 ml-2">
                          <Clock className="h-3 w-3" />
                          {new Date(chat.lastMessageAt).toLocaleDateString()}
                        </div>
                      )}
                    </div>
                    <div className="flex items-center justify-between mt-2 gap-2">
                      {assignedMember ? (
                        <div className="flex items-center gap-2 text-xs text-gray-600 bg-blue-50 px-2 py-1 rounded flex-shrink-0">
                          <Users className="h-3 w-3 text-blue-600 flex-shrink-0" />
                          <span className="text-blue-700 break-words line-clamp-1">{assignedMember.name}</span>
                        </div>
                      ) : (
                        <span className="text-xs text-gray-400 flex-shrink-0">Unassigned</span>
                      )}
                      <div className="relative flex-shrink-0">
                        <select
                          value={assignedMember?.id || ''}
                          onChange={(e) => handleAssignSalesMember(chat.chatId, e.target.value ? parseInt(e.target.value) : null)}
                          onClick={(e) => e.stopPropagation()}
                          className="text-xs border border-gray-300 rounded px-2 py-1 pr-6 appearance-none bg-white hover:bg-gray-50 focus:outline-none focus:ring-1 focus:ring-blue-500 max-w-[150px]"
                        >
                          <option value="">Assign to...</option>
                          {salesMembers.map((member) => (
                            <option key={member.id} value={member.id}>
                              {member.name}
                            </option>
                          ))}
                          {assignedMember && <option value="">Unassign</option>}
                        </select>
                        <ChevronDown className="absolute right-1 top-1/2 transform -translate-y-1/2 h-3 w-3 text-gray-400 pointer-events-none" />
                      </div>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        <div className="lg:col-span-2 bg-white rounded-lg shadow">
          {selectedChat ? (
            <div className="p-6">
              <div className="flex justify-between items-center mb-4">
                <div>
                  <h2 className="text-xl font-semibold">{selectedChat.propertyName || selectedChat.userName || 'Chat'}</h2>
                  <p className="text-sm text-gray-500">with {selectedChat.userName}</p>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-sm text-gray-600">Assign to:</span>
                  <select
                    value={getAssignedSalesMember(selectedChat.chatId)?.id || ''}
                    onChange={(e) => handleAssignSalesMember(selectedChat.chatId, e.target.value ? parseInt(e.target.value) : null)}
                    className="border border-gray-300 rounded px-3 py-1 text-sm focus:outline-none focus:ring-1 focus:ring-blue-500"
                  >
                    <option value="">None</option>
                    {salesMembers.map((member) => (
                      <option key={member.id} value={member.id}>
                        {member.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>
              <div className="space-y-4 max-h-[calc(100vh-300px)] overflow-y-auto">
                {selectedChat.messages && selectedChat.messages.length > 0 ? (
                  selectedChat.messages.map((message) => (
                    <div key={message.messageId} className="flex flex-col gap-2">
                      <div className="flex justify-between text-sm text-gray-500">
                        <span className="font-medium">{message.senderName}</span>
                        <span>{new Date(message.createdAt).toLocaleString()}</span>
                      </div>
                      <div className={`rounded-lg p-3 ${message.senderId === selectedChat.developerId ? 'bg-blue-50 ml-8' : 'bg-gray-50 mr-8'}`}>
                        <p>{message.content}</p>
                        {!message.isRead && message.senderId === selectedChat.developerId && (
                          <span className="text-xs text-blue-600 mt-1 block">Unread</span>
                        )}
                      </div>
                    </div>
                  ))
                ) : (
                  <p className="text-gray-500 text-center py-8">No messages in this chat</p>
                )}
              </div>
            </div>
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

