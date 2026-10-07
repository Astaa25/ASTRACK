// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('scratch_test_output.json');
  if (!file.existsSync()) {
    print('File not found');
    return;
  }
  final lines = file.readAsLinesSync();
  final suites = <int, String>{};
  final counts = <String, int>{};

  for (final l in lines) {
    if (l.trim().isEmpty) continue;
    try {
      final event = jsonDecode(l) as Map<String, dynamic>;
      final type = event['type'];
      if (type == 'suite') {
        final suite = event['suite'] as Map<String, dynamic>;
        suites[suite['id'] as int] = suite['path'] as String? ?? '';
      } else if (type == 'testStart') {
        final test = event['test'] as Map<String, dynamic>;
        final name = test['name'] as String? ?? '';
        if (name.startsWith('loading ')) continue;
        final suiteId = test['suiteID'] as int?;
        final path = suites[suiteId] ?? 'unknown';
        final filename = path.replaceAll(r'\', '/').split('/').last;
        counts[filename] = (counts[filename] ?? 0) + 1;
      }
    } catch (_) {}
  }

  int total = 0;
  final sortedKeys = counts.keys.toList()..sort();
  print('| No | File Test | Jumlah Tes |');
  print('|---|---|---|');
  int idx = 1;
  for (final k in sortedKeys) {
    final c = counts[k]!;
    print('| $idx | `$k` | $c |');
    total += c;
    idx++;
  }
  print('| | **TOTAL** | **$total** |');
}
