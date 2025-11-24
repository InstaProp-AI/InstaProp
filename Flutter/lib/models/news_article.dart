class NewsArticle {
  final String newsArticleId;
  final String title;
  final String content;
  final String? author;
  final String? category;
  final DateTime publishedDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublished;
  final List<String> images;

  NewsArticle({
    required this.newsArticleId,
    required this.title,
    required this.content,
    this.author,
    this.category,
    required this.publishedDate,
    required this.createdAt,
    this.updatedAt,
    required this.isPublished,
    required this.images,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    // Helper to parse ID fields (handle both string GUID and int legacy formats)
    String parseId(dynamic id, {String defaultValue = ''}) {
      if (id == null) return defaultValue;
      if (id is String) return id;
      if (id is int) return id.toString(); // Legacy format
      return id.toString();
    }

    return NewsArticle(
      newsArticleId: parseId(json['newsArticleId'] ?? json['NewsArticleId']),
      title: json['title'] ?? json['Title'] ?? '',
      content: json['content'] ?? json['Content'] ?? '',
      author: json['author'] ?? json['Author'],
      category: json['category'] ?? json['Category'],
      publishedDate: DateTime.parse(
        json['publishedDate'] ??
            json['PublishedDate'] ??
            DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['createdAt'] ??
            json['CreatedAt'] ??
            DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null || json['UpdatedAt'] != null
          ? DateTime.parse(json['updatedAt'] ?? json['UpdatedAt'])
          : null,
      isPublished: json['isPublished'] ?? json['IsPublished'] ?? true,
      images:
          (json['images'] as List<dynamic>?)
              ?.map((image) => image.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newsArticleId': newsArticleId,
      'title': title,
      'content': content,
      'author': author,
      'category': category,
      'publishedDate': publishedDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isPublished': isPublished,
      'images': images,
    };
  }

  // Helper method to get the first image or a placeholder
  String get firstImageUrl {
    if (images.isNotEmpty) {
      return images.first;
    }
    return 'https://via.placeholder.com/400x300?text=No+Image';
  }

  // Helper method to get formatted date
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedDate);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${publishedDate.day}/${publishedDate.month}/${publishedDate.year}';
    }
  }

  // Helper method to get category display name
  String get categoryDisplayName {
    if (category == null || category!.isEmpty) {
      return 'General';
    }
    return category!;
  }
}

class PaginatedNewsResponse {
  final List<NewsArticle> items;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final bool hasMore;

  PaginatedNewsResponse({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.hasMore,
  });

  factory PaginatedNewsResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedNewsResponse(
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => NewsArticle.fromJson(item))
              .toList() ??
          [],
      totalCount: json['totalCount'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      hasMore: json['hasMore'] ?? false,
    );
  }
}
