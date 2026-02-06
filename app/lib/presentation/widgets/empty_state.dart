import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: '$title. $message',
        child: Padding(
          padding: const EdgeInsets.all(Spacing.sectionGap),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Clean single circle with icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withOpacity(0.08),
                ),
                child: Icon(
                  icon,
                  size: 44,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: Spacing.sectionGap),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: Spacing.lg),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
