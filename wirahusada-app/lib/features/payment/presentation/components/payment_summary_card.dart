import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentSummaryCard extends StatelessWidget {
  final String title;
  final double amount;

  const PaymentSummaryCard({
    super.key,
    required this.title,
    required this.amount,
  });

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: const ShapeDecoration(
          color: Color(0xFFFAFAFA),
          shape: RoundedRectangleBorder(
            side: BorderSide(width: 1, color: Color(0xFFE7E7E7)),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1C1D1F),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.12,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE7E7E7)),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _currencyFormat.format(amount),
                style: const TextStyle(
                  color: Color(0xFF121111),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
