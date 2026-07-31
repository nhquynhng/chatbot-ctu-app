import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/source_ref.dart';

final themeModeProvider =
    StateProvider<ThemeMode>((ref) => ThemeMode.light);

final navIndexProvider = StateProvider<int>((ref) => 0);

/// Documents bookmarked by the student during the current app session.
final savedDocumentsProvider = StateProvider<List<SourceRef>>(
  (ref) => const [],
);
