// Builds a browsable HTML report from the visual regression screenshots.
//
//   flutter test test/visual --update-goldens   // refresh committed goldens
//   flutter test test/visual                    // verify UI did not change
//   dart run tool/visual_gallery.dart           // build the report
//   open build/visual-report/index.html
//
// When a visual test fails, Flutter writes expected/actual/diff images to
// test/failures/. The report shows those side by side too.
import 'dart:convert';
import 'dart:io';

const Map<String, String> _titles = {
  'home': 'Home',
  'products': 'Product catalogue',
  'product_detail': 'Product detail',
  'cart': 'Cart',
  'checkout': 'Checkout',
  'profile': 'Profile',
  'orders': 'Orders',
  'pets': 'Pets',
  'consultations': 'Consultations',
  'vet': 'Ask Dr. Paw',
  'blog': 'Blog',
  'help': 'Help',
  'referral': 'Referral',
  'info_about': 'About us',
  'cart_tablet': 'Cart (tablet)',
  'login': 'Sign in',
  'onboarding': 'Onboarding',
};

void main() {
  final root = Directory.current;
  final reportDir = Directory('${root.path}/build/visual-report')
    ..createSync(recursive: true);
  final screensDir = Directory('${reportDir.path}/screens')
    ..createSync(recursive: true);
  final failuresDir = Directory('${reportDir.path}/failures')
    ..createSync(recursive: true);

  final goldens = Directory('${root.path}/test/visual/goldens');
  final manifest = _readManifest('${reportDir.path}/manifest.json');

  final screens = <_Shot>[];
  if (goldens.existsSync()) {
    for (final file in goldens.listSync().whereType<File>()) {
      if (!file.path.endsWith('.png')) continue;
      final name = _basename(file.path);
      file.copySync('${screensDir.path}/$name');
      final meta = manifest[name.replaceAll(RegExp(r'\.png$'), '')];
      screens.add(
        _Shot(
          name: name,
          title: meta?['title'] as String? ?? _titleFor(name),
          route: meta?['route'] as String? ?? '',
          width: meta?['width'] as int?,
          height: meta?['height'] as int?,
          file: 'screens/$name',
        ),
      );
    }
  }
  screens.sort((a, b) => a.title.compareTo(b.title));

  final failures = <_Failure>[];
  final failureSource = Directory('${root.path}/test/failures');
  if (failureSource.existsSync()) {
    final files = failureSource
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .toList();
    final grouped = <String, List<File>>{};
    for (final file in files) {
      final name = _basename(file.path);
      final group = name.replaceFirst(
        RegExp(r'_(actual|expected|diff|maskedDiff|isolatedDiff)\.png$'),
        '',
      );
      grouped.putIfAbsent(group, () => []).add(file);
    }
    for (final entry in grouped.entries) {
      final images = <_Shot>[];
      for (final file in entry.value) {
        final name = _basename(file.path);
        file.copySync('${failuresDir.path}/$name');
        images.add(
          _Shot(
            name: name,
            title: _variantFor(name),
            route: '',
            file: 'failures/$name',
          ),
        );
      }
      images.sort((a, b) => a.title.compareTo(b.title));
      failures.add(_Failure(title: entry.key, images: images));
    }
  }

  final html = _buildHtml(
    screens: screens,
    failures: failures,
    generatedAt: DateTime.now(),
  );
  File('${reportDir.path}/index.html').writeAsStringSync(html);

  stdout.writeln('Visual report: ${reportDir.path}/index.html');
  stdout.writeln('Screens: ${screens.length}');
  stdout.writeln('Failing screens: ${failures.length}');
  if (failures.isNotEmpty) {
    stdout.writeln(
      'Review the diffs, fix the UI or accept the change with '
      '`flutter test test/visual --update-goldens`.',
    );
  }
}

Map<String, Map<String, dynamic>> _readManifest(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  try {
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! List) return {};
    return {
      for (final entry in decoded.whereType<Map<String, dynamic>>())
        if (entry['name'] is String)
          entry['name'] as String: {
            'title': entry['title'] as String? ??
                _titleFor('${entry['name']}.png'),
            'route': entry['route'],
            'width': entry['width'],
            'height': entry['height'],
          },
    };
  } on FormatException {
    return {};
  }
}

String _basename(String path) => path.split(Platform.pathSeparator).last;

