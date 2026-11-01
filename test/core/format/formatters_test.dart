import 'package:flutter_test/flutter_test.dart';
import 'package:dummyjson_flutter_test/core/format/formatters.dart';

void main() {
  test('formatPrice keeps two decimal places', () {
    expect(formatPrice(9.9), '\$9.90');
    expect(formatPrice(10), '\$10.00');
  });

  test('formatCategory splits hyphenated names', () {
    expect(formatCategory('home-decoration'), 'Home Decoration');
    expect(formatCategory('beauty'), 'Beauty');
    expect(formatCategory(''), 'General');
  });
}
