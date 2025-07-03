import 'package:flutter/material.dart';

class ErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error.toString().contains('Tidak ada koneksi internet')) {
      return 'Tidak ada koneksi internet. Mohon periksa koneksi Anda.';
    } else if (error.toString().contains('Gagal terhubung ke server')) {
      return 'Gagal terhubung ke server. Silakan coba lagi.';
    } else if (error.toString().contains('Koneksi timeout')) {
      return 'Koneksi timeout. Silakan coba lagi.';
    } else if (error.toString().contains('Token tidak ditemukan') ||
        error.toString().contains('401')) {
      return 'Sesi Anda telah berakhir. Silakan login ulang.';
    } else if (error.toString().contains('Failed host lookup')) {
      return 'Tidak dapat menemukan server. Periksa koneksi internet Anda.';
    } else if (error.toString().contains('Connection refused')) {
      return 'Server tidak dapat diakses. Silakan coba lagi nanti.';
    } else {
      return error.toString().replaceAll('Exception: ', '');
    }
  }

  static bool isConnectionError(dynamic error) {
    return error.toString().contains('Tidak ada koneksi internet') ||
        error.toString().contains('Gagal terhubung ke server') ||
        error.toString().contains('Koneksi timeout') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('Connection refused');
  }

  static bool isAuthError(dynamic error) {
    return error.toString().contains('Token tidak ditemukan') ||
        error.toString().contains('401') ||
        error.toString().contains('Unauthorized');
  }

  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    VoidCallback? onRetry,
    bool showRetryButton = true,
  }) {
    final errorMessage = getErrorMessage(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: isAuthError(error) ? Colors.red : Colors.orange,
        duration: const Duration(seconds: 4),
        action: showRetryButton && onRetry != null
            ? SnackBarAction(
                label: 'Coba Lagi',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  static void showConnectionErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.wifi_off,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          if (onRetry != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Coba Lagi'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
