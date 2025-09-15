// lib/features/transkrip/data/models/transkrip_model.dart
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';

class TranskripModel extends Transkrip {
  const TranskripModel({
    required String ipk,
    required int totalSks,
    required List<Course> courses,
  }) : super(ipk: ipk, totalSks: totalSks, courses: courses);

  factory TranskripModel.fromJson(Map<String, dynamic> json) {
    var coursesFromJson = json['courses'] as List;
    List<Course> courseList = coursesFromJson
        .map((i) => Course.fromJson(i))
        .toList();
    return TranskripModel(
      ipk: json['ipk'],
      totalSks: json['total_sks'],
      courses: courseList,
    );
  }
}
