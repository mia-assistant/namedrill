import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      return Scaffold(
        appBar: AppBar(title: const Text('Learn')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'All caught up!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'No cards due for review. Check back later!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Semantics(
                  label: 'All caught up Done button',
                  button: true,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Check if session is complete
    if (_currentIndex >= _cards.length) {
      return _buildSummaryScreen();
    }

    final currentCard = _cards[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_cards.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitConfirmation(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _cards.length,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
            padding: const EdgeInsets.all(24),
            child: _isRevealed
                ? Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          label: 'Forgot',
                          button: true,
                          child: OutlinedButton(
                            onPressed: () => _answer(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Forgot'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Semantics(
                          label: 'Got It',
                          button: true,
                          child: ElevatedButton(
                            onPressed: () => _answer(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Got It'),
                          ),
                        ),
                      ),
                    ],
                  )
                : Semantics(
                    label: 'Tap card to reveal',
                    child: Center(
                      child: Text(
                        'Tap card to reveal',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_LearnCard card) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Card(
        key: ValueKey('${card.person.id}_$_isRevealed'),
        elevation: 4,
        child: Container(
          width: double.infinity,
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
                        Icon(
                          Icons.help_outline,
                          size: 80,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Who is this?',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                Text(
                  card.person.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
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

    return Scaffold(
      appBar: AppBar(title: Semantics(label: 'Session Complete Title', child: const Text('Session Complete'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                accuracy >= 80 ? Icons.emoji_events : Icons.school,
                size: 64,
                color: accuracy >= 80 ? Colors.amber : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                accuracy >= 80 ? 'Great job!' : 'Keep practicing!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryStat(context, '$_totalReviewed', 'Cards'),
                  _buildSummaryStat(context, '$accuracy%', 'Accuracy'),
                  _buildSummaryStat(context, '$_correctCount', 'Correct'),
                ],
              ),
              
              if (_weakestPeople.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Focus on these:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _weakestPeople.take(5).map((person) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundImage: FileImage(File(person.photoPath)),
                        onBackgroundImageError: (_, __) {},
                      ),
                      label: Text(person.name),
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

  Widget _buildSummaryStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
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
