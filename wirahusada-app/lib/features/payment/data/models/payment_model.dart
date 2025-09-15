import '../../domain/entities/payment.dart';

// Helper function to parse currency strings
double _parseCurrency(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    try {
      // Remove "Rp", whitespace, and all separators (.,), then parse.
      final sanitized = value.replaceAll(RegExp(r'[Rp.,\s]'), '');
      return double.parse(sanitized);
    } catch (e) {
      return 0.0;
    }
  }
  return 0.0;
}

// --- PAYMENT HISTORY MODEL ---

class PaymentHistoryItemModel extends PaymentHistoryItem {
  const PaymentHistoryItemModel({
    required super.id,
    required super.txId,
    required super.tanggal,
    required super.tanggalFull,
    required super.type,
    required super.jumlah,
    required super.status,
    required super.method,
    required super.methodCode,
  });

  factory PaymentHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItemModel(
      id: json['id'].toString(),
      txId: json['tx_id'].toString(),
      tanggal: json['tanggal'].toString(),
      tanggalFull: json['tanggal_full'].toString(),
      type: json['type'].toString(),
      jumlah: _parseCurrency(json['jumlah']),
      status: json['status'].toString(),
      method: json['method'].toString(),
      methodCode: json['method_code'].toString(),
    );
  }
}

// --- PAYMENT SUMMARY MODEL ---

class PaymentSummaryModel extends PaymentSummary {
  const PaymentSummaryModel({
    required super.totalPembayaran,
    required super.breakdown,
  });

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    final breakdownData = json['breakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = breakdownData.map(
      (key, value) => MapEntry(key, _parseCurrency(value)),
    );

    return PaymentSummaryModel(
      totalPembayaran: _parseCurrency(json['total_pembayaran']),
      breakdown: breakdown,
    );
  }
}

// --- TRANSACTION DETAIL MODEL ---

class TransactionDetailModel extends TransactionDetail {
  const TransactionDetailModel({
    required super.id,
    required super.txId,
    required super.tanggal,
    required super.tanggalFull,
    required super.type,
    required super.jumlah,
    required super.status,
    required super.method,
    required super.studentName,
    required super.studentNim,
    required super.studentProdi,
    required super.paymentBreakdown,
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) {
    final breakdownData =
        json['payment_breakdown'] as Map<String, dynamic>? ?? {};
    final paymentBreakdown = breakdownData.map(
      (key, value) => MapEntry(key, _parseCurrency(value)),
    );

    return TransactionDetailModel(
      id: json['id'].toString(),
      txId: json['tx_id'].toString(),
      tanggal: json['tanggal'].toString(),
      tanggalFull: json['tanggal_full'].toString(),
      type: json['type'].toString(),
      jumlah: _parseCurrency(json['jumlah']),
      status: json['status'].toString(),
      method: json['method'].toString(),
      studentName: json['student_name'].toString(),
      studentNim: json['student_nim'].toString(),
      studentProdi: json['student_prodi'].toString(),
      paymentBreakdown: paymentBreakdown,
    );
  }
}

// --- PAYMENT TYPE MODEL ---

class PaymentTypeModel extends PaymentType {
  const PaymentTypeModel({required super.kode, required super.nama});

  factory PaymentTypeModel.fromJson(Map<String, dynamic> json) {
    return PaymentTypeModel(
      kode: json['kode'].toString(),
      nama: json['nama'].toString(),
    );
  }
}
