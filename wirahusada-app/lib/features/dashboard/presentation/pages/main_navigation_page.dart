import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wismon_keuangan/features/auth/presentation/bloc/auth_state.dart';
import 'package:wismon_keuangan/features/dashboard/presentation/pages/beranda_page.dart';
import 'package:wismon_keuangan/features/menu/presentation/pages/menu_page.dart';
import 'package:wismon_keuangan/features/profile/presentation/pages/profile_page.dart';
import 'package:wismon_keuangan/features/dashboard/presentation/bloc/beranda_bloc.dart';
import 'package:wismon_keuangan/features/dashboard/presentation/bloc/beranda_event.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_event.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late PageController _pageController;
  int _selectedIndex = 0;
  int _previousIndex = 0; // Track previous tab for detecting changes

  // Pre-create pages to avoid recreation and enable caching
  late final List<Widget> _pages = [
    const BerandaPage(),
    const MenuPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _selectedIndex,
      keepPage: true, // Keep pages in memory
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      // Store previous index before updating
      _previousIndex = _selectedIndex;
      
      setState(() {
        _selectedIndex = index;
      });
      
      // Handle tab change logic: refresh data when switching TO Beranda tab (index 0)
      if (index == 0 && _previousIndex != 0) {
        // User switched to Beranda tab from another tab - refresh dashboard
        _refreshBerandaAfterTabChange();
      }
      
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    }
  }
  
  /// Refresh Beranda dashboard when user switches back from other tabs
  void _refreshBerandaAfterTabChange() {
    try {
      // Refresh both Beranda data and Payment data to reflect any customizations
      context.read<BerandaBloc>().add(const RefreshBerandaDataEvent());
    } catch (e) {
      // Handle any BLoC access errors gracefully - BerandaBloc may not be available yet
      debugPrint('BerandaBloc not available for refresh after tab change: $e');
    }
    
    try {
      // Load payment summary after tab switch
      context.read<PaymentBloc>().add(const LoadPaymentSummaryEvent());
    } catch (e) {
      // Handle any BLoC access errors gracefully - PaymentBloc may not be available yet
      debugPrint('PaymentBloc not available for refresh after tab change: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is AuthAuthenticated) {
          return Scaffold(
            body: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                // Handle page swiping - same logic as tab tapping
                if (_selectedIndex != index) {
                  _previousIndex = _selectedIndex;
                  
                  setState(() {
                    _selectedIndex = index;
                  });
                  
                  // Handle refresh when swiping TO Beranda tab (index 0)
                  if (index == 0 && _previousIndex != 0) {
                    _refreshBerandaAfterTabChange();
                  }
                }
              },
              // Add smoother physics for better transitions
              physics: const ClampingScrollPhysics(),
              children: _pages,
            ),
            bottomNavigationBar: _buildBottomNavigationBar(),
          );
        }
        
        // When user is unauthenticated (logged out), reset BerandaBloc
        if (state is AuthUnauthenticated) {
          try {
            // Reset BerandaBloc user context
            context.read<BerandaBloc>().updateCurrentUser(null);
          } catch (e) {
            // Handle any BLoC access errors gracefully - BerandaBloc may not be available
            debugPrint('BerandaBloc not available for logout reset: $e');
          }
        }

        return const Center(child: Text('Loading...'));
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE7E7E7), width: 1)),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF121212),
        unselectedItemColor: const Color(0xFF858586),
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.12,
        ),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home_outlined, size: 24),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.home, size: 24),
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.menu, size: 24),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.menu, size: 24),
            ),
            label: 'Menu',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.person_outline, size: 24),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(Icons.person, size: 24),
            ),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Beranda Page (Work in Progress)')),
    );
  }
}
