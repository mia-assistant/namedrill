import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/group_model.dart';
import '../providers/app_providers.dart';

class GroupCard extends ConsumerWidget {
  final GroupModel group;
  final VoidCallback onTap;

  const GroupCard({
    super.key,
    required this.group,
    required this.onTap,
  });

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
    final personCountAsync = ref.watch(personCountProvider(group.id));
    final previewPeopleAsync = ref.watch(previewPeopleProvider(group.id));
    final groupStatsAsync = ref.watch(groupStatsProvider(group.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: group.name,
      button: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(CardStyles.borderRadius),
        child: InkWell(
          onTap: () {
            debugPrint('GroupCard tapped: ${group.name}');
            onTap();
          },
          borderRadius: BorderRadius.circular(CardStyles.borderRadius),
          child: Container(
            padding: const EdgeInsets.all(Spacing.cardPadding),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(CardStyles.borderRadius),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: CardStyles.softShadow(groupColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and chevron
                Row(
                  children: [
                    // Colored dot indicator
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: groupColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Person count inline
                    personCountAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (count) => Text(
                        '$count',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ],
                ),

                const SizedBox(height: Spacing.lg),

                // Photo grid preview
                previewPeopleAsync.when(
                  loading: () => _buildEmptyPhotosPlaceholder(context),
                  error: (_, __) => _buildEmptyPhotosPlaceholder(context),
                  data: (people) => people.isEmpty
                      ? _buildEmptyPhotosPlaceholder(context)
                      : _buildPhotoGrid(context, people),
                ),

                const SizedBox(height: Spacing.lg),

                // Progress bar at bottom
                groupStatsAsync.when(
                  loading: () => _buildProgressBar(context, 0),
                  error: (_, __) => _buildProgressBar(context, 0),
                  data: (stats) {
                    final percent = stats['percentLearned'] as int;
                    return _buildProgressBar(context, percent);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPhotosPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(CardStyles.smallBorderRadius),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 22,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'Add people to get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, List people) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: people.length > 4 ? 4 : people.length,
        itemBuilder: (context, index) {
          final person = people[index];
          final isLast = index == 3 && people.length > 4;
          
          return Padding(
            padding: EdgeInsets.only(right: index < 3 ? Spacing.sm : 0),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(person.photoPath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                    if (isLast && people.length > 4)
                      Container(
                        color: Colors.black.withOpacity(0.45),
                        child: Center(
                          child: Text(
                            '+${people.length - 4}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, int percent) {
    final progressColor = percent >= 80
        ? AppTheme.successColor
        : percent >= 50
            ? AppTheme.warningColor
            : groupColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        // Progress bar
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: percent / 100,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacing.md),
        // Percent label
        Text(
          '$percent%',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: progressColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
