import 'package:equatable/equatable.dart';

/// Domain entity representing a borrow request for a library collection
class BorrowRequest extends Equatable {
  /// Student registration number (nrm)
  final String nrm;

  /// Collection code being requested
  final String kode;

  /// Planned pickup date for the collection
  final String tanggalPengambilan;

  /// Due date for returning the collection
  final String tanggalKembali;

  /// Optional request ID (if assigned by backend)
  final String? requestId;

  /// Optional status of the request (pending, approved, rejected, etc.)
  final String status;

  /// Optional submission timestamp
  final DateTime? submittedAt;

  /// Optional additional notes for the request
  final String? notes;

  const BorrowRequest({
    required this.nrm,
    required this.kode,
    required this.tanggalPengambilan,
    required this.tanggalKembali,
    this.requestId,
    required this.status,
    this.submittedAt,
    this.notes,
  });

  /// Check if the request is still pending
  bool get isPending => status.toLowerCase() == 'pending';

  /// Check if the request has been approved
  bool get isApproved => status.toLowerCase() == 'approved';

  /// Check if the request has been rejected
  bool get isRejected => status.toLowerCase() == 'rejected';

  @override
  List<Object?> get props => [
        nrm,
        kode,
        tanggalPengambilan,
        tanggalKembali,
        requestId,
        status,
        submittedAt,
        notes,
      ];
}