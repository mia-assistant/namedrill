import 'dart:math' as math;
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

    return Semantics(
      label: 'Stats Summary',
      container: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting header
              Row(
                children: [
                  Text(
                    _getGreeting(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getGreetingEmoji(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Keep up the good work!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
              ),
              const SizedBox(height: 20),
              
              // Stats row with progress rings
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Streak
                  userStatsAsync.when(
                    loading: () => _buildProgressRing(
                      context,
                      value: 0,
                      maxValue: 7,
                      label: 'Streak',
                      valueText: '...',
                      icon: Icons.local_fire_department,
                      ringColor: Colors.orange,
                    ),
                    error: (_, __) => _buildProgressRing(
                      context,
                      value: 0,
                      maxValue: 7,
                      label: 'Streak',
                      valueText: '0',
                      icon: Icons.local_fire_department,
                      ringColor: Colors.orange,
                    ),
                    data: (stats) => _buildProgressRing(
                      context,
                      value: stats.currentStreak.clamp(0, 7).toDouble(),
                      maxValue: 7,
                      label: 'Streak',
                      valueText: '${stats.currentStreak}',
                      icon: Icons.local_fire_department,
                      ringColor: Colors.orange,
                    ),
                  ),

                  // Groups
                  _buildProgressRing(
                    context,
                    value: groupCount.clamp(0, 10).toDouble(),
                    maxValue: 10,
                    label: 'Groups',
                    valueText: '$groupCount',
                    icon: Icons.folder_outlined,
                    ringColor: Colors.cyan,
                  ),

                  // People
                  totalPeopleAsync.when(
                    loading: () => _buildProgressRing(
                      context,
                      value: 0,
                      maxValue: 50,
                      label: 'People',
                      valueText: '...',
                      icon: Icons.people_outline,
                      ringColor: Colors.green,
                    ),
                    error: (_, __) => _buildProgressRing(
                      context,
                      value: 0,
                      maxValue: 50,
                      label: 'People',
                      valueText: '0',
                      icon: Icons.people_outline,
                      ringColor: Colors.green,
                    ),
                    data: (count) => _buildProgressRing(
                      context,
                      value: count.clamp(0, 50).toDouble(),
                      maxValue: 50,
                      label: 'People',
                      valueText: '$count',
                      icon: Icons.people_outline,
                      ringColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️';
    if (hour < 17) return '👋';
    return '🌙';
  }

  Widget _buildProgressRing(
    BuildContext context, {
    required double value,
    required double maxValue,
    required String label,
    required String valueText,
    required IconData icon,
    required Color ringColor,
  }) {
    final progress = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Semantics(
      label: '$valueText $label',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background ring
                CustomPaint(
                  size: const Size(64, 64),
                  painter: _RingPainter(
                    progress: 1.0,
                    color: Colors.white.withOpacity(0.2),
                    strokeWidth: 6,
                  ),
                ),
                // Progress ring
                CustomPaint(
                  size: const Size(64, 64),
                  painter: _RingPainter(
                    progress: progress,
                    color: ringColor,
                    strokeWidth: 6,
                  ),
                ),
                // Center content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: ringColor,
                    ),
                    Text(
                      valueText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Draw arc from top (-90 degrees)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
