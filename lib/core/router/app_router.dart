import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/profile.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/email_verification_page.dart';
import '../../features/auth/presentation/link_children_page.dart';
import '../../data/repositories/supabase/auth_repository.dart';
import '../../features/dashboard/presentation/coach_dashboard_page.dart';
import '../../features/dashboard/presentation/parent_dashboard_page.dart';
import '../../features/dashboard/presentation/admin_dashboard_page.dart';
import '../../features/attendance/presentation/attendance_page.dart';
import '../../features/classes/presentation/admin_class_list_page.dart';
import '../../features/classes/presentation/admin_class_detail_page.dart';
import '../../features/coaches/presentation/coach_list_page.dart';
import '../../features/coaches/presentation/coach_detail_page.dart';
import '../../features/notices/presentation/notice_list_page.dart';
import '../../features/timeline/presentation/timeline_list_page.dart';
import '../../features/playbook/presentation/playbook_list_page.dart';
import '../../features/salary/presentation/salary_page.dart';
import '../../features/students/presentation/student_list_page.dart';
import '../widgets/app_shell.dart';

/// 路由配置 Provider
final routerProvider = Provider<GoRouter>((ref) {
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isLoggedIn = currentUser != null;
      final location = state.matchedLocation;
      final role = currentUser?.role;

      // 允许访问的公开页面（无需登录）
      final publicRoutes = ['/login', '/register', '/verify-email'];
      final isPublicRoute = publicRoutes.any((route) => location.startsWith(route));

      // 未登录且不在公开页面，跳转到登录页
      if (!isLoggedIn && !isPublicRoute) {
        // 绑定孩子页面需要登录
        if (location.startsWith('/link-children')) {
          return '/login';
        }
        return '/login';
      }

      // 已登录但在登录/注册页，跳转到对应的仪表板
      if (isLoggedIn && (location == '/login' || location == '/register')) {
        return _getDashboardRouteForRole(currentUser.role);
      }

      // 已登录但访问无权路由，重定向到各自仪表板
      if (isLoggedIn && role != null && !_isAuthorized(role, location)) {
        return _getDashboardRouteForRole(role);
      }

      return null;
    },
    routes: [
      // 登录页
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      // 注册页
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // 邮箱验证页
      GoRoute(
        path: '/verify-email',
        name: 'verify-email',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return EmailVerificationPage(
            email: extra?['email'] ?? '',
            phoneNumber: extra?['phoneNumber'] ?? '',
          );
        },
      ),

      // 绑定孩子页
      GoRoute(
        path: '/link-children',
        name: 'link-children',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LinkChildrenPage(
            phoneNumber: extra?['phoneNumber'] ?? '',
          );
        },
      ),

      // 教练 Shell Route
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(
            selectedIndex: _getCoachSelectedIndex(state.matchedLocation),
            onDestinationSelected: (index) => _onCoachDestinationSelected(context, index),
            onLogout: () => ref.read(supabaseAuthRepositoryProvider).signOut(),
            destinations: const [
              ShellDestination(
                label: '仪表板',
                iconOutlined: Icons.dashboard_outlined,
                iconSelected: Icons.dashboard,
                route: '/coach-dashboard',
              ),
              ShellDestination(
                label: '训练动态',
                iconOutlined: Icons.photo_library_outlined,
                iconSelected: Icons.photo_library,
                route: '/coach/timeline',
              ),
              ShellDestination(
                label: '训练手册',
                iconOutlined: Icons.menu_book_outlined,
                iconSelected: Icons.menu_book,
                route: '/coach/playbook',
              ),
              ShellDestination(
                label: '薪资',
                iconOutlined: Icons.account_balance_wallet_outlined,
                iconSelected: Icons.account_balance_wallet,
                route: '/salary',
              ),
            ],
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/coach-dashboard',
            name: 'coach-dashboard',
            builder: (context, state) => const CoachDashboardPage(),
          ),
          GoRoute(
            path: '/coach/timeline',
            name: 'coach-timeline',
            builder: (context, state) => const TimelineListPage(),
          ),
          GoRoute(
            path: '/coach/playbook',
            name: 'coach-playbook',
            builder: (context, state) => const PlaybookListPage(),
          ),
          GoRoute(
            path: '/salary',
            name: 'salary',
            builder: (context, state) => const SalaryPage(),
          ),
        ],
      ),

      // 家长 Shell Route
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(
            selectedIndex: _getParentSelectedIndex(state.matchedLocation),
            onDestinationSelected: (index) => _onParentDestinationSelected(context, index),
            onLogout: () => ref.read(supabaseAuthRepositoryProvider).signOut(),
            destinations: const [
              ShellDestination(
                label: '仪表板',
                iconOutlined: Icons.dashboard_outlined,
                iconSelected: Icons.dashboard,
                route: '/parent-dashboard',
              ),
              ShellDestination(
                label: '训练动态',
                iconOutlined: Icons.photo_library_outlined,
                iconSelected: Icons.photo_library,
                route: '/parent/timeline',
              ),
              ShellDestination(
                label: '训练手册',
                iconOutlined: Icons.menu_book_outlined,
                iconSelected: Icons.menu_book,
                route: '/parent/playbook',
              ),
            ],
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/parent-dashboard',
            name: 'parent-dashboard',
            builder: (context, state) => const ParentDashboardPage(),
          ),
          GoRoute(
            path: '/parent/timeline',
            name: 'parent-timeline',
            builder: (context, state) => const TimelineListPage(),
          ),
          GoRoute(
            path: '/parent/playbook',
            name: 'parent-playbook',
            builder: (context, state) => const PlaybookListPage(),
          ),
        ],
      ),

      // 管理员 Shell Route
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(
            selectedIndex: _getAdminSelectedIndex(state.matchedLocation),
            onDestinationSelected: (index) => _onAdminDestinationSelected(context, index),
            onLogout: () => ref.read(supabaseAuthRepositoryProvider).signOut(),
            destinations: const [
              ShellDestination(
                label: '仪表板',
                iconOutlined: Icons.dashboard_outlined,
                iconSelected: Icons.dashboard,
                route: '/admin-dashboard',
              ),
              ShellDestination(
                label: '班级管理',
                iconOutlined: Icons.class_outlined,
                iconSelected: Icons.class_,
                route: '/admin/classes',
              ),
              ShellDestination(
                label: '学员管理',
                iconOutlined: Icons.people_outline,
                iconSelected: Icons.people,
                route: '/students',
              ),
              ShellDestination(
                label: '教练管理',
                iconOutlined: Icons.sports_outlined,
                iconSelected: Icons.sports,
                route: '/admin/coaches',
              ),
              ShellDestination(
                label: '训练手册',
                iconOutlined: Icons.menu_book_outlined,
                iconSelected: Icons.menu_book,
                route: '/admin/playbook',
              ),
              ShellDestination(
                label: '发布公告',
                iconOutlined: Icons.campaign_outlined,
                iconSelected: Icons.campaign,
                route: '/admin/notices',
              ),
              ShellDestination(
                label: '训练动态',
                iconOutlined: Icons.photo_library_outlined,
                iconSelected: Icons.photo_library,
                route: '/admin/timeline',
              ),
            ],
            body: child,
          );
        },
        routes: [
          GoRoute(
            path: '/admin-dashboard',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/classes',
            name: 'admin-classes',
            builder: (context, state) => const AdminClassListPage(),
            routes: [
              GoRoute(
                path: ':classId',
                name: 'admin-class-detail',
                builder: (context, state) {
                  final classId = state.pathParameters['classId']!;
                  return AdminClassDetailPage(classId: classId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin/coaches',
            name: 'admin-coaches',
            builder: (context, state) => const CoachListPage(),
            routes: [
              GoRoute(
                path: ':coachId',
                name: 'admin-coach-detail',
                builder: (context, state) {
                  final coachId = state.pathParameters['coachId']!;
                  return CoachDetailPage(coachId: coachId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/admin/notices',
            name: 'admin-notices',
            builder: (context, state) => const NoticeListPage(),
          ),
          GoRoute(
            path: '/students',
            name: 'students',
            builder: (context, state) => const StudentListPage(),
          ),
          GoRoute(
            path: '/admin/timeline',
            name: 'admin-timeline',
            builder: (context, state) => const TimelineListPage(),
          ),
          GoRoute(
            path: '/admin/playbook',
            name: 'admin-playbook',
            builder: (context, state) => const PlaybookListPage(),
          ),
        ],
      ),

      // 公共页 (Shared Routes)
      // 注意：为了让 ShellRoute 生效，这些路由需要被包含在各自的 ShellRoute 中，
      // 或者我们需要为每个角色定义不同的路径。
      // 这里为了简单起见，我们把 shared routes 放在各自的 ShellRoute 中会比较复杂，
      // 因为 GoRouter 不支持同一个 path 在不同的 ShellRoute 中。
      // 
      // 解决方案：
      // 1. 使用不同的 path，例如 /coach/timeline, /parent/timeline
      // 2. 或者把 shared routes 放在顶层，不使用 ShellRoute (但这不符合需求)
      // 3. 使用 StatefulShellRoute (更复杂)
      //
      // 鉴于当前架构，我们采用方案 1：为不同角色使用不同的 path，但指向同一个 Page。
      
      // 非 Shell 路由 (如点名页面，可能不需要侧边栏)
      GoRoute(
        path: '/attendance/:sessionId',
        name: 'attendance',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return AttendancePage(sessionId: sessionId);
        },
      ),
      
      // Public/Shared Routes need to be duplicated or handled carefully.
      // For now, let's add them to the top-level routes list but they won't have the shell 
      // unless we restructure.
      // 
      // BETTER APPROACH:
      // Let's move the shared routes INTO the ShellRoutes above.
      // I've already added /timeline and /playbook to Coach and Parent ShellRoutes destinations.
      // Now I need to add the GoRoute definitions inside those ShellRoutes.
      
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '页面未找到',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.matchedLocation),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});

// --- Helper Functions ---

int _getAdminSelectedIndex(String path) {
  if (path.startsWith('/admin-dashboard')) return 0;
  if (path.startsWith('/admin/classes')) return 1;
  if (path.startsWith('/students')) return 2;
  if (path.startsWith('/admin/coaches')) return 3;
  if (path.startsWith('/admin/playbook')) return 4;
  if (path.startsWith('/admin/notices')) return 5;
  if (path.startsWith('/admin/timeline')) return 6;
  return 0;
}

void _onAdminDestinationSelected(BuildContext context, int index) {
  switch (index) {
    case 0: context.go('/admin-dashboard'); break;
    case 1: context.go('/admin/classes'); break;
    case 2: context.go('/students'); break;
    case 3: context.go('/admin/coaches'); break;
    case 4: context.go('/admin/playbook'); break;
    case 5: context.go('/admin/notices'); break;
    case 6: context.go('/admin/timeline'); break;
  }
}

int _getCoachSelectedIndex(String path) {
  if (path.startsWith('/coach-dashboard')) return 0;
  if (path.startsWith('/coach/timeline')) return 1;
  if (path.startsWith('/coach/playbook')) return 2;
  if (path.startsWith('/salary')) return 3;
  return 0;
}

void _onCoachDestinationSelected(BuildContext context, int index) {
  switch (index) {
    case 0: context.go('/coach-dashboard'); break;
    case 1: context.go('/coach/timeline'); break;
    case 2: context.go('/coach/playbook'); break;
    case 3: context.go('/salary'); break;
  }
}

int _getParentSelectedIndex(String path) {
  if (path.startsWith('/parent-dashboard')) return 0;
  if (path.startsWith('/parent/timeline')) return 1;
  if (path.startsWith('/parent/playbook')) return 2;
  return 0;
}

void _onParentDestinationSelected(BuildContext context, int index) {
  switch (index) {
    case 0: context.go('/parent-dashboard'); break;
    case 1: context.go('/parent/timeline'); break;
    case 2: context.go('/parent/playbook'); break;
  }
}

/// 根据角色获取对应的仪表板路由
String _getDashboardRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.admin:
      return '/admin-dashboard';
    case UserRole.coach:
      return '/coach-dashboard';
    case UserRole.parent:
      return '/parent-dashboard';
    case UserRole.student:
      return '/parent-dashboard'; // 学生暂时跳转到家长视图
  }
}

/// 简易路由权限校验
bool _isAuthorized(UserRole role, String location) {
  if (role == UserRole.admin) return true;

  if (role == UserRole.coach) {
    return location.startsWith('/coach-dashboard') ||
        location.startsWith('/attendance') ||
        location.startsWith('/salary') ||
        location.startsWith('/coach/timeline') ||
        location.startsWith('/coach/playbook');
  }

  if (role == UserRole.parent || role == UserRole.student) {
    return location.startsWith('/parent-dashboard') ||
        location.startsWith('/parent/timeline') ||
        location.startsWith('/parent/playbook') ||
        location.startsWith('/link-children');
  }

  return false;
}
