// lib/features/khs/presentation/pages/khs_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/core/services/api_service.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../domain/entities/khs.dart';
import '../bloc/khs_bloc.dart';

enum SemesterType { reguler, pendek }

class KhsPage extends StatelessWidget {
  const KhsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<KhsBloc>(),
      child: const KhsView(),
    );
  }
}

class KhsView extends StatefulWidget {
  const KhsView({super.key});

  @override
  State<KhsView> createState() => _KhsViewState();
}

class _KhsViewState extends State<KhsView> {
  int? _selectedSemester;
  int _latestSemesterForStudent = 1;
  bool _isLoadingSemester = true;
  String? _errorSemester;
  Khs? _lastLoadedKhs;
  SemesterType _selectedType = SemesterType.reguler;

  @override
  void initState() {
    super.initState();
    _fetchLatestSemester();
  }

  int _getJenisSemesterCode() {
    if (_selectedSemester == null) return 1;
    final bool isEven = _selectedSemester! % 2 == 0;
    if (_selectedType == SemesterType.reguler) {
      return isEven ? 2 : 1;
    } else {
      return isEven ? 4 : 5;
    }
  }

  void _fetchData() {
    if (_selectedSemester == null) return;
    // Reset data sebelumnya agar tidak tampil saat data baru belum ada
    setState(() {
      _lastLoadedKhs = null;
    });
    context.read<KhsBloc>().add(
      FetchKhsData(
        semesterKe: _selectedSemester!,
        jenisSemester: _getJenisSemesterCode(),
      ),
    );
  }

  Future<void> _fetchLatestSemester() async {
    try {
      final apiService = di.sl<ApiService>();
      final response = await apiService.get('/api/akademik/mahasiswa/info');
      if (mounted && response['success'] == true) {
        setState(() {
          _latestSemesterForStudent = response['data']['semester'] ?? 1;
          // --- PERUBAHAN DI SINI ---
          // Mengatur semester yang dipilih menjadi 1 (semester awal).
          _selectedSemester = 1;
          _isLoadingSemester = false;
        });
        _fetchData();
      } else {
        throw Exception(response['message'] ?? 'Gagal mengambil data semester');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorSemester = e.toString().replaceAll('Exception: ', '');
          _isLoadingSemester = false;
        });
      }
    }
  }

  void _onSemesterChanged(int newSemester) {
    if (_selectedSemester == newSemester) return;
    setState(() {
      _selectedSemester = newSemester;
    });
    _fetchData();
  }

  void _onTypeChanged(SemesterType newType) {
    if (_selectedType == newType) return;
    setState(() {
      _selectedType = newType;
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigator(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
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
              decoration: ShapeDecoration(
                color: const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF135EA2)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Text(
              'Kartu Hasil Studi',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFAFAFA),
                fontSize: 18,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 40), // Spacer
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoadingSemester) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorSemester != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('Error: $_errorSemester', textAlign: TextAlign.center),
        ),
      );
    }
    return Column(
      children: [
        _buildFilterSection(),
        Expanded(
          child: BlocListener<KhsBloc, KhsState>(
            listener: (context, state) {
              if (state is KhsLoaded) {
                setState(() => _lastLoadedKhs = state.khs);
              } else if (state is KhsError) {
                // Saat error, pastikan data lama dibersihkan
                setState(() {
                  _lastLoadedKhs = null;
                });
              }
            },
            child: BlocBuilder<KhsBloc, KhsState>(
              builder: (context, state) {
                if (state is KhsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is KhsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(state.message, textAlign: TextAlign.center),
                    ),
                  );
                }
                if (state is KhsLoaded && state.khs.mataKuliah.isNotEmpty) {
                  return _buildKhsContent(context, state.khs);
                }
                // Tampilan jika tidak ada data atau setelah error
                return const Center(
                  child: Text("Tidak ada data KHS untuk semester ini."),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomNavigator() {
    if (!_isLoadingSemester && _selectedSemester != null) {
      return _SemesterNavigator(
        currentSemester: _selectedSemester!,
        maxSemester: _latestSemesterForStudent,
        onNavigate: _onSemesterChanged,
      );
    }
    return null;
  }

  Widget _buildFilterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SemesterFilter(
            latestSemester: _latestSemesterForStudent,
            selectedSemester: _selectedSemester,
            onChanged: (newVal) {
              if (newVal != null) _onSemesterChanged(newVal);
            },
          ),
          const SizedBox(height: 12),
          _SemesterTypeSelector(
            selectedType: _selectedType,
            onChanged: _onTypeChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildKhsContent(BuildContext context, Khs khs) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 24),
          sliver: SliverToBoxAdapter(
            child: _RekapitulasiCard(rekap: khs.rekapitulasi),
          ),
        ),
        _MataKuliahSliverList(courses: khs.mataKuliah),
        const SliverPadding(
          padding: EdgeInsets.only(
            bottom: 80.0,
          ), // Bottom padding for navigation
        ),
      ],
    );
  }
}

