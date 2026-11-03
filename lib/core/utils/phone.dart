/// Normalize Indian local numbers without stripping a legitimate 91 prefix.
String normalizeIndianPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  return digits.length == 12 && digits.startsWith('91')
      ? digits.substring(2)
      : digits;
}
