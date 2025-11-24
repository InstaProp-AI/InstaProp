import React, { useState, useEffect } from 'react';
import { 
  Users, 
  Search, 
  Filter, 
  Mail, 
  Phone, 
  Calendar, 
  Edit, 
  Plus,
  Trash2,
  CheckCircle,
  XCircle,
  X,
  MessageSquare,
  Loader2,
  Folder,
  Building,
  ArrowLeft,
  TrendingUp,
  DollarSign,
  Clock,
  Target,
  BarChart3
} from 'lucide-react';
import { useToast } from '../contexts/ToastContext';
import { salesApi, authApi } from '../services/api';
import { Account, SalesTeam, TeamStats } from '../types';

interface SalesMember {
  accountId: string;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  status: string;
  isSuspended?: boolean;
  createdAt: string;
}

type ViewType = 'developers' | 'teams' | 'members';

const SalesPage: React.FC = () => {
  const toast = useToast();
  
  // Navigation state
  const [currentView, setCurrentView] = useState<ViewType>('developers');
  const [selectedDeveloper, setSelectedDeveloper] = useState<Account | null>(null);
  const [selectedTeam, setSelectedTeam] = useState<SalesTeam | null>(null);
  
  // Data state
  const [developers, setDevelopers] = useState<Account[]>([]);
  const [teams, setTeams] = useState<SalesTeam[]>([]);
  const [teamMembers, setTeamMembers] = useState<SalesMember[]>([]);
  const [teamStats, setTeamStats] = useState<TeamStats | null>(null);
  const [currentUser, setCurrentUser] = useState<Account | null>(null);
  const [loading, setLoading] = useState(true);
  
  // UI state
  const [searchTerm, setSearchTerm] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [selectedSalesMember, setSelectedSalesMember] = useState<SalesMember | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showTeamModal, setShowTeamModal] = useState(false);
  const [formData, setFormData] = useState<{
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
    password: string;
    developerId?: string;
    teamId?: string;
  }>({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    password: '',
    developerId: undefined,
    teamId: undefined
  });
  const [teamFormData, setTeamFormData] = useState<{
    teamName: string;
    developerId: string;
  }>({
    teamName: '',
    developerId: ''
  });

  // Helper function to extract error message from API error response
  const getErrorMessage = (error: any, defaultMessage: string): string => {
    if (!error?.response?.data) {
      return defaultMessage;
    }
    
    const data = error.response.data;
    
    if (typeof data === 'string') {
      return data;
    }
    
    if (typeof data === 'object') {
      return data.message || data.error || defaultMessage;
    }
    
    return defaultMessage;
  };

  // Load data on mount
  useEffect(() => {
    loadInitialData();
  }, []);

  // Load teams when developer is selected
  useEffect(() => {
    if (selectedDeveloper && currentView === 'teams') {
      loadTeams();
    }
  }, [selectedDeveloper, currentView]);

  // Load members and stats when team is selected
  useEffect(() => {
    if (selectedTeam && currentView === 'members') {
      loadTeamMembers();
      loadTeamStats();
    }
  }, [selectedTeam, currentView]);

  const loadInitialData = async () => {
    try {
      setLoading(true);
      
      const user = await authApi.getCurrentAccount();
      setCurrentUser(user);

      // If admin, load developers. If developer, go directly to teams view
      const isAdmin = user.roleId === '98237498-2374-4982-3749-823749823749' || user.roleName === 'Admin' || user.type === 'Admin';
      const isDeveloper = user.roleId === '78236478-2364-4782-3647-823647823647' || user.roleId === '78236478-2364-7823-0000-000000000000' || user.roleName === 'Developer' || user.type === 'Developer';
      
      if (isAdmin) {
        const devs = await salesApi.getDevelopers();
        setDevelopers(devs);
        setCurrentView('developers');
      } else if (isDeveloper) {
        setSelectedDeveloper(user);
        setCurrentView('teams');
        await loadTeams();
      }
    } catch (error: any) {
      console.error('Error loading initial data:', error);
      toast.error(getErrorMessage(error, 'Failed to load data'));
    } finally {
      setLoading(false);
    }
  };

  const loadTeams = async () => {
    try {
      if (!selectedDeveloper) return;
      
      const teamsData = await salesApi.getSalesTeams();
      // Filter teams for current developer if not admin
      const isAdmin = currentUser?.roleId === '98237498-2374-4982-3749-823749823749' || currentUser?.roleName === 'Admin' || currentUser?.type === 'Admin';
      const filteredTeams = isAdmin
        ? teamsData.filter((t: SalesTeam) => !selectedDeveloper || t.developerId === selectedDeveloper.accountId)
        : teamsData.filter((t: SalesTeam) => t.developerId === currentUser?.accountId);
      setTeams(filteredTeams);
    } catch (error: any) {
      console.error('Error loading teams:', error);
      toast.error(getErrorMessage(error, 'Failed to load teams'));
    }
  };

  const loadTeamMembers = async () => {
    try {
      if (!selectedTeam) return;
      
      const members = await salesApi.getTeamMembers(selectedTeam.teamId);
      // Map Account[] to SalesMember[] with proper type conversion
      const salesMembers: SalesMember[] = members.map(account => ({
        accountId: account.accountId,
        firstName: account.firstName,
        lastName: account.lastName,
        email: account.email,
        phoneNumber: account.phoneNumber,
        status: account.status,
        isSuspended: account.isSuspended ?? false,
        createdAt: account.createdAt
      }));
      setTeamMembers(salesMembers);
    } catch (error: any) {
      console.error('Error loading team members:', error);
      toast.error(getErrorMessage(error, 'Failed to load team members'));
    }
  };

  const loadTeamStats = async () => {
    try {
      if (!selectedTeam) return;
      
      const stats = await salesApi.getTeamStats(selectedTeam.teamId);
      setTeamStats(stats);
    } catch (error: any) {
      console.error('Error loading team stats:', error);
      toast.error(getErrorMessage(error, 'Failed to load team statistics'));
    }
  };

  const handleDeveloperClick = (developer: Account) => {
    setSelectedDeveloper(developer);
    setCurrentView('teams');
  };

  const handleTeamClick = (team: SalesTeam) => {
    setSelectedTeam(team);
    setCurrentView('members');
  };

  const handleBack = () => {
    if (currentView === 'members') {
      setCurrentView('teams');
      setSelectedTeam(null);
      setTeamStats(null);
    } else if (currentView === 'teams') {
      if (currentUser?.roleId === '98237498-2374-4982-3749-823749823749') {
        setCurrentView('developers');
        setSelectedDeveloper(null);
      }
    }
  };

  const handleAddTeam = () => {
    const isAdmin = currentUser?.roleId === '98237498-2374-4982-3749-823749823749' || currentUser?.roleName === 'Admin' || currentUser?.type === 'Admin';
    
    // For developers, use current user. For admins, use selected developer or allow selection in modal
    const developerId = isAdmin 
      ? (selectedDeveloper?.accountId || '')
      : (currentUser?.accountId || '');
    
    // For admins, if no developer is selected, allow selection in modal
    if (isAdmin && !selectedDeveloper) {
      setTeamFormData({
        teamName: '',
        developerId: ''
      });
      setShowTeamModal(true);
      return;
    }
    
    // For developers, they can always create teams (using their own ID)
    if (!isAdmin && !currentUser?.accountId) {
      toast.error('Unable to identify developer');
      return;
    }
    
    setTeamFormData({
      teamName: '',
      developerId: developerId
    });
    setShowTeamModal(true);
  };

  const handleSaveTeam = async () => {
    if (!teamFormData.developerId) {
      toast.error('Please select a developer');
      return;
    }
    
    try {
      await salesApi.createSalesTeam(teamFormData);
      await loadTeams();
      setShowTeamModal(false);
      toast.success('Team created successfully');
      // Reset form
      setTeamFormData({
        teamName: '',
        developerId: currentUser?.roleId === '98237498-2374-4982-3749-823749823749' 
          ? (selectedDeveloper?.accountId || '')
          : (currentUser?.accountId || '')
      });
    } catch (error: any) {
      toast.error(getErrorMessage(error, 'Failed to create team'));
    }
  };

  const handleAddMember = () => {
    if (!selectedTeam) return;
    setFormData({
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      password: '',
      developerId: selectedTeam.developerId,
      teamId: selectedTeam.teamId
    });
    setShowAddModal(true);
  };

  const handleSaveAdd = async () => {
    if (!formData.firstName || !formData.lastName || !formData.email || !formData.phone || !formData.password) {
      toast.error('Please fill in all required fields');
      return;
    }

    try {
      await salesApi.createSalesAccount(formData);
      await loadTeamMembers();
      await loadTeamStats();
      setShowAddModal(false);
      toast.success('Sales member added successfully');
    } catch (error: any) {
      toast.error(getErrorMessage(error, 'Failed to create sales member'));
    }
  };

  const handleEdit = (member: SalesMember) => {
    setSelectedSalesMember(member);
    setFormData({
      firstName: member.firstName,
      lastName: member.lastName,
      email: member.email,
      phone: member.phoneNumber,
      password: '',
      developerId: selectedTeam?.developerId,
      teamId: selectedTeam?.teamId
    });
    setShowEditModal(true);
  };

  const handleSaveEdit = async () => {
    if (!selectedSalesMember) return;

    try {
      const updateData: any = {
        firstName: formData.firstName,
        lastName: formData.lastName,
        email: formData.email,
        phoneNumber: formData.phone
      };

      await salesApi.updateSalesAccount(selectedSalesMember.accountId, updateData);
      await loadTeamMembers();
      await loadTeamStats();
      setShowEditModal(false);
      setSelectedSalesMember(null);
      toast.success('Sales member updated successfully');
    } catch (error: any) {
      toast.error(getErrorMessage(error, 'Failed to update sales member'));
    }
  };

  const handleDelete = async (id: number) => {
    if (window.confirm('Are you sure you want to delete this sales member?')) {
      try {
        await salesApi.deleteSalesAccount(id);
        await loadTeamMembers();
        await loadTeamStats();
        toast.success('Sales member deleted successfully');
      } catch (error: any) {
        toast.error(getErrorMessage(error, 'Failed to delete sales member'));
      }
    }
  };

  // Filter members
  const filteredMembers = teamMembers.filter(member => {
    const matchesSearch = 
      `${member.firstName} ${member.lastName}`.toLowerCase().includes(searchTerm.toLowerCase()) ||
      member.email.toLowerCase().includes(searchTerm.toLowerCase()) ||
      member.phoneNumber.includes(searchTerm);
    const matchesStatus = filterStatus === 'all' || 
      (filterStatus === 'Active' && !member.isSuspended) ||
      (filterStatus === 'Inactive' && member.isSuspended);
    return matchesSearch && matchesStatus;
  });

  // Render Developers View (Admin only)
  const renderDevelopersView = () => {
    const filteredDevelopers = developers.filter(dev =>
      `${dev.firstName} ${dev.lastName}`.toLowerCase().includes(searchTerm.toLowerCase()) ||
      dev.email.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
      <div>
        <div className="mb-6 flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">Sales Management</h1>
            <p className="text-gray-600">Select a developer to view their sales teams</p>
          </div>
        </div>

        {/* Search */}
        <div className="mb-6">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
            <input
              type="text"
              placeholder="Search developers..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>

        {/* Developers Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredDevelopers.map((developer) => (
            <div
              key={developer.accountId}
              onClick={() => handleDeveloperClick(developer)}
              className="bg-white rounded-lg shadow-md p-6 cursor-pointer hover:shadow-lg transition-shadow border-2 border-transparent hover:border-blue-500"
            >
              <div className="flex items-center gap-4 mb-4">
                <div className="h-12 w-12 rounded-full bg-blue-100 flex items-center justify-center">
                  <Building className="h-6 w-6 text-blue-600" />
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">
                    {developer.firstName} {developer.lastName}
                  </h3>
                  <p className="text-sm text-gray-500">{developer.email}</p>
                </div>
              </div>
              <div className="flex items-center gap-2 text-sm text-gray-600">
                <Users className="h-4 w-4" />
                <span>View Teams →</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  // Render Teams View
  const renderTeamsView = () => {
    const filteredTeams = teams.filter(team =>
      team.teamName.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
      <div>
        {/* Breadcrumb */}
        <div className="mb-4 flex items-center gap-2 text-sm text-gray-600">
          {currentUser?.roleId === '98237498-2374-4982-3749-823749823749' && (
            <>
              <button onClick={handleBack} className="hover:text-blue-600 flex items-center gap-1">
                <ArrowLeft className="h-4 w-4" />
                Developers
              </button>
              <span>/</span>
            </>
          )}
          <span className="text-gray-900 font-medium">
            {selectedDeveloper ? `${selectedDeveloper.firstName} ${selectedDeveloper.lastName}` : 'My Teams'}
          </span>
        </div>

        <div className="mb-6 flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">Sales Teams</h1>
            <p className="text-gray-600">Select a team to view members and statistics</p>
          </div>
          <button
            onClick={handleAddTeam}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="h-5 w-5" />
            Add Team
          </button>
        </div>

        {/* Search */}
        <div className="mb-6">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
            <input
              type="text"
              placeholder="Search teams..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
        </div>

        {/* Teams Grid (Folder-like) */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredTeams.map((team) => (
            <div
              key={team.teamId}
              onClick={() => handleTeamClick(team)}
              className="bg-white rounded-lg shadow-md p-6 cursor-pointer hover:shadow-lg transition-all border-2 border-transparent hover:border-blue-500"
            >
              <div className="flex items-start gap-4 mb-4">
                <div className="h-16 w-16 rounded-lg bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center shadow-lg">
                  <Folder className="h-8 w-8 text-white" />
                </div>
                <div className="flex-1">
                  <h3 className="text-xl font-bold text-gray-900 mb-1">{team.teamName}</h3>
                  <p className="text-sm text-gray-500">{team.developerName}</p>
                </div>
              </div>
              
              {/* Quick Stats */}
              <div className="grid grid-cols-2 gap-4 mt-4 pt-4 border-t border-gray-200">
                <div>
                  <p className="text-xs text-gray-500">Members</p>
                  <p className="text-lg font-semibold text-gray-900">{team.memberCount || 0}</p>
                </div>
                <div>
                  <p className="text-xs text-gray-500">Active</p>
                  <p className="text-lg font-semibold text-green-600">{team.activeMemberCount || 0}</p>
                </div>
              </div>
              
              <div className="mt-4 flex items-center gap-2 text-sm text-blue-600">
                <span>View Details →</span>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  // Render Team Members View
  const renderMembersView = () => {
    if (!selectedTeam) return null;

    return (
      <div>
        {/* Breadcrumb */}
        <div className="mb-4 flex items-center gap-2 text-sm text-gray-600">
          {currentUser?.roleId === '98237498-2374-4982-3749-823749823749' && (
            <>
              <button onClick={() => { setCurrentView('developers'); setSelectedDeveloper(null); }} className="hover:text-blue-600">
                Developers
              </button>
              <span>/</span>
              <button onClick={handleBack} className="hover:text-blue-600">
                {selectedDeveloper?.firstName} {selectedDeveloper?.lastName}
              </button>
              <span>/</span>
            </>
          )}
          <button onClick={handleBack} className="hover:text-blue-600 flex items-center gap-1">
            <ArrowLeft className="h-4 w-4" />
            Teams
          </button>
          <span>/</span>
          <span className="text-gray-900 font-medium">{selectedTeam.teamName}</span>
        </div>

        <div className="mb-6 flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">{selectedTeam.teamName}</h1>
            <p className="text-gray-600">Manage sales members and view team performance</p>
          </div>
          <button
            onClick={handleAddMember}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            <Plus className="h-5 w-5" />
            Add Member
          </button>
        </div>

        {/* Team Statistics */}
        {teamStats && (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
            <div className="bg-white rounded-lg shadow p-4 border-l-4 border-blue-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-500">Total Members</p>
                  <p className="text-2xl font-bold text-gray-900">{teamStats.totalMembers}</p>
                </div>
                <Users className="h-8 w-8 text-blue-500" />
              </div>
            </div>
            <div className="bg-white rounded-lg shadow p-4 border-l-4 border-green-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-500">Active Members</p>
                  <p className="text-2xl font-bold text-gray-900">{teamStats.activeMembers}</p>
                </div>
                <CheckCircle className="h-8 w-8 text-green-500" />
              </div>
            </div>
            <div className="bg-white rounded-lg shadow p-4 border-l-4 border-purple-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-500">Assigned Users</p>
                  <p className="text-2xl font-bold text-gray-900">{teamStats.totalAssignedUsers}</p>
                </div>
                <MessageSquare className="h-8 w-8 text-purple-500" />
              </div>
            </div>
            <div className="bg-white rounded-lg shadow p-4 border-l-4 border-orange-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-500">Deals Finished</p>
                  <p className="text-2xl font-bold text-gray-900">{teamStats.totalDealsFinished}</p>
                </div>
                <Target className="h-8 w-8 text-orange-500" />
              </div>
            </div>
            <div className="bg-white rounded-lg shadow p-4 border-l-4 border-yellow-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-500">Total Revenue</p>
                  <p className="text-2xl font-bold text-gray-900">${(teamStats.totalRevenue / 1000).toFixed(1)}K</p>
                </div>
                <DollarSign className="h-8 w-8 text-yellow-500" />
              </div>
            </div>
            <div className="bg-white rounded-lg shadow p-4 border-l-4 border-indigo-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-500">Total Chats</p>
                  <p className="text-2xl font-bold text-gray-900">{teamStats.totalChats}</p>
                </div>
                <MessageSquare className="h-8 w-8 text-indigo-500" />
              </div>
            </div>
            <div className="bg-white rounded-lg shadow p-4 border-l-4 border-pink-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-500">Avg Response</p>
                  <p className="text-2xl font-bold text-gray-900">
                    {teamStats.averageResponseTimeHours 
                      ? `${teamStats.averageResponseTimeHours.toFixed(1)}h`
                      : 'N/A'}
                  </p>
                </div>
                <Clock className="h-8 w-8 text-pink-500" />
              </div>
            </div>
            <div className="bg-white rounded-lg shadow p-4 border-l-4 border-teal-500">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-500">Conversion Rate</p>
                  <p className="text-2xl font-bold text-gray-900">{teamStats.conversionRate}%</p>
                </div>
                <TrendingUp className="h-8 w-8 text-teal-500" />
              </div>
            </div>
          </div>
        )}

        {/* Search and Filter */}
        <div className="mb-6 flex gap-4">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
            <input
              type="text"
              placeholder="Search by name, email, or phone..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
          </div>
          <div className="relative">
            <Filter className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-5 w-5" />
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="pl-10 pr-8 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent appearance-none bg-white"
            >
              <option value="all">All Status</option>
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
            </select>
          </div>
        </div>

        {/* Members Table */}
        <div className="bg-white rounded-lg shadow overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Name
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Contact
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Join Date
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredMembers.length === 0 ? (
                    <tr>
                      <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                        <Users className="mx-auto h-12 w-12 mb-2 text-gray-400" />
                        <p>No sales members found</p>
                      </td>
                    </tr>
                  ) : (
                    filteredMembers.map((member) => (
                      <tr key={member.accountId} className="hover:bg-gray-50 transition-colors">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center">
                            <div className="h-10 w-10 rounded-full bg-blue-100 flex items-center justify-center mr-3">
                              <Users className="h-5 w-5 text-blue-600" />
                            </div>
                            <div>
                              <div className="text-sm font-medium text-gray-900">
                                {member.firstName} {member.lastName}
                              </div>
                              <div className="text-sm text-gray-500">{member.email}</div>
                            </div>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="flex items-center gap-2 text-sm text-gray-600">
                            <Phone className="h-4 w-4 text-gray-400" />
                            {member.phoneNumber}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span
                            className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                              !member.isSuspended
                                ? 'bg-green-100 text-green-800'
                                : 'bg-gray-100 text-gray-800'
                            }`}
                          >
                            {!member.isSuspended ? (
                              <CheckCircle className="h-3 w-3 mr-1" />
                            ) : (
                              <XCircle className="h-3 w-3 mr-1" />
                            )}
                            {!member.isSuspended ? 'Active' : 'Inactive'}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                          <div className="flex items-center gap-2">
                            <Calendar className="h-4 w-4 text-gray-400" />
                            {new Date(member.createdAt).toLocaleDateString()}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                          <div className="flex items-center justify-end gap-2">
                            <button
                              onClick={() => handleEdit(member)}
                              className="text-blue-600 hover:text-blue-900 p-2 hover:bg-blue-50 rounded"
                            >
                              <Edit className="h-4 w-4" />
                            </button>
                            <button
                              onClick={() => handleDelete(member.accountId)}
                              className="text-red-600 hover:text-red-900 p-2 hover:bg-red-50 rounded"
                            >
                              <Trash2 className="h-4 w-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    );
  };

  if (loading && currentView === 'developers') {
    return (
      <div className="p-6 flex items-center justify-center min-h-screen">
        <Loader2 className="h-8 w-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <div className="p-6">
      {currentView === 'developers' && renderDevelopersView()}
      {currentView === 'teams' && renderTeamsView()}
      {currentView === 'members' && renderMembersView()}

      {/* Add Team Modal */}
      {showTeamModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold text-gray-900">Create New Team</h2>
              <button
                onClick={() => setShowTeamModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-4">
              {/* Developer Selection for Admin */}
              {currentUser?.roleId === '98237498-2374-4982-3749-823749823749' && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Developer *
                  </label>
                  <select
                    value={teamFormData.developerId}
                    onChange={(e) => setTeamFormData({ ...teamFormData, developerId: e.target.value })}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="">Select a developer</option>
                    {developers.map(dev => (
                      <option key={dev.accountId} value={dev.accountId}>
                        {dev.firstName} {dev.lastName} ({dev.email})
                      </option>
                    ))}
                  </select>
                </div>
              )}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Team Name
                </label>
                <input
                  type="text"
                  value={teamFormData.teamName}
                  onChange={(e) => setTeamFormData({ ...teamFormData, teamName: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Sales Team 1 (leave empty for auto-generation)"
                />
              </div>
            </div>
            <div className="mt-6 flex gap-3 justify-end">
              <button
                onClick={() => setShowTeamModal(false)}
                className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveTeam}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Create Team
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add Member Modal */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold text-gray-900">Add Sales Member</h2>
              <button
                onClick={() => setShowAddModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  First Name *
                </label>
                <input
                  type="text"
                  value={formData.firstName}
                  onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="First name"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Last Name *
                </label>
                <input
                  type="text"
                  value={formData.lastName}
                  onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Last name"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Email *
                </label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="email@example.com"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Phone *
                </label>
                <input
                  type="tel"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="+20 100 123 4567"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Password *
                </label>
                <input
                  type="password"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="Password"
                />
              </div>
            </div>
            <div className="mt-6 flex gap-3 justify-end">
              <button
                onClick={() => setShowAddModal(false)}
                className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveAdd}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Add Member
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Member Modal */}
      {showEditModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-bold text-gray-900">Edit Sales Member</h2>
              <button
                onClick={() => setShowEditModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  First Name *
                </label>
                <input
                  type="text"
                  value={formData.firstName}
                  onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Last Name *
                </label>
                <input
                  type="text"
                  value={formData.lastName}
                  onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Email *
                </label>
                <input
                  type="email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Phone *
                </label>
                <input
                  type="tel"
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>
            </div>
            <div className="mt-6 flex gap-3 justify-end">
              <button
                onClick={() => setShowEditModal(false)}
                className="px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveEdit}
                className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SalesPage;
