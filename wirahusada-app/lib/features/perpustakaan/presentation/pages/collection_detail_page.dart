import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wismon_keuangan/features/perpustakaan/domain/entities/collection.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_bloc.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_event.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/bloc/library_state.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/widgets/borrow_request_dialog.dart';

class CollectionDetailPage extends StatefulWidget {
  final Collection collection;

  const CollectionDetailPage({
    super.key,
    required this.collection,
  });

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  late LibraryBloc _libraryBloc;

  @override
  void initState() {
    super.initState();
    _libraryBloc = BlocProvider.of<LibraryBloc>(context);
  }

  void _showBorrowDialog() {
    showDialog(
      context: context,
      builder: (context) => BlocProvider.value(
        value: _libraryBloc,
        child: BorrowRequestDialog(
          collection: widget.collection,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Koleksi',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<LibraryBloc, LibraryState>(
        listener: (context, state) {
          if (state is BorrowRequestSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(); // Close dialog if open
          } else if (state is LibraryError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with cover image
              Container(
                height: 250,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cover placeholder or image
                    Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: widget.collection.sampul?.isNotEmpty == true
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.collection.sampul!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildCoverPlaceholder(),
                              ),
                            )
                          : _buildCoverPlaceholder(),
                    ),
                    const SizedBox(height: 16),
                    // Availability status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (widget.collection.stokTersedia ?? 0) > 0
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        (widget.collection.stokTersedia ?? 0) > 0
                            ? 'Tersedia (${widget.collection.stokTersedia ?? 0})'
                            : 'Tidak Tersedia',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content section
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.collection.judul,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Author
                      if (widget.collection.penulis?.isNotEmpty == true)
                        Text(
                          'oleh ${widget.collection.penulis}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Details section
                      _buildDetailSection('Informasi Koleksi', [
                        _buildDetailItem('Kode', widget.collection.kode),
                        _buildDetailItem('Kategori', widget.collection.kategori),
                        if (widget.collection.topik?.isNotEmpty == true)
                          _buildDetailItem('Topik', widget.collection.topik!),
                        if (widget.collection.penerbit?.isNotEmpty == true)
                          _buildDetailItem('Penerbit', widget.collection.penerbit!),
                        if (widget.collection.tahun != null)
                          _buildDetailItem('Tahun Terbit', widget.collection.tahun!),
                        if (widget.collection.isbn?.isNotEmpty == true)
                          _buildDetailItem('ISBN', widget.collection.isbn!),
                        _buildDetailItem('Total Stok', (widget.collection.stokTotal ?? 0).toString()),
                        _buildDetailItem('Stok Tersedia', (widget.collection.stokTersedia ?? 0).toString()),
                        if (widget.collection.lokasiRak?.isNotEmpty == true)
                          _buildDetailItem('Lokasi Rak', widget.collection.lokasiRak!),
                      ]),
                      
                      const SizedBox(height: 24),
                      
                      // Description
                      if (widget.collection.deskripsi?.isNotEmpty == true) ...[
                        _buildDetailSection('Deskripsi', []),
                        const SizedBox(height: 8),
                        Text(
                          widget.collection.deskripsi!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      // Borrow button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (widget.collection.stokTersedia ?? 0) > 0
                              ? _showBorrowDialog
                              : null,
                          icon: Icon(
                            (widget.collection.stokTersedia ?? 0) > 0
                                ? Icons.book_online
                                : Icons.block,
                            color: Colors.white,
                          ),
                          label: Text(
                            (widget.collection.stokTersedia ?? 0) > 0
                                ? 'Ajukan Peminjaman'
                                : 'Tidak Tersedia',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (widget.collection.stokTersedia ?? 0) > 0
                                ? const Color(0xFF4CAF50)
                                : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getCategoryIcon(),
            size: 40,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            widget.collection.kategori.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (widget.collection.kategori.toLowerCase()) {
      case 'buku':
        return Icons.book;
      case 'jurnal':
        return Icons.article;
      case 'skripsi':
      case 'tesis':
      case 'disertasi':
        return Icons.school;
      default:
        return Icons.library_books;
    }
  }

  Widget _buildDetailSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}