import 'package:flutter_test/flutter_test.dart';
import 'package:nvit_app/core/utils/phone.dart';

void main() {
  test('local 91 prefix survives send and verify normalization', () {
    expect(normalizeIndianPhone('9123456789'), '9123456789');
    expect(normalizeIndianPhone('+91 91234 56789'), '9123456789');
    expect(normalizeIndianPhone('9876543210'), '9876543210');
    expect(normalizeIndianPhone('+91 9876543210'), '9876543210');
    expect(normalizeIndianPhone('91'), '91');
  });
}
