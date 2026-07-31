import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectionArea(
              child: _FormattedMessage(
                text: text,
                color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color,
              ),
            ),
            if (!isUser)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Sao chép câu trả lời',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.copy_outlined,
                    size: 17,
                    color: theme.hintColor,
                  ),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép câu trả lời')),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Renders the Markdown and LaTex formats returned by the RAG model.
///
/// Supported: `**bold**`, `[label](url)`, inline `$x$`/`\\(x\\)`, and
/// display formulas delimited by `$$ ... $$`.
class _FormattedMessage extends StatelessWidget {
  const _FormattedMessage({required this.text, required this.color});

  final String text;
  final Color? color;

  static final _displayMathPattern = RegExp(r'\$\$([\s\S]*?)\$\$');
  static final _inlinePattern = RegExp(
    r'(\*\*.+?\*\*|\[.+?\]\(.+?\)|\\\(.+?\\\)|\$[^$\n]+?\$)',
  );

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: color, fontSize: 15, height: 1.4);
    final children = <Widget>[];
    var cursor = 0;

    for (final match in _displayMathPattern.allMatches(text)) {
      if (match.start > cursor) {
        children.add(_richTextBlock(text.substring(cursor, match.start), style));
      }

      final formula = match.group(1)?.trim() ?? '';
      if (formula.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(formula, textStyle: style),
            ),
          ),
        );
      }
      cursor = match.end;
    }

    if (cursor < text.length || children.isEmpty) {
      children.add(_richTextBlock(text.substring(cursor), style));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  InlineSpan _spanFor(String value, TextStyle style) {
    if (value.startsWith('**') && value.endsWith('**')) {
      return TextSpan(
        text: value.substring(2, value.length - 2),
        style: style.copyWith(fontWeight: FontWeight.w700),
      );
    }

    if (value.startsWith('[')) {
      final labelEnd = value.indexOf('](');
      return TextSpan(
        text: labelEnd > 1 ? value.substring(1, labelEnd) : value,
        style: style.copyWith(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
        ),
      );
    }

    if (value.startsWith(r'$') && value.endsWith(r'$')) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Math.tex(value.substring(1, value.length - 1), textStyle: style),
      );
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Math.tex(value.substring(2, value.length - 2), textStyle: style),
    );
  }

  Widget _richTextBlock(String value, TextStyle style) {
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _inlinePattern.allMatches(value)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: value.substring(cursor, match.start)));
      }
      spans.add(_spanFor(match.group(0)!, style));
      cursor = match.end;
    }
    if (cursor < value.length) spans.add(TextSpan(text: value.substring(cursor)));

    return Text.rich(TextSpan(style: style, children: spans));
  }
}
