import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/config/debug_config.dart';
import '../../core/providers/purchase_providers.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';

// UUID generator provider
final uuidProvider = Provider<Uuid>((ref) => const Uuid());

// Repository providers
final groupRepositoryProvider = Provider<GroupRepository>((ref) => GroupRepository());
final personRepositoryProvider = Provider<PersonRepository>((ref) => PersonRepository());
final learningRepositoryProvider = Provider<LearningRepository>((ref) => LearningRepository());
final quizRepositoryProvider = Provider<QuizRepository>((ref) => QuizRepository());
final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

// Groups state
final groupsProvider = StateNotifierProvider<GroupsNotifier, AsyncValue<List<GroupModel>>>((ref) {
  return GroupsNotifier(ref);
});

class GroupsNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  final Ref _ref;
  
  GroupsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadGroups();
  }

  Future<void> loadGroups() async {
    state = const AsyncValue.loading();
    try {
      final groups = await _ref.read(groupRepositoryProvider).getAllGroups();
      state = AsyncValue.data(groups);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGroup(String name, String? color) async {
    final uuid = _ref.read(uuidProvider);
    final now = DateTime.now();
    final group = GroupModel(
      id: uuid.v4(),
      name: name,
      color: color,
      createdAt: now,
      updatedAt: now,
    );
    
    await _ref.read(groupRepositoryProvider).insertGroup(group);
    await loadGroups();
  }

  Future<void> updateGroup(GroupModel group) async {
    final updated = group.copyWith(updatedAt: DateTime.now());
    await _ref.read(groupRepositoryProvider).updateGroup(updated);
    await loadGroups();
  }

  Future<void> deleteGroup(String groupId) async {
    await _ref.read(groupRepositoryProvider).deleteGroup(groupId);
    await loadGroups();
  }

  Future<void> reorderGroups(List<String> groupIds) async {
    await _ref.read(groupRepositoryProvider).updateGroupOrder(groupIds);
    await loadGroups();
  }
}

// People for a specific group
final peopleByGroupProvider = FutureProvider.family<List<PersonModel>, String>((ref, groupId) async {
  return ref.read(personRepositoryProvider).getPeopleByGroup(groupId);
});

// People state manager for a group
class PeopleNotifier extends StateNotifier<AsyncValue<List<PersonModel>>> {
  final Ref _ref;
  final String groupId;
  
  PeopleNotifier(this._ref, this.groupId) : super(const AsyncValue.loading()) {
    loadPeople();
  }

  Future<void> loadPeople() async {
    state = const AsyncValue.loading();
    try {
      final people = await _ref.read(personRepositoryProvider).getPeopleByGroup(groupId);
      state = AsyncValue.data(people);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addPerson({
    required String name,
    required String photoPath,
    String? notes,
  }) async {
    final uuid = _ref.read(uuidProvider);
    final personId = uuid.v4();
    final now = DateTime.now();
    
    // Save photo to permanent storage
    final savedPhotoPath = await _ref.read(personRepositoryProvider)
        .savePhoto(photoPath, personId);
    
    final person = PersonModel(
      id: personId,
      groupId: groupId,
      name: name,
      photoPath: savedPhotoPath,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );
    
    await _ref.read(personRepositoryProvider).insertPerson(person);
    await loadPeople();
  }

  Future<void> updatePerson(PersonModel person, {String? newPhotoPath}) async {
    String photoPath = person.photoPath;
    
    if (newPhotoPath != null) {
      photoPath = await _ref.read(personRepositoryProvider)
          .savePhoto(newPhotoPath, person.id);
    }
    
    final updated = person.copyWith(
      photoPath: photoPath,
      updatedAt: DateTime.now(),
    );
    
    await _ref.read(personRepositoryProvider).updatePerson(updated);
    await loadPeople();
  }

  Future<void> deletePerson(String personId) async {
    await _ref.read(personRepositoryProvider).deletePerson(personId);
    await _ref.read(learningRepositoryProvider).deleteRecordsForPerson(personId);
    await loadPeople();
  }

  Future<void> movePerson(String personId, String newGroupId) async {
    await _ref.read(personRepositoryProvider).movePerson(personId, newGroupId);
    await loadPeople();
  }
}

// Person count for a group (for display on group cards)
final personCountProvider = FutureProvider.family<int, String>((ref, groupId) async {
  return ref.read(personRepositoryProvider).getPersonCountByGroup(groupId);
});

// Preview people for group cards
final previewPeopleProvider = FutureProvider.family<List<PersonModel>, String>((ref, groupId) async {
  return ref.read(personRepositoryProvider).getPreviewPeopleForGroup(groupId);
});

// Group stats
final groupStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, groupId) async {
  return ref.read(learningRepositoryProvider).getGroupStats(groupId);
});

// User stats
final userStatsProvider = FutureProvider<UserStatsModel>((ref) async {
  return ref.read(userRepositoryProvider).getUserStats();
});

// Settings
final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsModel>>((ref) {
  return SettingsNotifier(ref);
});

class SettingsNotifier extends StateNotifier<AsyncValue<SettingsModel>> {
  final Ref _ref;
  
  SettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _ref.read(userRepositoryProvider).getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(SettingsModel settings) async {
    await _ref.read(userRepositoryProvider).updateSettings(settings);
    await loadSettings();
  }

  Future<void> setDarkMode(DarkModeOption mode) async {
    final current = state.value ?? SettingsModel();
    await updateSettings(current.copyWith(darkMode: mode));
  }

  Future<void> setNotifications(bool enabled, {int? hour, int? minute}) async {
    final current = state.value ?? SettingsModel();
    final updatedHour = hour ?? current.notificationHour;
    final updatedMinute = minute ?? current.notificationMinute;

    await updateSettings(current.copyWith(
      notificationsEnabled: enabled,
      notificationHour: updatedHour,
      notificationMinute: updatedMinute,
    ));

    // Schedule or cancel the daily reminder
    final notifService = NotificationService.instance;
    if (enabled) {
      final hasPermission = await notifService.requestPermission();
      if (hasPermission) {
        await notifService.scheduleDailyReminder(
          hour: updatedHour,
          minute: updatedMinute,
        );
      }
    } else {
      await notifService.cancelAllReminders();
    }
  }

  Future<void> setSessionCardCount(int count) async {
    final current = state.value ?? SettingsModel();
    await updateSettings(current.copyWith(sessionCardCount: count));
  }

  Future<void> setPremium(bool isPremium) async {
    final current = state.value ?? SettingsModel();
    await updateSettings(current.copyWith(
      isPremium: isPremium,
      premiumPurchaseDate: isPremium ? DateTime.now() : null,
    ));
  }
}

// Premium status (convenience) - combines store status with local settings
final isPremiumProvider = Provider<bool>((ref) {
  // Debug override
  if (DebugConfig.fakePremium) return true;
  
  // Check store purchase status first (source of truth)
  final purchaseState = ref.watch(purchaseStateProvider);
  if (purchaseState.isPremium) return true;
  
  // Fall back to local settings for offline access
  final settings = ref.watch(settingsProvider);
  return settings.value?.isPremium ?? false;
});

// Group count - watches groupsProvider to stay in sync
final groupCountProvider = Provider<int>((ref) {
  final groups = ref.watch(groupsProvider);
  return groups.value?.length ?? 0;
});

// Total people count
final totalPeopleCountProvider = FutureProvider<int>((ref) async {
  return ref.read(personRepositoryProvider).getTotalPersonCount();
});

// Weekly activity for stats
final weeklyActivityProvider = FutureProvider<Map<DateTime, int>>((ref) async {
  return ref.read(userRepositoryProvider).getWeeklyActivity();
});
