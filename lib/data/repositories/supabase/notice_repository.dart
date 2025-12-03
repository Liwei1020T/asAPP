import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/notice.dart';
import 'supabase_client_provider.dart';

/// Supabase 公告仓库
class SupabaseNoticeRepository {
  /// 获取公告列表（可选过滤）
  Future<List<Notice>> fetchNotices({
    NoticeAudience? audience,
    List<NoticeAudience>? audiences,
    bool? isPinned,
    int limit = 50,
  }) async {
    var query = supabaseClient.from('notices').select();

    // 过滤条件需要在排序和分页之前应用，以确保使用 PostgrestFilterBuilder 上的过滤方法
    if (audiences != null && audiences.isNotEmpty) {
      query = query.inFilter(
        'target_audience',
        audiences.map((e) => e.name).toList(),
      );
    } else if (audience != null) {
      query = query.eq('target_audience', audience.name);
    }
    if (isPinned != null) {
      query = query.eq('is_pinned', isPinned);
    }

    final data = await query
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => Notice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 实时订阅公告（按时间倒序）
  Stream<List<Notice>> watchNotices({int limit = 100}) {
    return supabaseClient
        .from('notices')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows
              .map((e) => Notice.fromJson(e as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.length > limit ? list.sublist(0, limit) : list;
        });
  }

  /// 创建公告
  Future<Notice> createNotice(Notice notice) async {
    // 使用数据库默认 UUID：插入时不传 id
    final payload = notice.toJson();
    payload.remove('id');

    final inserted =
        await supabaseClient.from('notices').insert(payload).select().single();
    return Notice.fromJson(inserted as Map<String, dynamic>);
  }

  /// 更新公告
  Future<Notice> updateNotice(Notice notice) async {
    final updated = await supabaseClient
        .from('notices')
        .update(notice.toJson())
        .eq('id', notice.id)
        .select()
        .single();
    return Notice.fromJson(updated as Map<String, dynamic>);
  }

  /// 删除公告
  Future<void> deleteNotice(String noticeId) async {
    await supabaseClient.from('notices').delete().eq('id', noticeId);
  }
}

/// Supabase Notice Repository Provider
final supabaseNoticeRepositoryProvider = Provider<SupabaseNoticeRepository>((ref) {
  return SupabaseNoticeRepository();
});
