import React from 'react';
import { ChatMessage } from '../services/chatFirestore';

interface ChatMessageBubbleProps {
  message: ChatMessage & {
    senderName?: string;
    propertyName?: string;
    propertyLocation?: string;
    propertyImageUrl?: string;
  };
  isOwn: boolean;
}

const ChatMessageBubble: React.FC<ChatMessageBubbleProps> = ({ message, isOwn }) => {
  const hasProperty = message.propertyId && message.propertyId > 0;

  return (
    <div className={`flex ${isOwn ? 'justify-end' : 'justify-start'}`}>
      <div className={`max-w-md ${isOwn ? 'items-end' : 'items-start'}`}>
        {/* Property Preview */}
        {hasProperty && (
          <div className={`mb-1 p-3 rounded-lg border ${
            isOwn ? 'bg-blue-50 border-blue-200' : 'bg-gray-100 border-gray-300'
          }`}>
            <div className="flex items-center gap-2">
              {message.propertyImageUrl && (
                <img
                  src={message.propertyImageUrl}
                  alt={message.propertyName}
                  className="w-16 h-16 rounded object-cover"
                />
              )}
              <div className="flex-1">
                <p className="font-semibold text-sm">{message.propertyName || 'Property'}</p>
                {message.propertyLocation && (
                  <p className="text-xs text-gray-600">{message.propertyLocation}</p>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Message Bubble */}
        <div
          className={`px-4 py-2 rounded-lg ${
            isOwn
              ? 'bg-blue-600 text-white'
              : 'bg-white border border-gray-300'
          }`}
        >
          <p className="text-sm">{message.content}</p>
        </div>

        {/* Timestamp */}
        <p className="text-xs text-gray-500 mt-1 px-1">
          {new Date(message.createdAt).toLocaleTimeString([], {
            hour: '2-digit',
            minute: '2-digit',
          })}
        </p>
      </div>
    </div>
  );
};

export default ChatMessageBubble;

