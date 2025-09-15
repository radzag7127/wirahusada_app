// lib/features/transkrip/presentation/bloc/transkrip_event.dart
import 'package:equatable/equatable.dart';
// --- PERBAIKAN: Import definisi class Course untuk mengatasi error ---
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';

abstract class TranskripEvent extends Equatable {
  const TranskripEvent();

  @override
  List<Object> get props => [];
}

class FetchTranskrip extends TranskripEvent {
  const FetchTranskrip();
}

// --- EVENT BARU: Untuk mentrigger usulan penghapusan ---
class ProposeDeletionToggled extends TranskripEvent {
  final Course courseToUpdate;
  const ProposeDeletionToggled({required this.courseToUpdate});

  @override
  List<Object> get props => [courseToUpdate];
}
