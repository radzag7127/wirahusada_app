import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;
import 'package:wismon_keuangan/core/services/dashboard_preferences_service.dart';
import 'package:wismon_keuangan/core/services/api_service.dart';
import 'package:wismon_keuangan/features/payment/presentation/pages/wismon_page.dart';
import 'package:wismon_keuangan/features/transkrip/presentation/pages/transkrip_page.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_event.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_state.dart';
import 'package:wismon_keuangan/features/payment/presentation/components/payment_summary_card.dart';
import 'package:wismon_keuangan/features/payment/domain/entities/payment.dart';
import 'package:wismon_keuangan/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:wismon_keuangan/features/auth/presentation/bloc/auth_state.dart';
import '../bloc/beranda_bloc.dart';
import '../bloc/beranda_event.dart';
import '../bloc/beranda_state.dart';
import '../../domain/entities/beranda.dart';
import '../../../settings/presentation/pages/settings_page.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin, RouteAware {
  final PageController _carouselController = PageController();
  int _currentCarouselIndex = 0;
  Timer? _carouselTimer;
  
  // Payment preferences for filtering
  late final DashboardPreferencesService _preferencesService;
  List<String>? _cachedSelectedTypes;
  bool _preferencesLoaded = false;
  
  // Cross-tab communication for dashboard changes
  StreamSubscription<DashboardChangeEvent>? _dashboardChangeSubscription;
  
  // RADICAL SOLUTION: Direct API fallback variables
  PaymentSummary? _directApiPaymentSummary;
  bool _directApiLoading = false;
  String? _directApiError;
  Timer? _paymentPollingTimer;
  int _paymentLoadAttempts = 0;
  static const int maxPaymentLoadAttempts = 5;
  
  // STARTUP FIX: Track first startup to prevent over-aggressive loading
  bool _isFirstStartup = true;
  bool _berandaDataLoaded = false;
  Timer? _startupDelayTimer;

  @override
  bool get wantKeepAlive => true; // Keep page alive when switching tabs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preferencesService = di.sl<DashboardPreferencesService>();
    _loadPreferences();
    _setupDashboardChangeListener();
    
    // STARTUP FIX: Load beranda data first, then payments with delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startupSequence();
    });
  }
  
  /// Set up listener for cross-tab dashboard customization changes
  void _setupDashboardChangeListener() {
    _dashboardChangeSubscription = DashboardPreferencesService.changeStream.listen(
      (DashboardChangeEvent event) {
        if (mounted) {
          // Dashboard preferences changed from another screen
          // Refresh preferences cache and payment data immediately
          _loadPreferences();
          try {
            context.read<PaymentBloc>().add(const LoadPaymentSummaryEvent());
          } catch (e) {
            debugPrint('PaymentBloc not available for dashboard change refresh: $e');
          }
        }
      },
      onError: (error) {
        debugPrint('Error listening to dashboard changes: $error');
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? currentRoute = ModalRoute.of(context);
    if (currentRoute is PageRoute) {
      di.sl<RouteObserver<PageRoute>>().subscribe(this, currentRoute);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    di.sl<RouteObserver<PageRoute>>().unsubscribe(this);
    _carouselTimer?.cancel();
    _paymentPollingTimer?.cancel(); // RADICAL SOLUTION: Cancel polling timer
    _startupDelayTimer?.cancel(); // STARTUP FIX: Cancel startup timer
    _carouselController.dispose();
    _dashboardChangeSubscription?.cancel(); // Clean up stream subscription
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint('🔥 RADICAL: didPopNext - user returned to beranda');
    
    // Refresh data when returning from other pages (like customization page)
    try {
      context.read<BerandaBloc>().add(const RefreshBerandaDataEvent());
    } catch (e) {
      debugPrint('BerandaBloc not available for refresh on didPopNext: $e');
    }
    
    // STARTUP FIX: No longer first startup, use normal loading
    _isFirstStartup = false;
    
    // RADICAL SOLUTION: Aggressively reload payment data when returning
    _triggerAggressivePaymentLoad('didPopNext');
    
    // Refresh preferences cache when returning from customization
    _loadPreferences();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _startCarouselTimer();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _stopCarouselTimer();
        break;
      case AppLifecycleState.detached:
        _stopCarouselTimer();
        break;
      case AppLifecycleState.hidden:
        _stopCarouselTimer();
        break;
    }
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_carouselController.hasClients) {
        final nextIndex =
            (_currentCarouselIndex + 1) %
            3; // 3 dummy announcements - loops back to start
        _carouselController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _stopCarouselTimer() {
    _carouselTimer?.cancel();
  }
  
  Future<void> _loadPreferences() async {
    try {
      final types = await _preferencesService.getSelectedPaymentTypes();
      if (mounted) {
        setState(() {
          _cachedSelectedTypes = types;
          _preferencesLoaded = true;
        });
      }
    } catch (e) {
      // Handle error gracefully, use defaults
      if (mounted) {
        setState(() {
          _cachedSelectedTypes = DashboardPreferencesService.defaultPaymentTypes;
          _preferencesLoaded = true;
        });
      }
    }
  }

  Future<void> _openArticleUrl(String? articleUrl) async {
    if (articleUrl == null || articleUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link artikel tidak tersedia'),
          backgroundColor: Color(0xFF135EA2),
        ),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(articleUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $articleUrl');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka link: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getServiceIcon(String serviceId) {
    switch (serviceId) {
      case 'repository':
        return Icons.library_books;
      case 'jurnal_whn':
        return Icons.article;
      case 'e_library':
        return Icons.account_balance;
      case 'e_resources':
        return Icons.computer;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return MultiBlocListener(
        listeners: [
          // Listen to auth state changes for post-login refresh
          BlocListener<AuthBloc, AuthState>(
            listener: (context, authState) {
              if (authState is AuthAuthenticated) {
                debugPrint('🔥 RADICAL: User authenticated - triggering startup sequence');
                // User just logged in successfully - refresh all data
                try {
                  context.read<BerandaBloc>().add(const RefreshBerandaDataEvent());
                  // Update current user context in BerandaBloc
                  context.read<BerandaBloc>().updateCurrentUser(authState.user.nrm);
                } catch (e) {
                  debugPrint('BerandaBloc not available for auth state change: $e');
                }
                
                // STARTUP FIX: Reset first startup flag and use startup sequence
                _isFirstStartup = true;
                _berandaDataLoaded = false;
                _startupSequence();
                
                // Also refresh preferences cache
                _loadPreferences();
              } else if (authState is AuthUnauthenticated) {
                debugPrint('🔥 RADICAL: User unauthenticated - stopping payment polling');
                // User logged out - reset BerandaBloc user context
                try {
                  context.read<BerandaBloc>().updateCurrentUser(null);
                } catch (e) {
                  debugPrint('BerandaBloc not available for logout reset: $e');
                }
                _stopPaymentPolling();
                _isFirstStartup = true; // Reset for next login
                _berandaDataLoaded = false;
              }
            },
          ),
        ],
        child: Scaffold(
          backgroundColor: const Color(0xFFFBFBFB),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: BlocBuilder<BerandaBloc, BerandaState>(
                    builder: (context, state) {
                      // STARTUP FIX: Always show initial loading on first startup
                      if ((state is BerandaLoading || state is BerandaInitial) && _isFirstStartup) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF135EA2),
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Memuat data...',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (state is BerandaLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF135EA2),
                            ),
                          ),
                        );
                      } else if (state is BerandaError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  state.message,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  try {
                                    context.read<BerandaBloc>().add(
                                      const RefreshBerandaDataEvent(),
                                    );
                                  } catch (e) {
                                    debugPrint('BerandaBloc not available for retry: $e');
                                  }
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (state is BerandaLoaded) {
                        // STARTUP FIX: Mark beranda data as loaded and trigger payment load if first startup
                        if (_isFirstStartup && !_berandaDataLoaded) {
                          _berandaDataLoaded = true;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _triggerDelayedPaymentLoad();
                          });
                        }
                        
                        return RefreshIndicator(
                          onRefresh: () async {
                            debugPrint('🔥 RADICAL: Pull to refresh - triggering aggressive reload');
                            try {
                              context.read<BerandaBloc>().add(
                                const RefreshBerandaDataEvent(),
                              );
                            } catch (e) {
                              debugPrint('BerandaBloc not available for pull refresh: $e');
                            }
                            // STARTUP FIX: No longer first startup after pull refresh
                            _isFirstStartup = false;
                            // RADICAL SOLUTION: Aggressive refresh on pull-to-refresh
                            await _triggerAggressivePaymentLoad('pullRefresh');
                            // Also refresh preferences when user pulls to refresh
                            await _loadPreferences();
                          },
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                _buildHeroCarousel(state.data.announcements),
                                const SizedBox(height: 24),
                                _buildLibraryServices(state.data.libraryServices),
                                const SizedBox(height: 24),
                                _buildPaymentSummary(state.data.payment),
                                const SizedBox(height: 24),
                                _buildTranscriptSummary(state.data.transcript),
                              ],
                            ),
                          ),
                        );
                      }
                      // STARTUP FIX: Show loading instead of blank during initial state
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
        ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            height: 36,
            child: SvgPicture.asset(
              'assets/wira-husada-nusantara-homepage.svg',
              fit: BoxFit.contain,
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
                _navigateToSettings();
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
    );
  }

  Widget _buildHeroCarousel(List<AnnouncementData> announcements) {
    // TODO: Replace with API data when backend is ready
    final dummyAnnouncements = [
      const AnnouncementData(
        id: '1',
        title: 'Gedung Baru WHN',
        description:
            'Peresmian gedung baru untuk fasilitas belajar mengajar yang modern dan nyaman.',
        imageUrl: 'https://picsum.photos/seed/1/800/600',
        articleUrl: 'https://wira-husada-nusantara.ac.id/news/1',
        status: 'active',
        createdAt: '2025-01-20T00:00:00.000Z',
      ),
      const AnnouncementData(
        id: '2',
        title: 'Seminar Kesehatan Nasional',
        description:
            'Jangan lewatkan seminar nasional "Inovasi dalam Penanganan Covid-29" tanggal 10 Juli 2025.',
        imageUrl: 'https://picsum.photos/seed/2/800/600',
        articleUrl: 'https://wira-husada-nusantara.ac.id/news/2',
        status: 'active',
        createdAt: '2025-01-19T00:00:00.000Z',
      ),
      const AnnouncementData(
        id: '3',
        title: 'Pendaftaran Mahasiswa Baru',
        description:
            'Periode pendaftaran mahasiswa baru telah dibuka! Dapatkan informasi lengkap di website resmi.',
        imageUrl: 'https://picsum.photos/seed/3/800/600',
        articleUrl: 'https://wira-husada-nusantara.ac.id/news/3',
        status: 'active',
        createdAt: '2025-01-18T00:00:00.000Z',
      ),
    ];

    final displayAnnouncements = dummyAnnouncements;

    if (displayAnnouncements.isEmpty) {
      return const SizedBox.shrink();
    }

    // Start auto-scroll timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCarouselTimer();
    });

    return Container(
      height: 258,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            PageView.builder(
              controller: _carouselController,
              onPageChanged: (index) {
                setState(() {
                  _currentCarouselIndex = index;
                });
                // Restart timer when page changes (either auto or manual)
                _startCarouselTimer();
              },
              itemCount: displayAnnouncements.length,
              itemBuilder: (context, index) {
                return _buildCarouselItem(displayAnnouncements[index]);
              },
            ),

            // Navigation dots
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: displayAnnouncements.asMap().entries.map((entry) {
                  int index = entry.key;
                  return GestureDetector(
                    onTap: () {
                      _carouselController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                      // Restart the timer when user manually navigates
                      _startCarouselTimer();
                    },
                    child: Container(
                      width: 8.0,
                      height: 8.0,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentCarouselIndex == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselItem(AnnouncementData announcement) {
    return GestureDetector(
      onTap: () => _openArticleUrl(announcement.articleUrl),
      child: Container(
        decoration: BoxDecoration(
          image: announcement.imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(announcement.imageUrl!),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Handle image loading error by showing gradient fallback
                    debugPrint(
                      'Failed to load image: ${announcement.imageUrl}',
                    );
                  },
                )
              : null,
          gradient: announcement.imageUrl == null
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF207BB5), Color(0xFF135EA2)],
                )
              : null,
        ),
        child: Stack(
          children: [
            // Dark overlay for better text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    announcement.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFBFBFB),
                      letterSpacing: -0.16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    announcement.description,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFE7E7E7),
                      letterSpacing: -0.12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryServices(List<LibraryServiceData> libraryServices) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionHeader(
            title: "Layanan Perpustakaan",
            actionText: "Lihat Semua",
            onActionTap: () {
              // TODO: Navigate to library services
            },
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.6, // Reduced from 1.8 to provide more height
              crossAxisSpacing: 9,
              mainAxisSpacing: 12,
            ),
            itemCount: libraryServices.length,
            itemBuilder: (context, index) {
              return _buildLibraryServiceCard(libraryServices[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryServiceCard(LibraryServiceData service) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (service.status == "coming_soon") {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur segera hadir!'),
                  backgroundColor: Color(0xFF135EA2),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12), // Reduced from 16 to save space
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Added to prevent overflow
              children: [
                Icon(
                  _getServiceIcon(service.id),
                  size: 32, // Reduced from 40 to save space
                  color: const Color(0xFF1C1D1F),
                ),
                const SizedBox(height: 6), // Reduced from 8
                Flexible(
                  // Wrapped text in Flexible to prevent overflow
                  child: Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 14, // Reduced from 16
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1D1F),
                      letterSpacing: -0.14,
                      height: 1.2, // Added line height for better readability
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2, // Allow up to 2 lines
                    overflow: TextOverflow
                        .ellipsis, // Handle text overflow gracefully
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSummary(PaymentSummaryData? payment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Rekap Biaya Kuliah",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1D1F),
                  letterSpacing: -0.16,
                ),
              ),
              GestureDetector(
                onTap: _navigateToPaymentPage,
                child: const Text(
                  "Lihat Detail",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF135EA2),
                    letterSpacing: -0.14,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Reuse existing PaymentBloc from main.dart instead of creating new one
          BlocBuilder<PaymentBloc, PaymentState>(
            buildWhen: (previous, current) =>
                current is PaymentSummaryLoaded ||
                current is PaymentError ||
                current is PaymentLoading,
            builder: (context, state) {
              // STARTUP FIX: Only force payment loading if beranda data is loaded
              if (state is PaymentInitial && mounted && _berandaDataLoaded && !_isFirstStartup) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  debugPrint('🔥 RADICAL: PaymentInitial detected - triggering force refresh');
                  _triggerAggressivePaymentLoad('paymentInitialState');
                });
              }
              
              // STARTUP FIX: Only retry if not in first startup sequence
              if (state is PaymentError && _paymentLoadAttempts < maxPaymentLoadAttempts && mounted && !_isFirstStartup) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  debugPrint('🔥 RADICAL: PaymentError detected - attempt ${_paymentLoadAttempts + 1}');
                  _triggerAggressivePaymentLoad('paymentErrorRetry');
                });
              }

              if (state is PaymentLoading || _directApiLoading) {
                return Column(
                  children: [
                    if (_paymentLoadAttempts > 1) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Loading attempt $_paymentLoadAttempts...',
                              style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Center(
                      child: SizedBox(
                        height: 60,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF135EA2),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (state is PaymentSummaryLoaded) {
                debugPrint('🔥 RADICAL: PaymentSummaryLoaded - resetting attempt counter');
                _paymentLoadAttempts = 0; // Reset attempt counter on success
                return _buildPaymentSummaryCards(state.summary);
              }
              
              // RADICAL SOLUTION: Fallback to direct API data if available
              if (_directApiPaymentSummary != null && (state is PaymentError || state is PaymentInitial)) {
                debugPrint('🔥 RADICAL: Using direct API fallback data');
                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Loaded via fallback API',
                              style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentSummaryCards(_directApiPaymentSummary!),
                  ],
                );
              }

              if (state is PaymentError) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Error loading payment data: ${state.message}',
                              style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Attempt $_paymentLoadAttempts/$maxPaymentLoadAttempts',
                            style: TextStyle(color: Colors.red.shade600, fontSize: 10),
                          ),
                          ElevatedButton(
                            onPressed: () => _triggerAggressivePaymentLoad('manualRetry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            child: const Text(
                              'Force Retry',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // Updated logic based on wismon_page.dart _buildPaymentSummary method with filtering
  Widget _buildPaymentSummaryCards(PaymentSummary summary) {
    // Use cached preferences instead of static mapping
    if (!_preferencesLoaded || _cachedSelectedTypes == null) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final selectedTypes = _cachedSelectedTypes!;
    if (selectedTypes.isEmpty) {
      return const SizedBox.shrink();
    }

    // Create filtered breakdown based on user preferences (same as wismon_page)
    final List<MapEntry<String, double>> filteredBreakdown = [];

    for (final selectedType in selectedTypes) {
      final amount = summary.breakdown[selectedType] ?? 0.0;
      filteredBreakdown.add(MapEntry(selectedType, amount));
    }

    if (filteredBreakdown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          'Tidak ada data pembayaran tersedia',
          style: TextStyle(color: Colors.grey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    final List<Widget> cardRows = [];
    for (int i = 0; i < filteredBreakdown.length; i += 2) {
      final item1 = filteredBreakdown[i];
      final card1 = Expanded(
        child: PaymentSummaryCard(
          title: item1.key,
          amount: item1.value,
        ),
      );

      final rowChildren = <Widget>[card1];

      if (i + 1 < filteredBreakdown.length) {
        final item2 = filteredBreakdown[i + 1];
        final card2 = Expanded(
          child: PaymentSummaryCard(
            title: item2.key,
            amount: item2.value,
          ),
        );
        rowChildren.addAll([const SizedBox(width: 12), card2]);
      }

      cardRows.add(Row(children: rowChildren));
      if (i + 2 < filteredBreakdown.length) {
        cardRows.add(const SizedBox(height: 12));
      }
    }

    return Column(mainAxisSize: MainAxisSize.min, children: cardRows);
  }

  Widget _buildTranscriptSummary(TranscriptSummaryData? transcript) {
    if (transcript == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildSectionHeader(
            title: "Transkrip Nilai",
            actionText: "Lihat Detail",
            onActionTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TranskripPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTranscriptCard(
                  "Total SKS",
                  transcript.totalSks.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTranscriptCard(
                  "Total Bobot",
                  transcript.totalBobot.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTranscriptCard(
                  "IP Kumulatif",
                  transcript.ipKumulatif.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptCard(String title, String value) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1C1D1F),
                letterSpacing: -0.12,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE7E7E7)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF121212),
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onActionTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1C1D1F),
            letterSpacing: -0.16,
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF135EA2),
              letterSpacing: -0.14,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
  }


  /// Navigate to payment page (wismon)
  Future<void> _navigateToPaymentPage() async {
    debugPrint('🔧 BerandaPage: Navigating to wismon page...');
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WismonPage()),
    );

    // Refresh preferences and payment data when returning from payment page
    // This ensures any customizations made from wismon page are reflected
    if (mounted) {
      debugPrint('🔧 BerandaPage: Returned from wismon page - refreshing data');
      await _loadPreferences();
      // STARTUP FIX: No longer first startup after wismon page
      _isFirstStartup = false;
      // RADICAL SOLUTION: Aggressive refresh after returning from payment page
      _triggerAggressivePaymentLoad('postWismonPage');
    }
  }
  
  /// RADICAL SOLUTION: Trigger aggressive payment loading with multiple strategies
  Future<void> _triggerAggressivePaymentLoad(String source) async {
    if (!mounted) return;
    
    debugPrint('🔥 RADICAL: Triggering aggressive payment load from: $source');
    _paymentLoadAttempts++;
    
    // Strategy 1: Force PaymentBloc refresh
    try {
      final paymentBloc = context.read<PaymentBloc>();
      paymentBloc.add(ForcePaymentRefreshEvent(
        clearCache: true,
        bypassCurrentState: true,
        debugSource: source,
      ));
      debugPrint('🔥 RADICAL: PaymentBloc force refresh triggered');
    } catch (e) {
      debugPrint('🔥 RADICAL: PaymentBloc not available, trying direct API: $e');
      // Strategy 2: Direct API fallback
      _loadPaymentDataDirectly(source);
    }
    
    // Strategy 3: Start polling if this is a critical load
    if (source.contains('auth') || source.contains('init')) {
      _startPaymentPolling(source);
    }
  }
  
  /// RADICAL SOLUTION: Direct API call bypassing BLoC
  Future<void> _loadPaymentDataDirectly(String source) async {
    if (!mounted) return;
    
    setState(() {
      _directApiLoading = true;
      _directApiError = null;
    });
    
    try {
      debugPrint('🔥 RADICAL: Loading payment data directly from API - source: $source');
      
      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      if (token == null || token.isEmpty) {
        throw Exception('No auth token available for direct API call');
      }
      
      // Make direct API call
      final apiService = di.sl<ApiService>();
      final response = await apiService.get('/payments/summary');
      
      if (response['success'] == true) {
        final summaryData = response['data'];
        
        // Convert response to PaymentSummary entity
        final paymentSummary = PaymentSummary(
          totalPembayaran: (summaryData['totalPembayaran'] ?? summaryData['totalAmount'] ?? 0.0).toDouble(),
          breakdown: Map<String, double>.from(
            summaryData['breakdown'] ?? {},
          ),
        );
        
        if (mounted) {
          setState(() {
            _directApiPaymentSummary = paymentSummary;
            _directApiLoading = false;
            _directApiError = null;
          });
          debugPrint('🔥 RADICAL: Direct API call successful - data loaded');
        }
      } else {
        throw Exception(response['message'] ?? 'API call failed');
      }
    } catch (e) {
      debugPrint('🔥 RADICAL: Direct API call failed: $e');
      if (mounted) {
        setState(() {
          _directApiLoading = false;
          _directApiError = 'Direct API failed: ${e.toString()}';
        });
      }
    }
  }
  
  /// RADICAL SOLUTION: Start polling for payment data
  void _startPaymentPolling(String source) {
    _stopPaymentPolling(); // Stop any existing polling
    
    debugPrint('🔥 RADICAL: Starting payment polling from: $source');
    
    _paymentPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Check if we already have data loaded
      try {
        final paymentBloc = context.read<PaymentBloc>();
        final currentState = paymentBloc.state;
        
        if (currentState is PaymentSummaryLoaded) {
          debugPrint('🔥 RADICAL: Payment polling successful - stopping timer');
          timer.cancel();
          return;
        }
        
        debugPrint('🔥 RADICAL: Payment polling attempt...');
        
        // Try to load again
        paymentBloc.add(const LoadPaymentSummaryEvent());
      } catch (e) {
        debugPrint('🔥 RADICAL: Payment polling bloc error: $e');
        _loadPaymentDataDirectly('polling');
      }
      
      // Stop polling after 10 attempts (50 seconds)
      if (timer.tick >= 10) {
        debugPrint('🔥 RADICAL: Payment polling timeout - stopping');
        timer.cancel();
      }
    });
  }
  
  /// RADICAL SOLUTION: Stop payment polling
  void _stopPaymentPolling() {
    _paymentPollingTimer?.cancel();
    _paymentPollingTimer = null;
  }
  
  /// STARTUP FIX: Coordinated startup sequence to prevent race conditions
  void _startupSequence() {
    if (!mounted) return;
    
    debugPrint('🔥 STARTUP: Starting coordinated startup sequence');
    
    // Step 1: Trigger beranda data load first (if not already loaded)
    try {
      final berandaBloc = context.read<BerandaBloc>();
      final currentState = berandaBloc.state;
      
      if (currentState is! BerandaLoaded) {
        debugPrint('🔥 STARTUP: Loading beranda data first');
        berandaBloc.add(const FetchBerandaDataEvent());
      } else {
        // Beranda already loaded, mark as loaded and proceed
        _berandaDataLoaded = true;
        _triggerDelayedPaymentLoad();
      }
    } catch (e) {
      debugPrint('🔥 STARTUP: BerandaBloc not available: $e');
      // Fallback: proceed with payment loading anyway
      _triggerDelayedPaymentLoad();
    }
  }
  
  /// STARTUP FIX: Delayed payment loading after beranda is ready
  void _triggerDelayedPaymentLoad() {
    if (!mounted) return;
    
    debugPrint('🔥 STARTUP: Triggering delayed payment load');
    
    // Add a small delay to ensure UI is rendered properly
    _startupDelayTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      
      debugPrint('🔥 STARTUP: Executing delayed payment load');
      _isFirstStartup = false; // Mark startup as complete
      _triggerAggressivePaymentLoad('startupSequence');
    });
  }
}
