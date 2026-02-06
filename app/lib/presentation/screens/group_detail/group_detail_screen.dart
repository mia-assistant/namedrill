import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/person_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/empty_state.dart';
import '../add_edit_person/add_edit_person_screen.dart';
import '../learn_mode/learn_mode_screen.dart';
import '../quiz_mode/quiz_mode_screen.dart';
import 'edit_group_dialog.dart';

// People notifier provider for specific group
final peopleNotifierProvider = StateNotifierProvider.family<PeopleNotifier, AsyncValue<List<PersonModel>>, String>(
  (ref, groupId) => PeopleNotifier(ref, groupId),
);

class GroupDetailScreen extends ConsumerWidget {
  final GroupModel group;

  const GroupDetailScreen({super.key, required this.group});

  Color get groupColor {
    if (group.color == null) return AppTheme.primaryColor;
    try {
      return Color(int.parse(group.color!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleNotifierProvider(group.id));
    final groupStatsAsync = ref.watch(groupStatsProvider(group.id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: groupColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: groupColor.withOpacity(0.4),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(group.name),
          ],
        ),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit Group'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Group', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _showEditGroupDialog(context, ref);
              } else if (value == 'delete') {
                _showDeleteConfirmation(context, ref);
              }
            },
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: peopleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (people) => _buildContent(context, ref, people, groupStatsAsync),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPerson(context, ref),
        backgroundColor: groupColor,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<PersonModel> people,
    AsyncValue<Map<String, dynamic>> statsAsync,
  ) {
    if (people.isEmpty) {
      return SafeArea(
        child: EmptyState(
          icon: Icons.person_add_outlined,
          title: 'No people yet',
          message: 'Add your first person to start learning names',
          action: Semantics(
            label: 'Add Person',
            button: true,
            child: ElevatedButton.icon(
              onPressed: () => _addPerson(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Person'),
              style: ElevatedButton.styleFrom(
                backgroundColor: groupColor,
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          // Fixed header section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                // Stats card
                _buildStatsCard(context, statsAsync, people.length),
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Learn',
                        button: true,
                        child: _buildActionButton(
                          context: context,
                          label: 'Learn',
                          icon: Icons.school,
                          isPrimary: true,
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LearnModeScreen(group: group),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        label: 'Quiz',
                        button: true,
                        child: _buildActionButton(
                          context: context,
                          label: 'Quiz',
                          icon: Icons.quiz,
                          isPrimary: false,
                          onPressed: people.length >= AppConstants.minPeopleForQuiz
                              ? () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuizModeScreen(group: group),
                                    ),
                                  )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Disabled quiz message
                if (people.length < AppConstants.minPeopleForQuiz)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: groupColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: groupColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add ${AppConstants.minPeopleForQuiz - people.length} more to unlock Quiz',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: groupColor,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Section header
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'People',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${people.length}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Scrollable people grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.8,
              ),
              itemCount: people.length,
              itemBuilder: (context, index) {
                final person = people[index];
                return _buildPersonCard(context, ref, person);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isPrimary,
    required VoidCallback? onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isPrimary) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: onPressed != null
              ? [
                  BoxShadow(
                    color: groupColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: groupColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    } else {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: onPressed != null ? groupColor : Theme.of(context).disabledColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: BorderSide(
            color: onPressed != null ? groupColor : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
      );
    }
  }

  Widget _buildStatsCard(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> statsAsync,
    int totalPeople,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            groupColor.withOpacity(isDark ? 0.15 : 0.08),
            groupColor.withOpacity(isDark ? 0.08 : 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: groupColor.withOpacity(0.15),
        ),
      ),
      child: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Text('Error loading stats'),
        data: (stats) {
          final learned = stats['learned'] as int;
          final percent = stats['percentLearned'] as int;

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip(context, '$totalPeople', 'Total', Icons.people, Colors.blue),
              _buildStatChip(context, '$learned', 'Learned', Icons.check_circle, AppTheme.successColor),
              _buildStatChip(context, '$percent%', 'Progress', Icons.trending_up, groupColor),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }

  Widget _buildPersonCard(BuildContext context, WidgetRef ref, PersonModel person) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddEditPersonScreen(
            groupId: group.id,
            person: person,
          ),
        ),
      ).then((_) => ref.read(peopleNotifierProvider(group.id).notifier).loadPeople()),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(person.photoPath),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            person.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _addPerson(BuildContext context, WidgetRef ref) async {
    final personCount = await ref.read(personCountProvider(group.id).future);
    final isPremium = ref.read(isPremiumProvider);

    if (!isPremium && personCount >= AppConstants.maxFreePeoplePerGroup) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upgrade to Premium to add more people'),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddEditPersonScreen(groupId: group.id),
        ),
      ).then((_) => ref.read(peopleNotifierProvider(group.id).notifier).loadPeople());
    }
  }

  void _showEditGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog<GroupModel>(
      context: context,
      builder: (context) => EditGroupDialog(group: group),
    ).then((updatedGroup) {
      if (updatedGroup != null) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group updated')),
        );
      }
    });
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: Text(
          'This will permanently delete "${group.name}" and all people in it. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(groupsProvider.notifier).deleteGroup(group.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
