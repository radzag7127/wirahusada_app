import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LoginForm();
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    // Hide keyboard
    FocusScope.of(context).unfocus();
    // Dispatch event with same parameter names for backend compatibility
    context.read<AuthBloc>().add(
      LoginRequestedEvent(
        namamNim: _usernameController.text, // Using username field for nama/nim
        nrm: _passwordController.text, // Using password field for nrm
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (kDebugMode) {
          print('📱 [LoginPage] BlocListener received state: ${state.runtimeType}');
        }
        
        if (state is AuthError) {
          if (kDebugMode) {
            print('❌ [LoginPage] Showing error: ${state.message}');
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
        } else if (state is AuthAuthenticated) {
          if (kDebugMode) {
            print('✅ [LoginPage] User authenticated! Navigating to main...');
            print('👤 [LoginPage] User: ${state.user.namam}');
          }
          // Navigate to main app when authentication is successful
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/main',
            (route) => false, // Remove all previous routes
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              _buildHeader(),
              // Form Content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 56), // Space from header
                        _buildInputFields(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
              // Bottom Button
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          Container(
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
                    color: Color(0xFF121315),
                  ),
                ),
              ),
            ),
          ),
          // Title
          const Text(
            'Masuk ke Aplikasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF121111),
              fontSize: 24,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w800,
              letterSpacing: -0.24,
            ),
          ),
          // Spacer (same width as back button)
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        // Username Field
        _buildInputField(
          label: 'Username atau Email',
          controller: _usernameController,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 24),
        // Password Field
        _buildInputField(
          label: 'Kata Sandi',
          controller: _passwordController,
          obscureText: true,
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1C1D1F),
            fontSize: 12,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w500,
            letterSpacing: -0.12,
          ),
        ),
        const SizedBox(height: 8),
        // Input Container
        Container(
          constraints: const BoxConstraints(
            minHeight: 40,
            maxHeight: 56,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFBFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCECECF), width: 1),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: Color(0xFF1C1D1F),
              fontSize: 14,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              letterSpacing: -0.14,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              return ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  maxHeight: 56,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                  onPressed: isLoading ? null : _onLoginPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135EA2),
                    disabledBackgroundColor: const Color(
                      0xFF135EA2,
                    ).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Masuk Sekarang',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFF3F3F3),
                            letterSpacing: -0.16,
                          ),
                        ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
