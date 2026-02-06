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

    return GestureDetector(
      onTap: () {
        debugPrint('GroupCard tapped: ${group.name}');
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with color indicator and name
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: groupColor,
                      shape: BoxShape.circle,
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
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Photo grid preview
              previewPeopleAsync.when(
                loading: () => const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (_, __) => const SizedBox(height: 60),
                data: (people) => people.isEmpty
                    ? Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'No people yet',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: 60,
                        child: Row(
                          children: [
                            ...people.take(6).map((person) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: Image.file(
                                        File(person.photoPath),
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          child: Icon(
                                            Icons.person,
                                            color: Theme.of(context).colorScheme.outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  // Person count
                  personCountAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (count) => Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$count ${count == 1 ? 'person' : 'people'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Progress percentage
                  groupStatsAsync.when(
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                    data: (stats) {
                      final percent = stats['percentLearned'] as int;
                      return Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: LinearProgressIndicator(
                              value: percent / 100,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(groupColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$percent%',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: groupColor,
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
