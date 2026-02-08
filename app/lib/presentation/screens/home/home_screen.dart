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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: NeoStyles.cardDecoration(
                isDark: isDark,
                backgroundColor: AppTheme.primaryColor,
                borderRadius: 12,
                shadowOffset: 3,
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
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
                decoration: NeoStyles.cardDecoration(
                  isDark: isDark,
                  borderRadius: 12,
                  shadowOffset: 2,
                  borderWidth: 2,
                ),
                child: const Icon(Icons.settings_outlined, size: 20),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ),
          const SizedBox(width: Spacing.sm),
        ],
      ),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: Spacing.lg),
                Text('Error: $error', textAlign: TextAlign.center),
                const SizedBox(height: Spacing.lg),
                ElevatedButton(
                  onPressed: () => ref.read(groupsProvider.notifier).loadGroups(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (groups) => _buildContent(context, ref, groups, isPremium),
      ),
      floatingActionButton: Semantics(
        label: 'New Group',
        button: true,
        child: Container(
          decoration: NeoStyles.buttonDecoration(
            backgroundColor: AppTheme.primaryColor,
            isDark: isDark,
            borderRadius: 16,
            shadowOffset: 4,
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _showCreateGroupDialog(context, ref),
            icon: const Icon(Icons.add, size: 22),
            label: Text(
              'New Group',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
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
              padding: EdgeInsets.fromLTRB(
                Spacing.screenPadding,
                Spacing.md,
                Spacing.screenPadding,
                Spacing.lg,
              ),
              child: StatsSummary(),
            ),
          ),

          // Groups header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                Spacing.screenPadding,
                Spacing.sm,
                Spacing.screenPadding,
                Spacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Groups',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm + 4,
                      vertical: Spacing.xs + 2,
                    ),
                    decoration: NeoStyles.chipDecoration(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2A2A2A)
                          : AppTheme.chipBlue,
                      isDark: Theme.of(context).brightness == Brightness.dark,
                      shadowOffset: 2,
                      borderWidth: 2,
                    ),
                    child: Text(
                      '${groups.length}${isPremium ? '' : '/${AppConstants.maxFreeGroups}'}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Groups list
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.screenPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = groups[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md + 4),
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
