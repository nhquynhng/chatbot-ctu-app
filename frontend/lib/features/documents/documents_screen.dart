import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../chat/widgets/source_card.dart';
import '../document/document_detail_screen.dart';
import '../shell/app_state.dart';

class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedDocuments = ref.watch(savedDocumentsProvider);

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 14,
              16,
              18,
            ),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: const Text(
              'Tài liệu đã lưu',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          Expanded(
            child: savedDocuments.isEmpty
                ? const _EmptySavedDocuments()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        'Đã lưu (${savedDocuments.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final source in savedDocuments)
                        SourceCard(
                          source: source,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  DocumentDetailScreen(sources: [source]),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptySavedDocuments extends StatelessWidget {
  const _EmptySavedDocuments();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              color: AppColors.primary,
              size: 52,
            ),
            SizedBox(height: 16),
            Text(
              'Chưa có tài liệu đã lưu',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Mở chi tiết một tài liệu từ phần Chat rồi bấm nút lưu để xem lại tại đây.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
