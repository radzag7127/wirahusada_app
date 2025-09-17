
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_bloc.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_event.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_state.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/collection_detail_page.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;
import 'package:wismon_keuangan/features/perpustakaan/presentation/components/collection_category_filter.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/components/collection_list_header.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/components/collection_list_item.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/widgets/search_bar_widget.dart';

class BookListPage extends StatefulWidget {
  final String? category;
  final String title;

  const BookListPage({
    super.key,
    this.category,
    required this.title,
  });

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedKategori = 'Semua';
  List<Collection> allBooks = [];
  List<String> kategoriList = ['Semua'];

  @override
  void initState() {
    super.initState();
    context
        .read<LibraryBloc>()
        .add(LoadCollectionsByCategoryEvent("", category: widget.category ?? 'buku'));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            CollectionListHeader(title: widget.title),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SearchBarWidget(
                      controller: _searchController,
                      hintText: "Cari buku...",
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CollectionCategoryFilter(
                      selectedValue: selectedKategori,
                      categoryList: kategoriList,
                      onChanged: (value) {
                        setState(() {
                          selectedKategori = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<LibraryBloc, LibraryState>(
                builder: (context, state) {
                  if (state is LibraryLoading) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF135EA2)));
                  } else if (state is LibraryLoaded) {
                    allBooks = state.collections;

                    final topikSet = {
                      for (var b in allBooks)
                        if (b.topik.isNotEmpty) b.topik
                    };
                    // Preserve the list instance if it hasn't changed
                    if (kategoriList.length - 1 != topikSet.length) {
                      kategoriList = ['Semua', ...topikSet];
                    }

                    final filteredBooks = allBooks.where((b) {
                      final cocokKategori = selectedKategori == 'Semua' ||
                          b.topik == selectedKategori;
                      final cocokSearch =
                          b.judul.toLowerCase().contains(searchQuery) ||
                              b.penulis.toLowerCase().contains(searchQuery);
                      return cocokKategori && cocokSearch;
                    }).toList();

                    if (filteredBooks.isEmpty) {
                      return const Center(
                          child: Text(
                              "Tidak ada buku yang cocok dengan kriteria."));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredBooks.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.grey[200], height: 1),
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];
                        return CollectionListItem(
                          collection: book,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider<LibraryBloc>(
                                  create: (context) => di.sl<LibraryBloc>(),
                                  child: CollectionDetailPage(collection: book),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  } else if (state is LibraryError) {
                    return Center(child: Text("Error: ${state.message}"));
                  } else if (state is LibraryEmpty) {
                    return const Center(
                        child: Text("Tidak ada buku ditemukan"));
                  } else {
                    return const Center(child: Text("Memuat data..."));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
