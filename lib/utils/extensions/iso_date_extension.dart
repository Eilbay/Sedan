import 'package:intl/intl.dart';

extension IsoDateExtension on String {
  /// Formats an ISO-8601 timestamp (e.g. `2026-05-25T12:54:39.445590Z`) as
  /// `dd.MM.yy` in local time. Returns an empty string when the value is empty
  /// or not valid ISO-8601, so a malformed API timestamp never crashes the UI.
  String get asShortDate {
    final parsed = DateTime.tryParse(this);
    if (parsed == null) return '';
    return DateFormat('dd.MM.yy').format(parsed.toLocal());
  }
}

String _ruPlural(int n, String one, String few, String many) {
  final mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) return many;
  switch (n % 10) {
    case 1:
      return one;
    case 2:
    case 3:
    case 4:
      return few;
    default:
      return many;
  }
}

extension RecentRelativeTimeExtension on DateTime {
  /// Relative label for fresh timestamps:
  /// under 60s — "только что", under 60m — "N минут назад",
  /// under 24h — "N часов назад", under 7d — "N дней назад".
  /// Returns null for anything older — the caller keeps its absolute
  /// date format.
  String? get asRecentRelativeTime {
    final diff = DateTime.now().difference(toLocal());
    if (diff.inSeconds < 60) return 'только что';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m ${_ruPlural(m, 'минуту', 'минуты', 'минут')} назад';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h ${_ruPlural(h, 'час', 'часа', 'часов')} назад';
    }
    if (diff.inDays < 7) {
      final d = diff.inDays;
      return '$d ${_ruPlural(d, 'день', 'дня', 'дней')} назад';
    }
    return null;
  }
}

extension RussianDateExtension on DateTime {
  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  /// Formats as `d MMMM yyyy` with a Russian genitive month name (e.g.
  /// `2 июня 2026`), independent of `intl`'s locale data being initialized.
  String get asRussianDate {
    final local = toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }
}
