import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/source_ref.dart';

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key, required this.sources});

  final List<SourceRef> sources;

  /// Gộp các nguồn trùng tài liệu (cùng `documentKey`), giữ nguyên thứ tự
  /// xuất hiện. Mỗi tài liệu chỉ hiện một thẻ chi tiết.
  List<SourceRef> get _uniqueDocuments {
    final seen = <String>{};
    final result = <SourceRef>[];
    for (final source in sources) {
      final key = source.documentKey.isNotEmpty
          ? source.documentKey
          : source.versionKey;
      if (seen.add(key)) result.add(source);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final documents = _uniqueDocuments;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết tài liệu'),
        foregroundColor: Colors.white,
        backgroundColor: AppColors.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (context, i) => _DocumentCard(source: documents[i]),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.source});

  final SourceRef source;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              source.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
            const Divider(height: 26),
            _DetailRow(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Tên file gốc',
              value: source.sourceFileNameLabel,
            ),
            _DetailRow(
              icon: Icons.event_outlined,
              label: 'Ngày ban hành',
              value: source.issuedDateLabel,
            ),
            _DetailRow(
              icon: Icons.apartment_outlined,
              label: 'Đơn vị chịu trách nhiệm',
              value: source.issuingAuthorityLabel,
            ),
            _DetailRow(
              icon: Icons.category_outlined,
              label: 'Loại tài liệu',
              value: source.documentTypeLabel,
            ),
            if (source.pageLabel.isNotEmpty)
              _DetailRow(
                icon: Icons.description_outlined,
                label: 'Vị trí trích dẫn',
                value: source.pageLabel,
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
