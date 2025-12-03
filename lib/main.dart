import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/router/app_router.dart';
import 'data/repositories/supabase/supabase_client_provider.dart';
import 'features/auth/application/auth_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();

  // 配置 flutter_animate 默认设置
  Animate.restartOnHotReload = true;

  runApp(
    const ProviderScope(
      child: ASPMSApp(),
    ),
  );
}

/// Art Sport Penang Management System 主应用
class ASPMSApp extends ConsumerWidget {
  const ASPMSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 同步 Supabase 会话到本地 user provider
    ref.watch(authInitializerProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ASP-MS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
