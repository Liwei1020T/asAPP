import 'package:flutter/material.dart';

enum ASTagType {
  normal,
  primary,
  success,
  warning,
  error,
  info,
  urgent,
}

/// 简化版 ASP 标签组件 (标准 Chip)
class ASTag extends StatelessWidget {
  const ASTag({
    super.key,
    required this.label,
    this.type = ASTagType.normal,
    this.icon,
    this.onTap,
    this.animate = false,
    this.animationDelay,
  });

  final String label;
  final ASTagType type;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool animate;
  final Duration? animationDelay;

  Color? _getColor(BuildContext context) {
    switch (type) {
      case ASTagType.normal: return null;
      case ASTagType.primary: return Theme.of(context).colorScheme.primaryContainer;
      case ASTagType.success: return Colors.green.shade100;
      case ASTagType.warning: return Colors.orange.shade100;
      case ASTagType.error: return Colors.red.shade100;
      case ASTagType.info: return Colors.blue.shade100;
      case ASTagType.urgent: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget tag = Chip(
      label: Text(label),
      avatar: icon != null ? Icon(icon, size: 16) : null,
      backgroundColor: _getColor(context),
      visualDensity: VisualDensity.compact,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: tag);
    }
    return tag;
  }
}

class ASAttendanceTag extends StatelessWidget {
  const ASAttendanceTag({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return ASTag(label: status);
  }
}

class ASLevelTag extends StatelessWidget {
  const ASLevelTag({super.key, required this.level});
  final String level;

  @override
  Widget build(BuildContext context) {
    return ASTag(label: level, type: ASTagType.primary);
  }
}
