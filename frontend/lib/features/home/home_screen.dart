import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../shell/app_state.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          onSearchTap: () => ref.read(navIndexProvider.notifier).state = 1,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Truy cập nhanh',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'Hỏi chatbot',
                        subtitle: 'Đặt câu hỏi ngay',
                        onTap: () =>
                            ref.read(navIndexProvider.notifier).state = 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAccessCard(
                        icon: Icons.menu_book_outlined,
                        title: 'Tra cứu tài liệu',
                        subtitle: 'Tài liệu của tôi',
                        onTap: () =>
                            ref.read(navIndexProvider.notifier).state = 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Trợ lý CTU có thể giúp gì?',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 12),
                const _SupportOverview(),
                const SizedBox(height: 24),
                const Text(
                  'Gợi ý câu hỏi',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuestionSuggestion(
                      text: 'Cách đăng ký học phần',
                      onTap: () =>
                          ref.read(navIndexProvider.notifier).state = 1,
                    ),
                    _QuestionSuggestion(
                      text: 'Điều kiện học bổng',
                      onTap: () =>
                          ref.read(navIndexProvider.notifier).state = 1,
                    ),
                    _QuestionSuggestion(
                      text: 'Hướng dẫn đóng học phí',
                      onTap: () =>
                          ref.read(navIndexProvider.notifier).state = 1,
                    ),
                    _QuestionSuggestion(
                      text: 'Bảo hiểm y tế',
                      onTap: () =>
                          ref.read(navIndexProvider.notifier).state = 1,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _InformationNote(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportOverview extends StatelessWidget {
  const _SupportOverview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SupportRow(
              icon: Icons.school_outlined,
              title: 'Học vụ',
              description: 'Đăng ký học phần, điểm và xếp loại học tập.',
            ),
            Divider(height: 24, color: theme.dividerColor),
            const _SupportRow(
              icon: Icons.payments_outlined,
              title: 'Tài chính sinh viên',
              description: 'Học phí, học bổng và các chính sách hỗ trợ.',
            ),
            Divider(height: 24, color: theme.dividerColor),
            const _SupportRow(
              icon: Icons.health_and_safety_outlined,
              title: 'Đời sống sinh viên',
              description: 'Bảo hiểm y tế, ký túc xá và các thủ tục cần thiết.',
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionSuggestion extends StatelessWidget {
  const _QuestionSuggestion({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.auto_awesome_outlined, size: 16),
      label: Text(text),
      onPressed: onTap,
      backgroundColor: AppColors.accentLight,
      side: BorderSide.none,
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InformationNote extends StatelessWidget {
  const _InformationNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Trợ lý trả lời dựa trên tài liệu tham khảo. Với thông tin quan trọng, hãy đối chiếu thông báo chính thức của Trường.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onSearchTap});

  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: ClipOval(
                  child: Image.asset(
                    'icon-ctu.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trường Đại học Cần Thơ',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'CTU Student Service',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Chào mừng trở lại 👋',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bạn cần hỗ trợ gì hôm nay ?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onSearchTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Theme.of(context).hintColor),
                  const SizedBox(width: 12),
                  Text(
                    'Tìm kiếm quy định, học phí...',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
