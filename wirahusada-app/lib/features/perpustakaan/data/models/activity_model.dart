import 'package:wismon_keuangan/features/perpustakaan/domain/entities/activity.dart';

/// Data model for Activity entity with JSON serialization
/// Represents borrowing activities in the library system
class ActivityModel extends Activity {
  const ActivityModel({
    required super.id,
    required super.idAktivitas,
    required super.nrmMahasiswa,
    required super.kodeKoleksi,
    required super.tglPinjam,
    required super.tglKembali,
    required super.status,
    super.tglDikembalikan,
    super.denda,
    super.keterangan,
    super.createdBy,
    super.updatedBy,
    super.createdAt,
    super.updatedAt,
    // Related data
    super.koleksiJudul,
    super.koleksiPenulis,
    super.koleksiKategori,
    super.mahasiswaNama,
    super.mahasiswaJurusan,
    super.daysOverdue,
    super.wasOverdueDays,
  });

  /// Create ActivityModel from JSON data
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      id: json['id']?.toString() ?? '',
      idAktivitas: json['id_aktivitas'] ?? '',
      nrmMahasiswa: json['nrm_mahasiswa'] ?? '',
      kodeKoleksi: json['kode_koleksi'] ?? '',
      tglPinjam: DateTime.parse(json['tgl_pinjam']),
      tglKembali: DateTime.parse(json['tgl_kembali']),
      status: json['status'] ?? '',
      tglDikembalikan: json['tgl_dikembalikan'] != null 
          ? DateTime.tryParse(json['tgl_dikembalikan'].toString()) 
          : null,
      denda: json['denda']?.toDouble() ?? 0.0,
      keterangan: json['keterangan'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at'].toString()) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString()) 
          : null,
      // Related data from joins
      koleksiJudul: json['koleksi_judul'],
      koleksiPenulis: json['koleksi_penulis'],
      koleksiKategori: json['koleksi_kategori'],
      mahasiswaNama: json['mahasiswa_nama'],
      mahasiswaJurusan: json['mahasiswa_jurusan'],
      daysOverdue: json['days_overdue']?.toInt(),
      wasOverdueDays: json['was_overdue_days']?.toInt(),
    );
  }

  /// Convert ActivityModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_aktivitas': idAktivitas,
      'nrm_mahasiswa': nrmMahasiswa,
      'kode_koleksi': kodeKoleksi,
      'tgl_pinjam': tglPinjam.toIso8601String(),
      'tgl_kembali': tglKembali.toIso8601String(),
      'status': status,
      'tgl_dikembalikan': tglDikembalikan?.toIso8601String(),
      'denda': denda,
      'keterangan': keterangan,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // Related data
      'koleksi_judul': koleksiJudul,
      'koleksi_penulis': koleksiPenulis,
      'koleksi_kategori': koleksiKategori,
      'mahasiswa_nama': mahasiswaNama,
      'mahasiswa_jurusan': mahasiswaJurusan,
      'days_overdue': daysOverdue,
      'was_overdue_days': wasOverdueDays,
    };
  }

  /// Create ActivityModel from domain entity
  factory ActivityModel.fromEntity(Activity activity) {
    return ActivityModel(
      id: activity.id,
      idAktivitas: activity.idAktivitas,
      nrmMahasiswa: activity.nrmMahasiswa,
      kodeKoleksi: activity.kodeKoleksi,
      tglPinjam: activity.tglPinjam,
      tglKembali: activity.tglKembali,
      status: activity.status,
      tglDikembalikan: activity.tglDikembalikan,
      denda: activity.denda,
      keterangan: activity.keterangan,
      createdBy: activity.createdBy,
      updatedBy: activity.updatedBy,
      createdAt: activity.createdAt,
      updatedAt: activity.updatedAt,
      // Related data
      koleksiJudul: activity.koleksiJudul,
      koleksiPenulis: activity.koleksiPenulis,
      koleksiKategori: activity.koleksiKategori,
      mahasiswaNama: activity.mahasiswaNama,
      mahasiswaJurusan: activity.mahasiswaJurusan,
      daysOverdue: activity.daysOverdue,
      wasOverdueDays: activity.wasOverdueDays,
    );
  }

  /// Convert to domain entity
  Activity toEntity() {
    return Activity(
      id: id,
      idAktivitas: idAktivitas,
      nrmMahasiswa: nrmMahasiswa,
      kodeKoleksi: kodeKoleksi,
      tglPinjam: tglPinjam,
      tglKembali: tglKembali,
      status: status,
      tglDikembalikan: tglDikembalikan,
      denda: denda,
      keterangan: keterangan,
      createdBy: createdBy,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      // Related data
      koleksiJudul: koleksiJudul,
      koleksiPenulis: koleksiPenulis,
      koleksiKategori: koleksiKategori,
      mahasiswaNama: mahasiswaNama,
      mahasiswaJurusan: mahasiswaJurusan,
      daysOverdue: daysOverdue,
      wasOverdueDays: wasOverdueDays,
    );
  }
}