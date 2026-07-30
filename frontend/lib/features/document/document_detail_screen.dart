import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/source_ref.dart';
import '../chat/data/rag_api_client.dart';

class DocumentDetailScreen extends StatelessWidget {
  const DocumentDetailScreen({
    super.key,
    required this.sources,
  });

  final List<SourceRef> sources;

  /// Gộp các nguồn trùng tài liệu, giữ nguyên thứ tự xuất hiện.
  List<SourceRef> get _uniqueDocuments {
    final seen = <String>{};
    final result = <SourceRef>[];

    for (final source in sources) {
      final key = source.documentKey.isNotEmpty
          ? source.documentKey
          : source.versionKey;

      if (seen.add(key)) {
        result.add(source);
      }
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
      body: documents.isEmpty
          ? const Center(
              child: Text('Không có thông tin tài liệu.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: documents.length,
              itemBuilder: (context, index) {
                return _DocumentCard(
                  source: documents[index],
                );
              },
            ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.source,
  });

  final SourceRef source;

  Future<void> _openUri(
    BuildContext context,
    Uri uri,
  ) async {
    if (!uri.hasScheme ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      _showMessage(
        context,
        'Đường dẫn tài liệu không hợp lệ.',
      );
      return;
    }

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
    );

    if (!opened && context.mounted) {
      _showMessage(
        context,
        'Không thể mở đường dẫn tài liệu.',
      );
    }
  }

  Future<void> _openSourceWeb(
    BuildContext context,
  ) async {
    final rawUrl = source.sourceUrl;
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);

    if (uri == null) {
      _showMessage(
        context,
        'Trang web nguồn không hợp lệ.',
      );
      return;
    }

    await _openUri(context, uri);
  }

  Future<void> _openSourceFile(
    BuildContext context,
  ) async {
    try {
      final preview = await RagApiClient().getSourcePreviewUrl(
        source.versionKey,
      );

      if (!context.mounted) return;
      await _openUri(context, preview.url);
    } on RagApiException catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.message);
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(
        context,
        'Không thể mở file nguồn.',
      );
    }
  }

  Future<void> _openCanonicalMarkdown(
    BuildContext context,
  ) async {
    try {
      final preview =
          await RagApiClient().getCanonicalMarkdownPreviewUrl(
        source.versionKey,
      );

      if (!context.mounted) return;
      await _openUri(context, preview.url);
    } on RagApiException catch (error) {
      if (!context.mounted) return;
      _showMessage(context, error.message);
    } catch (_) {
      if (!context.mounted) return;
      _showMessage(
        context,
        'Không thể mở bản OCR.',
      );
    }
  }

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyLink = source.hasSourceUrl ||
        source.hasSourceFile ||
        source.hasCanonicalMarkdown;

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
            if (source.hasCanonicalMarkdown)
              _DetailRow(
                icon: Icons.article_outlined,
                label: 'Tên file OCR',
                value: source.canonicalMarkdownFileNameLabel,
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
            if (hasAnyLink) ...[
              const Divider(height: 26),
              const Text(
                'Xem tài liệu',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (source.hasSourceUrl)
                    OutlinedButton.icon(
                      onPressed: () => _openSourceWeb(context),
                      icon: const Icon(Icons.language),
                      label: const Text('Mở trang web'),
                    ),
                  if (source.hasSourceFile)
                    OutlinedButton.icon(
                      onPressed: () => _openSourceFile(context),
                      icon: const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('Xem file gốc'),
                    ),
                  if (source.hasCanonicalMarkdown)
                    OutlinedButton.icon(
                      onPressed: () =>
                          _openCanonicalMarkdown(context),
                      icon: const Icon(Icons.article_outlined),
                      label: const Text('Xem bản OCR'),
                    ),
                ],
              ),
            ],
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
          Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 12,
                  ),
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