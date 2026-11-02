import 'package:intl/intl.dart';

String formatPrice(num? value) {
  if (value == null) return '₹0';
  final d = value.toDouble();
  return '₹${d.toStringAsFixed(d == d.roundToDouble() ? 0 : 2)}';
}

String formatDate(DateTime date) => DateFormat('dd MMM yyyy').format(date);

String formatDateTime(DateTime date) => DateFormat('dd MMM yyyy, hh:mm a').format(date);

String formatTime(DateTime date) => DateFormat('hh:mm a').format(date);

String capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String titleCase(String value) {
  return value.split(RegExp(r'[_\-\s]+')).map(capitalize).join(' ');
}

String stripHtml(String input) {
  if (input.isEmpty) return input;
  final withoutTags = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
  return withoutTags
      .replaceAll(RegExp(r'&nbsp;'), ' ')
      .replaceAll(RegExp(r'&amp;'), '&')
      .replaceAll(RegExp(r'&lt;'), '<')
      .replaceAll(RegExp(r'&gt;'), '>')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String truncate(String value, {int maxLength = 120}) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength).trimRight()}...';
}

String timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
  return '${(diff.inDays / 365).floor()}y ago';
}
