import React, { useEffect, useState } from 'react';
import { developerApi, PropertySummary, ProjectWithProperties } from '../services/developerApi';
import PropertyEditorModal from '../components/PropertyEditorModal';
import AuctionRequestModal from '../components/AuctionRequestModal';

const DeveloperPropertiesPage: React.FC = () => {
  const [properties, setProperties] = useState<PropertySummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [projects, setProjects] = useState<ProjectWithProperties[]>([]);
  const [editorOpen, setEditorOpen] = useState(false);
  const [auctionOpen, setAuctionOpen] = useState(false);
  const [editingProperty, setEditingProperty] = useState<PropertySummary | null>(null);
  const [auctionPropertyId, setAuctionPropertyId] = useState<number | null>(null);
  const [typeFilter, setTypeFilter] = useState<'All' | 'Primary' | 'Resale'>('All');

  useEffect(() => {
    load();
  }, []);

  const load = async () => {
    try {
      setLoading(true);
      // Prefer explicit developer-owned properties endpoint for completeness
      const [proj, props] = await Promise.all([
        developerApi.getProjects(),
        developerApi.getProperties(),
      ]);
      setProjects(proj);
      setProperties(props);
    } catch (e) {
      console.error('Error loading developer properties:', e);
    } finally {
      setLoading(false);
    }
  };

  const filtered = properties.filter(prop => {
    const matchesSearch = prop.name.toLowerCase().includes(search.toLowerCase()) ||
      (prop.location || '').toLowerCase().includes(search.toLowerCase());
    const matchesType = typeFilter === 'All' || prop.type === typeFilter;
    return matchesSearch && matchesType;
  });

  return (
    <div className="p-4">
      <div className="flex items-center justify-between mb-4 gap-2">
        <h1 className="text-2xl font-bold">My Properties</h1>
        <div className="flex items-center gap-2">
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search properties..."
            className="px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <button className="px-3 py-2 bg-blue-600 text-white rounded-md" onClick={() => { setEditingProperty(null); setEditorOpen(true); }}>+ New Property</button>
        </div>
      </div>

      {/* Type Filter Tabs */}
      <div className="flex gap-2 mb-4">
        <button 
          onClick={() => setTypeFilter('All')} 
          className={`px-4 py-2 rounded-md ${typeFilter === 'All' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700'}`}>
          All ({properties.length})
        </button>
        <button 
          onClick={() => setTypeFilter('Primary')} 
          className={`px-4 py-2 rounded-md ${typeFilter === 'Primary' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-700'}`}>
          🏗️ New Development ({properties.filter(p => p.type === 'Primary').length})
        </button>
        <button 
          onClick={() => setTypeFilter('Resale')} 
          className={`px-4 py-2 rounded-md ${typeFilter === 'Resale' ? 'bg-green-600 text-white' : 'bg-gray-100 text-gray-700'}`}>
          🏡 Resale ({properties.filter(p => p.type === 'Resale').length})
        </button>
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center text-gray-500 py-10">No properties found</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map((prop) => (
            <div key={prop.propertyId} className="bg-white rounded-lg shadow overflow-hidden relative">
              {prop.imageUrl ? (
                <img src={prop.imageUrl} alt={prop.name} className="w-full h-40 object-cover" />
              ) : (
                <div className="w-full h-40 bg-gray-100" />
              )}
              <div className="absolute top-2 left-2">
                {prop.type === 'Primary' ? (
                  <span className="px-2 py-1 bg-blue-600 text-white text-xs font-semibold rounded-full flex items-center gap-1">
                    🏗️ New Development
                  </span>
                ) : (
                  <span className="px-2 py-1 bg-green-600 text-white text-xs font-semibold rounded-full flex items-center gap-1">
                    🏡 Resale
                  </span>
                )}
              </div>
              <div className="p-4">
                <h2 className="text-lg font-semibold mb-1">{prop.name}</h2>
                <p className="text-sm text-gray-600 mb-2">{prop.location || 'No location'}</p>
                <div className="text-sm text-gray-500">
                  {prop.bedrooms} beds • {prop.bathrooms} baths • {prop.squareFeet} sqft
                </div>
                <div className="mt-3 flex items-center gap-3 text-sm">
                  <button className="text-blue-600 hover:underline" onClick={() => { setEditingProperty(prop); setEditorOpen(true); }}>Edit</button>
                  <button className="text-green-600 hover:underline" onClick={() => { setAuctionPropertyId(prop.propertyId); setAuctionOpen(true); }}>Request Auction</button>
                  <button className="text-emerald-600 hover:underline" onClick={() => { setEditingProperty(prop); setEditorOpen(true); }}>Manage Images</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <PropertyEditorModal
        open={editorOpen}
        onClose={() => setEditorOpen(false)}
        onSaved={load}
        property={editingProperty}
        projects={projects}
      />

      <AuctionRequestModal
        open={auctionOpen}
        onClose={() => setAuctionOpen(false)}
        propertyId={auctionPropertyId}
        onRequested={load}
      />
    </div>
  );
};

export default DeveloperPropertiesPage;

