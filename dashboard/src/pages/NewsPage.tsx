import React, { useState, useEffect } from 'react';
import { 
  Newspaper, 
  Calendar, 
  Eye, 
  Plus, 
  Edit, 
  Trash2, 
  X, 
  Search,
  Tag,
  CheckCircle,
  XCircle,
  Folder,
  ArrowLeft,
  Building
} from 'lucide-react';
import { newsApi, authApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { Account } from '../types';

interface NewsArticle {
  newsArticleId?: number;
  articleId?: number;
  id?: number;
  title: string;
  content: string;
  category?: string;
  publishedDate?: string;
  createdAt?: string;
  updatedAt?: string;
  isPublished?: boolean;
  developerId?: number;
  images?: string[];
  imageUrl?: string;
}

interface PaginatedNewsResponse {
  items: NewsArticle[];
  totalCount: number;
  currentPage: number;
  pageSize: number;
  hasMore: boolean;
}

interface DeveloperNewsCount {
  developerId: string;
  developerName: string;
  email: string;
  newsCount: number;
}

type ViewType = 'folders' | 'news';

const NewsPage: React.FC = () => {
  const toast = useToast();
  const [currentUser, setCurrentUser] = useState<Account | null>(null);
  const [loading, setLoading] = useState(true);
  
  // Navigation state
  const [currentView, setCurrentView] = useState<ViewType>('folders');
  const [selectedDeveloperId, setSelectedDeveloperId] = useState<number | null>(null);
  const [developers, setDevelopers] = useState<DeveloperNewsCount[]>([]);
  const [adminNewsCount, setAdminNewsCount] = useState(0);
  
  // News data state
  const [news, setNews] = useState<NewsArticle[]>([]);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize] = useState(12);
  const [totalCount, setTotalCount] = useState(0);
  const [searchTerm, setSearchTerm] = useState('');
  
  // Modal states
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [showViewModal, setShowViewModal] = useState(false);
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [selectedNews, setSelectedNews] = useState<NewsArticle | null>(null);
  
  // Form states
  const [formData, setFormData] = useState({
    title: '',
    content: '',
    category: '',
    imageUrls: '',
    isPublished: true,
  });
  
  const [formErrors, setFormErrors] = useState<Record<string, string>>({});
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    loadInitialData();
  }, []);

  useEffect(() => {
    if (currentView === 'news') {
      fetchNews();
    }
  }, [currentPage, currentView, selectedDeveloperId]);

  const loadInitialData = async () => {
    try {
      setLoading(true);
      const user = await authApi.getCurrentAccount();
      setCurrentUser(user);
      
      // Check if admin or developer
      const isAdmin = user.roleId === '98237498-2374-4982-3749-823749823749' || user.roleName === 'Admin';
      const isDeveloper = user.roleId === '78236478-2364-7823-0000-000000000000' || user.roleName === 'Developer';
      
      if (isAdmin) {
        // Admin: Load developers with news counts and admin posts count
        await loadDevelopersWithNews();
        await loadAdminNewsCount();
        setCurrentView('folders');
      } else if (isDeveloper) {
        // Developer: Go directly to news view (their own news)
        setCurrentView('news');
        setSelectedDeveloperId(null); // null means their own news
        await fetchNews();
      }
    } catch (error: any) {
      console.error('Error loading initial data:', error);
      toast.error(error?.response?.data?.message || 'Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  const loadDevelopersWithNews = async () => {
    try {
      const devs = await newsApi.getDevelopersWithNews();
      setDevelopers(devs);
    } catch (error: any) {
      console.error('Error loading developers:', error);
    }
  };

  const loadAdminNewsCount = async () => {
    try {
      // Get admin posts count (DeveloperId = null) using special value -1
      const adminData: PaginatedNewsResponse = await newsApi.getNews(1, 1000, -1);
      setAdminNewsCount(adminData.totalCount || 0);
    } catch (error: any) {
      console.error('Error loading admin news count:', error);
    }
  };

  const fetchNews = async () => {
    try {
      setLoading(true);
      // Use -1 as special value for admin posts (DeveloperId = null)
      // undefined means show all (for admin) or own news (for developer)
      const developerIdParam = selectedDeveloperId === null && isAdmin 
        ? -1  // Special value for admin posts
        : selectedDeveloperId !== null 
          ? selectedDeveloperId 
          : undefined;
      
      const data: PaginatedNewsResponse = await newsApi.getNews(
        currentPage, 
        pageSize, 
        developerIdParam
      );
      setNews(data.items || []);
      setTotalCount(data.totalCount || 0);
    } catch (error: any) {
      console.error('Error fetching news:', error);
      toast.error(error?.response?.data?.message || 'Failed to load news');
    } finally {
      setLoading(false);
    }
  };

  const handleSearch = async () => {
    if (!searchTerm.trim()) {
      fetchNews();
      return;
    }
    
    try {
      setLoading(true);
      const data: PaginatedNewsResponse = await newsApi.searchNews(searchTerm, 1, pageSize);
      setNews(data.items || []);
      setTotalCount(data.totalCount || 0);
      setCurrentPage(1);
    } catch (error: any) {
      console.error('Error searching news:', error);
      toast.error(error?.response?.data?.message || 'Failed to search news');
    } finally {
      setLoading(false);
    }
  };

  const handleFolderClick = (developerId: string | null) => {
    setSelectedDeveloperId(developerId);
    setCurrentView('news');
    setCurrentPage(1);
  };

  const handleBack = () => {
    setCurrentView('folders');
    setSelectedDeveloperId(null);
    setNews([]);
  };

  const validateForm = (): boolean => {
    const errors: Record<string, string> = {};
    
    if (!formData.title.trim()) {
      errors.title = 'Title is required';
    } else if (formData.title.length > 200) {
      errors.title = 'Title must be 200 characters or less';
    }
    
    if (!formData.content.trim()) {
      errors.content = 'Content is required';
    }
    
    if (formData.category && formData.category.length > 50) {
      errors.category = 'Category must be 50 characters or less';
    }
    
    if (formData.imageUrls.trim()) {
      const urls = formData.imageUrls.split('\n').filter(url => url.trim());
      const urlPattern = /^https?:\/\/.+/;
      for (const url of urls) {
        if (!urlPattern.test(url.trim())) {
          errors.imageUrls = 'Please enter valid image URLs (one per line)';
          break;
        }
      }
    }
    
    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleCreateNews = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!validateForm()) {
      toast.error('Please fix the form errors');
      return;
    }
    
    try {
      setSubmitting(true);
      const imageUrls = formData.imageUrls
        .split('\n')
        .map(url => url.trim())
        .filter(url => url.length > 0);
      
      const payload = {
        title: formData.title.trim(),
        content: formData.content.trim(),
        category: formData.category.trim() || null,
        imageUrls: imageUrls.length > 0 ? imageUrls : null,
        isPublished: formData.isPublished,
      };
      
      await newsApi.createNews(payload);
      toast.success('News article created successfully!');
      resetForm();
      setShowCreateModal(false);
      fetchNews();
      if (currentUser?.roleId === '98237498-2374-4982-3749-823749823749') {
        await loadAdminNewsCount();
        await loadDevelopersWithNews();
      }
    } catch (error: any) {
      console.error('Failed to create news:', error);
      toast.error(error?.response?.data?.message || 'Failed to create news article');
    } finally {
      setSubmitting(false);
    }
  };

  const handleEditNews = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!selectedNews) return;
    
    if (!validateForm()) {
      toast.error('Please fix the form errors');
      return;
    }
    
    try {
      setSubmitting(true);
      const imageUrls = formData.imageUrls
        .split('\n')
        .map(url => url.trim())
        .filter(url => url.length > 0);
      
      const payload = {
        title: formData.title.trim(),
        content: formData.content.trim(),
        category: formData.category.trim() || null,
        imageUrls: imageUrls.length > 0 ? imageUrls : null,
        isPublished: formData.isPublished,
      };
      
      const id = selectedNews.newsArticleId || selectedNews.articleId || selectedNews.id;
      if (!id) {
        toast.error('Invalid news article ID');
        return;
      }
      
      await newsApi.updateNews(id, payload);
      toast.success('News article updated successfully!');
      resetForm();
      setShowEditModal(false);
      setSelectedNews(null);
      fetchNews();
    } catch (error: any) {
      console.error('Failed to update news:', error);
      toast.error(error?.response?.data?.message || 'Failed to update news article');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDeleteNews = async () => {
    if (!selectedNews) return;
    
    try {
      setSubmitting(true);
      const id = selectedNews.newsArticleId || selectedNews.articleId || selectedNews.id;
      if (!id) {
        toast.error('Invalid news article ID');
        return;
      }
      
      await newsApi.deleteNews(id);
      toast.success('News article deleted successfully!');
      setShowDeleteModal(false);
      setSelectedNews(null);
      fetchNews();
      if (currentUser?.roleId === '98237498-2374-4982-3749-823749823749') {
        await loadAdminNewsCount();
        await loadDevelopersWithNews();
      }
    } catch (error: any) {
      console.error('Failed to delete news:', error);
      toast.error(error?.response?.data?.message || 'Failed to delete news article');
    } finally {
      setSubmitting(false);
    }
  };

  const resetForm = () => {
    setFormData({
      title: '',
      content: '',
      category: '',
      imageUrls: '',
      isPublished: true,
    });
    setFormErrors({});
  };

  const openCreateModal = () => {
    resetForm();
    setShowCreateModal(true);
  };

  const openEditModal = (article: NewsArticle) => {
    setSelectedNews(article);
    setFormData({
      title: article.title || '',
      content: article.content || '',
      category: article.category || '',
      imageUrls: (article.images || []).join('\n'),
      isPublished: article.isPublished !== undefined ? article.isPublished : true,
    });
    setFormErrors({});
    setShowEditModal(true);
  };

  const openViewModal = (article: NewsArticle) => {
    setSelectedNews(article);
    setShowViewModal(true);
  };

  const openDeleteModal = (article: NewsArticle) => {
    setSelectedNews(article);
    setShowDeleteModal(true);
  };

  const getNewsId = (article: NewsArticle): number => {
    return article.newsArticleId || article.articleId || article.id || 0;
  };

  const getNewsImage = (article: NewsArticle): string | undefined => {
    if (article.images && article.images.length > 0) {
      return article.images[0];
    }
    return article.imageUrl;
  };

  const isAdmin = currentUser?.roleId === '98237498-2374-4982-3749-823749823749' || currentUser?.roleName === 'Admin';
  const isDeveloper = currentUser?.roleId === '78236478-2364-7823-0000-000000000000' || currentUser?.roleName === 'Developer';

  if (loading && news.length === 0 && currentView === 'news') {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '50vh' }}>
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );
  }

  // Render Folders View (Admin only)
  const renderFoldersView = () => {
    return (
      <div>
        <div className="mb-6">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">News Management</h1>
          <p className="text-gray-600">Select a folder to view news articles</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {/* Admin Posts Folder */}
          <div
            onClick={() => handleFolderClick(null)}
            style={{
              backgroundColor: 'white',
              borderRadius: '0.75rem',
              boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
              padding: '1.5rem',
              cursor: 'pointer',
              transition: 'all 0.2s',
              border: '2px solid transparent',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.borderColor = '#667eea';
              e.currentTarget.style.boxShadow = '0 4px 12px rgba(102, 126, 234, 0.2)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.borderColor = 'transparent';
              e.currentTarget.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
            }}
          >
            <div style={{ display: 'flex', alignItems: 'start', gap: '1rem', marginBottom: '1rem' }}>
              <div style={{
                height: '4rem',
                width: '4rem',
                borderRadius: '0.5rem',
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                boxShadow: '0 4px 6px rgba(102, 126, 234, 0.3)',
              }}>
                <Folder style={{ height: '2rem', width: '2rem', color: 'white' }} />
              </div>
              <div style={{ flex: 1 }}>
                <h3 style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#111827', marginBottom: '0.25rem' }}>
                  Admin Posts
                </h3>
                <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>System news articles</p>
              </div>
            </div>
            <div style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              paddingTop: '1rem',
              borderTop: '1px solid #e5e7eb',
            }}>
              <Newspaper style={{ height: '1rem', width: '1rem', color: '#667eea' }} />
              <span style={{ fontSize: '0.875rem', color: '#667eea', fontWeight: '500' }}>
                {adminNewsCount} articles
              </span>
            </div>
          </div>

          {/* Developer Folders */}
          {developers.map((developer) => (
            <div
              key={developer.developerId}
              onClick={() => handleFolderClick(developer.developerId)}
              style={{
                backgroundColor: 'white',
                borderRadius: '0.75rem',
                boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1)',
                padding: '1.5rem',
                cursor: 'pointer',
                transition: 'all 0.2s',
                border: '2px solid transparent',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.borderColor = '#667eea';
                e.currentTarget.style.boxShadow = '0 4px 12px rgba(102, 126, 234, 0.2)';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.borderColor = 'transparent';
                e.currentTarget.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
              }}
            >
              <div style={{ display: 'flex', alignItems: 'start', gap: '1rem', marginBottom: '1rem' }}>
                <div style={{
                  height: '4rem',
                  width: '4rem',
                  borderRadius: '0.5rem',
                  background: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  boxShadow: '0 4px 6px rgba(16, 185, 129, 0.3)',
                }}>
                  <Building style={{ height: '2rem', width: '2rem', color: 'white' }} />
                </div>
                <div style={{ flex: 1 }}>
                  <h3 style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#111827', marginBottom: '0.25rem' }}>
                    {developer.developerName}
                  </h3>
                  <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>{developer.email}</p>
                </div>
              </div>
              <div style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.5rem',
                paddingTop: '1rem',
                borderTop: '1px solid #e5e7eb',
              }}>
                <Newspaper style={{ height: '1rem', width: '1rem', color: '#10b981' }} />
                <span style={{ fontSize: '0.875rem', color: '#10b981', fontWeight: '500' }}>
                  {developer.newsCount} articles
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  };

  // Render News Grid View
  const renderNewsView = () => {
    const folderName = selectedDeveloperId === null 
      ? 'Admin Posts' 
      : developers.find(d => d.developerId === selectedDeveloperId)?.developerName || 'Developer Posts';

    return (
      <div>
        {/* Breadcrumb */}
        {isAdmin && (
          <div style={{ marginBottom: '1rem', display: 'flex', alignItems: 'center', gap: '0.5rem', fontSize: '0.875rem', color: '#6b7280' }}>
            <button 
              onClick={handleBack}
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: '0.25rem',
                color: '#667eea',
                background: 'none',
                border: 'none',
                cursor: 'pointer',
                padding: '0.25rem 0.5rem',
                borderRadius: '0.25rem',
                transition: 'all 0.2s',
              }}
              onMouseEnter={(e) => {
                e.currentTarget.style.backgroundColor = '#f3f4f6';
              }}
              onMouseLeave={(e) => {
                e.currentTarget.style.backgroundColor = 'transparent';
              }}
            >
              <ArrowLeft style={{ height: '1rem', width: '1rem' }} />
              Back to Folders
            </button>
            <span>/</span>
            <span style={{ color: '#111827', fontWeight: '500' }}>{folderName}</span>
          </div>
        )}

        {/* Header */}
        <div className="mb-6 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">
              {isAdmin ? folderName : 'My News'}
            </h1>
            <p className="text-gray-600">Manage news articles</p>
          </div>
          <button
            onClick={openCreateModal}
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: '0.5rem',
              padding: '0.75rem 1.5rem',
              background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
              color: 'white',
              border: 'none',
              borderRadius: '0.5rem',
              cursor: 'pointer',
              fontWeight: '500',
              transition: 'all 0.2s',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = 'translateY(-2px)';
              e.currentTarget.style.boxShadow = '0 4px 12px rgba(102, 126, 234, 0.4)';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = 'translateY(0)';
              e.currentTarget.style.boxShadow = 'none';
            }}
          >
            <Plus style={{ height: '1.25rem', width: '1.25rem' }} />
            Create News
          </button>
        </div>

        {/* Search Bar */}
        <div className="mb-6 flex gap-2">
          <div style={{ position: 'relative', flex: 1, maxWidth: '500px' }}>
            <Search style={{
              position: 'absolute',
              left: '0.75rem',
              top: '50%',
              transform: 'translateY(-50%)',
              height: '1rem',
              width: '1rem',
              color: '#9ca3af'
            }} />
            <input
              type="text"
              placeholder="Search news articles..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
              style={{
                width: '100%',
                padding: '0.75rem 1rem 0.75rem 2.5rem',
                border: '1px solid #d1d5db',
                borderRadius: '0.5rem',
                fontSize: '0.875rem',
                outline: 'none',
                transition: 'all 0.2s',
              }}
              onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
              onBlur={(e) => e.currentTarget.style.borderColor = '#d1d5db'}
            />
          </div>
          <button
            onClick={handleSearch}
            style={{
              padding: '0.75rem 1.5rem',
              backgroundColor: '#f3f4f6',
              color: '#374151',
              border: '1px solid #d1d5db',
              borderRadius: '0.5rem',
              cursor: 'pointer',
              fontWeight: '500',
              transition: 'all 0.2s',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.backgroundColor = '#e5e7eb';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.backgroundColor = '#f3f4f6';
            }}
          >
            Search
          </button>
          {searchTerm && (
            <button
              onClick={() => {
                setSearchTerm('');
                fetchNews();
              }}
              style={{
                padding: '0.75rem 1.5rem',
                backgroundColor: '#ef4444',
                color: 'white',
                border: 'none',
                borderRadius: '0.5rem',
                cursor: 'pointer',
                fontWeight: '500',
              }}
            >
              Clear
            </button>
          )}
        </div>

        {/* News Grid */}
        {news.length === 0 ? (
          <div className="text-center py-12 bg-white rounded-lg shadow">
            <Newspaper className="mx-auto h-12 w-12 text-gray-400 mb-4" />
            <h3 className="text-lg font-medium text-gray-900 mb-2">No news articles found</h3>
            <p className="text-gray-600">Create your first news article to get started.</p>
          </div>
        ) : (
          <>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-6">
              {news.map((article) => {
                const newsId = getNewsId(article);
                const imageUrl = getNewsImage(article);
                const publishedDate = article.publishedDate || article.createdAt;
                
                return (
                  <div key={newsId} className="bg-white rounded-lg shadow overflow-hidden hover:shadow-lg transition-shadow">
                    {imageUrl && (
                      <img 
                        src={imageUrl} 
                        alt={article.title} 
                        className="w-full h-48 object-cover"
                        onError={(e) => {
                          (e.target as HTMLImageElement).style.display = 'none';
                        }}
                      />
                    )}
                    <div className="p-6">
                      <div className="flex items-start justify-between mb-2">
                        <h3 className="text-xl font-semibold line-clamp-2 flex-1">{article.title}</h3>
                        {article.isPublished !== false ? (
                          <CheckCircle className="h-5 w-5 text-green-500 ml-2 flex-shrink-0" />
                        ) : (
                          <XCircle className="h-5 w-5 text-gray-400 ml-2 flex-shrink-0" />
                        )}
                      </div>
                      {article.category && (
                        <div className="flex items-center gap-1 mb-2">
                          <Tag className="h-3 w-3 text-gray-400" />
                          <span className="text-xs text-gray-500">{article.category}</span>
                        </div>
                      )}
                      <p className="text-gray-600 mb-4 line-clamp-3">{article.content}</p>
                      <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                        <div className="flex items-center gap-2">
                          <Calendar className="h-4 w-4" />
                          <span>{publishedDate ? new Date(publishedDate).toLocaleDateString() : 'N/A'}</span>
                        </div>
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={() => openViewModal(article)}
                          style={{
                            flex: 1,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '0.5rem',
                            padding: '0.5rem',
                            backgroundColor: '#f3f4f6',
                            color: '#374151',
                            border: '1px solid #d1d5db',
                            borderRadius: '0.5rem',
                            cursor: 'pointer',
                            fontSize: '0.875rem',
                            transition: 'all 0.2s',
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.backgroundColor = '#e5e7eb';
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.backgroundColor = '#f3f4f6';
                          }}
                        >
                          <Eye className="h-4 w-4" />
                          View
                        </button>
                        <button
                          onClick={() => openEditModal(article)}
                          style={{
                            flex: 1,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '0.5rem',
                            padding: '0.5rem',
                            backgroundColor: '#dbeafe',
                            color: '#1e40af',
                            border: '1px solid #93c5fd',
                            borderRadius: '0.5rem',
                            cursor: 'pointer',
                            fontSize: '0.875rem',
                            transition: 'all 0.2s',
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.backgroundColor = '#bfdbfe';
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.backgroundColor = '#dbeafe';
                          }}
                        >
                          <Edit className="h-4 w-4" />
                          Edit
                        </button>
                        <button
                          onClick={() => openDeleteModal(article)}
                          style={{
                            flex: 1,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            gap: '0.5rem',
                            padding: '0.5rem',
                            backgroundColor: '#fee2e2',
                            color: '#991b1b',
                            border: '1px solid #fca5a5',
                            borderRadius: '0.5rem',
                            cursor: 'pointer',
                            fontSize: '0.875rem',
                            transition: 'all 0.2s',
                          }}
                          onMouseEnter={(e) => {
                            e.currentTarget.style.backgroundColor = '#fecaca';
                          }}
                          onMouseLeave={(e) => {
                            e.currentTarget.style.backgroundColor = '#fee2e2';
                          }}
                        >
                          <Trash2 className="h-4 w-4" />
                          Delete
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Pagination */}
            {totalCount > pageSize && (
              <div className="flex items-center justify-between bg-white rounded-lg shadow p-4">
                <div className="text-sm text-gray-600">
                  Showing {(currentPage - 1) * pageSize + 1} to {Math.min(currentPage * pageSize, totalCount)} of {totalCount} articles
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))}
                    disabled={currentPage === 1}
                    style={{
                      padding: '0.5rem 1rem',
                      backgroundColor: currentPage === 1 ? '#f3f4f6' : '#667eea',
                      color: currentPage === 1 ? '#9ca3af' : 'white',
                      border: 'none',
                      borderRadius: '0.5rem',
                      cursor: currentPage === 1 ? 'not-allowed' : 'pointer',
                      fontSize: '0.875rem',
                    }}
                  >
                    Previous
                  </button>
                  <button
                    onClick={() => setCurrentPage(prev => prev + 1)}
                    disabled={currentPage * pageSize >= totalCount}
                    style={{
                      padding: '0.5rem 1rem',
                      backgroundColor: currentPage * pageSize >= totalCount ? '#f3f4f6' : '#667eea',
                      color: currentPage * pageSize >= totalCount ? '#9ca3af' : 'white',
                      border: 'none',
                      borderRadius: '0.5rem',
                      cursor: currentPage * pageSize >= totalCount ? 'not-allowed' : 'pointer',
                      fontSize: '0.875rem',
                    }}
                  >
                    Next
                  </button>
                </div>
              </div>
            )}
          </>
        )}
      </div>
    );
  };

  return (
    <div className="p-6">
      {currentView === 'folders' ? renderFoldersView() : renderNewsView()}

      {/* Create Modal - Keep existing implementation */}
      {showCreateModal && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 50,
          padding: '1rem',
        }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '0.75rem',
            width: '100%',
            maxWidth: '700px',
            maxHeight: '90vh',
            overflow: 'auto',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
          }}>
            <div style={{
              padding: '1.5rem',
              borderBottom: '1px solid #e5e7eb',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}>
              <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', color: '#111827' }}>Create News Article</h2>
              <button
                onClick={() => {
                  setShowCreateModal(false);
                  resetForm();
                }}
                style={{
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  padding: '0.5rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <X className="h-5 w-5 text-gray-400" />
              </button>
            </div>
            <form onSubmit={handleCreateNews} style={{ padding: '1.5rem' }}>
              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{
                  display: 'block',
                  fontSize: '0.875rem',
                  fontWeight: '600',
                  color: '#374151',
                  marginBottom: '0.5rem',
                }}>
                  Title <span style={{ color: '#ef4444' }}>*</span>
                </label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => {
                    setFormData({ ...formData, title: e.target.value });
                    if (formErrors.title) setFormErrors({ ...formErrors, title: '' });
                  }}
                  maxLength={200}
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    border: `1px solid ${formErrors.title ? '#ef4444' : '#d1d5db'}`,
                    borderRadius: '0.5rem',
                    fontSize: '0.875rem',
                    outline: 'none',
                    transition: 'all 0.2s',
                  }}
                  onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                  onBlur={(e) => e.currentTarget.style.borderColor = formErrors.title ? '#ef4444' : '#d1d5db'}
                />
                {formErrors.title && (
                  <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{formErrors.title}</p>
                )}
                <p style={{ color: '#6b7280', fontSize: '0.75rem', marginTop: '0.25rem' }}>
                  {formData.title.length}/200 characters
                </p>
              </div>

              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{
                  display: 'block',
                  fontSize: '0.875rem',
                  fontWeight: '600',
                  color: '#374151',
                  marginBottom: '0.5rem',
                }}>
                  Content <span style={{ color: '#ef4444' }}>*</span>
                </label>
                <textarea
                  value={formData.content}
                  onChange={(e) => {
                    setFormData({ ...formData, content: e.target.value });
                    if (formErrors.content) setFormErrors({ ...formErrors, content: '' });
                  }}
                  rows={8}
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    border: `1px solid ${formErrors.content ? '#ef4444' : '#d1d5db'}`,
                    borderRadius: '0.5rem',
                    fontSize: '0.875rem',
                    outline: 'none',
                    transition: 'all 0.2s',
                    resize: 'vertical',
                    fontFamily: 'inherit',
                  }}
                  onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                  onBlur={(e) => e.currentTarget.style.borderColor = formErrors.content ? '#ef4444' : '#d1d5db'}
                />
                {formErrors.content && (
                  <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{formErrors.content}</p>
                )}
              </div>

              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{
                  display: 'block',
                  fontSize: '0.875rem',
                  fontWeight: '600',
                  color: '#374151',
                  marginBottom: '0.5rem',
                }}>
                  Category
                </label>
                <input
                  type="text"
                  value={formData.category}
                  onChange={(e) => {
                    setFormData({ ...formData, category: e.target.value });
                    if (formErrors.category) setFormErrors({ ...formErrors, category: '' });
                  }}
                  maxLength={50}
                  placeholder="e.g., Market Updates, Projects, Tips"
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    border: `1px solid ${formErrors.category ? '#ef4444' : '#d1d5db'}`,
                    borderRadius: '0.5rem',
                    fontSize: '0.875rem',
                    outline: 'none',
                    transition: 'all 0.2s',
                  }}
                  onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                  onBlur={(e) => e.currentTarget.style.borderColor = formErrors.category ? '#ef4444' : '#d1d5db'}
                />
                {formErrors.category && (
                  <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{formErrors.category}</p>
                )}
                <p style={{ color: '#6b7280', fontSize: '0.75rem', marginTop: '0.25rem' }}>
                  {formData.category.length}/50 characters (optional)
                </p>
              </div>

              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{
                  display: 'block',
                  fontSize: '0.875rem',
                  fontWeight: '600',
                  color: '#374151',
                  marginBottom: '0.5rem',
                }}>
                  Image URLs
                </label>
                <textarea
                  value={formData.imageUrls}
                  onChange={(e) => {
                    setFormData({ ...formData, imageUrls: e.target.value });
                    if (formErrors.imageUrls) setFormErrors({ ...formErrors, imageUrls: '' });
                  }}
                  rows={3}
                  placeholder="Enter image URLs, one per line"
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    border: `1px solid ${formErrors.imageUrls ? '#ef4444' : '#d1d5db'}`,
                    borderRadius: '0.5rem',
                    fontSize: '0.875rem',
                    outline: 'none',
                    transition: 'all 0.2s',
                    resize: 'vertical',
                    fontFamily: 'inherit',
                  }}
                  onFocus={(e) => e.currentTarget.style.borderColor = '#667eea'}
                  onBlur={(e) => e.currentTarget.style.borderColor = formErrors.imageUrls ? '#ef4444' : '#d1d5db'}
                />
                {formErrors.imageUrls && (
                  <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{formErrors.imageUrls}</p>
                )}
                <p style={{ color: '#6b7280', fontSize: '0.75rem', marginTop: '0.25rem' }}>
                  Enter one image URL per line (optional)
                </p>
              </div>

              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  cursor: 'pointer',
                }}>
                  <input
                    type="checkbox"
                    checked={formData.isPublished}
                    onChange={(e) => setFormData({ ...formData, isPublished: e.target.checked })}
                    style={{
                      width: '1.25rem',
                      height: '1.25rem',
                      cursor: 'pointer',
                    }}
                  />
                  <span style={{ fontSize: '0.875rem', fontWeight: '600', color: '#374151' }}>
                    Publish immediately
                  </span>
                </label>
              </div>

              <div style={{
                display: 'flex',
                gap: '1rem',
                justifyContent: 'flex-end',
                paddingTop: '1rem',
                borderTop: '1px solid #e5e7eb',
              }}>
                <button
                  type="button"
                  onClick={() => {
                    setShowCreateModal(false);
                    resetForm();
                  }}
                  style={{
                    padding: '0.75rem 1.5rem',
                    backgroundColor: '#f3f4f6',
                    color: '#374151',
                    border: '1px solid #d1d5db',
                    borderRadius: '0.5rem',
                    cursor: 'pointer',
                    fontWeight: '500',
                    transition: 'all 0.2s',
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  style={{
                    padding: '0.75rem 1.5rem',
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    color: 'white',
                    border: 'none',
                    borderRadius: '0.5rem',
                    cursor: submitting ? 'not-allowed' : 'pointer',
                    fontWeight: '500',
                    opacity: submitting ? 0.6 : 1,
                    transition: 'all 0.2s',
                  }}
                >
                  {submitting ? 'Creating...' : 'Create News'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Modal - Similar structure to Create, but with pre-filled data */}
      {showEditModal && selectedNews && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 50,
          padding: '1rem',
        }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '0.75rem',
            width: '100%',
            maxWidth: '700px',
            maxHeight: '90vh',
            overflow: 'auto',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
          }}>
            <div style={{
              padding: '1.5rem',
              borderBottom: '1px solid #e5e7eb',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}>
              <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', color: '#111827' }}>Edit News Article</h2>
              <button
                onClick={() => {
                  setShowEditModal(false);
                  setSelectedNews(null);
                  resetForm();
                }}
                style={{
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  padding: '0.5rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <X className="h-5 w-5 text-gray-400" />
              </button>
            </div>
            <form onSubmit={handleEditNews} style={{ padding: '1.5rem' }}>
              {/* Same form fields as Create Modal */}
              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{
                  display: 'block',
                  fontSize: '0.875rem',
                  fontWeight: '600',
                  color: '#374151',
                  marginBottom: '0.5rem',
                }}>
                  Title <span style={{ color: '#ef4444' }}>*</span>
                </label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => {
                    setFormData({ ...formData, title: e.target.value });
                    if (formErrors.title) setFormErrors({ ...formErrors, title: '' });
                  }}
                  maxLength={200}
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    border: `1px solid ${formErrors.title ? '#ef4444' : '#d1d5db'}`,
                    borderRadius: '0.5rem',
                    fontSize: '0.875rem',
                    outline: 'none',
                    transition: 'all 0.2s',
                  }}
                />
                {formErrors.title && (
                  <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{formErrors.title}</p>
                )}
              </div>

              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{
                  display: 'block',
                  fontSize: '0.875rem',
                  fontWeight: '600',
                  color: '#374151',
                  marginBottom: '0.5rem',
                }}>
                  Content <span style={{ color: '#ef4444' }}>*</span>
                </label>
                <textarea
                  value={formData.content}
                  onChange={(e) => {
                    setFormData({ ...formData, content: e.target.value });
                    if (formErrors.content) setFormErrors({ ...formErrors, content: '' });
                  }}
                  rows={8}
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    border: `1px solid ${formErrors.content ? '#ef4444' : '#d1d5db'}`,
                    borderRadius: '0.5rem',
                    fontSize: '0.875rem',
                    outline: 'none',
                    transition: 'all 0.2s',
                    resize: 'vertical',
                    fontFamily: 'inherit',
                  }}
                />
                {formErrors.content && (
                  <p style={{ color: '#ef4444', fontSize: '0.75rem', marginTop: '0.25rem' }}>{formErrors.content}</p>
                )}
              </div>

              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{
                  display: 'block',
                  fontSize: '0.875rem',
                  fontWeight: '600',
                  color: '#374151',
                  marginBottom: '0.5rem',
                }}>
                  Category
                </label>
                <input
                  type="text"
                  value={formData.category}
                  onChange={(e) => {
                    setFormData({ ...formData, category: e.target.value });
                    if (formErrors.category) setFormErrors({ ...formErrors, category: '' });
                  }}
                  maxLength={50}
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    border: `1px solid ${formErrors.category ? '#ef4444' : '#d1d5db'}`,
                    borderRadius: '0.5rem',
                    fontSize: '0.875rem',
                    outline: 'none',
                    transition: 'all 0.2s',
                  }}
                />
              </div>

              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{
                  display: 'block',
                  fontSize: '0.875rem',
                  fontWeight: '600',
                  color: '#374151',
                  marginBottom: '0.5rem',
                }}>
                  Image URLs
                </label>
                <textarea
                  value={formData.imageUrls}
                  onChange={(e) => {
                    setFormData({ ...formData, imageUrls: e.target.value });
                    if (formErrors.imageUrls) setFormErrors({ ...formErrors, imageUrls: '' });
                  }}
                  rows={3}
                  style={{
                    width: '100%',
                    padding: '0.75rem 1rem',
                    border: `1px solid ${formErrors.imageUrls ? '#ef4444' : '#d1d5db'}`,
                    borderRadius: '0.5rem',
                    fontSize: '0.875rem',
                    outline: 'none',
                    transition: 'all 0.2s',
                    resize: 'vertical',
                    fontFamily: 'inherit',
                  }}
                />
              </div>

              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: '0.5rem',
                  cursor: 'pointer',
                }}>
                  <input
                    type="checkbox"
                    checked={formData.isPublished}
                    onChange={(e) => setFormData({ ...formData, isPublished: e.target.checked })}
                    style={{
                      width: '1.25rem',
                      height: '1.25rem',
                      cursor: 'pointer',
                    }}
                  />
                  <span style={{ fontSize: '0.875rem', fontWeight: '600', color: '#374151' }}>
                    Published
                  </span>
                </label>
              </div>

              <div style={{
                display: 'flex',
                gap: '1rem',
                justifyContent: 'flex-end',
                paddingTop: '1rem',
                borderTop: '1px solid #e5e7eb',
              }}>
                <button
                  type="button"
                  onClick={() => {
                    setShowEditModal(false);
                    setSelectedNews(null);
                    resetForm();
                  }}
                  style={{
                    padding: '0.75rem 1.5rem',
                    backgroundColor: '#f3f4f6',
                    color: '#374151',
                    border: '1px solid #d1d5db',
                    borderRadius: '0.5rem',
                    cursor: 'pointer',
                    fontWeight: '500',
                  }}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  style={{
                    padding: '0.75rem 1.5rem',
                    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    color: 'white',
                    border: 'none',
                    borderRadius: '0.5rem',
                    cursor: submitting ? 'not-allowed' : 'pointer',
                    fontWeight: '500',
                    opacity: submitting ? 0.6 : 1,
                  }}
                >
                  {submitting ? 'Updating...' : 'Update News'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* View Modal - Keep existing implementation */}
      {showViewModal && selectedNews && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 50,
          padding: '1rem',
        }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '0.75rem',
            width: '100%',
            maxWidth: '800px',
            maxHeight: '90vh',
            overflow: 'auto',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
          }}>
            <div style={{
              padding: '1.5rem',
              borderBottom: '1px solid #e5e7eb',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
            }}>
              <h2 style={{ fontSize: '1.5rem', fontWeight: 'bold', color: '#111827' }}>News Article Details</h2>
              <button
                onClick={() => {
                  setShowViewModal(false);
                  setSelectedNews(null);
                }}
                style={{
                  background: 'none',
                  border: 'none',
                  cursor: 'pointer',
                  padding: '0.5rem',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                <X className="h-5 w-5 text-gray-400" />
              </button>
            </div>
            <div style={{ padding: '1.5rem' }}>
              {getNewsImage(selectedNews) && (
                <img
                  src={getNewsImage(selectedNews)}
                  alt={selectedNews.title}
                  style={{
                    width: '100%',
                    height: '300px',
                    objectFit: 'cover',
                    borderRadius: '0.5rem',
                    marginBottom: '1.5rem',
                  }}
                  onError={(e) => {
                    (e.target as HTMLImageElement).style.display = 'none';
                  }}
                />
              )}
              <div style={{ marginBottom: '1rem' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', marginBottom: '0.5rem' }}>
                  <h3 style={{ fontSize: '1.5rem', fontWeight: 'bold', color: '#111827', flex: 1 }}>
                    {selectedNews.title}
                  </h3>
                  {selectedNews.isPublished !== false ? (
                    <span style={{
                      padding: '0.25rem 0.75rem',
                      backgroundColor: '#d1fae5',
                      color: '#065f46',
                      borderRadius: '9999px',
                      fontSize: '0.75rem',
                      fontWeight: '600',
                    }}>
                      Published
                    </span>
                  ) : (
                    <span style={{
                      padding: '0.25rem 0.75rem',
                      backgroundColor: '#f3f4f6',
                      color: '#6b7280',
                      borderRadius: '9999px',
                      fontSize: '0.75rem',
                      fontWeight: '600',
                    }}>
                      Draft
                    </span>
                  )}
                </div>
                {selectedNews.category && (
                  <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                    <Tag className="h-4 w-4 text-gray-400" />
                    <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>{selectedNews.category}</span>
                  </div>
                )}
                <div style={{ display: 'flex', alignItems: 'center', gap: '0.5rem', marginBottom: '1rem' }}>
                  <Calendar className="h-4 w-4 text-gray-400" />
                  <span style={{ fontSize: '0.875rem', color: '#6b7280' }}>
                    Published: {selectedNews.publishedDate ? new Date(selectedNews.publishedDate).toLocaleString() : 'N/A'}
                  </span>
                </div>
              </div>
              <div style={{
                padding: '1rem',
                backgroundColor: '#f9fafb',
                borderRadius: '0.5rem',
                marginBottom: '1.5rem',
              }}>
                <p style={{ fontSize: '0.875rem', color: '#374151', lineHeight: '1.75', whiteSpace: 'pre-wrap' }}>
                  {selectedNews.content}
                </p>
              </div>
              {selectedNews.images && selectedNews.images.length > 1 && (
                <div style={{ marginBottom: '1.5rem' }}>
                  <h4 style={{ fontSize: '1rem', fontWeight: '600', color: '#374151', marginBottom: '0.75rem' }}>
                    Additional Images
                  </h4>
                  <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(150px, 1fr))', gap: '0.75rem' }}>
                    {selectedNews.images.slice(1).map((imageUrl, index) => (
                      <img
                        key={index}
                        src={imageUrl}
                        alt={`${selectedNews.title} - Image ${index + 2}`}
                        style={{
                          width: '100%',
                          height: '150px',
                          objectFit: 'cover',
                          borderRadius: '0.5rem',
                        }}
                        onError={(e) => {
                          (e.target as HTMLImageElement).style.display = 'none';
                        }}
                      />
                    ))}
                  </div>
                </div>
              )}
              <div style={{
                display: 'flex',
                gap: '1rem',
                justifyContent: 'flex-end',
                paddingTop: '1rem',
                borderTop: '1px solid #e5e7eb',
              }}>
                <button
                  onClick={() => {
                    setShowViewModal(false);
                    openEditModal(selectedNews);
                  }}
                  style={{
                    padding: '0.75rem 1.5rem',
                    backgroundColor: '#dbeafe',
                    color: '#1e40af',
                    border: '1px solid #93c5fd',
                    borderRadius: '0.5rem',
                    cursor: 'pointer',
                    fontWeight: '500',
                    display: 'flex',
                    alignItems: 'center',
                    gap: '0.5rem',
                  }}
                >
                  <Edit className="h-4 w-4" />
                  Edit
                </button>
                <button
                  onClick={() => {
                    setShowViewModal(false);
                    setSelectedNews(null);
                  }}
                  style={{
                    padding: '0.75rem 1.5rem',
                    backgroundColor: '#f3f4f6',
                    color: '#374151',
                    border: '1px solid #d1d5db',
                    borderRadius: '0.5rem',
                    cursor: 'pointer',
                    fontWeight: '500',
                  }}
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {showDeleteModal && selectedNews && (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(0, 0, 0, 0.5)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          zIndex: 50,
          padding: '1rem',
        }}>
          <div style={{
            backgroundColor: 'white',
            borderRadius: '0.75rem',
            width: '100%',
            maxWidth: '500px',
            boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
          }}>
            <div style={{
              padding: '1.5rem',
              borderBottom: '1px solid #e5e7eb',
            }}>
              <h2 style={{ fontSize: '1.25rem', fontWeight: 'bold', color: '#111827', marginBottom: '0.5rem' }}>
                Delete News Article
              </h2>
              <p style={{ fontSize: '0.875rem', color: '#6b7280' }}>
                Are you sure you want to delete this news article? This action cannot be undone.
              </p>
            </div>
            <div style={{ padding: '1.5rem', backgroundColor: '#f9fafb' }}>
              <div style={{
                padding: '1rem',
                backgroundColor: 'white',
                borderRadius: '0.5rem',
                border: '1px solid #e5e7eb',
                marginBottom: '1rem',
              }}>
                <h3 style={{ fontSize: '1rem', fontWeight: '600', color: '#111827', marginBottom: '0.5rem' }}>
                  {selectedNews.title}
                </h3>
                <p style={{ fontSize: '0.875rem', color: '#6b7280', lineHeight: '1.5' }}>
                  {selectedNews.content.substring(0, 100)}...
                </p>
              </div>
              <div style={{
                display: 'flex',
                gap: '1rem',
                justifyContent: 'flex-end',
              }}>
                <button
                  onClick={() => {
                    setShowDeleteModal(false);
                    setSelectedNews(null);
                  }}
                  disabled={submitting}
                  style={{
                    padding: '0.75rem 1.5rem',
                    backgroundColor: '#f3f4f6',
                    color: '#374151',
                    border: '1px solid #d1d5db',
                    borderRadius: '0.5rem',
                    cursor: submitting ? 'not-allowed' : 'pointer',
                    fontWeight: '500',
                    opacity: submitting ? 0.6 : 1,
                  }}
                >
                  Cancel
                </button>
                <button
                  onClick={handleDeleteNews}
                  disabled={submitting}
                  style={{
                    padding: '0.75rem 1.5rem',
                    backgroundColor: '#ef4444',
                    color: 'white',
                    border: 'none',
                    borderRadius: '0.5rem',
                    cursor: submitting ? 'not-allowed' : 'pointer',
                    fontWeight: '500',
                    opacity: submitting ? 0.6 : 1,
                  }}
                >
                  {submitting ? 'Deleting...' : 'Delete'}
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default NewsPage;
