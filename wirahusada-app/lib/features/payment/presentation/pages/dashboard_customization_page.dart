import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/services/dashboard_preferences_service.dart';
import '../../../../core/services/api_service.dart';
import '../../domain/entities/payment.dart';
import '../../constants.dart';

class DashboardCustomizationPage extends StatefulWidget {
  const DashboardCustomizationPage({super.key});

  @override
  State<DashboardCustomizationPage> createState() =>
      _DashboardCustomizationPageState();
}

class _DashboardCustomizationPageState
    extends State<DashboardCustomizationPage> {
  final DashboardPreferencesService _preferencesService = di
      .sl<DashboardPreferencesService>();
  final ApiService _apiService = di.sl<ApiService>();

  List<PaymentType> _availablePaymentTypes = [];
  List<String> _selectedPaymentTypes = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load available payment types from API
      final paymentTypes = await _apiService.getPaymentTypes();

      // Load current user preferences
      final selectedTypes = await _preferencesService.getSelectedPaymentTypes();

      if (!mounted) return;
      setState(() {
        _availablePaymentTypes = paymentTypes;
        _selectedPaymentTypes = List<String>.from(selectedTypes);

        // Ensure SPP is always included in selected types
        if (!_selectedPaymentTypes.contains(kMandatoryPaymentType)) {
          _selectedPaymentTypes.add(kMandatoryPaymentType);
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    try {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      // Ensure SPP is always included when saving
      final typesToSave = List<String>.from(_selectedPaymentTypes);
      if (!typesToSave.contains(kMandatoryPaymentType)) {
        typesToSave.add(kMandatoryPaymentType);
      }

      final success = await _preferencesService.saveSelectedPaymentTypes(
        typesToSave,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pengaturan dashboard berhasil disimpan'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(
            context,
            true,
          ); // Return true to indicate changes were made
        }
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Gagal menyimpan pengaturan';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _togglePaymentType(String paymentType) {
    // Prevent SPP from being toggled off
    if (paymentType == kMandatoryPaymentType) {
      return;
    }

    setState(() {
      if (_selectedPaymentTypes.contains(paymentType)) {
        _selectedPaymentTypes.remove(paymentType);
      } else {
        _selectedPaymentTypes.add(paymentType);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Ubah Dashboard',
          style: TextStyle(
            color: Color(0xFF1C1D1F),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1D1F)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _selectedPaymentTypes.isNotEmpty
                  ? _savePreferences
                  : null,
              child: const Text(
                'Simpan',
                style: TextStyle(
                  color: Color(0xFF135EA2),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDescription(),
          const SizedBox(height: 24),
          _buildPaymentTypesList(),
          const SizedBox(height: 24),
          _buildSelectionSummary(),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: const Color(0xFF135EA2),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Pengaturan Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Pilih jenis pembayaran yang ingin ditampilkan di dashboard. Anda dapat memilih beberapa jenis sesuai kebutuhan. SPP wajib ditampilkan dan tidak dapat diubah.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTypesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Jenis Pembayaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1C1D1F),
          ),
        ),
        const SizedBox(height: 12),
        ..._availablePaymentTypes.map((paymentType) {
          final isSelected = _selectedPaymentTypes.contains(paymentType.nama);
          final isSPP = paymentType.nama == kMandatoryPaymentType;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSPP ? const Color(0xFFE8EBF0) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSPP
                    ? const Color(0xFFB0BCC9)
                    : isSelected
                    ? const Color(0xFF135EA2)
                    : const Color(0xFFE7E7E7),
              ),
            ),
            child: CheckboxListTile(
              title: Text(
                paymentType.nama,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSPP
                      ? const Color(0xFF6B7280)
                      : isSelected
                      ? const Color(0xFF135EA2)
                      : const Color(0xFF1C1D1F),
                ),
              ),
              value: isSelected,
              onChanged: isSPP
                  ? null
                  : (bool? value) {
                      _togglePaymentType(paymentType.nama);
                    },
              activeColor: const Color(0xFF135EA2),
              controlAffinity: ListTileControlAffinity.trailing,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildSelectionSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan (${_selectedPaymentTypes.length} dipilih)',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1C1D1F),
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedPaymentTypes.isEmpty)
            const Text(
              'Belum ada jenis pembayaran yang dipilih',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedPaymentTypes.map((type) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF135EA2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF135EA2)),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF135EA2),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
