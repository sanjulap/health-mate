import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final DateFormat _storageDate = DateFormat('yyyy-MM-dd', 'en_US');
  static final DateFormat _longDate = DateFormat('d MMMM y', 'en_US');
  static final DateFormat _cardDate = DateFormat('EEE, d MMM y', 'en_US');
  static final DateFormat _shortDate = DateFormat('d MMM y', 'en_US');
  static final NumberFormat _number = NumberFormat.decimalPattern('en_US');

  static String storageDate(DateTime date) => _storageDate.format(date);

  static String longDate(String storedDate) =>
      _fromStored(storedDate, _longDate);

  static String cardDate(String storedDate) =>
      _fromStored(storedDate, _cardDate);

  static String shortDate(String storedDate) =>
      _fromStored(storedDate, _shortDate);

  static String number(int value) => _number.format(value);

  static String _fromStored(String storedDate, DateFormat format) {
    final parsed = DateTime.tryParse(storedDate);
    return parsed == null ? storedDate : format.format(parsed);
  }
}
