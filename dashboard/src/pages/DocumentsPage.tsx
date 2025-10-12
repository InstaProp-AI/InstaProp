import React, { useState, useEffect } from 'react';
import UserDocumentsManager from '../components/UserDocumentsManager';
import PropertyDocumentsManager from '../components/PropertyDocumentsManager';
import { usersApi, propertiesApi, documentsApi } from '../services/api';
import { Account, Property } from '../types';
import { useToast } from '../hooks/useToast';

export default function DocumentsPage() {
  const [activeTab, setActiveTab] = useState<'user' | 'property'>('user');
  const [users, setUsers] = useState<Account[]>([]);
  const [properties, setProperties] = useState<Property[]>([]);
  const [selectedUserId, setSelectedUserId] = useState<number | null>(null);
  const [selectedPropertyId, setSelectedPropertyId] = useState<number | null>(null);
  const [loading, setLoading] = useState(true);
  const [statistics, setStatistics] = useState<any>(null);
  const toast = useToast();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    try {
      setLoading(true);
      console.log('📊 Loading document management data...');
      
      const [usersData, propertiesData, statsData] = await Promise.all([
        usersApi.getAllUsers().catch((err) => {
          console.error('Failed to load users:', err);
          return [];
        }),
        propertiesApi.getProperties().catch((err) => {
          console.error('Failed to load properties:', err);
          return [];
        }),
        documentsApi.getDocumentStatistics().catch((err) => {
          console.warn('Failed to load statistics:', err);
          return null;
        })
      ]);
      
      console.log('✅ Data loaded:', { users: usersData.length, properties: propertiesData.length });
      
      setUsers(usersData);
      setProperties(propertiesData);
      setStatistics(statsData);
    } catch (error: any) {
      console.error('❌ Error loading data:', error);
      toast.error('Failed to load data: ' + (error.message || 'Unknown error'));
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <h1 className="text-3xl font-bold text-gray-900">Document Management</h1>
        </div>

        {/* Statistics */}
        {statistics && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-sm font-medium text-gray-500 mb-2">User Documents</h3>
              <p className="text-3xl font-bold text-blue-600">{statistics.totalUserDocs || 0}</p>
              {statistics.userDocuments && statistics.userDocuments.length > 0 && (
                <div className="mt-2 text-xs text-gray-500">
                  {statistics.userDocuments.map((stat: any) => (
                    <div key={stat.docType}>{stat.docType}: {stat.count}</div>
                  ))}
                </div>
              )}
            </div>
            
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-sm font-medium text-gray-500 mb-2">Property Documents</h3>
              <p className="text-3xl font-bold text-green-600">{statistics.totalPropertyDocs || 0}</p>
              {statistics.propertyDocuments && statistics.propertyDocuments.length > 0 && (
                <div className="mt-2 text-xs text-gray-500">
                  {statistics.propertyDocuments.map((stat: any) => (
                    <div key={stat.docType}>{stat.docType}: {stat.count}</div>
                  ))}
                </div>
              )}
            </div>
            
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-sm font-medium text-gray-500 mb-2">Property Images</h3>
              <p className="text-3xl font-bold text-purple-600">{statistics.totalPropertyImages || 0}</p>
              {statistics.propertyImages && statistics.propertyImages.length > 0 && (
                <div className="mt-2 text-xs text-gray-500">
                  {statistics.propertyImages.map((stat: any) => (
                    <div key={stat.imageType}>{stat.imageType}: {stat.count}</div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {/* Main Tabs */}
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            <button
              onClick={() => setActiveTab('user')}
              className={`${
                activeTab === 'user'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
            >
              📄 User Documents (KYC)
            </button>
            <button
              onClick={() => setActiveTab('property')}
              className={`${
                activeTab === 'property'
                  ? 'border-blue-500 text-blue-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
            >
              🏠 Property Documents & Images
            </button>
          </nav>
        </div>

        {/* Content */}
        {activeTab === 'user' ? (
          <div className="space-y-6">
            {/* User Selector */}
            <div className="bg-white rounded-lg shadow p-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Select User to View Documents
              </label>
              <select
                value={selectedUserId || ''}
                onChange={(e) => setSelectedUserId(e.target.value ? parseInt(e.target.value) : null)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">-- Select a User --</option>
                {users.map((user) => (
                  <option key={user.accountId} value={user.accountId}>
                    {user.firstName} {user.lastName} ({user.email}) - Status: {user.status}
                  </option>
                ))}
              </select>
            </div>

            {/* User Documents */}
            {selectedUserId && (
              <UserDocumentsManager userId={selectedUserId} isAdmin={true} />
            )}
          </div>
        ) : (
          <div className="space-y-6">
            {/* Property Selector */}
            <div className="bg-white rounded-lg shadow p-6">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Select Property to Manage Documents & Images
              </label>
              <select
                value={selectedPropertyId || ''}
                onChange={(e) => setSelectedPropertyId(e.target.value ? parseInt(e.target.value) : null)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="">-- Select a Property --</option>
                {properties.map((property) => (
                  <option key={property.propertyId} value={property.propertyId}>
                    {property.name} - {property.location} (Status: {property.status})
                  </option>
                ))}
              </select>
            </div>

            {/* Property Documents & Images */}
            {selectedPropertyId && (
              <PropertyDocumentsManager
                propertyId={selectedPropertyId}
                propertyName={properties.find(p => p.propertyId === selectedPropertyId)?.name}
              />
            )}
          </div>
        )}

        {/* Help Section */}
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 className="text-lg font-semibold text-blue-900 mb-3">
            📚 Document Management Guide
          </h3>
          <div className="space-y-2 text-sm text-blue-800">
            <p><strong>User Documents (KYC):</strong> Upload and manage identity verification documents for users. Supports ID cards, passports, and proof of address.</p>
            <p><strong>Property Documents:</strong> Manage legal documents, title deeds, floor plans, and other property-related documents.</p>
            <p><strong>Property Images:</strong> Upload property photos organized by type (exterior, interior, kitchen, etc.). Set a main image and display order.</p>
            <p><strong>File Limits:</strong> Maximum file size is 32MB. Supported formats: JPG, PNG, GIF, WEBP, PDF (for documents).</p>
            <p><strong>Storage:</strong> All files are stored on ImgBB with permanent URLs for easy sharing and display.</p>
          </div>
        </div>
      </div>
    </div>
  );
}


