import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/spacing.dart';

/// 标签类型
enum ASTagType {
  /// 默认灰色
  normal,

  /// 主色红
  primary,

  /// 成功绿
  success,

  /// 警告黄
  warning,

  /// 错误红
  error,

  /// 信息蓝
  info,

  /// 紧急（红底白字）
  urgent,
}

/// ASP 标签组件
class ASTag extends StatelessWidget {
  const ASTag({
    super.key,
    required this.label,
    this.type = ASTagType.normal,
    this.icon,
    this.onTap,
  });

  final String label;
  final ASTagType type;
  final IconData? icon;
  final VoidCallback? onTap;

  Color get backgroundColor {
    switch (type) {
      case ASTagType.normal:
        return ASColors.divider;
      case ASTagType.primary:
        return ASColors.primary.withValues(alpha: 0.1);
      case ASTagType.success:
        return ASColors.success.withValues(alpha: 0.1);
      case ASTagType.warning:
        return ASColors.warning.withValues(alpha: 0.1);
      case ASTagType.error:
        return ASColors.error.withValues(alpha: 0.1);
      case ASTagType.info:
        return ASColors.info.withValues(alpha: 0.1);
      case ASTagType.urgent:
        return ASColors.error;
    }
  }

  Color get foregroundColor {
    switch (type) {
      case ASTagType.normal:
        return ASColors.textSecondary;
      case ASTagType.primary:
        return ASColors.primary;
      case ASTagType.success:
        return ASColors.success;
      case ASTagType.warning:
        return const Color(0xFFE65100); // 深橙色，warning 的对比色
      case ASTagType.error:
        return ASColors.error;
      case ASTagType.info:
        return ASColors.info;
      case ASTagType.urgent:
        return ASColors.textOnPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tag = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ASSpacing.sm,
        vertical: ASSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ASSpacing.tagRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foregroundColor),
            const SizedBox(width: ASSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: tag,
      );
    }

    return tag;
  }
}

/// 出勤状态标签
class ASAttendanceTag extends StatelessWidget {
  const ASAttendanceTag({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    late ASTagType type;
    late String label;

    switch (status.toLowerCase()) {
      case 'present':
        type = ASTagType.success;
        label = '出席';
        break;
      case 'absent':
        type = ASTagType.error;
        label = '缺席';
        break;
      case 'late':
        type = ASTagType.warning;
        label = '迟到';
        break;
      case 'leave':
        type = ASTagType.normal;
        label = '请假';
        break;
      default:
        type = ASTagType.normal;
        label = status;
    }

    return ASTag(label: label, type: type);
  }
}

/// 级别标签
class ASLevelTag extends StatelessWidget {
  const ASLevelTag({
    super.key,
    required this.level,
  });

  final String level;

  @override
  Widget build(BuildContext context) {
    return ASTag(
      label: level,
      type: ASTagType.primary,
    );
  }
}
