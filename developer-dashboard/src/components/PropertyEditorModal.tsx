import React, { useEffect, useState } from 'react';
import { developerApi, ProjectWithProperties } from '../services/developerApi';
import PropertyDocumentsManager from './PropertyDocumentsManager';

interface PropertyEditorModalProps {
  open: boolean;
  onClose: () => void;
  onSaved: () => void;
  property?: {
    propertyId: number;
    name: string;
    description?: string;
    location?: string;
  } | null;
  projects: ProjectWithProperties[];
}

const PropertyEditorModal: React.FC<PropertyEditorModalProps> = ({ open, onClose, onSaved, property, projects }) => {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [location, setLocation] = useState('');
  const [projectId, setProjectId] = useState<number | undefined>(undefined);
  const [bedrooms, setBedrooms] = useState(2);
  const [bathrooms, setBathrooms] = useState(1);
  const [squareFeet, setSquareFeet] = useState(1000);
  const [yearBuilt, setYearBuilt] = useState(2000);
  const [category, setCategory] = useState('Residential');
  const [imageUrl, setImageUrl] = useState('');
  const [propertyType, setPropertyType] = useState<'Primary' | 'Resale'>('Primary');
  const [saving, setSaving] = useState(false);
  const [newlyCreatedPropertyId, setNewlyCreatedPropertyId] = useState<number | null>(null);

  useEffect(() => {
    if (property) {
      setName(property.name || '');
      setDescription(property.description || '');
      setLocation(property.location || '');
    } else {
      setName('');
      setDescription('');
      setLocation('');
      setProjectId(undefined);
    }
  }, [property]);

  if (!open) return null;

  const onSubmit = async () => {
    if (!name.trim()) return;
    setSaving(true);
    try {
      if (property) {
        await developerApi.updateProperty(property.propertyId, { name, description, location });
      } else {
        const propId = await developerApi.createProperty({
          name,
          description,
          location,
          projectId,
          bedrooms,
          bathrooms,
          squareFeet,
          yearBuilt,
          category,
          imageUrl,
          type: propertyType
        });
        setNewlyCreatedPropertyId(propId);
      }
      onSaved();
      // Keep modal open if newly created to let user upload images
      if (property) {
        onClose();
      }
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-y-auto p-6">
        <h2 className="text-xl font-bold mb-4">{property ? 'Edit Property' : 'Create Property'}</h2>
        <div className="grid grid-cols-2 gap-3">
          <input className="border rounded-md px-3 py-2" placeholder="Property name" value={name} onChange={(e) => setName(e.target.value)} />
          <input className="border rounded-md px-3 py-2" placeholder="Location" value={location} onChange={(e) => setLocation(e.target.value)} />
          <select className="border rounded-md px-3 py-2" value={projectId ?? ''} onChange={(e) => setProjectId(e.target.value ? Number(e.target.value) : undefined)}>
            <option value="">No Project</option>
            {projects.map(p => (
              <option key={p.projectId} value={p.projectId}>{p.name}</option>
            ))}
          </select>
          <select className="border rounded-md px-3 py-2" value={propertyType} onChange={(e) => setPropertyType(e.target.value as 'Primary' | 'Resale')}>
            <option value="Primary">Primary (New Construction)</option>
            <option value="Resale">Resale (Existing Property)</option>
          </select>
          <input className="border rounded-md px-3 py-2" placeholder="Image URL" value={imageUrl} onChange={(e) => setImageUrl(e.target.value)} />
          <input type="number" className="border rounded-md px-3 py-2" placeholder="Bedrooms" value={bedrooms} onChange={(e) => setBedrooms(Number(e.target.value))} />
          <input type="number" className="border rounded-md px-3 py-2" placeholder="Bathrooms" value={bathrooms} onChange={(e) => setBathrooms(Number(e.target.value))} />
          <input type="number" className="border rounded-md px-3 py-2" placeholder="Square Feet" value={squareFeet} onChange={(e) => setSquareFeet(Number(e.target.value))} />
          <input type="number" className="border rounded-md px-3 py-2" placeholder="Year Built" value={yearBuilt} onChange={(e) => setYearBuilt(Number(e.target.value))} />
          <input className="border rounded-md px-3 py-2 col-span-2" placeholder="Category" value={category} onChange={(e) => setCategory(e.target.value)} />
          <textarea className="border rounded-md px-3 py-2 col-span-2" rows={4} placeholder="Description" value={description} onChange={(e) => setDescription(e.target.value)} />
        </div>
        <div className="mt-6 flex items-center justify-end gap-2">
          <button className="px-4 py-2 border rounded-md" onClick={onClose} disabled={saving}>Cancel</button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-md" onClick={onSubmit} disabled={saving}>{saving ? 'Saving...' : 'Save'}</button>
        </div>

        {(property || newlyCreatedPropertyId) && (
          <div className="mt-8">
            <h3 className="text-lg font-semibold mb-3">Manage Documents & Images</h3>
            <PropertyDocumentsManager propertyId={property?.propertyId || newlyCreatedPropertyId!} propertyName={name} />
          </div>
        )}
      </div>
    </div>
  );
};

export default PropertyEditorModal;


