import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/supabase/auth_repository.dart';
import 'auth_providers.dart';
import '../../../data/repositories/supabase/supabase_client_provider.dart';

/// 初始化并监听 Supabase 会话变化，同步到 currentUserProvider。
final authInitializerProvider = FutureProvider<void>((ref) async {
  final supabaseAuthRepo = ref.read(supabaseAuthRepositoryProvider);

  // 启动时尝试恢复会话
  final profile = await supabaseAuthRepo.getCurrentProfile();
  ref.read(currentUserProvider.notifier).setUser(profile);

  // 监听后续会话变化
  final StreamSubscription<AuthState> sub =
      supabaseClient.auth.onAuthStateChange.listen((event) async {
    switch (event.event) {
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        final p = await supabaseAuthRepo.getCurrentProfile();
        ref.read(currentUserProvider.notifier).setUser(p);
        break;
      case AuthChangeEvent.signedOut:
      case AuthChangeEvent.userDeleted:
      case AuthChangeEvent.passwordRecovery:
        ref.read(currentUserProvider.notifier).setUser(null);
        break;
      default:
        break;
    }
  });

  ref.onDispose(() => sub.cancel());
});
