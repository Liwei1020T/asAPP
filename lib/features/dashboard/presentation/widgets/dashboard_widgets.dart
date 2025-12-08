import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/widgets/widgets.dart';

/// 简易折线图
class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({
    super.key,
    required this.data,
    required this.title,
    this.height = 200,
    this.lineColor,
    this.gradientColors,
  });

  final List<double> data;
  final String title;
  final double height;
  final Color? lineColor;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = lineColor ?? theme.colorScheme.primary;
    final gradient = gradientColors ?? [
      color.withValues(alpha: 0.3),
      color.withValues(alpha: 0.0),
    ];

    return ASCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ASSpacing.md),
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _LineChartPainter(
                data: data,
                lineColor: color,
                gradientColors: gradient,
                gridColor: theme.dividerColor.withValues(alpha: 0.5),
                labelStyle: theme.textTheme.bodySmall!,
              ),
            ),
          ).animate().fadeIn(duration: 600.ms),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;
  final List<Color> gradientColors;
  final Color gridColor;
  final TextStyle labelStyle;

  _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.gradientColors,
    required this.gridColor,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1.0;

    final path = Path();
    final fillPath = Path();

    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = 0.0; // Always start from 0 for attendance
    final range = maxVal - minVal;
    final effectiveRange = range == 0 ? 1.0 : range;

    final width = size.width;
    final height = size.height - 20; // Reserve space for labels

    final dx = width / (data.length - 1);

    // Draw Grid Lines (Horizontal)
    final gridSteps = 5;
    for (int i = 0; i <= gridSteps; i++) {
      final y = height - (i / gridSteps) * height;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
      
      // Draw Y-axis labels
      final labelValue = (minVal + (i / gridSteps) * effectiveRange).toInt();
      final textSpan = TextSpan(
        text: labelValue.toString(),
        style: labelStyle.copyWith(fontSize: 10, color: Colors.grey),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(-20, y - 6)); // Offset to left
    }

    // Build Path
    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = height - ((data[i] - minVal) / effectiveRange) * height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, height);
        fillPath.lineTo(x, y);
      } else {
        // Cubic Bezier for smooth curve
        final prevX = (i - 1) * dx;
        final prevY = height - ((data[i - 1] - minVal) / effectiveRange) * height;
        final controlX1 = prevX + dx / 2;
        final controlY1 = prevY;
        final controlX2 = x - dx / 2;
        final controlY2 = y;
        
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }

      // Draw X-axis labels (Day index)
      final textSpan = TextSpan(
        text: '${i + 1}', // 1-based index
        style: labelStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, height + 5));
    }

    fillPath.lineTo(width, height);
    fillPath.close();

    // Draw Gradient Fill
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: gradientColors,
    ).createShader(Rect.fromLTWH(0, 0, width, height));

    final fillPaint = Paint()
      ..shader = gradient
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw Points
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pointBorderPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = height - ((data[i] - minVal) / effectiveRange) * height;
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
      canvas.drawCircle(Offset(x, y), 4, pointBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// 快速操作按钮组
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return ASCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快速操作',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: ASSpacing.md),
          Wrap(
            spacing: ASSpacing.md,
            runSpacing: ASSpacing.md,
            children: [
              _ActionButton(
                icon: Icons.person_add,
                label: '添加学员',
                color: ASColors.primary,
                onTap: () => context.push('/students'),
              ),
              _ActionButton(
                icon: Icons.class_,
                label: '创建班级',
                color: ASColors.secondary,
                onTap: () => context.push('/classes'), // Assuming route exists or similar
              ),
              _ActionButton(
                icon: Icons.campaign,
                label: '发布公告',
                color: ASColors.warning,
                onTap: () {}, // TODO: Add notice creation route
              ),
              _ActionButton(
                icon: Icons.settings,
                label: '系统设置',
                color: Colors.grey,
                onTap: () {}, // TODO: Add settings route
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: ASSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
