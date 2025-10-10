import React, { useState, useEffect } from 'react';
import { settingsApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { 
  Settings,
  Bell,
  Lock,
  Globe,
  Mail,
  Smartphone,
  Shield,
  Database,
  Users,
  DollarSign,
  Save,
  RefreshCw,
  Download,
  Upload,
  CheckCircle,
  AlertTriangle
} from 'lucide-react';

const SettingsPage: React.FC = () => {
  const toast = useToast();
  const [activeTab, setActiveTab] = useState('general');
  const [loading, setLoading] = useState(false);
  const [settings, setSettings] = useState({
    siteName: 'Property Flipper',
    siteEmail: 'admin@propertyflipper.com',
    currency: 'USD',
    timezone: 'UTC',
    emailNotifications: true,
    smsNotifications: false,
    bidAlerts: true,
    userRegistration: true,
    autoApproval: false,
    maintenanceMode: false,
    twoFactorAuth: true
  });

  const tabs = [
    { id: 'general', label: 'General', icon: Settings },
    { id: 'notifications', label: 'Notifications', icon: Bell },
    { id: 'security', label: 'Security', icon: Lock },
    { id: 'system', label: 'System', icon: Database },
  ];

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      const data = await settingsApi.getSettings();
      setSettings(data);
    } catch (error: any) {
      console.error('Error loading settings:', error);
      toast.warning('Using default settings');
    }
  };

  const handleSave = async () => {
    try {
      setLoading(true);
      await settingsApi.updateSettings(settings);
      toast.success('Settings saved successfully!');
    } catch (error: any) {
      console.error('Error saving settings:', error);
      toast.error(error?.response?.data?.message || 'Failed to save settings');
    } finally {
      setLoading(false);
    }
  };

  const handleBackupDatabase = async () => {
    try {
      const result = await settingsApi.backupDatabase();
      toast.success(`Database backed up: ${result.filename}`);
    } catch (error: any) {
      toast.error('Failed to backup database');
    }
  };

  const handleClearCache = async () => {
    try {
      await settingsApi.clearCache();
      toast.success('Cache cleared successfully!');
    } catch (error: any) {
      toast.error('Failed to clear cache');
    }
  };

  return (
    <div>
      {/* Header */}
      <div style={{
        marginBottom: '2rem'
      }}>
        <h1 style={{
          fontSize: '2.5rem',
          fontWeight: 'bold',
          color: '#111827',
          marginBottom: '0.5rem',
          background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
          WebkitBackgroundClip: 'text',
          WebkitTextFillColor: 'transparent'
        }}>Settings</h1>
        <p style={{
          fontSize: '1.125rem',
          color: '#6b7280',
          margin: 0
        }}>
          Configure your admin dashboard and system preferences
        </p>
      </div>

      <div style={{ display: 'flex', gap: '2rem' }}>
        {/* Sidebar Tabs */}
        <div style={{
          width: '240px',
          flexShrink: 0
        }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            padding: '1rem',
            boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
            border: '1px solid #e5e7eb'
          }}>
            {tabs.map((tab) => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  style={{
                    width: '100%',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.75rem',
                    padding: '0.75rem 1rem',
                    marginBottom: '0.5rem',
                    borderRadius: '0.5rem',
                    border: 'none',
                    backgroundColor: activeTab === tab.id ? '#667eea' : 'transparent',
                    color: activeTab === tab.id ? 'white' : '#6b7280',
                    cursor: 'pointer',
                    transition: 'all 0.2s',
                    fontSize: '0.875rem',
                    fontWeight: '500',
                    textAlign: 'left'
                  }}
                >
                  <Icon style={{ height: '1.25rem', width: '1.25rem' }} />
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Content Area */}
        <div style={{ flex: 1 }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '1rem',
            padding: '2rem',
            boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
            border: '1px solid #e5e7eb'
          }}>
            {activeTab === 'general' && (
              <div>
                <h2 style={{ fontSize: '1.5rem', fontWeight: '600', color: '#111827', marginBottom: '1.5rem' }}>
                  General Settings
                </h2>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '500', color: '#374151', marginBottom: '0.5rem' }}>
                      Site Name
                    </label>
                    <input
                      type="text"
                      value={settings.siteName}
                      onChange={(e) => setSettings({ ...settings, siteName: e.target.value })}
                      style={{
                        width: '100%',
                        padding: '0.75rem',
                        border: '1px solid #d1d5db',
                        borderRadius: '0.5rem',
                        fontSize: '0.875rem',
                        outline: 'none'
                      }}
                    />
                  </div>
                  <div>
                    <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '500', color: '#374151', marginBottom: '0.5rem' }}>
                      Site Email
                    </label>
                    <input
                      type="email"
                      value={settings.siteEmail}
                      onChange={(e) => setSettings({ ...settings, siteEmail: e.target.value })}
                      style={{
                        width: '100%',
                        padding: '0.75rem',
                        border: '1px solid #d1d5db',
                        borderRadius: '0.5rem',
                        fontSize: '0.875rem',
                        outline: 'none'
                      }}
                    />
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1.5rem' }}>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '500', color: '#374151', marginBottom: '0.5rem' }}>
                        Currency
                      </label>
                      <select
                        value={settings.currency}
                        onChange={(e) => setSettings({ ...settings, currency: e.target.value })}
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          backgroundColor: 'white'
                        }}
                      >
                        <option value="USD">USD - US Dollar</option>
                        <option value="EUR">EUR - Euro</option>
                        <option value="GBP">GBP - British Pound</option>
                      </select>
                    </div>
                    <div>
                      <label style={{ display: 'block', fontSize: '0.875rem', fontWeight: '500', color: '#374151', marginBottom: '0.5rem' }}>
                        Timezone
                      </label>
                      <select
                        value={settings.timezone}
                        onChange={(e) => setSettings({ ...settings, timezone: e.target.value })}
                        style={{
                          width: '100%',
                          padding: '0.75rem',
                          border: '1px solid #d1d5db',
                          borderRadius: '0.5rem',
                          fontSize: '0.875rem',
                          outline: 'none',
                          backgroundColor: 'white'
                        }}
                      >
                        <option value="UTC">UTC</option>
                        <option value="EST">EST</option>
                        <option value="PST">PST</option>
                      </select>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'notifications' && (
              <div>
                <h2 style={{ fontSize: '1.5rem', fontWeight: '600', color: '#111827', marginBottom: '1.5rem' }}>
                  Notification Settings
                </h2>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                  {[
                    { key: 'emailNotifications', label: 'Email Notifications', description: 'Receive email notifications for important events', icon: Mail },
                    { key: 'smsNotifications', label: 'SMS Notifications', description: 'Receive text message alerts', icon: Smartphone },
                    { key: 'bidAlerts', label: 'Bid Alerts', description: 'Get notified when new bids are placed', icon: Bell }
                  ].map((item) => {
                    const Icon = item.icon;
                    return (
                      <div key={item.key} style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        padding: '1rem',
                        borderRadius: '0.5rem',
                        backgroundColor: '#f9fafb',
                        border: '1px solid #e5e7eb'
                      }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                          <div style={{
                            width: '2.5rem',
                            height: '2.5rem',
                            borderRadius: '0.5rem',
                            backgroundColor: 'white',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center'
                          }}>
                            <Icon style={{ height: '1.25rem', width: '1.25rem', color: '#667eea' }} />
                          </div>
                          <div>
                            <p style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827', margin: '0 0 0.25rem 0' }}>
                              {item.label}
                            </p>
                            <p style={{ fontSize: '0.75rem', color: '#6b7280', margin: 0 }}>
                              {item.description}
                            </p>
                          </div>
                        </div>
                        <label style={{ position: 'relative', display: 'inline-block', width: '3rem', height: '1.5rem' }}>
                          <input
                            type="checkbox"
                            checked={settings[item.key as keyof typeof settings] as boolean}
                            onChange={(e) => setSettings({ ...settings, [item.key]: e.target.checked })}
                            style={{ opacity: 0, width: 0, height: 0 }}
                          />
                          <span style={{
                            position: 'absolute',
                            cursor: 'pointer',
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            backgroundColor: settings[item.key as keyof typeof settings] ? '#667eea' : '#cbd5e1',
                            transition: '0.3s',
                            borderRadius: '1.5rem'
                          }}>
                            <span style={{
                              position: 'absolute',
                              content: '',
                              height: '1.125rem',
                              width: '1.125rem',
                              left: settings[item.key as keyof typeof settings] ? '1.625rem' : '0.1875rem',
                              bottom: '0.1875rem',
                              backgroundColor: 'white',
                              transition: '0.3s',
                              borderRadius: '50%'
                            }} />
                          </span>
                        </label>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {activeTab === 'security' && (
              <div>
                <h2 style={{ fontSize: '1.5rem', fontWeight: '600', color: '#111827', marginBottom: '1.5rem' }}>
                  Security Settings
                </h2>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                  {[
                    { key: 'userRegistration', label: 'User Registration', description: 'Allow new users to register', icon: Users },
                    { key: 'autoApproval', label: 'Auto Approval', description: 'Automatically approve verified users', icon: CheckCircle },
                    { key: 'twoFactorAuth', label: 'Two-Factor Authentication', description: 'Require 2FA for admin accounts', icon: Shield }
                  ].map((item) => {
                    const Icon = item.icon;
                    return (
                      <div key={item.key} style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'space-between',
                        padding: '1rem',
                        borderRadius: '0.5rem',
                        backgroundColor: '#f9fafb',
                        border: '1px solid #e5e7eb'
                      }}>
                        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                          <div style={{
                            width: '2.5rem',
                            height: '2.5rem',
                            borderRadius: '0.5rem',
                            backgroundColor: 'white',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center'
                          }}>
                            <Icon style={{ height: '1.25rem', width: '1.25rem', color: '#667eea' }} />
                          </div>
                          <div>
                            <p style={{ fontSize: '0.875rem', fontWeight: '500', color: '#111827', margin: '0 0 0.25rem 0' }}>
                              {item.label}
                            </p>
                            <p style={{ fontSize: '0.75rem', color: '#6b7280', margin: 0 }}>
                              {item.description}
                            </p>
                          </div>
                        </div>
                        <label style={{ position: 'relative', display: 'inline-block', width: '3rem', height: '1.5rem' }}>
                          <input
                            type="checkbox"
                            checked={settings[item.key as keyof typeof settings] as boolean}
                            onChange={(e) => setSettings({ ...settings, [item.key]: e.target.checked })}
                            style={{ opacity: 0, width: 0, height: 0 }}
                          />
                          <span style={{
                            position: 'absolute',
                            cursor: 'pointer',
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            backgroundColor: settings[item.key as keyof typeof settings] ? '#667eea' : '#cbd5e1',
                            transition: '0.3s',
                            borderRadius: '1.5rem'
                          }}>
                            <span style={{
                              position: 'absolute',
                              content: '',
                              height: '1.125rem',
                              width: '1.125rem',
                              left: settings[item.key as keyof typeof settings] ? '1.625rem' : '0.1875rem',
                              bottom: '0.1875rem',
                              backgroundColor: 'white',
                              transition: '0.3s',
                              borderRadius: '50%'
                            }} />
                          </span>
                        </label>
                      </div>
                    );
                  })}
                </div>
              </div>
            )}

            {activeTab === 'system' && (
              <div>
                <h2 style={{ fontSize: '1.5rem', fontWeight: '600', color: '#111827', marginBottom: '1.5rem' }}>
                  System Settings
                </h2>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1.5rem' }}>
                  <div style={{
                    padding: '1rem',
                    borderRadius: '0.5rem',
                    backgroundColor: '#fef3c7',
                    border: '1px solid #fcd34d',
                    display: 'flex',
                    alignItems: 'start',
                    gap: '0.75rem'
                  }}>
                    <AlertTriangle style={{ height: '1.25rem', width: '1.25rem', color: '#f59e0b', flexShrink: 0 }} />
                    <div>
                      <p style={{ fontSize: '0.875rem', fontWeight: '500', color: '#92400e', margin: '0 0 0.25rem 0' }}>
                        Maintenance Mode
                      </p>
                      <p style={{ fontSize: '0.75rem', color: '#92400e', margin: 0 }}>
                        When enabled, only admins can access the platform
                      </p>
                    </div>
                    <label style={{ position: 'relative', display: 'inline-block', width: '3rem', height: '1.5rem', marginLeft: 'auto' }}>
                      <input
                        type="checkbox"
                        checked={settings.maintenanceMode}
                        onChange={(e) => setSettings({ ...settings, maintenanceMode: e.target.checked })}
                        style={{ opacity: 0, width: 0, height: 0 }}
                      />
                      <span style={{
                        position: 'absolute',
                        cursor: 'pointer',
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        backgroundColor: settings.maintenanceMode ? '#ef4444' : '#cbd5e1',
                        transition: '0.3s',
                        borderRadius: '1.5rem'
                      }}>
                        <span style={{
                          position: 'absolute',
                          content: '',
                          height: '1.125rem',
                          width: '1.125rem',
                          left: settings.maintenanceMode ? '1.625rem' : '0.1875rem',
                          bottom: '0.1875rem',
                          backgroundColor: 'white',
                          transition: '0.3s',
                          borderRadius: '50%'
                        }} />
                      </span>
                    </label>
                  </div>

                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1rem' }}>
                    <button
                      onClick={handleBackupDatabase}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '0.5rem',
                        padding: '0.75rem 1rem',
                        backgroundColor: '#f3f4f6',
                        color: '#374151',
                        border: '1px solid #d1d5db',
                        borderRadius: '0.5rem',
                        cursor: 'pointer',
                        fontSize: '0.875rem',
                        fontWeight: '500'
                      }}
                    >
                      <Download style={{ height: '1rem', width: '1rem' }} />
                      Backup Database
                    </button>
                    <button
                      onClick={() => toast.info('Database restore feature coming soon')}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '0.5rem',
                        padding: '0.75rem 1rem',
                        backgroundColor: '#f3f4f6',
                        color: '#374151',
                        border: '1px solid #d1d5db',
                        borderRadius: '0.5rem',
                        cursor: 'pointer',
                        fontSize: '0.875rem',
                        fontWeight: '500'
                      }}
                    >
                      <Upload style={{ height: '1rem', width: '1rem' }} />
                      Restore Database
                    </button>
                    <button
                      onClick={handleClearCache}
                      style={{
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        gap: '0.5rem',
                        padding: '0.75rem 1rem',
                        backgroundColor: '#f3f4f6',
                        color: '#374151',
                        border: '1px solid #d1d5db',
                        borderRadius: '0.5rem',
                        cursor: 'pointer',
                        fontSize: '0.875rem',
                        fontWeight: '500'
                      }}
                    >
                      <RefreshCw style={{ height: '1rem', width: '1rem' }} />
                      Clear Cache
                    </button>
                    <button style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      gap: '0.5rem',
                      padding: '0.75rem 1rem',
                      backgroundColor: '#fef2f2',
                      color: '#dc2626',
                      border: '1px solid #fecaca',
                      borderRadius: '0.5rem',
                      cursor: 'pointer',
                      fontSize: '0.875rem',
                      fontWeight: '500'
                    }}>
                      <AlertTriangle style={{ height: '1rem', width: '1rem' }} />
                      Reset System
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* Save Button */}
            <div style={{
              marginTop: '2rem',
              paddingTop: '1.5rem',
              borderTop: '1px solid #e5e7eb',
              display: 'flex',
              justifyContent: 'flex-end',
              gap: '1rem'
            }}>
              <button
                onClick={handleSave}
                disabled={loading}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                  color: 'white',
                  fontWeight: '500',
                  padding: '0.75rem 1.5rem',
                  borderRadius: '0.5rem',
                  border: 'none',
                  cursor: loading ? 'not-allowed' : 'pointer',
                  transition: 'all 0.2s',
                  opacity: loading ? 0.6 : 1
                }}
              >
                <Save style={{ height: '1rem', width: '1rem' }} />
                {loading ? 'Saving...' : 'Save Changes'}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default SettingsPage;