class _SemesterTypeSelector extends StatelessWidget {
  final SemesterType selectedType;
  final ValueChanged<SemesterType> onChanged;

  const _SemesterTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: const Color(0xFFF3F3F3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              context,
              'Reguler',
              SemesterType.reguler,
              selectedType == SemesterType.reguler,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _buildTypeButton(
              context,
              'Pendek',
              SemesterType.pendek,
              selectedType == SemesterType.pendek,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    String title,
    SemesterType type,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => onChanged(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 32,
        decoration: ShapeDecoration(
          color: isSelected ? const Color(0xFFFAFAFA) : const Color(0xFFF3F3F3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          shadows: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF1C1D1F)
                  : const Color(0xFF858586),
              fontSize: 14,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.14,
            ),
          ),
        ),
      ),
    );
  }
}

class _SemesterFilter extends StatelessWidget {
  final int? selectedSemester;
  final int latestSemester;
  final Function(int?) onChanged;

  const _SemesterFilter({
    this.selectedSemester,
    required this.latestSemester,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final List<int> semesters = List.generate(
      latestSemester,
      (index) => index + 1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Semester',
          style: TextStyle(
            color: Color(0xFF1C1D1F),
            fontSize: 14,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w500,
            letterSpacing: -0.14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: selectedSemester,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          items: semesters.map((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(
                'Semester $value',
                style: const TextStyle(
                  color: Color(0xFF545556),
                  fontSize: 14,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.14,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SemesterNavigator extends StatelessWidget {
  final int currentSemester;
  final int maxSemester;
  final Function(int) onNavigate;

  const _SemesterNavigator({
    required this.currentSemester,
    required this.maxSemester,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final bool canGoBack = currentSemester > 1;
    final bool canGoForward = currentSemester < maxSemester;

    if (maxSemester <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            context: context,
            icon: Icons.chevron_left,
            text: 'Sebelumnya',
            isEnabled: canGoBack,
            onPressed: () => onNavigate(currentSemester - 1),
            isPrefix: true,
          ),
          Text(
            'Semester $currentSemester',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          _buildNavButton(
            context: context,
            icon: Icons.chevron_right,
            text: 'Berikutnya',
            isEnabled: canGoForward,
            onPressed: () => onNavigate(currentSemester + 1),
            isPrefix: false,
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    required bool isEnabled,
    required VoidCallback onPressed,
    bool isPrefix = false,
  }) {
    final color = isEnabled
        ? Theme.of(context).primaryColor
        : Colors.grey.withOpacity(0.5);
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        children: [
          if (isPrefix) Icon(icon, color: color),
          if (isPrefix) const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
          if (!isPrefix) const SizedBox(width: 4),
          if (!isPrefix) Icon(icon, color: color),
        ],
      ),
    );
  }
}

class _RekapitulasiCard extends StatelessWidget {
  final Rekapitulasi rekap;
  const _RekapitulasiCard({required this.rekap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _RekapItem(
                title: "IP Lulus/Beban",
                value: rekap.ipSemester,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _RekapItem(
                title: "IP Kumulatif Lulus/Beban",
                value: rekap.ipKumulatif,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _RekapItem(
                title: "SKS Lulus/Beban",
                value: rekap.sksSemester,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _RekapItem(
                title: "SKS Kumulatif Lulus/Beban",
                value: rekap.sksKumulatif,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RekapItem extends StatelessWidget {
  final String title;
  final String value;
  const _RekapItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Text(
              title,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            width: double.infinity,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _MataKuliahSliverList extends StatelessWidget {
  final List<KhsCourse> courses;
  const _MataKuliahSliverList({required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox.shrink(), // Don't show anything if no courses
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MataKuliahTile(course: courses[index]),
          );
        }, childCount: courses.length),
      ),
    );
  }
}

class _MataKuliahTile extends StatelessWidget {
  final KhsCourse course;
  const _MataKuliahTile({required this.course});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Center(
                child: Text(
                  course.nilai,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.namaMataKuliah,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      _InfoChip(text: '${course.sks} SKS'),
                      _InfoChip(text: course.kodeMataKuliah),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  const _InfoChip({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF135EA2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
