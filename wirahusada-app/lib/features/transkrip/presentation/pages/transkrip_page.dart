// lib/features/transkrip/presentation/pages/transkrip_page.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;
import 'package:wismon_keuangan/features/transkrip/domain/entities/transkrip.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_bloc.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_event.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/bloc/transkrip_state.dart';

// --- PERBAIKAN: Enum untuk kriteria dan arah pengurutan ---
enum SortCriterion { semester, kode, nama, sks }

enum SortDirection { ascending, descending }

class TranskripPage extends StatefulWidget {
  const TranskripPage({super.key});

  @override
  State<TranskripPage> createState() => _TranskripPageState();
}

class _TranskripPageState extends State<TranskripPage> {
  // --- PERBAIKAN UTAMA: Manajemen siklus hidup BLoC ---
  // BLoC diinisialisasi sekali saat state dibuat untuk mencegah pembuatan ulang pada setiap build.
  late final TranskripBloc _transkripBloc;

  // --- State untuk manajemen filter dan data ---
  List<Course> _originalCourses = [];
  List<Course> _sortedCourses = [];
  SortCriterion _currentSortCriterion =
      SortCriterion.semester; // Default sorting
  SortDirection _currentSortDirection = SortDirection.ascending;

  // --- FITUR BARU: Set untuk menyimpan kode mata kuliah yang diulang ---
  final Set<String> _repeatedCourseCodes = {};

  @override
  void initState() {
    super.initState();
    // --- PERBAIKAN UTAMA: Inisialisasi BLoC dan memuat data awal ---
    // Mengambil instance BLoC dari dependency injection.
    _transkripBloc = di.sl<TranskripBloc>();
    // Memanggil event untuk mengambil data transkrip.
    _transkripBloc.add(const FetchTranskrip());
  }

  @override
  void dispose() {
    // --- PERBAIKAN UTAMA: Membersihkan BLoC saat widget tidak lagi digunakan ---
    _transkripBloc.close();
    super.dispose();
  }

  // --- FUNGSI BARU: Untuk mengidentifikasi mata kuliah mana yang merupakan pengulangan ---
  void _identifyRepeatedCourses(List<Course> courses) {
    final counts = <String, int>{};
    // Hitung kemunculan setiap kode mata kuliah
    for (final course in courses) {
      counts[course.kodeMataKuliah] = (counts[course.kodeMataKuliah] ?? 0) + 1;
    }
    _repeatedCourseCodes.clear();
    // Jika sebuah kode MK muncul lebih dari sekali, tambahkan ke dalam set
    counts.forEach((key, value) {
      if (value > 1) {
        _repeatedCourseCodes.add(key);
      }
    });
  }

  // --- PERBAIKAN: Fungsi untuk melakukan pengurutan yang lebih aman ---
  void _sortCourses() {
    // Membuat salinan dari list original untuk diurutkan
    List<Course> coursesToSort = List.from(_originalCourses);

    coursesToSort.sort((a, b) {
      int compareResult;
      switch (_currentSortCriterion) {
        case SortCriterion.semester:
          // --- PERBAIKAN KESALAHAN PENGETIKAN: 'semesterKe' menjadi 'semesterke' ---
          compareResult = a.semesterKe.compareTo(b.semesterKe);
          // Jika semester sama, urutkan berdasarkan nama MK sebagai secondary sort
          if (compareResult == 0) {
            compareResult = a.namamk.compareTo(b.namamk);
          }
          break;
        case SortCriterion.kode:
          compareResult = a.kodeMataKuliah.compareTo(b.kodeMataKuliah);
          break;
        case SortCriterion.nama:
          compareResult = a.namamk.compareTo(b.namamk);
          break;
        case SortCriterion.sks:
          compareResult = (a.sks ?? 0).compareTo(b.sks ?? 0);
          break;
      }
      // Terapkan arah pengurutan
      return _currentSortDirection == SortDirection.ascending
          ? compareResult
          : -compareResult;
    });

    // Update state dengan list yang sudah diurutkan
    setState(() {
      _sortedCourses = coursesToSort;
    });
  }

