class NewsArticle {
  final int newsArticleId;
  final String title;
  final String content;
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
    this.category,
    required this.publishedDate,
    required this.createdAt,
    this.updatedAt,
    required this.isPublished,
    required this.images,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      newsArticleId: json['newsArticleId'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      category: json['category'],
      publishedDate: DateTime.parse(
        json['publishedDate'] ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isPublished: json['isPublished'] ?? true,
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
