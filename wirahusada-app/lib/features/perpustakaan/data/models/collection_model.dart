import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';

/// Data model for Collection entity with JSON serialization
class CollectionModel extends Collection {
  const CollectionModel({
    required super.kode,
    required super.kategori,
    required super.topik,
    required super.judul,
    required super.penulis,
    super.penerbit,
    super.tahun,
    super.lokasi,
    super.deskripsi,
    super.sampul,
    super.status,
    super.filePdf,
    super.link,
    super.id,
    super.isbn,
    super.subKategori,
    super.lokasiRak,
    super.stokTotal,
    super.stokTersedia,
    super.activeBorrows,
    super.createdAt,
    super.updatedAt,
  });

  /// Create CollectionModel from JSON data
  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    // Validate required fields to prevent type conversion errors
    if (json.isEmpty) {
      throw FormatException('JSON data is empty or null');
    }

    // Check for error response patterns that shouldn't be parsed as collection data
    if (json.containsKey('success') && json['success'] == false) {
      throw FormatException('Cannot parse error response as collection data: ${json['message'] ?? 'Unknown error'}');
    }

    if (json.containsKey('error') || (json.containsKey('message') && !json.containsKey('kode'))) {
      throw FormatException('Cannot parse error response as collection data: ${json['message'] ?? 'Error response detected'}');
    }

    // Validate required fields exist and are not null
    final requiredFields = ['kode', 'kategori', 'topik', 'judul', 'penulis'];
    for (final field in requiredFields) {
      if (!json.containsKey(field) || json[field] == null) {
        throw FormatException('Missing required field: $field');
      }
      if (json[field].toString().trim().isEmpty) {
        throw FormatException('Required field "$field" cannot be empty');
      }
    }

    try {
      return CollectionModel(
        kode: json['kode']?.toString() ?? '',
        kategori: json['kategori']?.toString() ?? '',
        topik: json['topik']?.toString() ?? '',
        judul: json['judul']?.toString() ?? '',
        penulis: json['penulis']?.toString() ?? '',
        penerbit: json['penerbit']?.toString(),
        tahun: json['tahun_terbit']?.toString(),
        lokasi: json['lokasi']?.toString(),
        deskripsi: json['deskripsi']?.toString(),
        sampul: json['sampul']?.toString(),
        status: json['status']?.toString(),
        filePdf: json['file_pdf']?.toString(),
        link: json['link']?.toString(),
        // Enhanced fields from backend
        id: json['id']?.toString(),
        isbn: json['isbn']?.toString(),
        subKategori: json['sub_kategori']?.toString(),
        lokasiRak: json['lokasi_rak']?.toString(),
        stokTotal: _safeParseInt(json['stok_total']),
        stokTersedia: _safeParseInt(json['stok_tersedia']),
        activeBorrows: _safeParseInt(json['active_borrows']),
        createdAt: _safeParseDateTime(json['created_at']),
        updatedAt: _safeParseDateTime(json['updated_at']),
      );
    } catch (e) {
      throw FormatException('Failed to parse collection data: $e');
    }
  }

  /// Safely parse integer values with fallback
  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Safely parse DateTime values with fallback
  static DateTime? _safeParseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  /// Convert CollectionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'kode': kode,
      'kategori': kategori,
      'topik': topik,
      'judul': judul,
      'penulis': penulis,
      'penerbit': penerbit,
      'tahun_terbit': tahun,
      'lokasi': lokasi,
      'deskripsi': deskripsi,
      'sampul': sampul,
      'status': status,
      'file_pdf': filePdf,
      'link': link,
      // Enhanced fields
      'id': id,
      'isbn': isbn,
      'sub_kategori': subKategori,
      'lokasi_rak': lokasiRak,
      'stok_total': stokTotal,
      'stok_tersedia': stokTersedia,
      'active_borrows': activeBorrows,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Create CollectionModel from domain entity
  factory CollectionModel.fromEntity(Collection collection) {
    return CollectionModel(
      kode: collection.kode,
      kategori: collection.kategori,
      topik: collection.topik,
      judul: collection.judul,
      penulis: collection.penulis,
      penerbit: collection.penerbit,
      tahun: collection.tahun,
      lokasi: collection.lokasi,
      deskripsi: collection.deskripsi,
      sampul: collection.sampul,
      status: collection.status,
      filePdf: collection.filePdf,
      link: collection.link,
      // Enhanced fields
      id: collection.id,
      isbn: collection.isbn,
      subKategori: collection.subKategori,
      lokasiRak: collection.lokasiRak,
      stokTotal: collection.stokTotal,
      stokTersedia: collection.stokTersedia,
      activeBorrows: collection.activeBorrows,
      createdAt: collection.createdAt,
      updatedAt: collection.updatedAt,
    );
  }

  /// Convert to domain entity
  Collection toEntity() {
    return Collection(
      kode: kode,
      kategori: kategori,
      topik: topik,
      judul: judul,
      penulis: penulis,
      penerbit: penerbit,
      tahun: tahun,
      lokasi: lokasi,
      deskripsi: deskripsi,
      sampul: sampul,
      status: status,
      filePdf: filePdf,
      link: link,
      // Enhanced fields
      id: id,
      isbn: isbn,
      subKategori: subKategori,
      lokasiRak: lokasiRak,
      stokTotal: stokTotal,
      stokTersedia: stokTersedia,
      activeBorrows: activeBorrows,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}