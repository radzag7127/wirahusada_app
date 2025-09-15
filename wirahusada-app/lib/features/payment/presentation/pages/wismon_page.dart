import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;
import 'package:wismon_keuangan/core/services/dashboard_preferences_service.dart';
import 'package:wismon_keuangan/core/services/api_service.dart';
import 'package:wismon_keuangan/features/payment/domain/entities/payment.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_event.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_state.dart';
import 'package:wismon_keuangan/features/payment/presentation/pages/transaction_detail_page.dart';
import 'package:wismon_keuangan/features/payment/presentation/pages/dashboard_customization_page.dart';
import 'package:wismon_keuangan/features/payment/presentation/components/components.dart';

class WismonPage extends StatefulWidget {
  const WismonPage({super.key});

  @override
  State<WismonPage> createState() => _WismonPageState();
}

class _WismonPageState extends State<WismonPage> with RouteAware {
  List<PaymentHistoryItem>? _historyItems;
  List<PaymentHistoryItem> _filteredHistoryItems = [];
  PaymentSummary? _paymentSummary;

  // Services
  late final DashboardPreferencesService _preferencesService;
  late final ApiService _apiService;

  // Payment types for dropdown (from API)
  List<Map<String, String>> _paymentTypesForDropdown = [];
  String _selectedPaymentTypeCode = 'all';

  // Cache preferences to avoid disk I/O on rebuilds
  List<String>? _cachedSelectedTypes;
  bool _preferencesLoaded = false;
  
  // Cross-page communication for dashboard changes
  StreamSubscription<DashboardChangeEvent>? _dashboardChangeSubscription;

  @override
  void initState() {
    super.initState();
    _preferencesService = di.sl<DashboardPreferencesService>();
    _apiService = di.sl<ApiService>();
    _setupDashboardChangeListener();
    _loadPreferences();
    _loadPaymentData();
  }
  
  /// Set up listener for cross-page dashboard customization changes
  void _setupDashboardChangeListener() {
    _dashboardChangeSubscription = DashboardPreferencesService.changeStream.listen(
      (DashboardChangeEvent event) {
        if (mounted) {
          debugPrint('🔧 WismonPage: Dashboard change detected - ${event.changeType}');
          // Dashboard preferences changed from another screen or customization page
          // Refresh preferences cache and payment summary immediately
          _loadPreferences();
          // Also refresh payment summary to show updated dashboard
          context.read<PaymentBloc>().add(const LoadPaymentSummaryEvent());
        }
      },
      onError: (error) {
        debugPrint('🔧 WismonPage: Error listening to dashboard changes: $error');
      },
    );
  }

  Future<void> _loadPreferences() async {
    try {
      debugPrint('🔧 WismonPage: Loading dashboard preferences...');
      final types = await _preferencesService.getSelectedPaymentTypes();
      if (mounted) {
        setState(() {
          _cachedSelectedTypes = types;
          _preferencesLoaded = true;
        });
        debugPrint('🔧 WismonPage: Dashboard preferences loaded - ${types.length} types selected');
      }
    } catch (e) {
      debugPrint('🔧 WismonPage: Error loading preferences: $e');
      // Handle error gracefully, use defaults
      if (mounted) {
        setState(() {
          _cachedSelectedTypes =
              DashboardPreferencesService.defaultPaymentTypes;
          _preferencesLoaded = true;
        });
      }
    }
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
    di.sl<RouteObserver<PageRoute>>().unsubscribe(this);
    _dashboardChangeSubscription?.cancel(); // Clean up stream subscription
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint('🔧 WismonPage: didPopNext - user returned to wismon page');
    
    // Refresh preferences when returning from other pages (like customization page)
    _loadPreferences();
    
    // Refresh payment data when returning from other pages
    context.read<PaymentBloc>().add(const RefreshPaymentDataEvent());
    context.read<PaymentBloc>().add(const LoadPaymentSummaryEvent());
  }

  void _loadPaymentData() {
    // Clear existing data
    if (mounted) {
      setState(() {
        _historyItems = null;
        _paymentSummary = null;
      });
    }

    // Load payment types from API
    _loadPaymentTypes();

    context.read<PaymentBloc>().add(const LoadPaymentHistoryEvent());
    context.read<PaymentBloc>().add(const LoadPaymentSummaryEvent());
  }

  Future<void> _loadPaymentTypes() async {
    try {
      final paymentTypes = await _apiService.getPaymentTypes();

      if (mounted) {
        setState(() {
          // Create dropdown items with "All" option first
          _paymentTypesForDropdown = [
            {'kode': 'all', 'nama': 'Semua Jenis Pembayaran'},
            ...paymentTypes.map(
              (type) => {
                'kode': type.nama, // Use nama as kode for filtering
                'nama': type.nama,
              },
            ),
          ];
        });
      }
    } catch (e) {
      // If API fails, fallback to default types
      if (mounted) {
        setState(() {
          _paymentTypesForDropdown = [
            {'kode': 'all', 'nama': 'Semua Jenis Pembayaran'},
            ...DashboardPreferencesService.defaultPaymentTypes.map(
              (type) => {'kode': type, 'nama': type},
            ),
          ];
        });
      }
    }
  }

  void _filterHistoryItems() {
    if (_historyItems == null) {
      _filteredHistoryItems = [];
      return;
    }
    if (_selectedPaymentTypeCode == 'all') {
      _filteredHistoryItems = _historyItems!;
    } else {
      _filteredHistoryItems = _historyItems!
          .where((item) => item.type == _selectedPaymentTypeCode)
          .toList();
    }
  }
  
