import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrow_request.dart';

/// Data model for BorrowRequest entity with JSON serialization
class BorrowRequestModel extends BorrowRequest {
  const BorrowRequestModel({
    required super.nrm,
    required super.kode,
    required super.tanggalPengambilan,
    required super.tanggalKembali,
    super.requestId,
    required super.status,
    super.submittedAt,
    super.notes,
  });

  /// Getter for backward compatibility with 'catatan' property name
  String? get catatan => notes;

  /// Create BorrowRequestModel from JSON data
  factory BorrowRequestModel.fromJson(Map<String, dynamic> json) {
    return BorrowRequestModel(
      nrm: json['nrm'] ?? '',
      kode: json['kode'] ?? '',
      tanggalPengambilan: json['tanggal_pengambilan'] ?? '',
      tanggalKembali: json['tanggal_kembali'] ?? '',
      requestId: json['request_id']?.toString(),
      status: json['status'] ?? '',
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString())
          : null,
      notes: json['notes'],
    );
  }

  /// Convert BorrowRequestModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'nrm': nrm,
      'kode': kode,
      'tanggal_pengambilan': tanggalPengambilan,
      'tanggal_kembali': tanggalKembali,
      if (requestId != null) 'request_id': requestId,
      'status': status,
      if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
      if (notes != null) 'notes': notes,
      if (notes != null) 'catatan': notes, // Add catatan alias for backward compatibility
    };
  }

  /// Create BorrowRequestModel from domain entity
  factory BorrowRequestModel.fromEntity(BorrowRequest borrowRequest) {
    return BorrowRequestModel(
      nrm: borrowRequest.nrm,
      kode: borrowRequest.kode,
      tanggalPengambilan: borrowRequest.tanggalPengambilan,
      tanggalKembali: borrowRequest.tanggalKembali,
      requestId: borrowRequest.requestId,
      status: borrowRequest.status,
      submittedAt: borrowRequest.submittedAt,
      notes: borrowRequest.notes,
    );
  }

  /// Convert to domain entity
  BorrowRequest toEntity() {
    return BorrowRequest(
      nrm: nrm,
      kode: kode,
      tanggalPengambilan: tanggalPengambilan,
      tanggalKembali: tanggalKembali,
      requestId: requestId,
      status: status,
      submittedAt: submittedAt,
      notes: notes,
    );
  }
}