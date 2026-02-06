import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/group_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/group_card.dart';
import '../../widgets/stats_summary.dart';
import '../../widgets/empty_state.dart';
import '../group_detail/group_detail_screen.dart';
import '../settings/settings_screen.dart';
import 'create_group_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(groupsProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('NameDrill'),
          ],
        ),
        centerTitle: false,
        actions: [
          Semantics(
            label: 'Settings',
            button: true,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.settings_outlined, size: 20),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(groupsProvider.notifier).loadGroups(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (groups) => _buildContent(context, ref, groups, isPremium),
      ),
      floatingActionButton: Semantics(
        label: 'New Group',
        button: true,
        child: FloatingActionButton.extended(
          onPressed: () => _showCreateGroupDialog(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('New Group'),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<GroupModel> groups,
    bool isPremium,
  ) {
    if (groups.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline,
        title: 'No groups yet',
        message: 'Create your first group to start learning names.\nPerfect for teachers, coaches, and team leaders!',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(groupsProvider.notifier).loadGroups(),
      child: CustomScrollView(
        slivers: [
          // Stats summary
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: StatsSummary(),
            ),
          ),

          // Groups header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.folder_outlined,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Your Groups',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${groups.length}${isPremium ? '' : '/${AppConstants.maxFreeGroups}'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Groups list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = groups[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GroupCard(
                      group: group,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(group: group),
                        ),
                      ),
                    ),
                  );
                },
                childCount: groups.length,
              ),
            ),
          ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) async {
    final groupCount = ref.read(groupCountProvider);
    final isPremium = ref.read(isPremiumProvider);

    if (!isPremium && groupCount >= AppConstants.maxFreeGroups) {
      // Show upgrade prompt
      if (context.mounted) {
        _showUpgradeDialog(context, ref);
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => const CreateGroupDialog(),
      );
    }
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'You\'ve reached the free limit of 2 groups. '
          'Upgrade to Premium for unlimited groups and people!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
            child: const Text('Learn More'),
          ),
        ],
      ),
    );
  }
}
