import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:wismon_keuangan/core/error/failures.dart';
import 'package:wismon_keuangan/core/usecases/usecase.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/borrow_request.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/repositories/library_repository.dart';

/// Use case for submitting a borrow request
class SubmitBorrowRequestUseCase implements UseCase<bool, BorrowRequestParams> {
  final LibraryRepository repository;

  SubmitBorrowRequestUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(BorrowRequestParams params) async {
    final borrowRequest = BorrowRequest(
      nrm: params.nrm,
      kode: params.kode,
      tanggalPengambilan: params.tanggalPengambilan,
      tanggalKembali: params.tanggalKembali,
      status: 'pending', // Default status for new requests
      notes: params.notes,
    );

    return await repository.submitBorrowRequest(borrowRequest);
  }
}

/// Parameters for borrow request submission
class BorrowRequestParams extends Equatable {
  final String nrm;
  final String kode;
  final String tanggalPengambilan;
  final String tanggalKembali;
  final String? notes;

  const BorrowRequestParams({
    required this.nrm,
    required this.kode,
    required this.tanggalPengambilan,
    required this.tanggalKembali,
    this.notes,
  });

  @override
  List<Object?> get props => [nrm, kode, tanggalPengambilan, tanggalKembali, notes];
}