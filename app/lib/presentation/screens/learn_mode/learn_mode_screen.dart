import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/spaced_repetition.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/person_model.dart';
import '../../../data/models/learning_record_model.dart';
import '../../providers/app_providers.dart';

class LearnModeScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const LearnModeScreen({super.key, required this.group});

  @override
  ConsumerState<LearnModeScreen> createState() => _LearnModeScreenState();
}

class _LearnModeScreenState extends ConsumerState<LearnModeScreen> {
  List<_LearnCard> _cards = [];
  int _currentIndex = 0;
  bool _isRevealed = false;
  bool _isLoading = true;
  int _correctCount = 0;
  int _totalReviewed = 0;
  List<PersonModel> _weakestPeople = [];

  Color get groupColor {
    if (widget.group.color == null) return AppTheme.primaryColor;
    try {
      return Color(int.parse(widget.group.color!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return AppTheme.primaryColor;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final learningRepo = ref.read(learningRepositoryProvider);
      final personRepo = ref.read(personRepositoryProvider);
      final uuid = ref.read(uuidProvider);
      final settings = await ref.read(userRepositoryProvider).getSettings();
      
      final sessionSize = settings.sessionCardCount;
      final records = await learningRepo.getSessionCards(
        widget.group.id,
        sessionSize,
        () => uuid.v4(),
      );

      // Load people for these records
      final cards = <_LearnCard>[];
      for (final record in records) {
        final person = await personRepo.getPersonById(record.personId);
        if (person != null) {
          // Randomly choose face→name or name→face
          final showFaceFirst = Random().nextBool();
          cards.add(_LearnCard(
            person: person,
            record: record,
            showFaceFirst: showFaceFirst,
          ));
        }
      }

      // Shuffle for variety
      cards.shuffle();

      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading session: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Learn')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cards.isEmpty) {
      return _buildAllCaughtUpScreen();
    }

    // Check if session is complete
    if (_currentIndex >= _cards.length) {
      return _buildSummaryScreen();
    }

    final currentCard = _cards[_currentIndex];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${_currentIndex + 1} / ${_cards.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitConfirmation(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              groupColor.withOpacity(0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Progress bar with styling
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentIndex + 1) / _cards.length,
                    backgroundColor: groupColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(groupColor),
                    minHeight: 6,
                  ),
                ),
              ),
              
              // Card area
              Expanded(
                child: Semantics(
                  label: 'Flashcard',
                  button: true,
                  child: GestureDetector(
                    onTap: () => setState(() => _isRevealed = true),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildCard(currentCard),
                    ),
                  ),
                ),
              ),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: _isRevealed
                    ? Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: 'Forgot',
                              button: true,
                              child: _buildActionButton(
                                label: 'Forgot',
                                icon: Icons.close,
                                color: AppTheme.errorColor,
                                isOutlined: true,
                                onPressed: () => _answer(false),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Semantics(
                              label: 'Got It',
                              button: true,
                              child: _buildActionButton(
                                label: 'Got It',
                                icon: Icons.check,
                                color: AppTheme.successColor,
                                isOutlined: false,
                                onPressed: () => _answer(true),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Semantics(
                        label: 'Tap card to reveal',
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: groupColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 18,
                                color: groupColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tap card to reveal',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: groupColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isOutlined,
    required VoidCallback onPressed,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 2),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
  }

  Widget _buildCard(_LearnCard card) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey('${card.person.id}_$_isRevealed'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: groupColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Colored accent at top
              Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [groupColor, groupColor.withOpacity(0.7)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (card.showFaceFirst || _isRevealed) ...[
                        // Show photo
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(card.person.photoPath),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Show name only
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: groupColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.help_outline,
                                    size: 60,
                                    color: groupColor,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Who is this?',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Name display
                      if (!card.showFaceFirst || _isRevealed)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                groupColor.withOpacity(0.1),
                                groupColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            card.person.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: groupColor,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Tap to reveal name',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllCaughtUpScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.successColor.withOpacity(0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success illustration
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.successColor.withOpacity(0.1),
                      ),
                    ),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.successColor.withOpacity(0.15),
                      ),
                    ),
                    Icon(
                      Icons.check_circle,
                      size: 60,
                      color: AppTheme.successColor,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'All caught up!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No cards due for review.\nCheck back later!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Semantics(
                  label: 'All caught up Done button',
                  button: true,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Done'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _answer(bool gotIt) async {
    final currentCard = _cards[_currentIndex];
    
    // Update learning record
    final updatedRecord = SpacedRepetition.processReview(
      record: currentCard.record,
      gotIt: gotIt,
    );
    
    await ref.read(learningRepositoryProvider).updateRecord(updatedRecord);
    
    // Track stats
    _totalReviewed++;
    if (gotIt) _correctCount++;
    if (!gotIt) {
      _weakestPeople.add(currentCard.person);
    }

    // Record activity for streak
    await ref.read(userRepositoryProvider).recordActivity();

    // Move to next card
    setState(() {
      _currentIndex++;
      _isRevealed = false;
    });
  }

  Widget _buildSummaryScreen() {
    final accuracy = _totalReviewed > 0 ? (_correctCount / _totalReviewed * 100).round() : 0;
    final isGreat = accuracy >= 80;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isGreat ? Colors.amber : AppTheme.primaryColor).withOpacity(0.15),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trophy or school icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isGreat ? Colors.amber : AppTheme.primaryColor).withOpacity(0.1),
                      ),
                    ),
                    Icon(
                      isGreat ? Icons.emoji_events : Icons.school,
                      size: 56,
                      color: isGreat ? Colors.amber : AppTheme.primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  isGreat ? 'Great job!' : 'Keep practicing!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 32),
                
                // Stats cards row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(context, '$_totalReviewed', 'Cards', Icons.style),
                    _buildStatCard(context, '$accuracy%', 'Accuracy', Icons.track_changes),
                    _buildStatCard(context, '$_correctCount', 'Correct', Icons.check_circle),
                  ],
                ),
                
                if (_weakestPeople.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Focus on these:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _weakestPeople.take(5).map((person) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Chip(
                          avatar: CircleAvatar(
                            backgroundImage: FileImage(File(person.photoPath)),
                            onBackgroundImageError: (_, __) {},
                          ),
                          label: Text(person.name),
                          backgroundColor: Colors.transparent,
                          side: BorderSide.none,
                        ),
                      );
                    }).toList(),
                  ),
                ],
                
                const Spacer(),
                
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    label: 'Done',
                    button: true,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    if (_totalReviewed == 0) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session?'),
        content: const Text('Your progress so far will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('End'),
          ),
        ],
      ),
    );
  }
}

class _LearnCard {
  final PersonModel person;
  final LearningRecordModel record;
  final bool showFaceFirst;

  _LearnCard({
    required this.person,
    required this.record,
    required this.showFaceFirst,
  });
}
