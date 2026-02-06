import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class StatsSummary extends ConsumerWidget {
  const StatsSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatsProvider);
    final totalPeopleAsync = ref.watch(totalPeopleCountProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Streak
            userStatsAsync.when(
              loading: () => _buildStatItem(context, '...', 'Day Streak', Icons.local_fire_department),
              error: (_, __) => _buildStatItem(context, '0', 'Day Streak', Icons.local_fire_department),
              data: (stats) => _buildStatItem(
                context,
                stats.currentStreak.toString(),
                'Day Streak',
                Icons.local_fire_department,
                valueColor: stats.currentStreak > 0 ? Colors.orange : null,
              ),
            ),

            // Divider
            Container(
              height: 40,
              width: 1,
              color: Theme.of(context).dividerColor,
            ),

            // Groups
            _buildStatItem(
              context,
              ref.watch(groupCountProvider).toString(),
              'Groups',
              Icons.folder_outlined,
            ),

            // Divider
            Container(
              height: 40,
              width: 1,
              color: Theme.of(context).dividerColor,
            ),

            // People
            totalPeopleAsync.when(
              loading: () => _buildStatItem(context, '...', 'People', Icons.people_outline),
              error: (_, __) => _buildStatItem(context, '0', 'People', Icons.people_outline),
              data: (count) => _buildStatItem(
                context,
                count.toString(),
                'People',
                Icons.people_outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon, {
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: valueColor ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      ],
    );
  }
}