String _titleFor(String filename) {
  final key = filename.replaceAll(RegExp(r'\.png$'), '');
  final known = _titles[key];
  if (known != null) return known;
  final words = key.replaceAll('_', ' ').trim();
  if (words.isEmpty) return key;
  return words[0].toUpperCase() + words.substring(1);
}

String _variantFor(String filename) {
  if (filename.contains('actual')) return 'Actual';
  if (filename.contains('expected')) return 'Expected';
  if (filename.contains('maskedDiff') || filename.contains('isolatedDiff')) {
    return 'Diff';
  }
  if (filename.contains('diff')) return 'Diff';
  return 'Screenshot';
}

String _buildHtml({
  required List<_Shot> screens,
  required List<_Failure> failures,
  required DateTime generatedAt,
}) {
  const css = r'''
    :root {
      color-scheme: dark;
      --bg: #0e1512;
      --panel: #151f1a;
      --panel-2: #1b2822;
      --border: #2b3b33;
      --text: #eef5f0;
      --muted: #93a69b;
      --brand: #4c9b7a;
      --danger: #e07a6a;
      --radius: 14px;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: radial-gradient(1200px 600px at 20% -10%, #163328 0%, var(--bg) 55%);
      color: var(--text);
      font: 15px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    header {
      padding: 34px 34px 18px;
      display: flex;
      flex-wrap: wrap;
      gap: 18px;
      align-items: flex-end;
      justify-content: space-between;
    }
    h1 { margin: 0; font-size: 26px; letter-spacing: -0.02em; }
    h2 { margin: 34px 34px 14px; font-size: 18px; }
    .sub { color: var(--muted); margin-top: 4px; font-size: 13px; }
    .stats { display: flex; gap: 10px; flex-wrap: wrap; }
    .pill {
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: 999px;
      padding: 6px 12px;
      font-size: 13px;
      color: var(--muted);
    }
    .pill strong { color: var(--text); }
    .toolbar { padding: 0 34px; }
    input[type=search] {
      width: 100%;
      max-width: 420px;
      padding: 10px 14px;
      border-radius: 10px;
      border: 1px solid var(--border);
      background: var(--panel);
      color: var(--text);
      outline: none;
      font: inherit;
    }
    input[type=search]:focus { border-color: var(--brand); }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(250px, 1fr));
      gap: 18px;
      padding: 18px 34px 44px;
    }
    figure {
      margin: 0;
      background: var(--panel);
      border: 1px solid var(--border);
      border-radius: var(--radius);
      overflow: hidden;
      transition: transform 120ms ease, border-color 120ms ease;
    }
    figure:hover { transform: translateY(-2px); border-color: var(--brand); }
    figure img {
      display: block;
      width: 100%;
      height: auto;
      background: #0a0f0c;
      cursor: zoom-in;
    }
    figcaption { padding: 12px 14px 14px; }
    .name { font-weight: 600; }
    .meta {
      color: var(--muted);
      font-size: 12px;
      margin-top: 3px;
      font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
      overflow-wrap: anywhere;
    }
    .empty {
      margin: 0 34px 40px;
      padding: 22px;
      border: 1px dashed var(--border);
      border-radius: var(--radius);
      color: var(--muted);
      background: var(--panel);
    }
    .failures { border-top: 1px solid var(--border); margin-top: 10px; }
    .failure {
      margin: 18px 34px;
      padding: 16px;
      border: 1px solid rgba(224, 122, 106, 0.4);
      border-radius: var(--radius);
      background: var(--panel);
    }
    .failure h3 { margin: 0 0 12px; font-size: 15px; color: var(--danger); }
    .variants {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 14px;
    }
    .variants figure { background: var(--panel-2); }
    dialog {
      border: none;
      background: transparent;
      padding: 0;
      max-width: 96vw;
      max-height: 96vh;
    }
    dialog::backdrop { background: rgba(0, 0, 0, 0.82); }
    dialog img {
      display: block;
      max-width: 96vw;
      max-height: 88vh;
      margin: 0 auto;
      border-radius: 10px;
      background: #0a0f0c;
    }
    dialog p {
      text-align: center;
      color: var(--muted);
      font-size: 13px;
      margin: 10px 0 0;
    }
    code {
      background: var(--panel-2);
      border: 1px solid var(--border);
      border-radius: 5px;
      padding: 1px 5px;
      font-size: 12px;
    }
  ''';

  String card(_Shot shot) {
    final meta = [
      if (shot.route.isNotEmpty) shot.route,
      if (shot.width != null && shot.height != null) '${shot.width}×${shot.height}',
    ].join(' · ');
    final payload = const HtmlEscape().convert(jsonEncode([shot.file, shot.title]));
    return '''
      <figure data-search="${const HtmlEscape().convert('${shot.title} ${shot.route} ${shot.name}'.toLowerCase())}">
        <img src="${shot.file}" alt="${const HtmlEscape().convert(shot.title)}"
             loading="lazy" onclick="zoom($payload)">
        <figcaption>
          <div class="name">${const HtmlEscape().convert(shot.title)}</div>
          <div class="meta">${const HtmlEscape().convert(meta)}</div>
        </figcaption>
      </figure>''';
  }

  final generated = generatedAt.toLocal().toString().split('.').first;
  final buffer = StringBuffer()
    ..writeln('<!doctype html>')
    ..writeln('<html lang="en">')
    ..writeln('<head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln('<meta name="viewport" content="width=device-width, initial-scale=1">')
    ..writeln('<title>KK Nutrivet · Visual UI report</title>')
    ..writeln('<style>$css</style>')
    ..writeln('</head>')
    ..writeln('<body>')
    ..writeln('<header>')
    ..writeln('<div><h1>KK Nutrivet · Visual UI report</h1>')
    ..writeln('<div class="sub">Screens rendered with real fonts, theme and router · '
        'generated $generated</div></div>')
    ..writeln('<div class="stats">')
    ..writeln('<span class="pill"><strong>${screens.length}</strong> screens</span>')
    ..writeln('<span class="pill"><strong>${failures.length}</strong> failing</span>')
    ..writeln('</div>')
    ..writeln('</header>')
    ..writeln('<div class="toolbar">')
    ..writeln('<input type="search" id="filter" placeholder="Filter by screen or route…" '
        'oninput="filterCards(this.value)">')
    ..writeln('</div>');

  if (failures.isNotEmpty) {
    buffer
      ..writeln('<section class="failures">')
      ..writeln('<h2>Visual differences</h2>');
    for (final failure in failures) {
      buffer
        ..writeln('<div class="failure">')
        ..writeln('<h3>${const HtmlEscape().convert(failure.title)}</h3>')
        ..writeln('<div class="variants">');
      for (final image in failure.images) {
        buffer.writeln(card(image));
      }
      buffer
        ..writeln('</div>')
        ..writeln('</div>');
    }
    buffer.writeln('</section>');
  }

  buffer.writeln('<section id="screens"><h2>Screens</h2>');
  if (screens.isEmpty) {
    buffer.writeln(
      '<div class="empty">No screenshots yet. Run '
      '<code>flutter test test/visual --update-goldens</code>, then rebuild '
      'this report.</div>',
    );
  } else {
    buffer.writeln('<div class="grid" id="grid">');
    for (final shot in screens) {
      buffer.writeln(card(shot));
    }
    buffer.writeln('</div>');
  }
  buffer
    ..writeln('</section>')
    ..writeln('<dialog id="lightbox" onclick="this.close()">'
        '<img id="lightbox-img" alt=""><p id="lightbox-caption"></p></dialog>')
    ..writeln('<script>')
    ..writeln(r'''
      function zoom(payload) {
        const [src, title] = payload;
        document.getElementById('lightbox-img').src = src;
        document.getElementById('lightbox-caption').textContent = title;
        document.getElementById('lightbox').showModal();
      }
      function filterCards(query) {
        const needle = query.trim().toLowerCase();
        document.querySelectorAll('#grid figure').forEach((card) => {
          card.style.display = !needle || card.dataset.search.includes(needle) ? '' : 'none';
        });
      }
      document.getElementById('lightbox').addEventListener('click', (event) => {
        if (event.target.tagName !== 'IMG') event.currentTarget.close();
      });
    ''')
    ..writeln('</script>')
    ..writeln('</body>')
    ..writeln('</html>');

  return buffer.toString();
}

class _Shot {
  _Shot({
    required this.name,
    required this.title,
    required this.file,
    this.route = '',
    this.width,
    this.height,
  });

  final String name;
  final String title;
  final String file;
  final String route;
  final int? width;
  final int? height;
}

class _Failure {
  _Failure({required this.title, required this.images});

  final String title;
  final List<_Shot> images;
}
