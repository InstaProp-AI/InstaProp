import axios from 'axios';
import { Account, Project, Property, DashboardStats, CreateProjectDto, UpdateProjectDto, CreatePropertyDto } from '../types';

const API_BASE_URL = 'http://localhost:5001/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add auth token to requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('authToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Auth API
export const authApi = {
  login: async (email: string, password: string) => {
    const response = await api.post('/account/login', { email, password });
    return response.data;
  },
  
  getCurrentAccount: async (): Promise<Account> => {
    const response = await api.get('/account/me');
    return response.data;
  },
};

// Projects API
export const projectsApi = {
  getProjects: async (): Promise<Project[]> => {
    const response = await api.get('/project');
    return response.data;
  },
  
  getProject: async (id: number): Promise<Project> => {
    const response = await api.get(`/project/${id}`);
    return response.data;
  },
  
  createProject: async (data: CreateProjectDto): Promise<Project> => {
    const response = await api.post('/project', data);
    return response.data;
  },
  
  updateProject: async (id: number, data: UpdateProjectDto): Promise<void> => {
    await api.put(`/project/${id}`, data);
  },
  
  deleteProject: async (id: number): Promise<void> => {
    await api.delete(`/project/${id}`);
  },
  
  getProjectProperties: async (id: number): Promise<Property[]> => {
    const response = await api.get(`/project/${id}/properties`);
    return response.data;
  },
};

// Properties API
export const propertiesApi = {
  getProperties: async (): Promise<Property[]> => {
    const response = await api.get('/property');
    return response.data;
  },
  
  getProperty: async (id: number): Promise<Property> => {
    const response = await api.get(`/property/${id}`);
    return response.data;
  },
  
  createProperty: async (data: CreatePropertyDto): Promise<Property> => {
    const response = await api.post('/property', data);
    return response.data;
  },
  
  updateProperty: async (id: number, data: Partial<CreatePropertyDto>): Promise<void> => {
    await api.put(`/property/${id}`, data);
  },
  
  deleteProperty: async (id: number): Promise<void> => {
    await api.delete(`/property/${id}`);
  },
  
  approveProperty: async (id: number): Promise<void> => {
    await api.put(`/property/${id}/approve`);
  },
};

// Dashboard API
export const dashboardApi = {
  getStats: async (): Promise<DashboardStats> => {
    const response = await api.get('/dashboard/stats');
    return response.data;
  },
  
  getAnalytics: async () => {
    const response = await api.get('/dashboard/analytics');
    return response.data;
  },
};

export default api;
