import 'package:flutter_test/flutter_test.dart';
import 'package:health_mate/utils/formatters.dart';

void main() {
  group('AppFormatters', () {
    test('storageDate pads month and day to YYYY-MM-DD', () {
      expect(AppFormatters.storageDate(DateTime(2026, 2, 3)), '2026-02-03');
    });

    test('display formats turn a stored date into readable text', () {
      expect(AppFormatters.longDate('2026-11-25'), '25 November 2026');
      expect(AppFormatters.cardDate('2026-11-25'), 'Wed, 25 Nov 2026');
      expect(AppFormatters.shortDate('2026-11-25'), '25 Nov 2026');
    });

    test('an invalid stored date is shown as-is instead of throwing', () {
      expect(AppFormatters.longDate('not-a-date'), 'not-a-date');
    });

    test('number adds thousands separators', () {
      expect(AppFormatters.number(0), '0');
      expect(AppFormatters.number(420), '420');
      expect(AppFormatters.number(7850), '7,850');
      expect(AppFormatters.number(1234567), '1,234,567');
    });
  });
}
