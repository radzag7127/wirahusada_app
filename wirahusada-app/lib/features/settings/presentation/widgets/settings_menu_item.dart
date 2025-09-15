import 'package:flutter/material.dart';

class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isEnabled;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.isEnabled = true,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = isEnabled
        ? (titleColor ?? const Color(0xFF121111))
        : const Color(0xFF999999);

    final effectiveIconColor = isEnabled
        ? (iconColor ?? const Color(0xFF121212))
        : const Color(0xFF999999);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: isEnabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Icon(icon, size: 20, color: effectiveIconColor),
                  ),
                ),
                const SizedBox(width: 8),
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: effectiveTitleColor,
                      fontSize: 14,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
