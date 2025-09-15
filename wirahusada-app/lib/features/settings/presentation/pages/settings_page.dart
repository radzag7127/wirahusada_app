import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../widgets/logout_confirmation_dialog.dart';
import '../widgets/settings_menu_item.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _appVersion = '1.0.0 indev'; // Fallback version

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = 'WHN Mobile versi : ${packageInfo.version}';
        });
      }
    } catch (e) {
      // Keep fallback version if package info fails
      if (mounted) {
        setState(() {
          _appVersion = 'WHN Mobile versi : 1.0.0 indev';
        });
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => LogoutConfirmationDialog(
        onConfirmLogout: () {
          Navigator.of(context).pop(); // Close dialog
          context.read<AuthBloc>().add(const LogoutRequestedEvent());
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Only listen when transitioning to unauthenticated from any other state
        return current is AuthUnauthenticated && 
               previous is! AuthUnauthenticated &&
               previous is! AuthInitial;
      },
      listener: (context, state) {
        // When logout is successful, navigate to login
        if (state is AuthUnauthenticated) {
          // Use Navigator.pushNamedAndRemoveUntil to ensure clean navigation stack
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildAppDescriptionCard(),
                        const SizedBox(height: 20),
                        _buildDivider(),
                        const SizedBox(height: 20),
                        _buildMenuItems(),
                      ],
                    ),
                  ),
                ),
              ),
              // Version Info
              _buildVersionInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
            // Back Button
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFB),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.of(context).pop(),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_left,
                      size: 24,
                      color: Color(0xFF121212),
                    ),
                  ),
                ),
              ),
            ),
            // Title
            const Text(
              'Pengaturan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFAFAFA),
                fontSize: 18,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
                letterSpacing: -0.18,
              ),
            ),
            // Spacer (same width as back button)
            const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAppDescriptionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Aplikasi WHN Mobile adalah sebuah aplikasi sistem informasi layanan terpadu yang memberikan kemudahan akses akan informasi dan layanan bagi seluruh pengguna layanan Sistem Informasi Wira Husada Nusantara yang menggunakan perangkat mobile.',
          textAlign: TextAlign.justify,
          style: TextStyle(
            color: Color(0xFF323335),
            fontSize: 12,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w500,
            letterSpacing: -0.12,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      color: const Color(0xFFE7E7E7),
    );
  }

  Widget _buildMenuItems() {
    return Column(
      children: [
        // Check Update - Disabled
        SettingsMenuItem(
          icon: Icons.update,
          title: 'Cek Update Aplikasi',
          isEnabled: false,
          onTap: null,
        ),
        const SizedBox(height: 12),
        // Logout - Active
        SettingsMenuItem(
          icon: Icons.logout,
          title: 'Keluar Akun',
          isEnabled: true,
          titleColor: const Color(0xFF207BB5),
          iconColor: const Color(0xFF207BB5),
          onTap: _showLogoutDialog,
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        _appVersion,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF323335),
          fontSize: 14,
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w500,
          letterSpacing: -0.14,
        ),
      ),
    );
  }
}
