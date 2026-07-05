import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/mock/mock_data.dart';
import '../../shared/models/document_detail.dart';

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({super.key, required this.documentKey});

  final String documentKey;

  @override
  Widget build(BuildContext context) {
    final doc = kMockDocuments[documentKey];

    return Scaffold(
      body: Column(
        children: [
          _DetailHeader(),
          Expanded(
            child: doc == null
                ? const Center(child: Text('Không tìm thấy tài liệu'))
                : _DetailBody(doc: doc),
          ),
          if (doc != null) _DocumentActions(doc: doc),
          _BackToChatButton(),
        ],
      ),
    );
  }
}

class _DocumentActions extends StatelessWidget {
  const _DocumentActions({required this.doc});

  final DocumentDetail doc;

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: doc.sourceUrl.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(
                          ClipboardData(text: doc.sourceUrl));
                      if (context.mounted) {
                        _showSnack(context, 'Đã sao chép liên kết tài liệu');
                      }
                    },
              icon: const Icon(Icons.link, size: 20),
              label: const Text('Sao chép liên kết'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: doc.pdfFileName.isEmpty
                  ? null
                  : () => _showSnack(
                      context, 'Đang tải xuống ${doc.pdfFileName}'),
              icon: const Icon(Icons.download, size: 20),
              label: const Text('Tải xuống'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          8, MediaQuery.of(context).padding.top + 8, 8, 20),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nguồn tham khảo',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('Chi tiết tài liệu',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chia sẻ tài liệu')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.doc});

  final DocumentDetail doc;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_outlined,
                            color: AppColors.primary, size: 16),
                        const SizedBox(width: 6),
                        Text(doc.category,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(doc.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          height: 1.25)),
                  const SizedBox(height: 10),
                  Text('• Trang ${doc.page} / ${doc.section}',
                      style: TextStyle(color: theme.hintColor, fontSize: 14)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetaTile(
                  icon: Icons.apartment,
                  label: 'ĐƠN VỊ',
                  value: doc.department,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetaTile(
                  icon: Icons.calendar_today,
                  label: 'NGÀY CẬP NHẬT',
                  value: doc.updatedDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetaTile(
                  icon: Icons.description_outlined,
                  label: 'LOẠI TÀI LIỆU',
                  value: doc.documentType,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetaTile(
                  icon: Icons.bookmark_border,
                  label: 'MÃ TÀI LIỆU',
                  value: doc.code,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15, height: 1.3)),
          ],
        ),
      ),
    );
  }
}

class _BackToChatButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back),
                SizedBox(width: 8),
                Text('Quay lại cuộc trò chuyện',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
