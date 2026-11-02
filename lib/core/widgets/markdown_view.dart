import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';

/// Minimal markdown renderer sufficient for KK Nutrivet blog/help content.
/// Supports headings, bold/italic/inline-code, bullet & numbered lists,
/// blockquotes, horizontal rules, links and paragraphs.
class MarkdownView extends StatelessWidget {
  const MarkdownView(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final blocks = _parse(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks
          .map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _renderBlock(context, b),
              ))
          .toList(),
    );
  }

  List<_Block> _parse(String text) {
    final lines = text.split('\n');
    final blocks = <_Block>[];
    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        i++;
        continue;
      }
      if (trimmed == '---' || trimmed == '***' || trimmed == '___') {
        blocks.add(const _Block(_BlockKind.rule, ''));
        i++;
        continue;
      }
      if (trimmed.startsWith('> ')) {
        final quote = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('> ')) {
          quote.add(lines[i].trim().substring(2));
          i++;
        }
        blocks.add(_Block(_BlockKind.quote, quote.join('\n')));
        continue;
      }
      if (RegExp(r'^#{1,6}\s').hasMatch(trimmed)) {
        blocks.add(_Block(_BlockKind.heading, trimmed));
        i++;
        continue;
      }
      if (RegExp(r'^[-*]\s').hasMatch(trimmed)) {
        final items = <String>[];
        while (i < lines.length &&
            (RegExp(r'^[-*]\s').hasMatch(lines[i].trim()) || lines[i].trim().isEmpty)) {
          if (lines[i].trim().isNotEmpty) items.add(lines[i].trim().substring(2));
          i++;
        }
        blocks.add(_Block(_BlockKind.bullets, items.join('\n')));
        continue;
      }
      if (RegExp(r'^\d+[.)]\s').hasMatch(trimmed)) {
        final items = <String>[];
        while (i < lines.length && RegExp(r'^\d+[.)]\s').hasMatch(lines[i].trim())) {
          items.add(lines[i].trim().replaceFirst(RegExp(r'^\d+[.)]\s'), ''));
          i++;
        }
        blocks.add(_Block(_BlockKind.ordered, items.join('\n')));
        continue;
      }
      if (trimmed.startsWith('|')) {
        final rows = <String>[];
        while (i < lines.length && lines[i].trim().startsWith('|')) {
          rows.add(lines[i].trim());
          i++;
        }
        blocks.add(_Block(_BlockKind.table, rows.join('\n')));
        continue;
      }
      blocks.add(_Block(_BlockKind.paragraph, trimmed));
      i++;
    }
    return blocks;
  }

  Widget _renderBlock(BuildContext context, _Block block) {
    switch (block.kind) {
      case _BlockKind.heading:
        final match = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(block.text)!;
        final level = match.group(1)!.length;
        final size = switch (level) {
          1 => 20.0,
          2 => 18.0,
          3 => 16.5,
          4 => 15.0,
          _ => 14.0,
        };
        return Text.rich(_spans(context, match.group(2)!),
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.35));
      case _BlockKind.bullets:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.text
              .split('\n')
              .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text.rich(_spans(context, item),
                                style: const TextStyle(fontSize: 14, height: 1.5))),
                      ],
                    ),
                  ))
              .toList(),
        );
      case _BlockKind.ordered:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.text
              .split('\n')
              .asMap()
              .entries
              .map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                            width: 22,
                            child: Text('${e.key + 1}.',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                        Expanded(
                            child: Text.rich(_spans(context, e.value),
                                style: const TextStyle(fontSize: 14, height: 1.5))),
                      ],
                    ),
                  ))
              .toList(),
        );
      case _BlockKind.quote:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text.rich(_spans(context, block.text),
              style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.textPrimary)),
        );
      case _BlockKind.rule:
        return const Divider(color: AppColors.border, thickness: 1);
      case _BlockKind.paragraph:
        return Text.rich(_spans(context, block.text),
            style: const TextStyle(fontSize: 14.5, height: 1.6, color: AppColors.textPrimary));
      case _BlockKind.table:
        final rows = block.text
            .split('\n')
            .where((r) => !RegExp(r'^\|[\s\-:|]+\|$').hasMatch(r))
            .toList();
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: rows.map((row) {
              final cells = row
                  .split('|')
                  .where((c) => c.trim().isNotEmpty)
                  .map((c) => c.trim())
                  .toList();
              final isHeader = rows.indexOf(row) == 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                color: isHeader ? AppColors.primary.withValues(alpha: 0.06) : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cells
                      .map((c) => Expanded(
                            child: Text.rich(_spans(context, c),
                                style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.4,
                                    fontWeight: isHeader ? FontWeight.w700 : FontWeight.w400)),
                          ))
                      .toList(),
                ),
              );
            }).toList(),
          ),
        );
    }
  }

  TextSpan _spans(BuildContext context, String text) {
    final spans = <InlineSpan>[];
    final inlineRegex = RegExp(r'(\*\*\*.*?\*\*\*|\*\*.*?\*\*|`[^`]+`|\*[^*]+\*|\[[^\]]+\]\([^)]+\))');
    var last = 0;
    for (final match in inlineRegex.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(text: text.substring(last, match.start)));
      }
      final token = match.group(0)!;
      if (token.startsWith('***') && token.endsWith('***')) {
        spans.add(TextSpan(
            text: token.substring(3, token.length - 3),
            style: const TextStyle(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)));
      } else if (token.startsWith('**')) {
        spans.add(TextSpan(
            text: token.substring(2, token.length - 2),
            style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (token.startsWith('`')) {
        spans.add(TextSpan(
            text: token.substring(1, token.length - 1),
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12.5,
                color: AppColors.primaryDark,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08))));
      } else if (token.startsWith('*')) {
        spans.add(TextSpan(
            text: token.substring(1, token.length - 1),
            style: const TextStyle(fontStyle: FontStyle.italic)));
      } else if (token.startsWith('[')) {
        final linkMatch = RegExp(r'\[([^\]]+)\]\(([^)]+)\)').firstMatch(token)!;
        final label = linkMatch.group(1)!;
        final url = linkMatch.group(2)!;
        spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
              child: Text(label,
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            )));
      }
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(text: text.substring(last)));
    }
    return TextSpan(children: spans);
  }
}

enum _BlockKind { heading, paragraph, bullets, ordered, quote, rule, table }

class _Block {
  const _Block(this.kind, this.text);
  final _BlockKind kind;
  final String text;
}
