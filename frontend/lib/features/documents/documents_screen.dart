import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/mock/mock_data.dart';
import '../../shared/models/document_category.dart';
import 'category_detail_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  String _query = '';

  List<DocumentCategory> get _filtered {
    if (_query.isEmpty) return kDocumentCategories;
    final q = _query.toLowerCase();
    return kDocumentCategories
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q))
        .toList();
  }

  int get _totalDocs => kDocumentsByCategory.values
      .fold(0, (sum, list) => sum + list.length);

  @override
  Widget build(BuildContext context) {
    final categories = _filtered;
    return Scaffold(
      body: Column(
        children: [
          _DocumentsHeader(
            categoryCount: kDocumentCategories.length,
            onSearch: (value) => setState(() => _query = value),
          ),
          _StatsBar(
            categoryCount: kDocumentCategories.length,
            totalDocs: _totalDocs,
            latestDate: kDocumentLatestUpdate,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Chọn loại tài liệu để xem chi tiết',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: categories.length,
              itemBuilder: (context, i) =>
                  _CategoryCard(category: categories[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsHeader extends StatelessWidget {
  const _DocumentsHeader({required this.categoryCount, required this.onSearch});

  final int categoryCount;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 14, 16, 18),
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tài liệu tham khảo',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          const SizedBox(height: 4),
          Text('$categoryCount loại tài liệu',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 14),
          TextField(
            onChanged: onSearch,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm loại tài liệu...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  const _StatsBar({
    required this.categoryCount,
    required this.totalDocs,
    required this.latestDate,
  });

  final int categoryCount;
  final int totalDocs;
  final String latestDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Row(
        children: [
          _Stat(value: '$categoryCount', label: 'Loại tài liệu'),
          _divider(),
          _Stat(value: '$totalDocs', label: 'Tổng tài liệu'),
          _divider(),
          _Stat(value: latestDate, label: 'Cập nhật mới nhất'),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: Colors.grey.withValues(alpha: 0.25),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).hintColor, fontSize: 11)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final DocumentCategory category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = kDocumentsByCategory[category.key]?.length ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryDetailScreen(category: category),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: category.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: category.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(category.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: category.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$count',
                              style: TextStyle(
                                  color: category.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(category.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: theme.hintColor, fontSize: 13)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 13, color: theme.hintColor),
                        const SizedBox(width: 5),
                        Text('Mới nhất: ${category.latestDate}',
                            style: TextStyle(
                                color: theme.hintColor, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.hintColor),
            ],
          ),
        ),
      ),
    );
  }
}
