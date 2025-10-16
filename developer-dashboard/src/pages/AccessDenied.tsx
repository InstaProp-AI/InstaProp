import React from 'react';

const AccessDenied: React.FC = () => {
  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: 'linear-gradient(135deg, #dbeafe 0%, #e0e7ff 100%)' }}>
      <div style={{ backgroundColor: 'white', padding: '2rem', borderRadius: '1rem', boxShadow: '0 10px 25px rgba(0,0,0,0.1)', maxWidth: '28rem', textAlign: 'center' }}>
        <h1 style={{ fontSize: '1.5rem', fontWeight: 700, marginBottom: '0.5rem', color: '#111827' }}>Access Denied</h1>
        <p style={{ color: '#6b7280', marginBottom: '1.5rem' }}>
          This dashboard is only available for developer accounts. Please login with a developer account.
        </p>
        <a href="/" style={{ display: 'inline-block', padding: '0.5rem 1rem', backgroundColor: '#2563eb', color: 'white', borderRadius: '0.5rem', textDecoration: 'none' }}>
          Go to Login
        </a>
      </div>
    </div>
  );
};

export default AccessDenied;


