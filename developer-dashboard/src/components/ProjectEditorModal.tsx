import React, { useState, useEffect } from 'react';
import { developerApi, ProjectWithProperties } from '../services/developerApi';

interface ProjectEditorModalProps {
  open: boolean;
  onClose: () => void;
  project?: ProjectWithProperties | null;
  onSaved: () => void;
}

const ProjectEditorModal: React.FC<ProjectEditorModalProps> = ({ open, onClose, project, onSaved }) => {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [location, setLocation] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (project) {
      setName(project.name || '');
      setDescription(project.description || '');
      setLocation(project.location || '');
    } else {
      setName('');
      setDescription('');
      setLocation('');
    }
  }, [project]);

  if (!open) return null;

  const onSubmit = async () => {
    if (!name.trim()) return;
    setSaving(true);
    try {
      if (project) {
        await developerApi.updateProject(project.projectId, { name, description, location });
      } else {
        await developerApi.createProject({ name, description, location });
      }
      onSaved();
      onClose();
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-lg p-6">
        <h2 className="text-xl font-bold mb-4">{project ? 'Edit Project' : 'Create Project'}</h2>
        <div className="space-y-3">
          <input className="w-full border rounded-md px-3 py-2" placeholder="Project name" value={name} onChange={(e) => setName(e.target.value)} />
          <input className="w-full border rounded-md px-3 py-2" placeholder="Location" value={location} onChange={(e) => setLocation(e.target.value)} />
          <textarea className="w-full border rounded-md px-3 py-2" placeholder="Description" value={description} rows={4} onChange={(e) => setDescription(e.target.value)} />
        </div>
        <div className="mt-6 flex items-center justify-end gap-2">
          <button className="px-4 py-2 border rounded-md" onClick={onClose} disabled={saving}>Cancel</button>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-md" onClick={onSubmit} disabled={saving}>{saving ? 'Saving...' : 'Save'}</button>
        </div>
      </div>
    </div>
  );
};

export default ProjectEditorModal;


