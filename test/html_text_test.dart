import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/utils/html_text.dart';

void main() {
  group('htmlToMarkdown', () {
    test('strips paragraph tags used by the CMS', () {
      expect(
        htmlToMarkdown('<p>Balanced meals keep pets active and healthy.</p>'),
        'Balanced meals keep pets active and healthy.',
      );
    });

    test('converts headings, lists and links', () {
      final result = htmlToMarkdown(
        '<h2>Feeding guide</h2>'
        '<ul><li>Fresh water</li><li>Measured portions</li></ul>'
        '<p>Read <a href="https://example.com">the full guide</a>.</p>',
      );

      expect(result, contains('## Feeding guide'));
      expect(result, contains('- Fresh water'));
      expect(result, contains('- Measured portions'));
      expect(
        result,
        contains('[the full guide](https://example.com)'),
      );
      expect(result, isNot(contains('<')));
    });

    test('decodes common and numeric entities', () {
      expect(
        htmlToMarkdown('<p>Fish &amp; chips&nbsp;—&nbsp;5 &#8377;</p>'),
        'Fish & chips — 5 ₹',
      );
      expect(htmlToMarkdown('<p>&#x1F436; approved</p>'), '🐶 approved');
    });

    test('leaves plain markdown untouched', () {
      const markdown = '## Title\n\n- One\n- Two\n\n**Bold** text.';
      expect(htmlToMarkdown(markdown), markdown);
    });

    test('keeps comparison symbols that are not tags', () {
      expect(
        htmlToMarkdown('<p>Dose is 5 < 10 mg &gt; 1 mg.</p>'),
        'Dose is 5 < 10 mg > 1 mg.',
      );
    });
  });
}
