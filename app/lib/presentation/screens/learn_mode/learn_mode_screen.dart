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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: Text('${_currentIndex + 1} / ${_cards.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restart session',
            onPressed: () => _showRestartConfirmation(),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitConfirmation(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar — chunky with border
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 14,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _cards.length,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(groupColor),
                      minHeight: 10,
                    ),
                  ),
                ),
              ),
            ),
              
            
            const SizedBox(height: Spacing.lg),
            
            // Card area
            Expanded(
              flex: 5,
              child: Semantics(
                label: 'Flashcard',
                button: true,
                child: GestureDetector(
                  onTap: () => setState(() => _isRevealed = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildCard(currentCard),
                  ),
                ),
              ),
            ),
              
            // Action buttons
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
                    : Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: NeoStyles.chipDecoration(
                            backgroundColor: AppTheme.getChipBlue(isDark),
                            isDark: isDark,
                            borderRadius: 14,
                            shadowOffset: 2,
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
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isOutlined) {
      return Container(
        decoration: NeoStyles.buttonDecoration(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          isDark: isDark,
          borderRadius: 14,
          shadowOffset: 3,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: color),
                  const SizedBox(width: 8),
                  Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15)),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        decoration: NeoStyles.buttonDecoration(
          backgroundColor: color,
          isDark: isDark,
          borderRadius: 14,
          shadowOffset: 3,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                ],
              ),
            ),
          ),
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
        decoration: NeoStyles.cardDecoration(
          isDark: isDark,
          shadowOffset: 5,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(CardStyles.borderRadius - 2),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.cardPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (card.showFaceFirst || _isRevealed) ...[
                  // Show photo
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(CardStyles.smallBorderRadius),
                        border: Border.all(
                          color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(CardStyles.smallBorderRadius - 2),
                        child: Image.file(
                          card.person.photoFile,
                          fit: BoxFit.cover,
                          width: double.infinity,
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
                  ),
                ] else ...[
                  // Name→face mode, not revealed
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(Spacing.lg),
                            decoration: BoxDecoration(
                              color: AppTheme.getChipBlue(isDark),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.person_outline,
                              size: 60,
                              color: groupColor,
                            ),
                          ),
                          const SizedBox(height: Spacing.lg),
                          Text(
                            'Can you picture them?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: Spacing.lg),
                
                // Name/prompt display
                if (!card.showFaceFirst && !_isRevealed) ...[
                  // Name→face mode: show name as prompt
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                    decoration: NeoStyles.chipDecoration(
                      backgroundColor: isDark ? groupColor.withOpacity(0.2) : groupColor.withOpacity(0.12),
                      isDark: isDark,
                      borderRadius: CardStyles.smallBorderRadius,
                      shadowOffset: 2,
                    ),
                    child: Text(
                      card.person.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: groupColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Tap to reveal face',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ] else if (card.showFaceFirst && !_isRevealed) ...[
                  // Face→name mode: prompt
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                    decoration: NeoStyles.chipDecoration(
                      backgroundColor: AppTheme.getChipYellow(isDark),
                      isDark: isDark,
                      borderRadius: CardStyles.smallBorderRadius,
                      shadowOffset: 2,
                    ),
                    child: Text(
                      'Who is this?',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Tap to reveal name',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ] else ...[
                  // Revealed: show name
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.lg,
                      vertical: Spacing.md,
                    ),
                    decoration: NeoStyles.chipDecoration(
                      backgroundColor: isDark ? groupColor.withOpacity(0.2) : groupColor.withOpacity(0.12),
                      isDark: isDark,
                      borderRadius: CardStyles.smallBorderRadius,
                      shadowOffset: 2,
                    ),
                    child: Text(
                      card.person.name,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: groupColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllCaughtUpScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Success illustration — neo-brutalist
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.getChipGreen(isDark),
                  border: Border.all(
                    color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                    width: 3,
                  ),
                  boxShadow: NeoStyles.hardShadow(offset: 4, isDark: isDark),
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'All caught up!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'Start Over',
                      button: true,
                      child: OutlinedButton.icon(
                        onPressed: () => _startFreshSession(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Start Over'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Semantics(
                      label: 'Done',
                      button: true,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy — neo-brutalist
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark 
                      ? (isGreat ? AppTheme.chipYellowDark : AppTheme.chipBlueDark) 
                      : (isGreat ? AppTheme.chipYellow : AppTheme.chipBlue),
                  border: Border.all(
                    color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                    width: 3,
                  ),
                  boxShadow: NeoStyles.hardShadow(offset: 4, isDark: isDark),
                ),
                child: Icon(
                  isGreat ? Icons.emoji_events : Icons.school,
                  size: 56,
                  color: isGreat ? Colors.amber : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isGreat ? 'Great job!' : 'Keep practicing!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 32),
              
              // Stats cards row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard(context, '$_totalReviewed', 'Cards', Icons.style, AppTheme.chipBlue),
                  _buildStatCard(context, '$accuracy%', 'Accuracy', Icons.track_changes, AppTheme.chipPink),
                  _buildStatCard(context, '$_correctCount', 'Correct', Icons.check_circle, AppTheme.chipGreen),
                ],
              ),
              
              if (_weakestPeople.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Focus on these:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _weakestPeople.take(5).map((person) {
                    return Container(
                      decoration: NeoStyles.chipDecoration(
                        backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        isDark: isDark,
                        borderRadius: 20,
                        shadowOffset: 2,
                        borderWidth: 2,
                      ),
                        child: Chip(
                          avatar: CircleAvatar(
                            backgroundImage: FileImage(person.photoFile),
                            onBackgroundImageError: (_, __) {},
                          ),
                          label: Text(person.name, style: const TextStyle(fontWeight: FontWeight.w600)),
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
      );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon, Color chipBg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Get the dark mode version of the chip color
    Color darkChipBg = const Color(0xFF1E1E1E);
    if (chipBg == AppTheme.chipBlue) darkChipBg = AppTheme.chipBlueDark;
    if (chipBg == AppTheme.chipGreen) darkChipBg = AppTheme.chipGreenDark;
    if (chipBg == AppTheme.chipYellow) darkChipBg = AppTheme.chipYellowDark;
    if (chipBg == AppTheme.chipPink) darkChipBg = AppTheme.chipPinkDark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      decoration: NeoStyles.chipDecoration(
        backgroundColor: isDark ? darkChipBg : chipBg,
        isDark: isDark,
        borderRadius: CardStyles.smallBorderRadius,
        shadowOffset: 3,
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppTheme.primaryColor),
          const SizedBox(height: Spacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  fontWeight: FontWeight.w600,
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

  void _showRestartConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Session?'),
        content: const Text('This will shuffle the cards and start over. Progress on individual cards is still saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartSession();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _restartSession() {
    setState(() {
      _cards.shuffle();
      _currentIndex = 0;
      _isRevealed = false;
      _correctCount = 0;
      _totalReviewed = 0;
      _weakestPeople.clear();
    });
  }

  Future<void> _startFreshSession() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final personRepo = ref.read(personRepositoryProvider);
      final learningRepo = ref.read(learningRepositoryProvider);
      final uuid = ref.read(uuidProvider);
      final settings = await ref.read(userRepositoryProvider).getSettings();
      
      // Get all people in this group
      final people = await personRepo.getPeopleByGroup(widget.group.id);
      
      if (people.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No people in this group')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Create cards for all people (ignoring due dates)
      final cards = <_LearnCard>[];
      for (final person in people.take(settings.sessionCardCount)) {
        // Get or create learning record
        final record = await learningRepo.getOrCreateRecord(person.id, uuid.v4());
        
        final showFaceFirst = Random().nextBool();
        cards.add(_LearnCard(
          person: person,
          record: record,
          showFaceFirst: showFaceFirst,
        ));
      }

      cards.shuffle();

      setState(() {
        _cards = cards;
        _currentIndex = 0;
        _isRevealed = false;
        _correctCount = 0;
        _totalReviewed = 0;
        _weakestPeople.clear();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
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
