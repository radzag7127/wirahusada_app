import 'package:dartz/dartz.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for getting popular collections
/// Returns collections sorted by borrowing frequency
class GetPopularCollectionsUseCase implements UseCase<List<Collection>, PopularCollectionsParams> {
  final LibraryRepository repository;

  const GetPopularCollectionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Collection>>> call(PopularCollectionsParams params) async {
    return await repository.getPopularCollections(limit: params.limit);
  }
}

/// Parameters for getting popular collections
class PopularCollectionsParams {
  /// Maximum number of collections to return
  final int limit;
  
  /// Time period for popularity calculation (week, month, year)
  final PopularityPeriod period;
  
  /// Filter by category
  final String? category;
  
  /// Minimum borrow count to be considered popular
  final int? minBorrowCount;

  const PopularCollectionsParams({
    this.limit = 10,
    this.period = PopularityPeriod.month,
    this.category,
    this.minBorrowCount,
  });
}

/// Time period for calculating popularity
enum PopularityPeriod {
  week,
  month,
  year,
  allTime,
}

extension PopularityPeriodExtension on PopularityPeriod {
  String get displayName {
    switch (this) {
      case PopularityPeriod.week:
        return 'This Week';
      case PopularityPeriod.month:
        return 'This Month';
      case PopularityPeriod.year:
        return 'This Year';
      case PopularityPeriod.allTime:
        return 'All Time';
    }
  }

  int get days {
    switch (this) {
      case PopularityPeriod.week:
        return 7;
      case PopularityPeriod.month:
        return 30;
      case PopularityPeriod.year:
        return 365;
      case PopularityPeriod.allTime:
        return 0; // No limit
    }
  }
}

/// Use case for getting recent collections
class GetRecentCollectionsUseCase implements UseCase<List<Collection>, RecentCollectionsParams> {
  final LibraryRepository repository;

  const GetRecentCollectionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Collection>>> call(RecentCollectionsParams params) async {
    return await repository.getRecentCollections(limit: params.limit);
  }
}

/// Parameters for getting recent collections
class RecentCollectionsParams {
  /// Maximum number of collections to return
  final int limit;
  
  /// Filter by category
  final String? category;
  
  /// Only include collections added within this many days
  final int? withinDays;

  const RecentCollectionsParams({
    this.limit = 10,
    this.category,
    this.withinDays,
  });
}

/// Use case for getting trending collections
class GetTrendingCollectionsUseCase implements UseCase<List<Collection>, TrendingCollectionsParams> {
  final GetPopularCollectionsUseCase getPopularCollectionsUseCase;
  final GetRecentCollectionsUseCase getRecentCollectionsUseCase;

  const GetTrendingCollectionsUseCase({
    required this.getPopularCollectionsUseCase,
    required this.getRecentCollectionsUseCase,
  });

  @override
  Future<Either<Failure, List<Collection>>> call(TrendingCollectionsParams params) async {
    // Get popular collections from the last week
    final popularResult = await getPopularCollectionsUseCase.call(
      PopularCollectionsParams(
        limit: params.limit * 2, // Get more to allow for filtering
        period: PopularityPeriod.week,
        category: params.category,
      ),
    );
    
    return popularResult.fold(
      (failure) => Left(failure),
      (popular) {
        // Get recent collections
        return getRecentCollectionsUseCase.call(
          RecentCollectionsParams(
            limit: params.limit,
            category: params.category,
            withinDays: 14, // Recent within 2 weeks
          ),
        ).then((recentResult) {
          return recentResult.fold(
            (failure) => Left(failure),
            (recent) {
              // Combine and deduplicate
              final trending = <Collection>[];
              final addedCodes = <String>{};
              
              // Add popular items first
              for (final collection in popular) {
                if (!addedCodes.contains(collection.kode)) {
                  trending.add(collection);
                  addedCodes.add(collection.kode);
                  if (trending.length >= params.limit) break;
                }
              }
              
              // Add recent items if still have space
              for (final collection in recent) {
                if (!addedCodes.contains(collection.kode) && trending.length < params.limit) {
                  trending.add(collection);
                  addedCodes.add(collection.kode);
                }
              }
              
              return Right(trending);
            },
          );
        });
      },
    );
  }
}

/// Parameters for getting trending collections
class TrendingCollectionsParams {
  /// Maximum number of collections to return
  final int limit;
  
  /// Filter by category
  final String? category;

  const TrendingCollectionsParams({
    this.limit = 10,
    this.category,
  });
}

/// Use case for getting recommended collections based on user's borrowing history
class GetRecommendedCollectionsUseCase implements UseCase<List<Collection>, RecommendationParams> {
  final LibraryRepository repository;

  const GetRecommendedCollectionsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Collection>>> call(RecommendationParams params) async {
    try {
      // This would ideally use a recommendation algorithm
      // For now, we'll use popular collections filtered by user's preferences
      
      // Get user's borrowing history to determine preferences
      final historyResult = await repository.getMyBorrowingHistory();
      
      return historyResult.fold(
        (failure) => Left(failure),
        (history) async {
          // Analyze user preferences from history
          final preferences = _analyzeUserPreferences(history);
          
          // Get popular collections in preferred categories
          final popularResult = await repository.getPopularCollections(
            limit: params.limit * 2,
          );
          
          return popularResult.fold(
            (failure) => Left(failure),
            (popular) {
              // Filter and rank based on preferences
              final recommended = _filterByPreferences(popular, preferences, params.limit);
              return Right(recommended);
            },
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to get recommendations: ${e.toString()}'));
    }
  }

  UserPreferences _analyzeUserPreferences(List<dynamic> history) {
    final categoryCount = <String, int>{};
    final topicCount = <String, int>{};
    
    // This would analyze the user's borrowing history
    // For now, return default preferences
    return UserPreferences(
      preferredCategories: ['buku'],
      preferredTopics: [],
      preferredAuthors: [],
    );
  }

  List<Collection> _filterByPreferences(
    List<Collection> collections,
    UserPreferences preferences,
    int limit,
  ) {
    // Filter collections based on preferences
    var filtered = collections.where((collection) {
      if (preferences.preferredCategories.isNotEmpty &&
          !preferences.preferredCategories.contains(collection.kategori)) {
        return false;
      }
      return true;
    }).toList();
    
    // Limit results
    if (filtered.length > limit) {
      filtered = filtered.sublist(0, limit);
    }
    
    return filtered;
  }
}

/// Parameters for getting personalized recommendations
class RecommendationParams {
  /// Maximum number of recommendations to return
  final int limit;
  
  /// Include categories user hasn't explored
  final bool includeExploration;
  
  /// Minimum similarity score (0-1)
  final double? minSimilarity;

  const RecommendationParams({
    this.limit = 10,
    this.includeExploration = true,
    this.minSimilarity,
  });
}

/// User preferences derived from borrowing history
class UserPreferences {
  final List<String> preferredCategories;
  final List<String> preferredTopics;
  final List<String> preferredAuthors;

  const UserPreferences({
    required this.preferredCategories,
    required this.preferredTopics,
    required this.preferredAuthors,
  });
}