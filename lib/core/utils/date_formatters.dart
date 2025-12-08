import 'package:intl/intl.dart';

/// 日期格式化工具类
class DateFormatters {
  DateFormatters._();

  /// 完整日期时间：2025-01-15 14:30
  static String fullDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  /// 格式化日期时间（与模板保持一致）
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy年M月d日 HH:mm').format(dateTime);
  }

  /// 日期：2025-01-15
  static String date(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd').format(dateTime);
  }

  /// 时间：14:30
  static String time(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  /// 时间范围：14:30 - 16:00
  static String timeRange(DateTime start, DateTime end) {
    return '${time(start)} - ${time(end)}';
  }

  /// 友好日期：今天、昨天、1月15日
  static String friendlyDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return '今天';
    } else if (date == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else if (date == today.add(const Duration(days: 1))) {
      return '明天';
    } else if (dateTime.year == now.year) {
      return DateFormat('M月d日').format(dateTime);
    } else {
      return DateFormat('yyyy年M月d日').format(dateTime);
    }
  }

  /// 相对日期：今天、昨天、3天前、1周前
  static String relativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(date);

    if (date == today) {
      return '今天 ${time(dateTime)}';
    } else if (difference.inDays == 1) {
      return '昨天 ${time(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}周前';
    } else if (dateTime.year == now.year) {
      return DateFormat('M月d日').format(dateTime);
    } else {
      return DateFormat('yyyy年M月d日').format(dateTime);
    }
  }

  /// 相对时间：刚刚、5分钟前、2小时前、3天前
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}周前';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}个月前';
    } else {
      return '${(difference.inDays / 365).floor()}年前';
    }
  }

  /// 月份：2025年1月
  static String month(DateTime dateTime) {
    return DateFormat('yyyy年M月').format(dateTime);
  }

  /// 星期几：周一、周二...
  static String weekday(int weekday) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[(weekday - 1) % 7];
  }

  /// 从 0-6 格式的星期转换（0=周日）
  static String weekdayFromZeroIndex(int dayOfWeek) {
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[dayOfWeek % 7];
  }

  /// 当前月份第一天
  static DateTime firstDayOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, 1);
  }

  /// 当前月份最后一天
  static DateTime lastDayOfMonth(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month + 1, 0);
  }
}
