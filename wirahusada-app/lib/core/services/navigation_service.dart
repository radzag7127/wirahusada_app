import 'package:flutter/material.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/book_list_page.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/library_menu_page.dart';

class NavigationService {
  static void navigateToLibraryService(BuildContext context, String serviceId) {
    Widget? page;
    String? title;
    
    switch (serviceId) {
      case 'repository': // Buku
        page = BookListPage(category: 'buku', title: 'Koleksi Buku');
        title = 'Koleksi Buku';
        break;
      case 'jurnal_whn': // Jurnal
        page = BookListPage(category: 'jurnal', title: 'Koleksi Jurnal');
        title = 'Koleksi Jurnal';
        break;
      case 'e_library': // Skripsi
        page = BookListPage(category: 'skripsi', title: 'Koleksi Skripsi');
        title = 'Koleksi Skripsi';
        break;
      case 'e_resources': // Semua Koleksi
        page = const LibraryMenuPage();
        title = 'Perpustakaan';
        break;
      default:
        // Handle unknown service
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Layanan belum tersedia')),
          );
        }
        return;
    }

    if (page != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => page!,
          settings: RouteSettings(name: '/library/$serviceId', arguments: title),
        ),
      );
    }
  }

  // Alternative method that uses the href from backend service
  static void navigateToLibraryServiceByHref(BuildContext context, String href) {
    // Map href to service ID
    final serviceMap = {
      '/perpustakaan/buku': 'repository',
      '/perpustakaan/jurnal': 'jurnal_whn',
      '/perpustakaan/skripsi': 'e_library',
      '/perpustakaan': 'e_resources',
    };

    final serviceId = serviceMap[href];
    if (serviceId != null) {
      navigateToLibraryService(context, serviceId);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan tidak ditemukan')),
      );
    }
  }
}