  Future<void> _onRefreshData(BuildContext context) async {
    debugPrint('🔧 WismonPage: Pull-to-refresh triggered');
    // Refresh dashboard preferences first
    await _loadPreferences();
    // Then refresh payment data
    if (mounted) {
      context.read<PaymentBloc>().add(const RefreshPaymentDataEvent());
      context.read<PaymentBloc>().add(const LoadPaymentSummaryEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocListener<PaymentBloc, PaymentState>(
              listener: (context, state) {
                if (state is PaymentError) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else if (state is PaymentHistoryLoaded) {
                  if (mounted) {
                    setState(() {
                      _historyItems = state.historyItems;
                      _filterHistoryItems();
                    });
                  }
                } else if (state is PaymentSummaryLoaded) {
                  if (mounted) {
                    setState(() {
                      _paymentSummary = state.summary;
                    });
                  }
                }
              },
              child: BlocBuilder<PaymentBloc, PaymentState>(
                buildWhen: (previous, current) {
                  // Only rebuild on specific state changes
                  return current is PaymentLoading ||
                      current is PaymentError ||
                      (_historyItems != null && _paymentSummary != null);
                },
                builder: (context, state) {
                  if (state is PaymentLoading && _historyItems == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (_historyItems != null) {
                    return _buildPaymentContent(context);
                  }

                  return _buildEmptyState(context);
                },
              ),
            ),
          ),
        ],
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
      child: Column(
        children: [
          // Status bar height
          SizedBox(height: MediaQuery.of(context).padding.top),
          // Header content
          Padding(
            padding: const EdgeInsets.only(
              top: 12,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF135EA2),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
                // Title
                const Text(
                  'Biaya Kuliah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFAFAFA),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.18,
                  ),
                ),
                // Right placeholder (to balance the layout)
                const SizedBox(width: 40, height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _onRefreshData(context),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_paymentSummary != null) ...[
                    _buildDashboardSection(context, _paymentSummary!),
                    const SizedBox(height: 20),
                  ],
                  _buildFilterSection(context),
                  const SizedBox(height: 20),
                  Container(height: 1, color: const Color(0xFFE7E7E7)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_filteredHistoryItems.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (index >= _filteredHistoryItems.length) return null;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _filteredHistoryItems.length - 1 ? 8 : 20,
                    ),
                    child: _buildTransactionCard(
                      context,
                      _filteredHistoryItems[index],
                    ),
                  );
                }, childCount: _filteredHistoryItems.length),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(child: _buildEmptyHistory(context)),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Jenis Pembayaran',
          style: TextStyle(
            color: Color(0xFF1C1D1F),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPaymentTypeCode,
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null && mounted) {
              setState(() {
                _selectedPaymentTypeCode = newValue;
                _filterHistoryItems();
              });
            }
          },
          items: _paymentTypesForDropdown.map<DropdownMenuItem<String>>((
            Map<String, String> type,
          ) {
            return DropdownMenuItem<String>(
              value: type['kode'],
              child: Text(
                type['nama']!,
                style: const TextStyle(
                  color: Color(0xFF545556),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Color(0xFFFAFAFA),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            constraints: BoxConstraints(
              minHeight: 48,
              maxHeight: 56,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFFE7E7E7), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFFE7E7E7), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: Color(0xFF135EA2), width: 2),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardSection(BuildContext context, PaymentSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                color: Color(0xFF1C1D1F),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.14,
              ),
            ),
            GestureDetector(
              onTap: () => _navigateToCustomization(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF135EA2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF135EA2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit, size: 16, color: Color(0xFF135EA2)),
                    const SizedBox(width: 4),
                    const Text(
                      'Ubah',
                      style: TextStyle(
                        color: Color(0xFF135EA2),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPaymentSummary(context, summary),
      ],
    );
  }

  Future<void> _navigateToCustomization(BuildContext context) async {
    debugPrint('🔧 WismonPage: Navigating to customization page...');
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DashboardCustomizationPage()),
    );

    // If user made changes, refresh preferences cache and UI
    if (result == true && mounted) {
      debugPrint('🔧 WismonPage: User saved customization changes - refreshing UI');
      await _loadPreferences(); // Refresh cached preferences
      // Note: Stream listener will also trigger, providing double-assurance
    } else {
      debugPrint('🔧 WismonPage: User canceled customization or no changes made');
    }
  }

  Widget _buildPaymentSummary(BuildContext context, PaymentSummary summary) {
    // Use cached preferences instead of FutureBuilder
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

    // Create filtered breakdown based on user preferences
    final List<MapEntry<String, double>> filteredBreakdown = [];

    for (final selectedType in selectedTypes) {
      final amount = summary.breakdown[selectedType] ?? 0.0;
      filteredBreakdown.add(MapEntry(selectedType, amount));
    }

    if (filteredBreakdown.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Widget> cardRows = [];
    for (int i = 0; i < filteredBreakdown.length; i += 2) {
      final item1 = filteredBreakdown[i];
      final card1 = Expanded(
        child: PaymentSummaryCard(title: item1.key, amount: item1.value),
      );

      final rowChildren = <Widget>[card1];

      if (i + 1 < filteredBreakdown.length) {
        final item2 = filteredBreakdown[i + 1];
        final card2 = Expanded(
          child: PaymentSummaryCard(title: item2.key, amount: item2.value),
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

  Widget _buildTransactionCard(BuildContext context, PaymentHistoryItem item) {
    return TransactionCard(
      item: item,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TransactionDetailPage(transactionId: item.id),
          ),
        );
      },
    );
  }

  Widget _buildEmptyHistory(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Payment History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any payment records yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Unable to load payment data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadPaymentData(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
