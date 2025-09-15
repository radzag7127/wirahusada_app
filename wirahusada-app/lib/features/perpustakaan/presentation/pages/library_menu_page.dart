import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_bloc.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_event.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_state.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/book_list_page.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/journal_list_page.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/thesis_list_page.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;

class LibraryMenuPage extends StatelessWidget {
  const LibraryMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perpustakaan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header section with welcome message
              Container(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.local_library,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Selamat Datang di Perpustakaan Digital',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Temukan berbagai koleksi buku, jurnal, dan karya ilmiah',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Menu grid
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildMenuCard(
                          context,
                          'Buku',
                          'Koleksi buku umum dan textbook',
                          Icons.book,
                          const Color(0xFF4CAF50),
                          () => _navigateToCategory(context, 'buku', 'Koleksi Buku'),
                        ),
                        _buildMenuCard(
                          context,
                          'Jurnal',
                          'Jurnal dan artikel ilmiah',
                          Icons.article,
                          const Color(0xFF2196F3),
                          () => _navigateToCategory(context, 'jurnal', 'Koleksi Jurnal'),
                        ),
                        _buildMenuCard(
                          context,
                          'Skripsi',
                          'Karya tulis mahasiswa',
                          Icons.school,
                          const Color(0xFFFF9800),
                          () => _navigateToCategory(context, 'skripsi', 'Koleksi Skripsi'),
                        ),
                        _buildMenuCard(
                          context,
                          'Semua Koleksi',
                          'Lihat semua koleksi',
                          Icons.library_books,
                          const Color(0xFF9C27B0),
                          () => _navigateToAllCollections(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, String category, String title) {
    Widget page;
    
    switch (category) {
      case 'buku':
        page = BookListPage(category: category, title: title);
        break;
      case 'jurnal':
        page = JournalListPage(category: category, title: title);
        break;
      case 'skripsi':
        page = ThesisListPage(category: category, title: title);
        break;
      default:
        page = BookListPage(category: category, title: title);
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider<LibraryBloc>(
          create: (context) => di.sl<LibraryBloc>(),
          child: page,
        ),
      ),
    );
  }

  void _navigateToAllCollections(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider<LibraryBloc>(
          create: (context) => di.sl<LibraryBloc>(),
          child: BookListPage(
            category: null,
            title: 'Semua Koleksi',
          ),
        ),
      ),
    );
  }
}