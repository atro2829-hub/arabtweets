import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

class AppFormatters {
  static String formatCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    if (count < 1000000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    return '${(count / 1000000000).toStringAsFixed(1)}B';
  }

  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
    if (diff.inDays < 30) return 'منذ ${diff.inDays ~/ 7} أسبوع';
    if (diff.inDays < 365) return 'منذ ${diff.inDays ~/ 30} شهر';
    return 'منذ ${diff.inDays ~/ 365} سنة';
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  static String formatFullDate(DateTime dateTime) {
    final months = ['يناير','فبراير','مارس','أبريل','مايو','يونيو','يوليو','أغسطس','سبتمبر','أكتوبر','نوفمبر','ديسمبر'];
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} · ${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  static String highlightHashtags(String text) {
    return text.replaceAllMapped(
      RegExp(r'#([\u0600-\u06FFa-zA-Z0-9_]+)'),
      (match) => '#${match.group(1)}',
    );
  }

  static String highlightMentions(String text) {
    return text.replaceAllMapped(
      RegExp(r'@([a-zA-Z0-9_]+)'),
      (match) => '@${match.group(1)}',
    );
  }
}

// Arabic timeago messages
class ArabicMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => 'منذ';
  @override
  String prefixFromNow() => 'بعد';
  @override
  String suffixAgo() => '';
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => 'الآن';
  @override
  String aboutAMinute(int minutes) => 'دقيقة';
  @override
  String minutes(int minutes) => '$minutes د';
  @override
  String aboutAnHour(int minutes) => 'ساعة';
  @override
  String hours(int hours) => '$hours س';
  @override
  String aDay(int hours) => 'يوم';
  @override
  String days(int days) => '$days ي';
  @override
  String aboutAMonth(int days) => 'شهر';
  @override
  String months(int months) => '$months شهر';
  @override
  String aboutAYear(int months) => 'سنة';
  @override
  String years(int years) => '$years سنة';
  @override
  String wordSeparator() => ' ';
}