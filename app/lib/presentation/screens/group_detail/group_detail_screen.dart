import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
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
    if (group.color == null) return const Color(0xFF6366F1);
    try {
      return Color(int.parse(group.color!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peopleAsync = ref.watch(peopleNotifierProvider(group.id));
    final groupStatsAsync = ref.watch(groupStatsProvider(group.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
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
      body: peopleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (people) => _buildContent(context, ref, people, groupStatsAsync),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPerson(context, ref),
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
      return EmptyState(
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
          ),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        // Stats card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatsCard(context, statsAsync, people.length),
          ),
        ),

        // Action buttons
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Learn',
                    button: true,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LearnModeScreen(group: group),
                        ),
                      ),
                      icon: const Icon(Icons.school),
                      label: const Text('Learn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: groupColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: 'Quiz',
                    button: true,
                    child: OutlinedButton.icon(
                      onPressed: people.length >= AppConstants.minPeopleForQuiz
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QuizModeScreen(group: group),
                                ),
                              )
                          : null,
                      icon: const Icon(Icons.quiz),
                      label: const Text('Quiz'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Disabled quiz message
        if (people.length < AppConstants.minPeopleForQuiz)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Add ${AppConstants.minPeopleForQuiz - people.length} more people to unlock Quiz mode',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),

        // People grid
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final person = people[index];
                return _buildPersonCard(context, ref, person);
              },
              childCount: people.length,
            ),
          ),
        ),

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    AsyncValue<Map<String, dynamic>> statsAsync,
    int totalPeople,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Error loading stats'),
          data: (stats) {
            final learned = stats['learned'] as int;
            final percent = stats['percentLearned'] as int;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(context, '$totalPeople', 'Total'),
                    _buildStatItem(context, '$learned', 'Learned'),
                    _buildStatItem(context, '$percent%', 'Progress'),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(groupColor),
                    minHeight: 8,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(person.photoPath),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            person.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
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
