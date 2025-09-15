import 'package:equatable/equatable.dart';

/// Domain entity representing a library collection item
/// This entity represents books, journals, or theses in the library
class Collection extends Equatable {
  /// Unique identifier for the collection item
  final String kode;
  
  /// Category of the collection (buku, jurnal, skripsi)
  final String kategori;
  
  /// Topic or subject of the collection
  final String topik;
  
  /// Title of the collection item
  final String judul;
  
  /// Author of the collection item
  final String penulis;
  
  /// Publisher of the collection item (optional)
  final String? penerbit;
  
  /// Publication year (optional)
  final String? tahun;
  
  /// Physical location of the item (optional)
  final String? lokasi;
  
  /// Description of the collection item (optional)
  final String? deskripsi;
  
  /// Cover image URL (optional)
  final String? sampul;
  
  /// Current status of the item (available, borrowed, etc.) (optional)
  final String? status;
  
  /// PDF file URL for digital access (optional)
  final String? filePdf;

  /// External link URL (optional)
  final String? link;

  // Enhanced fields from backend
  /// Database ID (optional)
  final String? id;
  
  /// ISBN number (optional)
  final String? isbn;
  
  /// Sub-category (optional)
  final String? subKategori;
  
  /// Shelf location (optional)
  final String? lokasiRak;
  
  /// Total stock/copies available
  final int? stokTotal;
  
  /// Currently available stock
  final int? stokTersedia;
  
  /// Number of active borrowings
  final int? activeBorrows;
  
  /// Creation timestamp
  final DateTime? createdAt;
  
  /// Last update timestamp
  final DateTime? updatedAt;

  const Collection({
    required this.kode,
    required this.kategori,
    required this.topik,
    required this.judul,
    required this.penulis,
    this.penerbit,
    this.tahun,
    this.lokasi,
    this.deskripsi,
    this.sampul,
    this.status,
    this.filePdf,
    this.link,
    // Enhanced fields
    this.id,
    this.isbn,
    this.subKategori,
    this.lokasiRak,
    this.stokTotal,
    this.stokTersedia,
    this.activeBorrows,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if the collection item is available for borrowing
  bool get isAvailable => 
    stokTersedia != null ? stokTersedia! > 0 : 
    status?.toLowerCase() == 'tersedia';

  /// Check if the collection item has a digital copy
  bool get hasDigitalCopy => filePdf != null && filePdf!.isNotEmpty;

  /// Check if the collection item has a cover image
  bool get hasCoverImage => sampul != null && sampul!.isNotEmpty;

  /// Get availability percentage
  double get availabilityPercentage {
    if (stokTotal == null || stokTotal == 0) return 0.0;
    return (stokTersedia ?? 0) / stokTotal! * 100;
  }

  /// Check if the collection is popular (based on active borrows)
  bool get isPopular => activeBorrows != null && activeBorrows! > 3;

  /// Get formatted publication year
  String get formattedYear => tahun ?? 'Unknown';

  /// Get full shelf location
  String get fullLocation => lokasiRak ?? lokasi ?? 'Not specified';

  @override
  List<Object?> get props => [
        kode,
        kategori,
        topik,
        judul,
        penulis,
        penerbit,
        tahun,
        lokasi,
        deskripsi,
        sampul,
        status,
        filePdf,
        link,
        // Enhanced fields
        id,
        isbn,
        subKategori,
        lokasiRak,
        stokTotal,
        stokTersedia,
        activeBorrows,
        createdAt,
        updatedAt,
      ];
}