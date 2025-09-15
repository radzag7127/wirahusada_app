import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_bloc.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_event.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_state.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/widgets/collection_card.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/widgets/search_bar_widget.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/widgets/loading_indicator.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/widgets/empty_state_widget.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/widgets/error_widget.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/collection_detail_page.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/core/di/injection_container.dart' as di;

class BookListPage extends StatefulWidget {
  final String? category;
  final String title;

  const BookListPage({
    super.key,
    required this.category,
    required this.title,
  });

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  late LibraryBloc _libraryBloc;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _libraryBloc = BlocProvider.of<LibraryBloc>(context);
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    if (widget.category != null) {
      _libraryBloc.add(LoadCollectionsByCategoryEvent(category: widget.category!));
    } else {
      _libraryBloc.add(const LoadAllCollectionsEvent());
    }
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      _loadInitialData();
    } else {
      _libraryBloc.add(SearchCollectionsEvent(query: query.trim()));
    }
  }

  void _onRefresh() {
    _searchController.clear();
    _loadInitialData();
  }

  void _navigateToDetail(Collection collection) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider<LibraryBloc>(
          create: (context) => di.sl<LibraryBloc>(),
          child: CollectionDetailPage(collection: collection),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: const Color(0xFF1976D2),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchBarWidget(
                controller: _searchController,
                onChanged: _onSearchChanged,
                hintText: 'Cari ${widget.category ?? 'koleksi'}...',
              ),
            ),
          ),
          // Content
          Expanded(
            child: BlocBuilder<LibraryBloc, LibraryState>(
              builder: (context, state) {
                if (state is LibraryLoading) {
                  return const LibraryLoadingIndicator();
                }
                
                if (state is LibraryError) {
                  return LibraryErrorWidget(
                    message: state.message,
                    onRetry: _onRefresh,
                  );
                }
                
                if (state is LibraryEmpty) {
                  return EmptyStateWidget(
                    message: state.message,
                    onRefresh: _onRefresh,
                  );
                }
                
                if (state is LibraryLoaded) {
                  if (state.collections.isEmpty) {
                    String emptyMessage;
                    if (state.isSearchActive && state.searchQuery?.isNotEmpty == true) {
                      emptyMessage = 'Tidak ada hasil untuk pencarian "${state.searchQuery}"';
                    } else if (widget.category != null) {
                      emptyMessage = 'Belum ada koleksi ${widget.category}';
                    } else {
                      emptyMessage = 'Belum ada koleksi tersedia';
                    }
                    
                    return EmptyStateWidget(
                      message: emptyMessage,
                      onRefresh: _onRefresh,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _onRefresh(),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.collections.length,
                      itemBuilder: (context, index) {
                        final collection = state.collections[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CollectionCard(
                            collection: collection,
                            onTap: () => _navigateToDetail(collection),
                          ),
                        );
                      },
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state is LibraryLoaded && state.collections.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: const Color(0xFF1976D2),
              child: const Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}