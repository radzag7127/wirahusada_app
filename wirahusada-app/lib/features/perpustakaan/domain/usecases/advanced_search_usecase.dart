import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/search_filter.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for advanced search with comprehensive filtering
class AdvancedSearchUseCase implements UseCase<SearchResult, SearchFilter> {
  final LibraryRepository repository;

  const AdvancedSearchUseCase(this.repository);

  @override
  Future<Either<Failure, SearchResult>> call(SearchFilter filter) async {
    final startTime = DateTime.now();
    
    final result = await repository.searchCollectionsAdvanced(filter);
    
    return result.fold(
      (failure) => Left(failure),
      (collections) {
        final endTime = DateTime.now();
        final searchTime = endTime.difference(startTime).inMilliseconds;
        
        final searchResult = SearchResult(
          collections: collections,
          totalResults: collections.length,
          searchTime: searchTime,
          filter: filter,
          suggestions: _generateSearchSuggestions(filter, collections),
        );
        
        return Right(searchResult);
      },
    );
  }

  List<String> _generateSearchSuggestions(SearchFilter filter, List<Collection> results) {
    final suggestions = <String>[];
    
    if (results.isEmpty && filter.query?.isNotEmpty == true) {
      // Generate spelling suggestions or related terms
      suggestions.addAll(_getSpellingSuggestions(filter.query!));
      suggestions.addAll(_getRelatedTerms(filter.query!));
    }
    
    if (results.isNotEmpty) {
      // Generate category suggestions based on results
      final categories = results.map((c) => c.kategori).toSet().toList();
      for (final category in categories.take(3)) {
        if (filter.category != category) {
          suggestions.add('in $category');
        }
      }
      
      // Generate author suggestions
      final authors = results.map((c) => c.penulis).toSet().toList();
      for (final author in authors.take(2)) {
        if (filter.author != author) {
          suggestions.add('by $author');
        }
      }
    }
    
    return suggestions.take(5).toList();
  }

  List<String> _getSpellingSuggestions(String query) {
    // Simple spelling suggestion logic
    // In a real app, this would use a proper spell-checking library
    final suggestions = <String>[];
    
    // Remove common typos
    if (query.contains('teh')) {
      suggestions.add(query.replaceAll('teh', 'the'));
    }
    if (query.contains('adn')) {
      suggestions.add(query.replaceAll('adn', 'and'));
    }
    
    return suggestions;
  }

  List<String> _getRelatedTerms(String query) {
    // Generate related search terms
    final relatedTerms = <String, List<String>>{
      'programming': ['coding', 'software', 'development', 'computer'],
      'mathematics': ['math', 'calculus', 'algebra', 'statistics'],
      'science': ['physics', 'chemistry', 'biology', 'research'],
      'history': ['historical', 'ancient', 'modern', 'world'],
    };
    
    final suggestions = <String>[];
    final lowerQuery = query.toLowerCase();
    
    relatedTerms.forEach((key, terms) {
      if (lowerQuery.contains(key)) {
        suggestions.addAll(terms);
      }
    });
    
    return suggestions;
  }
}

/// Result of an advanced search operation
class SearchResult {
  /// Collections found
  final List<Collection> collections;
  
  /// Total number of results
  final int totalResults;
  
  /// Search execution time in milliseconds
  final int searchTime;
  
  /// Applied search filter
  final SearchFilter filter;
  
  /// Search suggestions for refinement
  final List<String> suggestions;
  
  /// Popular searches (could be added later)
  final List<String>? popularSearches;

  const SearchResult({
    required this.collections,
    required this.totalResults,
    required this.searchTime,
    required this.filter,
    required this.suggestions,
    this.popularSearches,
  });

  /// Check if search has results
  bool get hasResults => collections.isNotEmpty;
  
  /// Check if search was fast (under 500ms)
  bool get wasFast => searchTime < 500;
  
  /// Get performance level
  SearchPerformance get performance {
    if (searchTime < 100) return SearchPerformance.excellent;
    if (searchTime < 300) return SearchPerformance.good;
    if (searchTime < 600) return SearchPerformance.average;
    return SearchPerformance.slow;
  }

  /// Get result quality metrics
  SearchQuality get quality {
    if (totalResults == 0) return SearchQuality.noResults;
    if (totalResults <= 5) return SearchQuality.precise;
    if (totalResults <= 20) return SearchQuality.good;
    if (totalResults <= 50) return SearchQuality.broad;
    return SearchQuality.tooGeneral;
  }

  /// Get search summary for display
  String get summary {
    if (totalResults == 0) {
      return 'No results found';
    } else if (totalResults == 1) {
      return '1 result found in ${searchTime}ms';
    } else {
      return '$totalResults results found in ${searchTime}ms';
    }
  }
}

