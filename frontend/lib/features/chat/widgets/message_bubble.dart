import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as markdown;
import 'package:flutter_markdown_plus_latex/flutter_markdown_plus_latex.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = isUser ? Colors.white : theme.textTheme.bodyLarge?.color;

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
            markdown.MarkdownBody(
              data: text,
              selectable: true,
              extensionSet: md.ExtensionSet(
                [
                  ...md.ExtensionSet.gitHubFlavored.blockSyntaxes,
                  LatexBlockSyntax(),
                ],
                [
                  ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                  LatexInlineSyntax(),
                ],
              ),
              builders: {
                'latex': LatexElementBuilder(
                  textStyle: TextStyle(color: textColor, fontSize: 15),
                ),
              },
              onTapLink: (_, href,_) {
                if (href == null) return;
                launchUrl(
                  Uri.parse(href),
                  mode: LaunchMode.externalApplication,
                );
              },
              styleSheet: markdown.MarkdownStyleSheet.fromTheme(theme).copyWith(
                p: TextStyle(color: textColor, fontSize: 15, height: 1.4),
                a: TextStyle(
                  color: isUser ? Colors.white : AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
                strong: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
                tableBorder: TableBorder.all(
                  color: textColor?.withValues(alpha: 0.2) ?? Colors.grey,
                ),
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
