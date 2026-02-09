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
            decoration: NeoStyles.cardDecoration(isDark: isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and chevron
                Row(
                  children: [
                    // Colored dot indicator — larger, with border
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: groupColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? _neoBorderDark : _neoBorderLight,
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Text(
                        group.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Person count inline
                    personCountAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                      data: (count) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: NeoStyles.chipDecoration(
                          backgroundColor: AppTheme.getChipYellow(isDark),
                          isDark: isDark,
                          borderRadius: 8,
                          shadowOffset: 2,
                          borderWidth: 1.5,
                        ),
                        child: Text(
                          '$count',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    Icon(
                      Icons.chevron_right,
                      size: 22,
                      color: isDark ? Colors.grey[400] : const Color(0xFF1A1A1A),
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

                // Progress bar at bottom — chunky
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
      decoration: NeoStyles.cardDecoration(
        isDark: isDark,
        backgroundColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFF8F0),
        borderRadius: CardStyles.smallBorderRadius,
        shadowOffset: 2,
        borderWidth: 2,
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 22,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: Spacing.sm),
            Text(
              'Add people to get started',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, List people) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
              decoration: NeoStyles.cardDecoration(
                isDark: isDark,
                borderRadius: 14,
                shadowOffset: 3,
                borderWidth: 2,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      person.photoFile,
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
                        color: Colors.black.withOpacity(0.55),
                        child: Center(
                          child: Text(
                            '+${people.length - 4}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
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
        // Progress bar — chunky with border
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark ? _neoBorderDark : _neoBorderLight,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(1),
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
        ),
        const SizedBox(width: Spacing.md),
        // Percent label
        Text(
          '$percent%',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: progressColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

// Re-export border colors for use in this file
const Color _neoBorderLight = Color(0xFF1A1A1A);
const Color _neoBorderDark = Color(0xFF888888);
