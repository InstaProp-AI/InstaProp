import React, { useEffect, useState } from 'react';
import { developerApi, ProjectWithProperties } from '../services/developerApi';
import ProjectEditorModal from '../components/ProjectEditorModal';
import { Calendar, MapPin, Home } from 'lucide-react';

const DeveloperProjectsPage: React.FC = () => {
  const [projects, setProjects] = useState<ProjectWithProperties[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [editorOpen, setEditorOpen] = useState(false);
  const [editingProject, setEditingProject] = useState<ProjectWithProperties | null>(null);

  useEffect(() => {
    load();
  }, []);

  const load = async () => {
    try {
      setLoading(true);
      const data = await developerApi.getProjects();
      setProjects(data);
    } catch (e) {
      console.error('Error loading developer projects:', e);
    } finally {
      setLoading(false);
    }
  };

  const filtered = projects.filter(p =>
    p.name.toLowerCase().includes(search.toLowerCase()) ||
    (p.location || '').toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="p-4">
      <div className="flex items-center justify-between mb-4 gap-2">
        <h1 className="text-2xl font-bold">My Projects</h1>
        <div className="flex items-center gap-2">
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search projects..."
            className="px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <button className="px-3 py-2 bg-blue-600 text-white rounded-md" onClick={() => { setEditingProject(null); setEditorOpen(true); }}>+ New Project</button>
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center h-40">
          <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
        </div>
      ) : filtered.length === 0 ? (
        <div className="text-center text-gray-500 py-10">No projects found</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filtered.map((p) => (
            <div key={p.projectId} className="bg-white rounded-lg shadow p-4">
              <div className="flex items-start justify-between mb-2">
                <h2 className="text-lg font-semibold">{p.name}</h2>
                <span className="text-xs text-gray-500 flex items-center gap-1">
                  <Calendar className="w-3 h-3" />
                  {new Date(p.createdAt).toLocaleDateString()}
                </span>
              </div>
              {p.location && (
                <div className="text-sm text-gray-600 flex items-center gap-1 mb-2">
                  <MapPin className="w-4 h-4" /> {p.location}
                </div>
              )}
              <div className="text-sm text-gray-700 mb-3 line-clamp-3">{p.description || 'No description'}</div>
              <div className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-2">
                  <div className="px-2 py-1 bg-blue-50 text-blue-700 rounded-md flex items-center gap-1">
                    <Home className="w-4 h-4" /> {p.properties.length} properties
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <button className="text-blue-600 hover:underline text-xs" onClick={() => { setEditingProject(p); setEditorOpen(true); }}>Edit</button>
                  <span className="text-xs text-gray-500">{p.isActive ? 'Active' : 'Inactive'}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <ProjectEditorModal
        open={editorOpen}
        onClose={() => setEditorOpen(false)}
        project={editingProject}
        onSaved={load}
      />
    </div>
  );
};

export default DeveloperProjectsPage;

