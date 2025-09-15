import 'package:equatable/equatable.dart';

class BerandaData extends Equatable {
  final PaymentSummaryData payment;
  final TranscriptSummaryData transcript;
  final List<AnnouncementData> announcements;
  final List<LibraryServiceData> libraryServices;

  const BerandaData({
    required this.payment,
    required this.transcript,
    required this.announcements,
    required this.libraryServices,
  });

  @override
  List<Object> get props => [
    payment,
    transcript,
    announcements,
    libraryServices,
  ];
}

class PaymentSummaryData extends Equatable {
  final Map<String, dynamic> fees;

  const PaymentSummaryData({required this.fees});

  @override
  List<Object> get props => [fees];
}

class TranscriptSummaryData extends Equatable {
  final int totalSks;
  final double totalBobot;
  final double ipKumulatif;

  const TranscriptSummaryData({
    required this.totalSks,
    required this.totalBobot,
    required this.ipKumulatif,
  });

  @override
  List<Object> get props => [totalSks, totalBobot, ipKumulatif];
}

class AnnouncementData extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final String? articleUrl;
  final String status;
  final String createdAt;

  const AnnouncementData({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.articleUrl,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    imageUrl,
    articleUrl,
    status,
    createdAt,
  ];
}

class LibraryServiceData extends Equatable {
  final String id;
  final String title;
  final String status;

  const LibraryServiceData({
    required this.id,
    required this.title,
    required this.status,
  });

  @override
  List<Object> get props => [id, title, status];
}
