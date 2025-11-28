import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news_article.dart';
import '../services/api_client.dart';
import '../services/news_service.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/modern_search_bar.dart';
import 'news_detail_page.dart';

class AllNewsPage extends StatefulWidget {
  const AllNewsPage({super.key});

  @override
  State<AllNewsPage> createState() => _AllNewsPageState();
}

class _AllNewsPageState extends State<AllNewsPage> {
  late NewsService _newsService;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<NewsArticle> _news = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _selectedCategory;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize NewsService with token
    _initializeNewsService();
    _loadNews();
    _scrollController.addListener(_onScroll);
  }

  void _initializeNewsService() {
    // News is now anonymous, but use token if available
    final appState = Provider.of<AppState>(context, listen: false);
    _newsService = NewsService(ApiClient.baseUrl, token: appState.token);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadMoreNews();
    }
  }

  Future<void> _loadNews({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _currentPage = 1;
        _news.clear();
        _hasMore = true;
      }
    });

    try {
      // News is now anonymous, but use token if available for better experience
      final appState = Provider.of<AppState>(context, listen: false);
      _newsService = NewsService(ApiClient.baseUrl, token: appState.token);

      // Check if any filters are applied
      final hasFilters = _searchQuery.isNotEmpty ||
          _selectedCategory != null ||
          _dateFrom != null ||
          _dateTo != null;

      final PaginatedNewsResponse response;

      // Use getAllNews when no filters are applied, otherwise use searchNews
      if (!hasFilters) {
        response = await _newsService.getAllNews(
          page: _currentPage,
          pageSize: 10,
        );
      } else {
        response = await _newsService.searchNews(
          query: _searchQuery.isEmpty ? null : _searchQuery,
          category: _selectedCategory,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          page: _currentPage,
          pageSize: 10,
        );
      }

      // Sort by date (newest first)
      final sortedItems = List<NewsArticle>.from(response.items);
      sortedItems.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));

      setState(() {
        if (refresh) {
          _news = sortedItems;
        } else {
          _news.addAll(sortedItems);
          // Re-sort all news after adding new items
          _news.sort((a, b) => b.publishedDate.compareTo(a.publishedDate));
        }
        _hasMore = response.hasMore;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        final errorMessage = e.toString();
        print('❌ Error loading news: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load news: $errorMessage')),
        );
      }
    }
  }

  Future<void> _loadMoreNews() async {
    await _loadNews();
  }

  Future<void> _refreshNews() async {
    await _loadNews(refresh: true);
  }

  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
    _refreshNews();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
      _dateFrom = null;
      _dateTo = null;
      _searchController.clear();
    });
    _refreshNews();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter News',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'SF Pro Display',
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Text',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterOption('All', null),
                _buildFilterOption('Real Estate', 'Real Estate'),
                _buildFilterOption('Market Updates', 'Market Updates'),
                _buildFilterOption('Technology', 'Technology'),
                _buildFilterOption('Finance', 'Finance'),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearFilters,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Clear',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _refreshNews();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Apply',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'SF Pro Text',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'SF Pro Text',
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? AppColors.surface : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? value : null;
        });
      },
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'News',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: 'SF Pro Display',
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: ModernSearchBar(
                  controller: _searchController,
                  hintText: 'Search news...',
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              // Filter chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null, _selectedCategory == null),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Real Estate',
                        'Real Estate',
                        _selectedCategory == 'Real Estate',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Market',
                        'Market Updates',
                        _selectedCategory == 'Market Updates',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Technology',
                        'Technology',
                        _selectedCategory == 'Technology',
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Finance',
                        'Finance',
                        _selectedCategory == 'Finance',
                      ),
                      if (_selectedCategory != null ||
                          _dateFrom != null ||
                          _dateTo != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            label: const Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'SF Pro Text',
                              ),
                            ),
                            onSelected: (_) => _clearFilters(),
                            backgroundColor: AppColors.error.withOpacity(0.1),
                            selectedColor: AppColors.error.withOpacity(0.2),
                            labelStyle: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Text',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNews,
        color: AppColors.primary,
        child: _news.isEmpty && !_isLoading
            ? _buildEmptyState()
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _news.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _news.length) {
                    return _buildLoadingIndicator();
                  }
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _news.length - 1 ? 0 : 12,
                    ),
                    child: _buildNewsCard(_news[index]),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, bool isSelected) {
    return FilterChip(
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontFamily: 'SF Pro Text'),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? value : null;
        });
        _refreshNews();
      },
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary.withOpacity(0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        fontFamily: 'SF Pro Text',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1 : 0,
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle news) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => NewsDetailPage(news: news)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowCard,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                height: 200,
                width: double.infinity,
                color: AppColors.background,
                child: news.images.isNotEmpty
                    ? Image.network(
                        news.firstImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.article_outlined,
                              size: 48,
                              color: AppColors.textTertiary,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(
                          Icons.article_outlined,
                          size: 48,
                          color: AppColors.textTertiary,
                        ),
                      ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and date
                  Row(
                    children: [
                      if (news.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            news.categoryDisplayName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'SF Pro Text',
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      if (news.category != null) const SizedBox(width: 8),
                      Text(
                        news.formattedDate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'SF Pro Text',
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'SF Pro Display',
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Content preview
                  Text(
                    news.content,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'SF Pro Text',
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              'No news found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                fontFamily: 'SF Pro Display',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or filters',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'SF Pro Text',
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _clearFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'SF Pro Text',
                ),
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
