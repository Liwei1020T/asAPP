import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/venue.dart';
import 'supabase_client_provider.dart';

/// Supabase 场地仓库
class SupabaseVenuesRepository {
  Future<List<Venue>> fetchVenues() async {
    final data = await supabaseClient
        .from('venues')
        .select()
        .order('name', ascending: true);
    return (data as List)
        .map((e) => Venue.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final supabaseVenuesRepositoryProvider = Provider<SupabaseVenuesRepository>((ref) {
  return SupabaseVenuesRepository();
});
