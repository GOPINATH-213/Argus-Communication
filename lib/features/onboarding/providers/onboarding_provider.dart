import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/hive_service.dart';

class UserProfileState {
  final String? name;
  final int streak;
  final int totalSessions;
  final bool isOnboarded;

  UserProfileState({
    this.name,
    this.streak = 0,
    this.totalSessions = 0,
    this.isOnboarded = false,
  });

  UserProfileState copyWith({
    String? name,
    int? streak,
    int? totalSessions,
    bool? isOnboarded,
  }) {
    return UserProfileState(
      name: name ?? this.name,
      streak: streak ?? this.streak,
      totalSessions: totalSessions ?? this.totalSessions,
      isOnboarded: isOnboarded ?? this.isOnboarded,
    );
  }
}

class OnboardingNotifier extends StateNotifier<UserProfileState> {
  OnboardingNotifier() : super(UserProfileState()) {
    _loadProfile();
  }

  void _loadProfile() {
    final name = HiveService.getUserName();
    if (name != null) {
      HiveService.updateStreakAndActivity();
      state = UserProfileState(
        name: name,
        streak: HiveService.getStreak(),
        totalSessions: HiveService.getTotalSessions(),
        isOnboarded: true,
      );
    }
  }

  Future<void> submitName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    await HiveService.saveUserName(trimmed);
    state = UserProfileState(
      name: trimmed,
      streak: 1,
      totalSessions: 0,
      isOnboarded: true,
    );
  }

  Future<void> incrementSessionCount() async {
    // Reload metrics when user completes a conversation
    state = state.copyWith(
      totalSessions: HiveService.getTotalSessions(),
      streak: HiveService.getStreak(),
    );
  }

  Future<void> resetAllData() async {
    await HiveService.clearAllExceptTurns();
    state = UserProfileState(
      name: null,
      streak: 0,
      totalSessions: 0,
      isOnboarded: false,
    );
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, UserProfileState>((ref) {
  return OnboardingNotifier();
});
