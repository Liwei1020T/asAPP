import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/timeline_post.dart';
import '../../models/timeline_comment.dart';
import 'supabase_client_provider.dart';

/// Supabase 训练动态仓库
class SupabaseTimelineRepository {
  Future<List<TimelinePost>> getAllPosts({int limit = 50}) async {
    final data = await supabaseClient
        .from('timeline_posts')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => TimelinePost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 订阅训练动态（按时间倒序，实时）
  Stream<List<TimelinePost>> watchAllPosts({int limit = 50}) {
    return supabaseClient
        .from('timeline_posts')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows
              .map((e) => TimelinePost.fromJson(e as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.length > limit ? list.sublist(0, limit) : list;
        });
  }

  Future<List<TimelinePost>> getPostsForStudents(List<String> studentIds, {int limit = 50}) async {
    if (studentIds.isEmpty) return [];

    final data = await supabaseClient
        .from('timeline_posts')
        .select()
        .contains('mentioned_student_ids', studentIds)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => TimelinePost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TimelinePost> createPost(TimelinePost post) async {
    // 使用数据库默认 UUID：插入时不传 id
    final payload = post.toJson();
    payload.remove('id');

    final inserted = await supabaseClient
        .from('timeline_posts')
        .insert(payload)
        .select()
        .single();
    return TimelinePost.fromJson(inserted as Map<String, dynamic>);
  }

  /// 当前用户点赞的帖子列表
  Future<List<String>> getLikedPostIds(String userId) async {
    final data = await supabaseClient
        .from('timeline_likes')
        .select('post_id')
        .eq('user_id', userId);
    return (data as List)
        .map((e) => (e as Map<String, dynamic>)['post_id'] as String)
        .toList();
  }

  /// 点赞/取消点赞
  Future<void> toggleLike(String postId, String userId) async {
    final existing = await supabaseClient
        .from('timeline_likes')
        .select()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      await supabaseClient
          .from('timeline_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await supabaseClient.from('timeline_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  /// 获取评论
  Future<List<TimelineComment>> fetchComments(String postId, {int limit = 50}) async {
    final data = await supabaseClient
        .from('timeline_comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => TimelineComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 发表评论
  Future<void> addComment({
    required String postId,
    required String userId,
    required String content,
  }) async {
    await supabaseClient.from('timeline_comments').insert({
      'post_id': postId,
      'user_id': userId,
      'content': content,
    });
  }
}

final supabaseTimelineRepositoryProvider = Provider<SupabaseTimelineRepository>((ref) {
  return SupabaseTimelineRepository();
});
