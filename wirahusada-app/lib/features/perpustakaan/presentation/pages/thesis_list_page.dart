import 'package:flutter/material.dart';
import 'package:wismon_keuangan/features/perpustakaan/presentation/pages/book_list_page.dart';

/// ThesisListPage is essentially the same as BookListPage but specialized for thesis
/// This follows DRY principle by extending the common functionality
class ThesisListPage extends BookListPage {
  const ThesisListPage({
    super.key,
    required String category,
    required String title,
  }) : super(category: category, title: title);
}