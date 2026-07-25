import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            decoration: const BoxDecoration(gradient: AppColors.headerGradient),
            child: const Text(
              'Tài liệu tham khảo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      color: AppColors.primary,
                      size: 52,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có API tài liệu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Danh mục và tài liệu sẽ hiển thị khi backend cung cấp endpoint tương ứng.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
