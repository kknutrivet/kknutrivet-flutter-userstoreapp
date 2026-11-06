/// Converts the small subset of HTML returned by the content API into the
/// lightweight markdown rendered by `MarkdownView`.
///
/// Blog content comes from the CMS as HTML (`<p>`, `<h2>`, lists, links), so
/// rendering it as markdown directly leaks tags such as `<p>` into the UI.
/// This intentionally supports only the common inline/block tags; unknown tags
/// are stripped rather than shown to the reader.
String htmlToMarkdown(String input) {
  if (!RegExp(
    r'<(p|br|div|h[1-6]|ul|ol|li|strong|b|em|i|blockquote|a|code)\b',
    caseSensitive: false,
  ).hasMatch(input)) {
    return input;
  }

  var text = input.replaceAll('\r\n', '\n');

  text = text.replaceAllMapped(
    RegExp(r'<h([1-6])[^>]*>(.*?)</h\1>', caseSensitive: false, dotAll: true),
    (match) => '\n\n${'#' * int.parse(match[1]!)} ${match[2]}\n\n',
  );

  text = text.replaceAllMapped(
    RegExp(
      r'''<a[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>''',
      caseSensitive: false,
      dotAll: true,
    ),
    (match) => '[${match[2]}](${match[1]})',
  );

  text = text
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n- ')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<blockquote[^>]*>', caseSensitive: false), '\n> ')
      .replaceAll(RegExp(r'</blockquote>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<(strong|b)[^>]*>', caseSensitive: false), '**')
      .replaceAll(RegExp(r'</(strong|b)>', caseSensitive: false), '**')
      .replaceAll(RegExp(r'<(em|i)[^>]*>', caseSensitive: false), '*')
      .replaceAll(RegExp(r'</(em|i)>', caseSensitive: false), '*')
      .replaceAll(RegExp(r'<code[^>]*>', caseSensitive: false), '`')
      .replaceAll(RegExp(r'</code>', caseSensitive: false), '`')
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<p[^>]*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<div[^>]*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<ul[^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</ul>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<ol[^>]*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</ol>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '');

  text = _decodeEntities(text);
  text = text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trimRight())
      .join('\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n');

  return text.trim();
}

const Map<String, String> _namedEntities = {
  'amp': '&',
  'apos': "'",
  'gt': '>',
  'hellip': '…',
  'ldquo': '“',
  'lsquo': '‘',
  'lt': '<',
  'mdash': '—',
  'nbsp': ' ',
  'ndash': '–',
  'quot': '"',
  'rdquo': '”',
  'rsquo': '’',
  'times': '×',
};

String _decodeEntities(String input) {
  return input.replaceAllMapped(RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z]+);'), (
    match,
  ) {
    final entity = match[1]!;
    if (entity.startsWith('#x') || entity.startsWith('#X')) {
      final code = int.tryParse(entity.substring(2), radix: 16);
      return code == null ? match[0]! : String.fromCharCode(code);
    }
    if (entity.startsWith('#')) {
      final code = int.tryParse(entity.substring(1));
      return code == null ? match[0]! : String.fromCharCode(code);
    }
    return _namedEntities[entity.toLowerCase()] ?? match[0]!;
  });
}
