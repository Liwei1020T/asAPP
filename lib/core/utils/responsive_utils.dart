import 'package:flutter/material.dart';

/// 响应式断点
class ASBreakpoints {
  ASBreakpoints._();

  /// 手机最大宽度
  static const double mobile = 600;
  
  /// 平板最大宽度
  static const double tablet = 900;
  
  /// 桌面最大宽度
  static const double desktop = 1200;
  
  /// 大屏幕最大宽度
  static const double largeDesktop = 1600;
}

/// 设备类型枚举
enum ASDeviceType {
  mobile,
  tablet,
  desktop,
  largeDesktop,
}

/// 响应式工具类
class ASResponsive {
  ASResponsive._();

  /// 根据屏幕宽度获取设备类型
  static ASDeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return getDeviceTypeFromWidth(width);
  }

  /// 根据宽度获取设备类型
  static ASDeviceType getDeviceTypeFromWidth(double width) {
    if (width < ASBreakpoints.mobile) {
      return ASDeviceType.mobile;
    } else if (width < ASBreakpoints.tablet) {
      return ASDeviceType.tablet;
    } else if (width < ASBreakpoints.largeDesktop) {
      return ASDeviceType.desktop;
    } else {
      return ASDeviceType.largeDesktop;
    }
  }

  /// 是否为手机
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == ASDeviceType.mobile;
  }

  /// 是否为平板
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == ASDeviceType.tablet;
  }

  /// 是否为桌面
  static bool isDesktop(BuildContext context) {
    final type = getDeviceType(context);
    return type == ASDeviceType.desktop || type == ASDeviceType.largeDesktop;
  }

  /// 是否为大屏幕
  static bool isLargeDesktop(BuildContext context) {
    return getDeviceType(context) == ASDeviceType.largeDesktop;
  }

  /// 根据设备类型返回不同的值
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final type = getDeviceType(context);
    return switch (type) {
      ASDeviceType.mobile => mobile,
      ASDeviceType.tablet => tablet ?? mobile,
      ASDeviceType.desktop => desktop ?? tablet ?? mobile,
      ASDeviceType.largeDesktop => largeDesktop ?? desktop ?? tablet ?? mobile,
    };
  }

  /// 获取网格列数
  static int getGridColumns(BuildContext context, {
    int mobile = 1,
    int tablet = 2,
    int desktop = 3,
    int largeDesktop = 4,
  }) {
    return value(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  /// 获取页面内边距
  static EdgeInsets getPagePadding(BuildContext context) {
    return value(
      context,
      mobile: const EdgeInsets.all(16),
      tablet: const EdgeInsets.all(20),
      desktop: const EdgeInsets.all(24),
      largeDesktop: const EdgeInsets.all(32),
    );
  }

  /// 获取卡片间距
  static double getCardSpacing(BuildContext context) {
    return value(
      context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
      largeDesktop: 24.0,
    );
  }
}

/// 响应式构建器组件
class ASResponsiveBuilder extends StatelessWidget {
  const ASResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final type = ASResponsive.getDeviceTypeFromWidth(constraints.maxWidth);
        return switch (type) {
          ASDeviceType.mobile => mobile,
          ASDeviceType.tablet => tablet ?? mobile,
          ASDeviceType.desktop => desktop ?? tablet ?? mobile,
          ASDeviceType.largeDesktop => largeDesktop ?? desktop ?? tablet ?? mobile,
        };
      },
    );
  }
}

/// 响应式网格
class ASResponsiveGrid extends StatelessWidget {
  const ASResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.largeDesktopColumns = 4,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio = 1.0,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int largeDesktopColumns;
  final double spacing;
  final double runSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = ASResponsive.getGridColumns(
          context,
          mobile: mobileColumns,
          tablet: tabletColumns,
          desktop: desktopColumns,
          largeDesktop: largeDesktopColumns,
        );

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: runSpacing,
            crossAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// 响应式 Wrap（自适应列数的流式布局）
class ASResponsiveWrap extends StatelessWidget {
  const ASResponsiveWrap({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.alignment = WrapAlignment.start,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      children: children,
    );
  }
}
