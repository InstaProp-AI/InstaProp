import React, { useState, useEffect } from 'react';
import { CheckCircle, XCircle, AlertTriangle, Info, X } from 'lucide-react';

export type ToastType = 'success' | 'error' | 'warning' | 'info';

interface ToastProps {
  type: ToastType;
  message: string;
  onClose: () => void;
  duration?: number;
}

const Toast: React.FC<ToastProps> = ({ type, message, onClose, duration = 5000 }) => {
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(false);
      setTimeout(onClose, 300); // Wait for animation to complete
    }, duration);

    return () => clearTimeout(timer);
  }, [duration, onClose]);

  const getIcon = () => {
    switch (type) {
      case 'success':
        return <CheckCircle style={{ height: '1.25rem', width: '1.25rem' }} />;
      case 'error':
        return <XCircle style={{ height: '1.25rem', width: '1.25rem' }} />;
      case 'warning':
        return <AlertTriangle style={{ height: '1.25rem', width: '1.25rem' }} />;
      case 'info':
        return <Info style={{ height: '1.25rem', width: '1.25rem' }} />;
    }
  };

  const getColors = () => {
    switch (type) {
      case 'success':
        return { bg: '#dcfce7', border: '#10b981', text: '#166534' };
      case 'error':
        return { bg: '#fef2f2', border: '#ef4444', text: '#991b1b' };
      case 'warning':
        return { bg: '#fef3c7', border: '#f59e0b', text: '#92400e' };
      case 'info':
        return { bg: '#dbeafe', border: '#3b82f6', text: '#1e40af' };
    }
  };

  const colors = getColors();

  return (
    <div
      style={{
        position: 'fixed',
        top: '1rem',
        right: '1rem',
        zIndex: 1000,
        backgroundColor: colors.bg,
        borderLeft: `4px solid ${colors.border}`,
        color: colors.text,
        padding: '1rem 1.5rem',
        borderRadius: '0.5rem',
        boxShadow: '0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05)',
        display: 'flex',
        alignItems: 'center',
        gap: '1rem',
        minWidth: '300px',
        maxWidth: '500px',
        transform: isVisible ? 'translateX(0)' : 'translateX(120%)',
        transition: 'transform 0.3s ease',
      }}
    >
      {getIcon()}
      <p style={{ flex: 1, margin: 0, fontSize: '0.875rem', fontWeight: '500' }}>{message}</p>
      <button
        onClick={() => {
          setIsVisible(false);
          setTimeout(onClose, 300);
        }}
        style={{
          background: 'transparent',
          border: 'none',
          cursor: 'pointer',
          padding: '0.25rem',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: colors.text,
          opacity: 0.7,
          transition: 'opacity 0.2s'
        }}
      >
        <X style={{ height: '1rem', width: '1rem' }} />
      </button>
    </div>
  );
};

export default Toast;


