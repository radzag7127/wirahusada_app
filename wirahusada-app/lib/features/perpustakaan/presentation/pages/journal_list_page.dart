import 'package:flutter/material.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/book_list_page.dart';

/// JournalListPage is essentially the same as BookListPage but specialized for journals
/// This follows DRY principle by extending the common functionality
class JournalListPage extends BookListPage {
  const JournalListPage({
    super.key,
    required String category,
    required String title,
  }) : super(category: category, title: title);
}