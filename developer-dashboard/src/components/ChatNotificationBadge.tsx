import React from 'react';

interface ChatNotificationBadgeProps {
  count: number;
}

const ChatNotificationBadge: React.FC<ChatNotificationBadgeProps> = ({ count }) => {
  if (count === 0) return null;

  return (
    <span className="inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-white bg-red-600 rounded-full">
      {count > 99 ? '99+' : count}
    </span>
  );
};

export default ChatNotificationBadge;

