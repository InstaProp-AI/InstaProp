import React, { useState, useEffect } from 'react';
import { propertiesApi } from '../services/api';
import { Property } from '../types';
import { X, Home } from 'lucide-react';

interface PropertyShareModalProps {
  onClose: () => void;
  onSelect: (propertyId: number) => void;
}

const PropertyShareModal: React.FC<PropertyShareModalProps> = ({ onClose, onSelect }) => {
  const [properties, setProperties] = useState<Property[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadProperties();
  }, []);

  const loadProperties = async () => {
    try {
      const data = await propertiesApi.getProperties();
      setProperties(data);
    } catch (error) {
      console.error('Error loading properties:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredProperties = properties.filter((property) =>
    property.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (property.location?.toLowerCase().includes(searchTerm.toLowerCase()) ?? false)
  );

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl max-h-[80vh] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b">
          <h3 className="text-xl font-bold">Select Property to Share</h3>
          <button
            onClick={onClose}
            className="p-1 hover:bg-gray-100 rounded"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Search */}
        <div className="p-4 border-b">
          <input
            type="text"
            placeholder="Search properties..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>

        {/* Properties List */}
        <div className="flex-1 overflow-y-auto p-4">
          {loading ? (
            <div className="flex items-center justify-center h-32">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            </div>
          ) : filteredProperties.length === 0 ? (
            <div className="text-center text-gray-500 py-8">
              <Home className="w-12 h-12 mx-auto mb-2 opacity-50" />
              <p>No properties found</p>
            </div>
          ) : (
            <div className="space-y-3">
              {filteredProperties.map((property) => (
                <button
                  key={property.propertyId}
                  onClick={() => onSelect(property.propertyId)}
                  className="w-full flex items-center gap-4 p-4 border rounded-lg hover:bg-gray-50 transition-colors text-left"
                >
                  {property.imageUrl ? (
                    <img
                      src={property.imageUrl}
                      alt={property.name}
                      className="w-20 h-20 rounded object-cover"
                    />
                  ) : (
                    <div className="w-20 h-20 bg-gray-200 rounded flex items-center justify-center">
                      <Home className="w-8 h-8 text-gray-400" />
                    </div>
                  )}
                  
                  <div className="flex-1">
                    <h4 className="font-semibold">{property.name}</h4>
                    {property.location && (
                      <p className="text-sm text-gray-600">{property.location}</p>
                    )}
                    <div className="text-xs text-gray-500 mt-1">
                      {property.bedrooms} beds • {property.bathrooms} baths • {property.squareFeet} sqft
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default PropertyShareModal;

