import 'package:equatable/equatable.dart';

/// Domain entity representing a library borrowing activity
/// This entity represents the borrowing, returning, and renewal activities
class Activity extends Equatable {
  /// Database ID
  final String id;
  
  /// Unique activity identifier
  final String idAktivitas;
  
  /// Student NRM who borrowed the book
  final String nrmMahasiswa;
  
  /// Collection code that was borrowed
  final String kodeKoleksi;
  
  /// Date when the book was borrowed
  final DateTime tglPinjam;
  
  /// Due date for returning the book
  final DateTime tglKembali;
  
  /// Current status (Dipinjam, Dikembalikan, Diperpanjang, Terlambat)
  final String status;
  
  /// Date when the book was actually returned (optional)
  final DateTime? tglDikembalikan;
  
  /// Fine amount (optional)
  final double? denda;
  
  /// Additional notes (optional)
  final String? keterangan;
  
  /// User who created the record (optional)
  final String? createdBy;
  
  /// User who last updated the record (optional)
  final String? updatedBy;
  
  /// Creation timestamp (optional)
  final DateTime? createdAt;
  
  /// Last update timestamp (optional)
  final DateTime? updatedAt;
  
  // Related data from joins (optional)
  /// Collection title
  final String? koleksiJudul;
  
  /// Collection author
  final String? koleksiPenulis;
  
  /// Collection category
  final String? koleksiKategori;
  
  /// Student name
  final String? mahasiswaNama;
  
  /// Student department
  final String? mahasiswaJurusan;
  
  /// Current days overdue (calculated)
  final int? daysOverdue;
  
  /// Days overdue when returned (calculated)
  final int? wasOverdueDays;

  const Activity({
    required this.id,
    required this.idAktivitas,
    required this.nrmMahasiswa,
    required this.kodeKoleksi,
    required this.tglPinjam,
    required this.tglKembali,
    required this.status,
    this.tglDikembalikan,
    this.denda,
    this.keterangan,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
    // Related data
    this.koleksiJudul,
    this.koleksiPenulis,
    this.koleksiKategori,
    this.mahasiswaNama,
    this.mahasiswaJurusan,
    this.daysOverdue,
    this.wasOverdueDays,
  });

  /// Check if the activity is currently overdue
  bool get isOverdue {
    if (status == 'Dikembalikan') return false;
    return DateTime.now().isAfter(tglKembali);
  }

  /// Check if the activity is active (borrowed but not returned)
  bool get isActive => status == 'Dipinjam' || status == 'Diperpanjang';

  /// Check if the activity is completed (returned)
  bool get isCompleted => status == 'Dikembalikan';

  /// Check if the activity was returned late
  bool get wasReturnedLate {
    if (tglDikembalikan == null) return false;
    return tglDikembalikan!.isAfter(tglKembali);
  }

  /// Get the number of days overdue (current or when returned)
  int get overdueDays {
    if (daysOverdue != null) return daysOverdue!;
    if (wasOverdueDays != null) return wasOverdueDays!;
    
    if (isOverdue) {
      return DateTime.now().difference(tglKembali).inDays;
    }
    
    if (wasReturnedLate) {
      return tglDikembalikan!.difference(tglKembali).inDays;
    }
    
    return 0;
  }

  /// Get the borrowing duration in days
  int get borrowingDuration {
    final endDate = tglDikembalikan ?? DateTime.now();
    return endDate.difference(tglPinjam).inDays;
  }

  /// Check if the activity has a fine
  bool get hasFine => denda != null && denda! > 0;

  /// Get formatted fine amount
  String get formattedFine {
    if (denda == null || denda == 0) return 'Rp 0';
    return 'Rp ${denda!.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  /// Get status display text
  String get statusDisplay {
    switch (status.toLowerCase()) {
      case 'dipinjam':
        return 'Borrowed';
      case 'dikembalikan':
        return 'Returned';
      case 'diperpanjang':
        return 'Renewed';
      case 'terlambat':
        return 'Overdue';
      default:
        return status;
    }
  }

  /// Get status color based on current state
  String get statusColor {
    if (isOverdue) return 'red';
    if (isActive) return 'blue';
    if (isCompleted) return 'green';
    return 'grey';
  }

  @override
  List<Object?> get props => [
        id,
        idAktivitas,
        nrmMahasiswa,
        kodeKoleksi,
        tglPinjam,
        tglKembali,
        status,
        tglDikembalikan,
        denda,
        keterangan,
        createdBy,
        updatedBy,
        createdAt,
        updatedAt,
        // Related data
        koleksiJudul,
        koleksiPenulis,
        koleksiKategori,
        mahasiswaNama,
        mahasiswaJurusan,
        daysOverdue,
        wasOverdueDays,
      ];
}