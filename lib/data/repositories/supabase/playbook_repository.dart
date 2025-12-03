import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/training_material.dart';
import 'supabase_client_provider.dart';

/// Supabase 训练手册仓库
class SupabasePlaybookRepository {
  Future<List<TrainingMaterial>> fetchMaterials({String? category, String? search, int limit = 100}) async {
    var query = supabaseClient.from('training_materials').select();

    // 先应用过滤，再排序与限制
    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }
    if (search != null && search.isNotEmpty) {
      query = query.ilike('title', '%$search%');
    }

    final data = await query
        .order('created_at', ascending: false)
        .limit(limit);
    return (data as List)
        .map((e) => TrainingMaterial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 实时订阅训练资料（按创建时间倒序）
  Stream<List<TrainingMaterial>> watchMaterials({int limit = 200}) {
    return supabaseClient
        .from('training_materials')
        .stream(primaryKey: ['id'])
        .map((rows) {
          final list = rows
              .map((e) => TrainingMaterial.fromJson(e as Map<String, dynamic>))
              .toList();
          list.sort((a, b) => (b.createdAt ?? DateTime.now())
              .compareTo(a.createdAt ?? DateTime.now()));
          return list.length > limit ? list.sublist(0, limit) : list;
        });
  }

  Future<TrainingMaterial> createMaterial(TrainingMaterial material) async {
    // 使用数据库默认 UUID：插入时不传 id
    final payload = material.toJson();
    payload.remove('id');

    final inserted = await supabaseClient
        .from('training_materials')
        .insert(payload)
        .select()
        .single();
    return TrainingMaterial.fromJson(inserted as Map<String, dynamic>);
  }

  Future<TrainingMaterial> updateMaterial(TrainingMaterial material) async {
    final updated = await supabaseClient
        .from('training_materials')
        .update(material.toJson())
        .eq('id', material.id)
        .select()
        .single();
    return TrainingMaterial.fromJson(updated as Map<String, dynamic>);
  }

  Future<void> deleteMaterial(String id) async {
    await supabaseClient.from('training_materials').delete().eq('id', id);
  }
}

final supabasePlaybookRepositoryProvider = Provider<SupabasePlaybookRepository>((ref) {
  return SupabasePlaybookRepository();
});
