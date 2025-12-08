import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../constants/animations.dart';
import '../theme/theme_provider.dart';

/// 应用程序外壳
/// 
/// 提供响应式导航结构（桌面端侧边栏，移动端底部导航）和全局主题切换。
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.body,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onLogout,
  });

  final Widget body;
  final List<ShellDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final isDark = themeState.mode == ThemeMode.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800; // 调整断点以适应平板

          // 统一的 AppBar Action
        final actions = [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: onLogout,
            tooltip: '退出登录',
          ),
          const SizedBox(width: 8),
        ];

        // 统一的 Body 包装器 (添加转场动画)
        final animatedBody = AnimatedSwitcher(
          duration: ASAnimations.pageTransitionDuration,
          switchInCurve: ASAnimations.pageTransitionCurve,
          switchOutCurve: ASAnimations.pageTransitionCurve,
          child: KeyedSubtree(
            key: ValueKey(selectedIndex),
            child: body,
          ),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
        );

        if (isMobile) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('ASP-MS'),
              actions: actions,
            ),
            body: animatedBody,
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
              destinations: destinations
                  .map((d) => NavigationDestination(
                        icon: Icon(d.iconOutlined),
                        selectedIcon: Icon(d.iconSelected),
                        label: d.label,
                      ))
                  .toList(),
            ),
          );
        }

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                labelType: NavigationRailLabelType.all,
                leading: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: FlutterLogo(size: 32), // 替换为应用 Logo
                ),
                trailing: Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: onLogout,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                destinations: destinations
                    .map((d) => NavigationRailDestination(
                          icon: Icon(d.iconOutlined),
                          selectedIcon: Icon(d.iconSelected),
                          label: Text(d.label),
                        ))
                    .toList(),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: animatedBody),
            ],
          ),
        );
      },
    );
  }
}

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.iconOutlined,
    required this.iconSelected,
    required this.route,
  });

  final String label;
  final IconData iconOutlined;
  final IconData iconSelected;
  final String route;
}
