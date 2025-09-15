import 'package:equatable/equatable.dart';

/// Domain entity representing collection availability status
class CollectionAvailability extends Equatable {
  /// Whether the collection is available for borrowing
  final bool available;
  
  /// Number of copies available for borrowing
  final int availableCopies;
  
  /// Total number of copies in the collection
  final int totalCopies;
  
  /// Number of currently borrowed copies
  final int borrowedCopies;
  
  /// Number of reserved copies (if reservation system is enabled)
  final int reservedCopies;

  const CollectionAvailability({
    required this.available,
    required this.availableCopies,
    required this.totalCopies,
    this.borrowedCopies = 0,
    this.reservedCopies = 0,
  });

  /// Check if any copies are available
  bool get hasAvailableCopies => availableCopies > 0;

  /// Check if all copies are borrowed
  bool get isFullyBorrowed => borrowedCopies >= totalCopies;

  /// Get availability percentage
  double get availabilityPercentage => 
      totalCopies > 0 ? (availableCopies / totalCopies) * 100 : 0.0;

  /// Get borrowing rate percentage
  double get borrowingRate => 
      totalCopies > 0 ? (borrowedCopies / totalCopies) * 100 : 0.0;

  /// Get availability status as a human-readable string
  String get availabilityStatus {
    if (available && availableCopies > 0) {
      return '$availableCopies of $totalCopies available';
    } else if (isFullyBorrowed) {
      return 'All copies borrowed';
    } else {
      return 'Not available';
    }
  }

  /// Get urgency level for borrowing
  String get urgencyLevel {
    final rate = availabilityPercentage;
    if (rate >= 50) return 'low';
    if (rate >= 20) return 'medium';
    if (rate > 0) return 'high';
    return 'unavailable';
  }

  @override
  List<Object> get props => [
        available,
        availableCopies,
        totalCopies,
        borrowedCopies,
        reservedCopies,
      ];

  @override
  String toString() => 'CollectionAvailability('
      'available: $available, '
      'copies: $availableCopies/$totalCopies'
      ')';
}