import 'package:equatable/equatable.dart';

// --- PAYMENT HISTORY ---

class PaymentHistoryItem extends Equatable {
  final String id;
  final String txId;
  final String tanggal;
  final String tanggalFull;
  final String type;
  final double jumlah;
  final String status;
  final String method;
  final String methodCode;

  const PaymentHistoryItem({
    required this.id,
    required this.txId,
    required this.tanggal,
    required this.tanggalFull,
    required this.type,
    required this.jumlah,
    required this.status,
    required this.method,
    required this.methodCode,
  });

  @override
  List<Object?> get props => [
    id,
    txId,
    tanggal,
    tanggalFull,
    type,
    jumlah,
    status,
    method,
    methodCode,
  ];
}

// --- PAYMENT SUMMARY ---

class PaymentSummary extends Equatable {
  final double totalPembayaran;
  final Map<String, double> breakdown;

  const PaymentSummary({
    required this.totalPembayaran,
    required this.breakdown,
  });

  @override
  List<Object> get props => [totalPembayaran, breakdown];
}

// --- TRANSACTION DETAIL ---

class TransactionDetail extends Equatable {
  final String id;
  final String txId;
  final String tanggal;
  final String tanggalFull;
  final String type;
  final double jumlah;
  final String status;
  final String method;
  final String studentName;
  final String studentNim;
  final String studentProdi;
  final Map<String, double> paymentBreakdown;

  const TransactionDetail({
    required this.id,
    required this.txId,
    required this.tanggal,
    required this.tanggalFull,
    required this.type,
    required this.jumlah,
    required this.status,
    required this.method,
    required this.studentName,
    required this.studentNim,
    required this.studentProdi,
    required this.paymentBreakdown,
  });

  @override
  List<Object?> get props => [
    id,
    txId,
    tanggal,
    tanggalFull,
    type,
    jumlah,
    status,
    method,
    studentName,
    studentNim,
    studentProdi,
    paymentBreakdown,
  ];
}

// --- PAYMENT TYPE ---

class PaymentType extends Equatable {
  final String kode;
  final String nama;

  const PaymentType({required this.kode, required this.nama});

  @override
  List<Object> get props => [kode, nama];
}
