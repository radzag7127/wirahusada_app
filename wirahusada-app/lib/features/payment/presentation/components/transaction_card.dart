import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/payment.dart';

class TransactionCard extends StatelessWidget {
  final PaymentHistoryItem item;
  final VoidCallback onTap;

  const TransactionCard({super.key, required this.item, required this.onTap});

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Material(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
        elevation: 2,
        shadowColor: const Color(0x0C000000),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type,
                        style: const TextStyle(
                          color: Color(0xFF121315),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Transaction ID Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA5DCFF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.txId,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF323335),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                height: 1.78,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Amount
                          Text(
                            _currencyFormat.format(item.jumlah),
                            style: const TextStyle(
                              color: Color(0xFF858586),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(item.tanggal),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF858586),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.09,
                      ),
                    ),
                    Text(
                      _formatYear(item.tanggal),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF858586),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.09,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final parts = dateString.split(' ');
      if (parts.length >= 2) {
        return '${parts[0]} ${parts[1]}';
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  String _formatYear(String dateString) {
    try {
      final parts = dateString.split(' ');
      if (parts.length >= 3) {
        return parts[2];
      }
      return DateTime.now().year.toString();
    } catch (e) {
      return DateTime.now().year.toString();
    }
  }
}
