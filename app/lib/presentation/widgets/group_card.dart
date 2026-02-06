import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      child: GestureDetector(
        onTap: () {
          debugPrint('GroupCard tapped: ${group.name}');
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: groupColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored accent bar at top
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      groupColor,
                      groupColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with name
                    Row(
                      children: [
                        // Colored dot with subtle glow
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: groupColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: groupColor.withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: groupColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: groupColor,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Photo grid preview
                    previewPeopleAsync.when(
                      loading: () => _buildEmptyPhotosPlaceholder(context),
                      error: (_, __) => _buildEmptyPhotosPlaceholder(context),
                      data: (people) => people.isEmpty
                          ? _buildEmptyPhotosPlaceholder(context)
                          : _buildPhotoGrid(context, people),
                    ),

                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        // Person count chip
                        personCountAsync.when(
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                          data: (count) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$count ${count == 1 ? 'person' : 'people'}',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Progress indicator
                        groupStatsAsync.when(
                          loading: () => const SizedBox(),
                          error: (_, __) => const SizedBox(),
                          data: (stats) {
                            final percent = stats['percentLearned'] as int;
                            return _buildProgressIndicator(context, percent);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPhotosPlaceholder(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 20,
              color: Theme.of(context).colorScheme.outline.withOpacity(0.6),
            ),
            const SizedBox(width: 8),
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
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: people.length > 4 ? 4 : people.length,
        itemBuilder: (context, index) {
          final person = people[index];
          final isLast = index == 3 && people.length > 4;
          
          return Padding(
            padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Text(
                            '+${people.length - 4}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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

  Widget _buildProgressIndicator(BuildContext context, int percent) {
    final progressColor = percent >= 80
        ? const Color(0xFF22C55E)
        : percent >= 50
            ? const Color(0xFFF59E0B)
            : groupColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular progress
        SizedBox(
          width: 32,
          height: 32,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: percent / 100,
                strokeWidth: 3,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              Text(
                '$percent',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: progressColor,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
        ),
      ],
    );
  }
}
