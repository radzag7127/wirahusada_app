import 'package:flutter/material.dart';
import 'package:wismon_keuangan/features/payment/presentation/pages/wismon_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../settings/presentation/pages/settings_page.dart';

// IMPORT UNTUK FITUR KRS
import 'package:wismon_keuangan/features/krs/presentation/pages/krs_page.dart';

//IMPORT UNTUK TRANSKRIP
import 'package:wismon_keuangan/features/transkrip/presentation/pages/transkrip_page.dart';

//IMPORT UNTUK KHS
import 'package:wismon_keuangan/features/khs/presentation/pages/khs_page.dart';

// IMPORT UNTUK PERPUSTAKAAN
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/library_menu_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep page alive when switching tabs

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Responsive positioned logo background
          Positioned(
            right: MediaQuery.of(context).size.width * 0.15,
            bottom: MediaQuery.of(context).size.height * 0.2,
            child: RepaintBoundary(
              child: Opacity(
                opacity: 1,
                child: Transform.scale(
                  scale: MediaQuery.of(context).size.width / 100,
                  child: SvgPicture.asset(
                    'assets/logo-whn-menu-aplikasi.svg',
                    width: MediaQuery.of(context).size.width * 0.8,
                    height:
                        MediaQuery.of(context).size.width * 0.8 * (185 / 300),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(child: _buildMenuItems(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Menu Aplikasi',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF121212),
                letterSpacing: -0.24,
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
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
                onPressed: () => _navigateToSettings(context),
                icon: const Icon(
                  Icons.settings,
                  color: Color(0xFF121212),
                  size: 20,
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
  }

  Widget _buildMenuItems(BuildContext context) {
    return RepaintBoundary(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 4),
            _buildMenuItem(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              title: 'Biaya Kuliah',
              subtitle: 'Detail biaya kuliah Anda.',
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const WismonPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 200),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // =================================================================
            // REVISI LOGIKA onTap UNTUK TRANSKRIP
            // =================================================================
            _buildMenuItem(
              context: context,
              icon: Icons.description_outlined,
              title: 'Transkrip Nilai',
              subtitle: 'Dokumen resmi riwayat akademik lengkap Anda.',
              onTap: () {
                // Navigasi ke TranskripPage tidak lagi memerlukan NRM
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TranskripPage()),
                );
              },
            ),
            const SizedBox(height: 16),

            // --- PERBAIKAN DI SINI ---
            _buildMenuItem(
              context: context,
              icon: Icons.folder_open_outlined,
              title: 'Kartu Hasil Studi (KHS)',
              subtitle: 'Lihat nilai dan progres akademik Anda dengan mudah.',
              onTap: () {
                // Mengarahkan ke halaman KHS
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KhsPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            // --- PERUBAHAN UNTUK FITUR KRS ---
            // Logika onTap diubah untuk menangani navigasi ke halaman KRS.
            _buildMenuItem(
              context: context,
              icon: Icons.edit_note_outlined,
              title: 'Kartu Rencana Studi (KRS)',
              subtitle: 'Rencanakan dan pilih mata kuliah selama perkuliahan.',
              onTap: () {
                // Navigasi ke halaman KRS yang baru
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KrsPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context: context,
              icon: Icons.calendar_today_outlined,
              title: 'Presensi Kelas',
              subtitle: 'Catat kehadiran Anda di setiap sesi perkuliahan.',
              onTap: () {
                _showComingSoonSnackBar(context, 'Presensi Kelas');
              },
            ),
            const SizedBox(height: 16),
            _buildMenuItem(
              context: context,
              icon: Icons.public_outlined,
              title: 'Layanan Perpustakaan',
              subtitle: 'Akses berbagai sumber daya akademik.',
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LibraryMenuPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: animation,
                        child: child,
                      );
                        },
                    transitionDuration: const Duration(milliseconds: 200),
                  ),
                );
              },
            ),
            const SizedBox(height: 20), // Extra padding at bottom
          ],
        ),
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName akan segera tersedia'),
        backgroundColor: const Color(0xFF207BB5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            splashColor: const Color(0xFF207BB5).withOpacity(0.1),
            highlightColor: const Color(0xFF207BB5).withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFCECECF),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(icon, color: const Color(0xFF121212), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C1D1F),
                            letterSpacing: -0.14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF545556),
                            letterSpacing: -0.12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
