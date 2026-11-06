// Parses an lcov.info file and enforces a minimum total line coverage.
//
// Usage:
//   flutter test --coverage
//   dart run tool/check_coverage.dart coverage/lcov.info 35
//
// Exits with code 1 when coverage is below the threshold. Also prints the
// least-covered source files, which is the fastest guide for where to add
// tests next.
import 'dart:io';

class FileCoverage {
  FileCoverage(this.path, this.hit, this.total);
  final String path;
  final int hit;
  final int total;

  double get percent => total == 0 ? 100 : hit / total * 100;
}

void main(List<String> args) {
  final lcovPath = args.isNotEmpty ? args[0] : 'coverage/lcov.info';
  final threshold = args.length > 1 ? double.tryParse(args[1]) ?? 0 : 0;

  final file = File(lcovPath);
  if (!file.existsSync()) {
    stderr.writeln('Coverage file not found: $lcovPath');
    stderr.writeln('Run `flutter test --coverage` first.');
    exitCode = 2;
    return;
  }

  final files = <FileCoverage>[];
  String? currentPath;
  var hit = 0;
  var total = 0;

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      currentPath = line.substring(3).trim();
      hit = 0;
      total = 0;
    } else if (line.startsWith('LH:')) {
      hit = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LF:')) {
      total = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line == 'end_of_record' && currentPath != null) {
      if (currentPath.startsWith('lib/') || currentPath.contains('/lib/')) {
        files.add(FileCoverage(currentPath, hit, total));
      }
      currentPath = null;
    }
  }

  if (files.isEmpty) {
    stderr.writeln('No lib/ records found in $lcovPath.');
    exitCode = 2;
    return;
  }

  final totalHit = files.fold<int>(0, (sum, f) => sum + f.hit);
  final totalLines = files.fold<int>(0, (sum, f) => sum + f.total);
  final percent = totalLines == 0 ? 100.0 : totalHit / totalLines * 100;

  stdout.writeln(
    'Line coverage: ${percent.toStringAsFixed(2)}% '
    '($totalHit/$totalLines lines across ${files.length} files)',
  );

  final weakest = files.where((f) => f.total >= 20).toList()
    ..sort((a, b) => a.percent.compareTo(b.percent));
  stdout.writeln('Least-covered files:');
  for (final entry in weakest.take(12)) {
    stdout.writeln(
      '  ${entry.percent.toStringAsFixed(1).padLeft(5)}%  '
      '${entry.hit}/${entry.total}  ${entry.path}',
    );
  }

  if (percent + 0.001 < threshold) {
    stderr.writeln(
      'Coverage ${percent.toStringAsFixed(2)}% is below the '
      '${threshold.toStringAsFixed(2)}% threshold.',
    );
    exitCode = 1;
  }
}
