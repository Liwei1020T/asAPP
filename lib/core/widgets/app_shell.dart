import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/animations.dart';
import '../constants/spacing.dart';
import '../theme/theme_provider.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          return Scaffold(
            appBar: AppBar(
              actions: [
                // 主题切换按钮
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: ASAnimations.fast,
                    child: Icon(
                      getThemeModeIcon(themeState.mode),
                      key: ValueKey(themeState.mode),
                    ),
                  ),
                  onPressed: () => themeNotifier.toggleTheme(),
                  tooltip: getThemeModeName(themeState.mode),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: onLogout,
                ),
              ],
            ),
            body: AnimatedSwitcher(
              duration: ASAnimations.normal,
              child: body,
            ),
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

        final isExtended = constraints.maxWidth >= 900;
        final surfaceColor = theme.colorScheme.surface;
        final primaryColor = theme.colorScheme.primary;
        final textSecondaryColor = isDark 
            ? Colors.white70 
            : Colors.black54;

        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                extended: isExtended,
                backgroundColor: surfaceColor,
                selectedIconTheme: IconThemeData(color: primaryColor),
                unselectedIconTheme: IconThemeData(color: textSecondaryColor),
                selectedLabelTextStyle: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: textSecondaryColor,
                ),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: ASSpacing.lg),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.sports_tennis, color: Colors.white),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1, 1),
                            duration: ASAnimations.medium,
                            curve: ASAnimations.emphasizeCurve,
                          ),
                      if (isExtended) ...[
                        const SizedBox(width: ASSpacing.sm),
                        Text(
                          'ASP-MS',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: ASAnimations.normal)
                            .slideX(
                              begin: -0.2,
                              end: 0,
                              duration: ASAnimations.normal,
                            ),
                      ],
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
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: ASSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 主题切换按钮
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: ASAnimations.fast,
                              transitionBuilder: (child, animation) {
                                return RotationTransition(
                                  turns: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Icon(
                                getThemeModeIcon(themeState.mode),
                                key: ValueKey(themeState.mode),
                                color: textSecondaryColor,
                              ),
                            ),
                            onPressed: () => themeNotifier.toggleTheme(),
                            tooltip: getThemeModeName(themeState.mode),
                          ),
                          const SizedBox(height: ASSpacing.sm),
                          IconButton(
                            icon: Icon(Icons.logout, color: textSecondaryColor),
                            onPressed: onLogout,
                            tooltip: '退出登录',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              VerticalDivider(
                thickness: 1,
                width: 1,
                color: theme.dividerColor,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: ASAnimations.normal,
                  child: Container(
                    key: ValueKey(selectedIndex),
                    color: theme.scaffoldBackgroundColor,
                    child: body,
                  ),
                ),
              ),
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
