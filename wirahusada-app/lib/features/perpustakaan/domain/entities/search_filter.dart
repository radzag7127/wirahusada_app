import 'package:equatable/equatable.dart';

/// Domain entity representing advanced search filters
class SearchFilter extends Equatable {
  /// Search query text
  final String? query;
  
  /// Filter by category (buku, jurnal, skripsi, etc.)
  final String? category;
  
  /// Filter by author/penulis
  final String? author;
  
  /// Filter by publication year
  final int? year;
  
  /// Filter by year range
  final int? yearFrom;
  final int? yearTo;
  
  /// Show only available items
  final bool? availableOnly;
  
  /// Filter by publisher
  final String? publisher;
  
  /// Filter by topic
  final String? topic;
  
  /// Filter by location
  final String? location;
  
  /// Sort by field
  final String? sortBy;
  
  /// Sort order (asc/desc)
  final String? sortOrder;
  
  /// Pagination
  final int page;
  final int limit;

  const SearchFilter({
    this.query,
    this.category,
    this.author,
    this.year,
    this.yearFrom,
    this.yearTo,
    this.availableOnly,
    this.publisher,
    this.topic,
    this.location,
    this.sortBy,
    this.sortOrder,
    this.page = 1,
    this.limit = 20,
  });

  /// Check if any filters are applied
  bool get hasFilters => 
      query?.isNotEmpty == true ||
      category != null ||
      author != null ||
      year != null ||
      yearFrom != null ||
      yearTo != null ||
      availableOnly != null ||
      publisher != null ||
      topic != null ||
      location != null;

  /// Check if this is a basic search (only query)
  bool get isBasicSearch => 
      query?.isNotEmpty == true && !hasAdvancedFilters;

  /// Check if advanced filters are applied
  bool get hasAdvancedFilters =>
      category != null ||
      author != null ||
      year != null ||
      yearFrom != null ||
      yearTo != null ||
      availableOnly != null ||
      publisher != null ||
      topic != null ||
      location != null;

  /// Get active filter count
  int get activeFilterCount {
    int count = 0;
    if (query?.isNotEmpty == true) count++;
    if (category != null) count++;
    if (author != null) count++;
    if (year != null) count++;
    if (yearFrom != null || yearTo != null) count++;
    if (availableOnly != null) count++;
    if (publisher != null) count++;
    if (topic != null) count++;
    if (location != null) count++;
    return count;
  }

  /// Get human-readable description of active filters
  List<String> get activeFiltersDescription {
    final filters = <String>[];
    
    if (query?.isNotEmpty == true) {
      filters.add('Search: "$query"');
    }
    if (category != null) {
      filters.add('Category: $category');
    }
    if (author != null) {
      filters.add('Author: $author');
    }
    if (year != null) {
      filters.add('Year: $year');
    }
    if (yearFrom != null && yearTo != null) {
      filters.add('Year range: $yearFrom - $yearTo');
    } else if (yearFrom != null) {
      filters.add('Year from: $yearFrom');
    } else if (yearTo != null) {
      filters.add('Year to: $yearTo');
    }
    if (availableOnly == true) {
      filters.add('Available only');
    }
    if (publisher != null) {
      filters.add('Publisher: $publisher');
    }
    if (topic != null) {
      filters.add('Topic: $topic');
    }
    if (location != null) {
      filters.add('Location: $location');
    }
    
    return filters;
  }

  /// Create a copy with updated fields
  SearchFilter copyWith({
    String? query,
    String? category,
    String? author,
    int? year,
    int? yearFrom,
    int? yearTo,
    bool? availableOnly,
    String? publisher,
    String? topic,
    String? location,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) {
    return SearchFilter(
      query: query ?? this.query,
      category: category ?? this.category,
      author: author ?? this.author,
      year: year ?? this.year,
      yearFrom: yearFrom ?? this.yearFrom,
      yearTo: yearTo ?? this.yearTo,
      availableOnly: availableOnly ?? this.availableOnly,
      publisher: publisher ?? this.publisher,
      topic: topic ?? this.topic,
      location: location ?? this.location,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      page: page ?? this.page,
      limit: limit ?? this.limit,
    );
  }

  /// Clear all filters
  SearchFilter clearFilters() {
    return const SearchFilter();
  }

  /// Clear only search query
  SearchFilter clearQuery() {
    return copyWith(query: '');
  }

  /// Convert to query parameters map
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    
    if (query?.isNotEmpty == true) params['q'] = query!;
    if (category != null) params['category'] = category!;
    if (author != null) params['author'] = author!;
    if (year != null) params['year'] = year!.toString();
    if (yearFrom != null) params['yearFrom'] = yearFrom!.toString();
    if (yearTo != null) params['yearTo'] = yearTo!.toString();
    if (availableOnly != null) params['available'] = availableOnly!.toString();
    if (publisher != null) params['publisher'] = publisher!;
    if (topic != null) params['topic'] = topic!;
    if (location != null) params['location'] = location!;
    if (sortBy != null) params['sortBy'] = sortBy!;
    if (sortOrder != null) params['sortOrder'] = sortOrder!;
    params['page'] = page.toString();
    params['limit'] = limit.toString();
    
    return params;
  }

  @override
  List<Object?> get props => [
        query,
        category,
        author,
        year,
        yearFrom,
        yearTo,
        availableOnly,
        publisher,
        topic,
        location,
        sortBy,
        sortOrder,
        page,
        limit,
      ];

  @override
  String toString() => 'SearchFilter('
      'query: $query, '
      'filters: ${activeFilterCount}, '
      'page: $page/$limit'
      ')';
}