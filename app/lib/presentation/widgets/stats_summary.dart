import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../providers/app_providers.dart';

class StatsSummary extends ConsumerWidget {
  const StatsSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsProvider);
    final totalPeopleAsync = ref.watch(totalPeopleCountProvider);
    final groupCount = ref.watch(groupCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Stats Summary',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.cardPadding),
        decoration: NeoStyles.cardDecoration(isDark: isDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple row of stat chips
            Row(
              children: [
                // Streak
                Expanded(
                  child: userStatsAsync.when(
                    loading: () => _buildStatChip(
                      context,
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      chipColor: AppTheme.chipYellow,
                      value: '...',
                      label: 'streak',
                    ),
                    error: (_, __) => _buildStatChip(
                      context,
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      chipColor: AppTheme.chipYellow,
                      value: '0',
                      label: 'day streak',
                    ),
                    data: (stats) => _buildStatChip(
                      context,
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      chipColor: AppTheme.chipYellow,
                      value: '${stats.currentStreak}',
                      label: stats.currentStreak == 1 ? 'day streak' : 'day streak',
                      highlight: stats.currentStreak >= 7,
                    ),
                  ),
                ),
                
                const SizedBox(width: Spacing.md),
                
                // Groups
                Expanded(
                  child: _buildStatChip(
                    context,
                    icon: Icons.folder_outlined,
                    iconColor: Colors.cyan,
                    chipColor: AppTheme.chipBlue,
                    value: '$groupCount',
                    label: groupCount == 1 ? 'group' : 'groups',
                  ),
                ),
                
                const SizedBox(width: Spacing.md),
                
                // People
                Expanded(
                  child: totalPeopleAsync.when(
                    loading: () => _buildStatChip(
                      context,
                      icon: Icons.people_outline,
                      iconColor: AppTheme.secondaryColor,
                      chipColor: AppTheme.chipGreen,
                      value: '...',
                      label: 'people',
                    ),
                    error: (_, __) => _buildStatChip(
                      context,
                      icon: Icons.people_outline,
                      iconColor: AppTheme.secondaryColor,
                      chipColor: AppTheme.chipGreen,
                      value: '0',
                      label: 'people',
                    ),
                    data: (count) => _buildStatChip(
                      context,
                      icon: Icons.people_outline,
                      iconColor: AppTheme.secondaryColor,
                      chipColor: AppTheme.chipGreen,
                      value: '$count',
                      label: count == 1 ? 'person' : 'people',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color chipColor,
    required String value,
    required String label,
    bool highlight = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm + 4,
        vertical: Spacing.md,
      ),
      decoration: NeoStyles.chipDecoration(
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : chipColor,
        isDark: isDark,
        borderRadius: CardStyles.smallBorderRadius,
        shadowOffset: 3,
        borderWidth: highlight ? 2.5 : 2,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 26,
            color: iconColor,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
