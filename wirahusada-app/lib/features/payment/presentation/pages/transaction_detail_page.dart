import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wismon_keuangan/features/payment/domain/entities/payment.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_bloc.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_event.dart';
import 'package:wismon_keuangan/features/payment/presentation/bloc/payment_state.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;

  const TransactionDetailPage({super.key, required this.transactionId});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<PaymentBloc>().add(
      LoadTransactionDetailEvent(transactionId: widget.transactionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocConsumer<PaymentBloc, PaymentState>(
              listener: (context, state) {
                if (state is PaymentError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is PaymentLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is TransactionDetailLoaded) {
                  return _buildTransactionDetail(
                    context,
                    state.transactionDetail,
                  );
                }
                // Use the current state if it contains the detail, e.g. after a refresh
                if (state is PaymentHistoryLoaded &&
                    state.transactionDetail != null) {
                  return _buildTransactionDetail(
                    context,
                    state.transactionDetail!,
                  );
                }

                return _buildErrorState(context);
              },
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
                  'Detail Transaksi',
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

  Widget _buildTransactionDetail(
    BuildContext context,
    TransactionDetail transactionDetail,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    Color statusColor = Colors.green;
    if (transactionDetail.status.toUpperCase() == 'LUNAS') {
      statusColor = Colors.green;
    } else {
      statusColor = Colors.orange;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status & Amount Summary
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFFAFAFA),
              borderRadius: BorderRadius.all(Radius.circular(8)),
              border: Border.fromBorderSide(
                BorderSide(width: 1, color: Color(0xFFE7E7E7)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Pembayaran Berhasil',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF545556),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(transactionDetail.jumlah),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      transactionDetail.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rincian Pembayaran
          _buildDetailCard(
            context,
            title: 'Rincian Pembayaran',
            children: [
              _buildDetailRow('Jenis Pembayaran', transactionDetail.type),
              _buildDetailRow(
                'Tanggal Transaksi',
                transactionDetail.tanggalFull,
              ),
              _buildDetailRow('Metode Pembayaran', transactionDetail.method),
              _buildCopyableDetailRow(
                context,
                'Nomor Transaksi',
                transactionDetail.txId,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rincian Tagihan
          if (transactionDetail.paymentBreakdown.isNotEmpty) ...[
            _buildDetailCard(
              context,
              title: 'Rincian Tagihan',
              children: [
                ...transactionDetail.paymentBreakdown.entries.map(
                  (entry) => _buildDetailRow(
                    entry.key,
                    currencyFormat.format(entry.value),
                  ),
                ),
                const Divider(
                  height: 24,
                  thickness: 1,
                  color: Color(0xFFE7E7E7),
                ),
                _buildDetailRow(
                  'Total Dibayar',
                  currencyFormat.format(transactionDetail.jumlah),
                  isTotal: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Informasi Mahasiswa
          _buildDetailCard(
            context,
            title: 'Informasi Mahasiswa',
            children: [
              _buildDetailRow('Nama Mahasiswa', transactionDetail.studentName),
              _buildDetailRow('NIM', transactionDetail.studentNim),
              _buildDetailRow('Program Studi', transactionDetail.studentProdi),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.all(Radius.circular(8)),
        border: Border.fromBorderSide(
          BorderSide(width: 1, color: Color(0xFFE7E7E7)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1D1F),
                letterSpacing: -0.16,
              ),
            ),
          ),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE7E7E7),
            indent: 20,
            endIndent: 20,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: const Color(0xFF545556),
                fontSize: 14,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
                fontSize: isTotal ? 16 : 14,
                color: isTotal
                    ? const Color(0xFF1C1D1F)
                    : const Color(0xFF121111),
                letterSpacing: isTotal ? -0.16 : -0.14,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableDetailRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF545556),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF135EA2),
                      letterSpacing: -0.14,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _copyToClipboard(context, value),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy, size: 16, color: Color(0xFF135EA2)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            borderRadius: BorderRadius.all(Radius.circular(8)),
            border: Border.fromBorderSide(
              BorderSide(width: 1, color: Color(0xFFE7E7E7)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF545556),
              ),
              const SizedBox(height: 16),
              const Text(
                'Transaction not found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1D1F),
                  letterSpacing: -0.18,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The transaction details could not be loaded',
                style: TextStyle(
                  color: Color(0xFF545556),
                  fontSize: 14,
                  letterSpacing: -0.14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<PaymentBloc>().add(
                    LoadTransactionDetailEvent(
                      transactionId: widget.transactionId,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135EA2),
                  foregroundColor: const Color(0xFFFAFAFA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showToast(context, 'Nomor transaksi disalin!');
  }

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFFAFAFA),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.14,
          ),
        ),
        backgroundColor: const Color(0xFF135EA2),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
