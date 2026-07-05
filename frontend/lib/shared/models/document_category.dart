import 'package:flutter/material.dart';

class DocumentCategory {
  final String key;
  final String name;
  final String description;
  final String latestDate;
  final IconData icon;
  final Color color;
  final Color bg;

  const DocumentCategory({
    required this.key,
    required this.name,
    required this.description,
    required this.latestDate,
    required this.icon,
    required this.color,
    required this.bg,
  });
}
