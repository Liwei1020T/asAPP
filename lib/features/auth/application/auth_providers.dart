import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/profile.dart';

class CurrentUserNotifier extends Notifier<Profile?> {
  @override
  Profile? build() {
    return null;
  }

  void setUser(Profile? profile) {
    state = profile;
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, Profile?>(CurrentUserNotifier.new);

final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role;
});
