import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? actionText;
  final VoidCallback? onRefresh;
  final VoidCallback? onAction;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.actionText,
    this.onRefresh,
    this.onAction,
    this.icon = Icons.library_books,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Empty state illustration
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 80,
                  color: Colors.grey[400],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Empty state title
              const Text(
                'Tidak Ada Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Empty state message
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Refresh button
                  if (onRefresh != null)
                    ElevatedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Muat Ulang',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1976D2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  
                  // Action button
                  if (onAction != null && actionText != null) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: onAction,
                      icon: const Icon(
                        Icons.add,
                        color: Color(0xFF1976D2),
                      ),
                      label: Text(
                        actionText!,
                        style: const TextStyle(
                          color: Color(0xFF1976D2),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1976D2)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Specific empty state for search results
class EmptySearchResultWidget extends EmptyStateWidget {
  final String query;

  const EmptySearchResultWidget({
    super.key,
    required this.query,
    super.onRefresh,
  }) : super(
          message: 'Tidak ada hasil untuk pencarian "$query".\nCoba gunakan kata kunci yang berbeda.',
          icon: Icons.search_off,
        );
}

/// Specific empty state for categories
class EmptyCategoryWidget extends EmptyStateWidget {
  final String category;

  const EmptyCategoryWidget({
    super.key,
    required this.category,
    super.onRefresh,
  }) : super(
          message: 'Belum ada koleksi $category yang tersedia.\nSilakan coba kategori lain.',
          icon: Icons.category,
        );
}

/// Specific empty state for no collections at all
class NoCollectionsWidget extends EmptyStateWidget {
  const NoCollectionsWidget({
    super.key,
    super.onRefresh,
  }) : super(
          message: 'Perpustakaan belum memiliki koleksi.\nSilakan hubungi administrator.',
          icon: Icons.library_books,
        );
}