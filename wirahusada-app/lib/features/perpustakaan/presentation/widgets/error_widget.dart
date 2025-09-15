import 'package:flutter/material.dart';

class LibraryErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const LibraryErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: Colors.red,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Error title
              const Text(
                'Oops! Terjadi Kesalahan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Error message
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Retry button
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Network error specific widget
class NetworkErrorWidget extends LibraryErrorWidget {
  const NetworkErrorWidget({
    super.key,
    super.onRetry,
  }) : super(
          message: 'Tidak dapat terhubung ke server.\nPeriksa koneksi internet Anda.',
          icon: Icons.wifi_off,
        );
}

/// Server error widget
class ServerErrorWidget extends LibraryErrorWidget {
  const ServerErrorWidget({
    super.key,
    super.onRetry,
  }) : super(
          message: 'Server sedang mengalami gangguan.\nSilakan coba lagi nanti.',
          icon: Icons.dns,
        );
}

/// Not found error widget
class NotFoundErrorWidget extends LibraryErrorWidget {
  const NotFoundErrorWidget({
    super.key,
    super.onRetry,
  }) : super(
          message: 'Data yang dicari tidak ditemukan.',
          icon: Icons.search_off,
        );
}