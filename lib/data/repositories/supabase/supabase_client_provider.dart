import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';

/// 初始化 Supabase（在 main 中调用）
Future<void> initSupabase() async {
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );
}

/// 全局 Supabase 客户端
SupabaseClient get supabaseClient => Supabase.instance.client;