enum SearchPerformance {
  excellent, // < 100ms
  good,      // < 300ms
  average,   // < 600ms
  slow,      // >= 600ms
}

enum SearchQuality {
  noResults,   // 0 results
  precise,     // 1-5 results
  good,        // 6-20 results
  broad,       // 21-50 results
  tooGeneral,  // > 50 results
}

/// Use case for search suggestions and autocomplete
class GetSearchSuggestionsUseCase implements UseCase<List<String>, SearchSuggestionParams> {
  final LibraryRepository repository;

  const GetSearchSuggestionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(SearchSuggestionParams params) async {
    try {
      final suggestions = <String>[];
      
      // Get suggestions based on query prefix
      if (params.query.length >= 2) {
        suggestions.addAll(_getTitleSuggestions(params.query));
        suggestions.addAll(_getAuthorSuggestions(params.query));
        suggestions.addAll(_getTopicSuggestions(params.query));
      }
      
      // Add popular searches if no query
      if (params.query.isEmpty) {
        suggestions.addAll(_getPopularSearches());
      }
      
      // Limit results
      final limitedSuggestions = suggestions
          .take(params.limit)
          .toList();
      
      return Right(limitedSuggestions);
    } catch (e) {
      return Left(ServerFailure('Failed to get search suggestions: ${e.toString()}'));
    }
  }

  List<String> _getTitleSuggestions(String query) {
    // In a real app, this would query a search index or database
    final commonTitles = [
      'Introduction to Programming',
      'Data Structures and Algorithms',
      'Database Management Systems',
      'Software Engineering Principles',
      'Web Development Fundamentals',
      'Mobile App Development',
      'Machine Learning Basics',
      'Artificial Intelligence',
      'Computer Networks',
      'Operating Systems',
    ];
    
    return commonTitles
        .where((title) => title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<String> _getAuthorSuggestions(String query) {
    final commonAuthors = [
      'Robert C. Martin',
      'Martin Fowler',
      'Gang of Four',
      'Steve McConnell',
      'Kent Beck',
      'Eric Evans',
      'Uncle Bob',
    ];
    
    return commonAuthors
        .where((author) => author.toLowerCase().contains(query.toLowerCase()))
        .map((author) => 'by $author')
        .toList();
  }

  List<String> _getTopicSuggestions(String query) {
    final commonTopics = [
      'programming',
      'algorithms',
      'data structures',
      'software engineering',
      'web development',
      'mobile development',
      'database design',
      'machine learning',
      'artificial intelligence',
      'computer science',
    ];
    
    return commonTopics
        .where((topic) => topic.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<String> _getPopularSearches() {
    return [
      'programming books',
      'data structures',
      'web development',
      'mobile apps',
      'algorithms',
      'database',
      'software engineering',
      'machine learning',
    ];
  }
}

/// Parameters for search suggestions
class SearchSuggestionParams {
  /// Current query text
  final String query;
  
  /// Maximum number of suggestions
  final int limit;
  
  /// Type of suggestions to include
  final List<SuggestionType> types;

  const SearchSuggestionParams({
    required this.query,
    this.limit = 8,
    this.types = const [
      SuggestionType.titles,
      SuggestionType.authors,
      SuggestionType.topics,
    ],
  });
}

enum SuggestionType {
  titles,
  authors,
  topics,
  categories,
  popular,
}

/// Use case for saving and managing search history
class SearchHistoryUseCase implements UseCase<bool, SearchHistoryParams> {
  // In a real app, this would use local storage or a cache service
  static final List<String> _searchHistory = [];

  @override
  Future<Either<Failure, bool>> call(SearchHistoryParams params) async {
    try {
      switch (params.action) {
        case SearchHistoryAction.save:
          _saveSearch(params.query!);
          break;
        case SearchHistoryAction.clear:
          _clearHistory();
          break;
        case SearchHistoryAction.remove:
          _removeSearch(params.query!);
          break;
      }
      return const Right(true);
    } catch (e) {
      return Left(CacheFailure('Failed to manage search history: ${e.toString()}'));
    }
  }

  void _saveSearch(String query) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      // Keep only last 20 searches
      if (_searchHistory.length > 20) {
        _searchHistory.removeLast();
      }
    }
  }

  void _clearHistory() {
    _searchHistory.clear();
  }

  void _removeSearch(String query) {
    _searchHistory.remove(query);
  }

  static List<String> getHistory() => List.from(_searchHistory);
}

/// Parameters for search history operations
class SearchHistoryParams {
  final SearchHistoryAction action;
  final String? query;

  const SearchHistoryParams({
    required this.action,
    this.query,
  });
}

enum SearchHistoryAction {
  save,
  clear,
  remove,
}