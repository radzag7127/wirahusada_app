import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_bloc.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_event.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_state.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/book_list_page.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/journal_list_page.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/thesis_list_page.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;

class LibraryMenuPage extends StatefulWidget {
  const LibraryMenuPage({super.key});

  @override
  State<LibraryMenuPage> createState() => _LibraryMenuPageState();
}

class _LibraryMenuPageState extends State<LibraryMenuPage> {
  // Create separate BLoC instances for each category
  late final LibraryBloc _bookBloc;
  late final LibraryBloc _journalBloc;
  late final LibraryBloc _thesisBloc;

  @override
  void initState() {
    super.initState();
    // Initialize BLoCs
    _bookBloc = di.sl<LibraryBloc>();
    _journalBloc = di.sl<LibraryBloc>();
    _thesisBloc = di.sl<LibraryBloc>();

    // Load data for each category
    _bookBloc.add(const LoadCollectionsByCategoryEvent("", category: 'buku'));
    _journalBloc.add(const LoadCollectionsByCategoryEvent("", category: 'jurnal'));
    _thesisBloc.add(const LoadCollectionsByCategoryEvent("", category: 'skripsi'));
  }

  @override
  void dispose() {
    // Dispose all BLoCs
    _bookBloc.close();
    _journalBloc.close();
    _thesisBloc.close();
    super.dispose();
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => BlocProvider<LibraryBloc>(
                  create: (context) => di.sl<LibraryBloc>(),
                  child: page,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Mountain peaks background anchored to bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height:
                MediaQuery.of(context).size.height * 1, // 100% of screen height
            child: RepaintBoundary(
              child: ClipRect(
                child: Transform.translate(
                  offset: const Offset(
                    0,
                    400,
                  ), // Push bottom part below visible area
                  child: SvgPicture.asset(
                    'assets/logo-whn-profil.svg',
                    width: MediaQuery.of(context).size.width,
                    height:
                        MediaQuery.of(context).size.width *
                        (391 / 402), // Maintain aspect ratio
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Column(
            children: [
              _buildHeader(context),
              _buildSearchBar(),
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  children: [
                    _buildBlocMenuItem(
                      context,
                      bloc: _bookBloc,
                      icon: Icons.book_outlined,
                      title: "Buku",
                      suffix: "Buku",
                      onTap: () => _navigateTo(
                          context,
                          const BookListPage(
                              category: 'buku', title: 'Koleksi Buku')),
                    ),
                    _buildBlocMenuItem(
                      context,
                      bloc: _journalBloc,
                      icon: Icons.article_outlined,
                      title: "Jurnal",
                      suffix: "Jurnal",
                      onTap: () => _navigateTo(
                          context,
                          const JournalListPage(
                              category: 'jurnal', title: 'Koleksi Jurnal')),
                    ),
                    _buildBlocMenuItem(
                      context,
                      bloc: _thesisBloc,
                      icon: Icons.description_outlined,
                      title: "Dokumen Skripsi",
                      suffix: "Dokumen Skripsi",
                      onTap: () => _navigateTo(
                          context,
                          const ThesisListPage(
                              category: 'skripsi', title: 'Koleksi Skripsi')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: Color(0xFF135EA2),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: ShapeDecoration(
                color: const Color(0xFFFAFAFA),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                shadows: const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Text(
              'Layanan Perpustakaan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFAFAFA),
                fontSize: 18,
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 40), // Spacer
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Cari...',
            prefixIcon: Icon(Icons.search, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.only(top: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildBlocMenuItem(
    BuildContext context, {
    required LibraryBloc bloc,
    required IconData icon,
    required String title,
    required String suffix,
    required VoidCallback onTap,
  }) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          String subtitle = 'Memuat...';
          if (state is LibraryLoaded) {
            subtitle = "Tersedia ${state.collections.length} $suffix.";
          } else if (state is LibraryEmpty) {
            subtitle = "Tersedia 0 $suffix.";
          } else if (state is LibraryError) {
            subtitle = "Gagal memuat";
          }

          return _buildMenuItem(
            icon: icon,
            title: title,
            subtitle: subtitle,
            onTap: onTap,
          );
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey, width: 0.5),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Icon(icon, size: 28, color: Colors.black),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        onTap: onTap,
      ),
    );
  }
}
