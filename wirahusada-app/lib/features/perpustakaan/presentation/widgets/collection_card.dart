import 'package:flutter/material.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';

class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback onTap;

  const CollectionCard({
    super.key,
    required this.collection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover or placeholder
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: collection.sampul?.isNotEmpty == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          collection.sampul!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildCoverPlaceholder(),
                        ),
                      )
                    : _buildCoverPlaceholder(),
              ),
              
              const SizedBox(width: 16),
              
              // Book information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      collection.judul,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Author
                    if (collection.penulis?.isNotEmpty == true)
                      Text(
                        collection.penulis!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    const SizedBox(height: 8),
                    
                    // Category and year
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            collection.kategori.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (collection.tahun != null)
                          Text(
                            collection.tahun!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Availability and location
                    Row(
                      children: [
                        // Availability status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (collection.status?.toLowerCase() == 'tersedia' || 
                                    collection.stokTersedia != null && collection.stokTersedia! > 0)
                                ? Colors.green
                                : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (collection.status?.toLowerCase() == 'tersedia' || 
                             collection.stokTersedia != null && collection.stokTersedia! > 0)
                                ? 'Tersedia${collection.stokTersedia != null ? ' (${collection.stokTersedia})' : ''}'
                                : 'Dipinjam',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Location
                        if (collection.lokasiRak?.isNotEmpty == true)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                collection.lokasiRak!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 24,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            collection.kategori.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[500],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (collection.kategori.toLowerCase()) {
      case 'buku':
        return Icons.book;
      case 'jurnal':
        return Icons.article;
      case 'skripsi':
      case 'tesis':
      case 'disertasi':
        return Icons.school;
      case 'majalah':
        return Icons.auto_stories;
      case 'cd':
      case 'dvd':
        return Icons.album;
      default:
        return Icons.library_books;
    }
  }

  Color _getCategoryColor() {
    switch (collection.kategori.toLowerCase()) {
      case 'buku':
        return const Color(0xFF4CAF50);
      case 'jurnal':
        return const Color(0xFF2196F3);
      case 'skripsi':
        return const Color(0xFFFF9800);
      case 'tesis':
        return const Color(0xFFFF5722);
      case 'disertasi':
        return const Color(0xFF9C27B0);
      case 'majalah':
        return const Color(0xFF795548);
      case 'cd':
      case 'dvd':
        return const Color(0xFF607D8B);
      default:
        return const Color(0xFF1976D2);
    }
  }
}