  void _onSortChanged(SortCriterion criterion) {
    setState(() {
      if (_currentSortCriterion == criterion) {
        // Jika kriteria sama, balik arahnya
        _currentSortDirection = _currentSortDirection == SortDirection.ascending
            ? SortDirection.descending
            : SortDirection.ascending;
      } else {
        // Jika kriteria baru, set default ke ascending
        _currentSortCriterion = criterion;
        _currentSortDirection = SortDirection.ascending;
      }
      // Panggil fungsi sort setelah state diubah
      _sortCourses();
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- PERBAIKAN UTAMA: Menggunakan BlocProvider.value ---
    // Menyediakan instance BLoC yang sudah ada ke widget tree di bawahnya.
    return BlocProvider.value(
      value: _transkripBloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                // --- Menggunakan BlocListener untuk aksi sampingan seperti navigasi atau menampilkan SnackBar ---
                child: BlocListener<TranskripBloc, TranskripState>(
                  listener: (context, state) {
                    if (state is TranskripLoaded) {
                      // Hanya set data original saat data berhasil dimuat
                      setState(() {
                        _originalCourses = state.transkrip.courses;
                        // --- FITUR BARU: Identifikasi MK ulang sebelum mengurutkan ---
                        _identifyRepeatedCourses(_originalCourses);
                        _sortCourses(); // Lakukan pengurutan awal (default)
                      });
                    }

                    // --- FITUR BARU: Menampilkan notifikasi (SnackBar) saat usulan berhasil atau gagal ---
                    if (state is TranskripUpdateSuccess) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Status usulan berhasil diperbarui.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                    }
                    if (state is TranskripUpdateError) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('Gagal: ${state.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                    }
                  },
                  // --- Menggunakan BlocBuilder untuk membangun UI berdasarkan state BLoC ---
                  child: BlocBuilder<TranskripBloc, TranskripState>(
                    builder: (context, state) {
                      if (state is TranskripLoading &&
                          _originalCourses.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF135EA2),
                            ),
                          ),
                        );
                      } else if (state is TranskripLoaded) {
                        // Tampilkan konten menggunakan data yang sudah diurutkan
                        return _buildContent(context, state.transkrip);
                      } else if (state is TranskripError) {
                        return _buildErrorState(context, state.message);
                      }
                      // Tampilkan konten terakhir yang valid jika ada, atau loading
                      return _originalCourses.isNotEmpty
                          ? _buildContent(
                              context,
                              Transkrip(
                                ipk:
                                    '', // Placeholder, karena data utama ada di _originalCourses
                                totalSks: 0, // Placeholder
                                courses: _originalCourses,
                              ),
                            )
                          : const Center(
                              child: Text("Memuat data transkrip..."),
                            );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF135EA2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFB),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.chevron_left,
                  color: Color(0xFF121212),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
            const Text(
              'Transkrip Nilai',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFBFBFB),
                letterSpacing: -0.18,
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Transkrip transkrip) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(
                        transkrip,
                        _originalCourses,
                      ), // Summary tetap dari data original
                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFE7E7E7), height: 1),
                      const SizedBox(height: 20),
                      _buildFilterChips(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildCourseSliverList(_sortedCourses), // Virtualized list
            ],
          ),
        ),
        _buildDownloadButton(context),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Urutkan Berdasarkan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF121315),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSortChip(SortCriterion.semester, 'Semester'),
              _buildSortChip(SortCriterion.kode, 'Kode MK'),
              _buildSortChip(SortCriterion.nama, 'Nama MK'),
              _buildSortChip(SortCriterion.sks, 'SKS'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(SortCriterion criterion, String label) {
    final bool isActive = _currentSortCriterion == criterion;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        onPressed: () => _onSortChanged(criterion),
        backgroundColor: isActive ? const Color(0xFF135EA2) : Colors.grey[200],
        label: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Icon(
                _currentSortDirection == SortDirection.ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                size: 14,
                color: Colors.white,
              ),
            ],
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isActive ? const Color(0xFF135EA2) : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Gagal memuat data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Memanggil event untuk mencoba lagi menggunakan instance BLoC yang ada
              _transkripBloc.add(const FetchTranskrip());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF135EA2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Coba Lagi',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Transkrip transkrip, List<Course> allCourses) {
    final totalSks = allCourses.fold<int>(
      0,
      (sum, course) => sum + (course.sks ?? 0),
    );
    final totalBobot = allCourses.fold<double>(
      0.0,
      (sum, course) => sum + ((course.bobotNilai ?? 0) * (course.sks ?? 0)),
    );
    final ipk = totalSks > 0 ? totalBobot / totalSks : 0.0;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(title: 'Total SKS', value: totalSks.toString()),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Bobot',
            value: totalBobot.toStringAsFixed(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'IP Kumulatif',
            value: ipk.toStringAsFixed(2),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseSliverList(List<Course> courses) {
    if (courses.isEmpty) {
      return const SliverPadding(
        padding: EdgeInsets.all(32),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: Text(
              'Tidak ada data mata kuliah',
              style: TextStyle(fontSize: 14, color: Color(0xFF545556)),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            // Add header before first item
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTableHeader(),
                const SizedBox(height: 12),
                _CourseTile(
                  course: courses[0],
                  repeatedCourseCodes: _repeatedCourseCodes,
                  onProposeDeletion: (course) =>
                      _showProposeDeletionDialog(context, course),
                ),
              ],
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _CourseTile(
              course: courses[index],
              repeatedCourseCodes: _repeatedCourseCodes,
              onProposeDeletion: (course) =>
                  _showProposeDeletionDialog(context, course),
            ),
          );
        }, childCount: courses.length),
      ),
    );
  }

  // --- FUNGSI BARU: Menampilkan dialog konfirmasi untuk usulan hapus ---
  void _showProposeDeletionDialog(BuildContext context, Course course) {
    final isCurrentlyProposed = course.usulanHapus;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            isCurrentlyProposed
                ? 'Batalkan Usulan Hapus?'
                : 'Usulkan Penghapusan?',
          ),
          content: Text(
            'Mata kuliah ini akan ${isCurrentlyProposed ? 'dibatalkan dari daftar usulan' : 'diusulkan untuk'} dihapus oleh administrasi. Lanjutkan?',
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Ya, Lanjutkan'),
              onPressed: () {
                // --- PERUBAHAN: Memanggil event BLoC saat tombol ditekan ---
                // Menggunakan context.read karena BlocProvider ada di atas widget ini.
                context.read<TranskripBloc>().add(
                  ProposeDeletionToggled(courseToUpdate: course),
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 64,
            child: Text(
              'Semester',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Nama Matakuliah',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 37,
            child: Text(
              'SKS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 37,
            child: Text(
              'Nilai',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 37,
            child: Text(
              'Bobot',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // --- PERUBAHAN: Menambahkan header untuk kolom aksi ---
          const SizedBox(
            width: 48, // Lebar disesuaikan dengan IconButton
            child: Text(
              'Aksi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF024088),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBFBFB),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      child: ElevatedButton(
        onPressed: () => _showDownloadModal(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF135EA2),
          foregroundColor: const Color(0xFFFBFBFB),
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: const Text(
          'Download Transkrip Nilai',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.16,
          ),
        ),
      ),
    );
  }

  void _showDownloadModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Column(
                    children: [
                      Text(
                        'Download Transkrip Nilai',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF121212),
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Apakah Anda yakin untuk download\ntranskrip nilai Anda?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF545556),
                          letterSpacing: -0.14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF858586),
                            foregroundColor: const Color(0xFFFBFBFB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Kembali',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Fitur download sedang dalam pengembangan',
                                ),
                                backgroundColor: Color(0xFF135EA2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF135EA2),
                            foregroundColor: const Color(0xFFFBFBFB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: const Text(
                            'Download',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1C1D1F),
                letterSpacing: -0.12,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121212),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

// --- PERUBAHAN: Modifikasi _CourseTile untuk menerima data dan menampilkan tombol ---
class _CourseTile extends StatelessWidget {
  final Course course;
  final Set<String> repeatedCourseCodes;
  final Function(Course) onProposeDeletion;

  const _CourseTile({
    required this.course,
    required this.repeatedCourseCodes,
    required this.onProposeDeletion,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRepeated = repeatedCourseCodes.contains(course.kodeMataKuliah);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: course.usulanHapus ? Colors.red.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                // --- PERBAIKAN KESALAHAN PENGETIKAN: 'semesterKe' menjadi 'semesterke' ---
                course.semesterKe.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1D1F),
                  letterSpacing: -0.14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.namamk,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1C1D1F),
                    letterSpacing: -0.12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _InfoChip(
                      text: course.kurikulum,
                      backgroundColor: const Color(0xFF135EA2),
                      textColor: const Color(0xFFFBFBFB),
                    ),
                    const SizedBox(width: 4),
                    _InfoChip(
                      text: course.kodeMataKuliah,
                      backgroundColor: const Color(0xFFA6DCFF),
                      textColor: const Color(0xFF121212),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 37,
                child: Text(
                  (course.sks ?? 0).toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF121212),
                    letterSpacing: -0.14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 37,
                child: Text(
                  course.nilai ?? '-',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF121212),
                    letterSpacing: -0.14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 37,
                child: Text(
                  (course.bobotNilai ?? 0).toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF121212),
                    letterSpacing: -0.14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // --- FITUR BARU: Menampilkan tombol usulan hapus ---
              SizedBox(
                width: 48, // Lebar disesuaikan dengan header
                child: isRepeated
                    ? IconButton(
                        icon: Icon(
                          course.usulanHapus
                              ? Icons.undo
                              : Icons.delete_outline,
                          color: course.usulanHapus
                              ? Colors.orange
                              : Colors.red,
                          size: 20,
                        ),
                        onPressed: () => onProposeDeletion(course),
                        tooltip: course.usulanHapus
                            ? 'Batalkan usulan hapus'
                            : 'Usulkan untuk dihapus',
                      )
                    : null, // Tidak menampilkan tombol jika bukan MK ulang
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;

  const _InfoChip({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 1,
          height: 16 / 9,
        ),
      ),
    );
  }
}
