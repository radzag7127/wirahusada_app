import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wismon_keuangan/features/auth/presentation/bloc/auth_state.dart';
import 'package:wismon_keuangan/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
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
          // Mountain peaks background anchored to bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height:
                MediaQuery.of(context).size.height * 1, // 100% of screen height
            child: RepaintBoundary(
              child: ClipRect(
                child: Transform.translate(
                  offset: const Offset(
                    0,
                    400,
                  ), // Push bottom part below visible area
                  child: SvgPicture.asset(
                    'assets/logo-whn-profil.svg',
                    width: MediaQuery.of(context).size.width,
                    height:
                        MediaQuery.of(context).size.width *
                        (391 / 402), // Maintain aspect ratio
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: BlocBuilder<AuthBloc, AuthState>(
                    buildWhen: (previous, current) {
                      // Only rebuild when auth state changes
                      return previous.runtimeType != current.runtimeType;
                    },
                    builder: (context, state) {
                      if (state is AuthAuthenticated) {
                        return _buildProfileContent(context, state.user);
                      }
                      if (state is AuthError) {
                        return _buildErrorState(context, state.message);
                      }
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF135EA2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
              'Profil',
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
                onPressed: () {
                  _navigateToSettings(context);
                },
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

  Widget _buildErrorState(BuildContext context, String message) {
    return RepaintBoundary(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat profil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Retry loading profile
                  context.read<AuthBloc>().add(const CheckAuthStatusEvent());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF207BB5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, dynamic user) {
    // Add null safety checks
    if (user == null) {
      return _buildErrorState(context, 'Data profil tidak tersedia');
    }

    return RepaintBoundary(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileCard(context, user),
            const SizedBox(height: 20),
            _buildInfoGrid(user),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic user) {
    
    // Safe access to user properties with fallbacks
    final userName = _safeGetString(user.namam) ?? 'Nama tidak tersedia';
    final birthPlace = _safeGetString(user.tplahir) ?? '';
    final registrationDate = _formatDate(_safeGetString(user.tgdaftar)) ?? '';

    String locationInfo = '';
    if (birthPlace.isNotEmpty && registrationDate.isNotEmpty) {
      locationInfo = '$birthPlace • Terdaftar $registrationDate';
    } else if (birthPlace.isNotEmpty) {
      locationInfo = 'Tempat Lahir: $birthPlace';
    } else if (registrationDate.isNotEmpty) {
      locationInfo = 'Terdaftar: $registrationDate';
    } else {
      locationInfo = 'Informasi tidak tersedia';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF207BB5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF121212),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  locationInfo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF545556),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(dynamic user) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoBox('NRM', _safeGetString(user.nrm) ?? '-'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildInfoBox('NIM', _safeGetString(user.nim) ?? 'Belum tersedia'),
        const SizedBox(height: 8),
        _buildInfoBox('Email', _safeGetString(user.email) ?? 'Belum diatur'),
        const SizedBox(height: 8),
        _buildInfoBox(
          'No. Telepon',
          _safeGetString(user.phone) ?? 'Belum diatur',
        ),
        const SizedBox(height: 8),
        _buildInfoBox(
          'Tempat Lahir',
          _safeGetString(user.tplahir) ?? 'Belum diatur',
        ),
        const SizedBox(height: 8),
        _buildInfoBox(
          'Tanggal Daftar',
          _formatDate(_safeGetString(user.tgdaftar)) ?? 'Belum tersedia',
        ),
      ],
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1D1F),
            ),
          ),
          const Divider(height: 8, color: Color(0xFFE7E7E7)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1C1D1F),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Helper method to safely get string values
  String? _safeGetString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString().isEmpty ? null : value.toString();
  }

  // Helper method to format date strings
  String? _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    
    try {
      DateTime dateTime = DateTime.parse(dateString);
      // Format as DD/MM/YYYY
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      // If parsing fails, return the original string
      return dateString;
    }
  }
}
