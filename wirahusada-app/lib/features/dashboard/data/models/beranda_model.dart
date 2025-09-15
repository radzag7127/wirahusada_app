import '../../domain/entities/beranda.dart';

class BerandaModel extends BerandaData {
  const BerandaModel({
    required super.payment,
    required super.transcript,
    required super.announcements,
    required super.libraryServices,
  });

  factory BerandaModel.fromJson(Map<String, dynamic> json) {
    return BerandaModel(
      payment: PaymentSummaryModel.fromJson(json['payment'] ?? {}),
      transcript: TranscriptSummaryModel.fromJson(json['transcript'] ?? {}),
      announcements:
          (json['announcements'] as List<dynamic>?)
              ?.map((item) => AnnouncementModel.fromJson(item))
              .toList() ??
          [],
      libraryServices:
          (json['libraryServices'] as List<dynamic>?)
              ?.map((item) => LibraryServiceModel.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'payment': (payment as PaymentSummaryModel).toJson(),
      'transcript': (transcript as TranscriptSummaryModel).toJson(),
      'announcements': announcements
          .map((item) => (item as AnnouncementModel).toJson())
          .toList(),
      'libraryServices': libraryServices
          .map((item) => (item as LibraryServiceModel).toJson())
          .toList(),
    };
  }
}

class PaymentSummaryModel extends PaymentSummaryData {
  const PaymentSummaryModel({required super.fees});

  factory PaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return PaymentSummaryModel(fees: Map<String, dynamic>.from(json));
  }

  Map<String, dynamic> toJson() {
    return fees;
  }
}

class TranscriptSummaryModel extends TranscriptSummaryData {
  const TranscriptSummaryModel({
    required super.totalSks,
    required super.totalBobot,
    required super.ipKumulatif,
  });

  factory TranscriptSummaryModel.fromJson(Map<String, dynamic> json) {
    return TranscriptSummaryModel(
      totalSks: json['totalSks'] ?? 0,
      totalBobot: (json['totalBobot'] ?? 0.0).toDouble(),
      ipKumulatif: (json['ipKumulatif'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSks': totalSks,
      'totalBobot': totalBobot,
      'ipKumulatif': ipKumulatif,
    };
  }
}

class AnnouncementModel extends AnnouncementData {
  const AnnouncementModel({
    required super.id,
    required super.title,
    required super.description,
    super.imageUrl,
    super.articleUrl,
    required super.status,
    required super.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      articleUrl: json['articleUrl'],
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'articleUrl': articleUrl,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

class LibraryServiceModel extends LibraryServiceData {
  const LibraryServiceModel({
    required super.id,
    required super.title,
    required super.status,
  });

  factory LibraryServiceModel.fromJson(Map<String, dynamic> json) {
    return LibraryServiceModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      status: json['status'] ?? 'coming_soon',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'status': status};
  }
}
