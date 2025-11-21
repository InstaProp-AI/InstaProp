import React, { useState, useEffect } from 'react';
import { newsApi } from '../services/api';
import { useToast } from '../contexts/ToastContext';
import { Newspaper, Calendar, Eye } from 'lucide-react';

const NewsPage: React.FC = () => {
  const toast = useToast();
  const [news, setNews] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize] = useState(12);

  useEffect(() => {
    fetchNews();
  }, [currentPage]);

  const fetchNews = async () => {
    try {
      setLoading(true);
      const data = await newsApi.getNews(currentPage, pageSize);
      setNews(data.items || data.articles || data || []);
    } catch (error: any) {
      console.error('Error fetching news:', error);
      toast.error(error?.response?.data?.message || 'Failed to load news');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: '50vh' }}>
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">News</h1>
        <p className="text-gray-600">Latest property and real estate news</p>
      </div>

      {news.length === 0 ? (
        <div className="text-center py-12 bg-white rounded-lg shadow">
          <Newspaper className="mx-auto h-12 w-12 text-gray-400 mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">No news articles found</h3>
          <p className="text-gray-600">News articles will appear here once they are published.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {news.map((article) => (
            <div key={article.articleId || article.id} className="bg-white rounded-lg shadow overflow-hidden hover:shadow-lg transition-shadow">
              {article.imageUrl && (
                <img src={article.imageUrl} alt={article.title} className="w-full h-48 object-cover" />
              )}
              <div className="p-6">
                <h3 className="text-xl font-semibold mb-2 line-clamp-2">{article.title}</h3>
                <p className="text-gray-600 mb-4 line-clamp-3">{article.summary || article.content}</p>
                <div className="flex items-center justify-between text-sm text-gray-500">
                  <div className="flex items-center gap-2">
                    <Calendar className="h-4 w-4" />
                    <span>{new Date(article.publishedAt || article.createdAt).toLocaleDateString()}</span>
                  </div>
                  {article.views !== undefined && (
                    <div className="flex items-center gap-2">
                      <Eye className="h-4 w-4" />
                      <span>{article.views}</span>
                    </div>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default NewsPage;

