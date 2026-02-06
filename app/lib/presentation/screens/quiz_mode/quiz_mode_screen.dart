import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/person_model.dart';
import '../../../data/models/quiz_score_model.dart';
import '../../providers/app_providers.dart';

class QuizModeScreen extends ConsumerStatefulWidget {
  final GroupModel group;

  const QuizModeScreen({super.key, required this.group});

  @override
  ConsumerState<QuizModeScreen> createState() => _QuizModeScreenState();
}

class _QuizModeScreenState extends ConsumerState<QuizModeScreen> {
  List<PersonModel> _allPeople = [];
  PersonModel? _currentPerson;
  List<String> _options = [];
  int _score = 0;
  int _timeRemaining = AppConstants.quizDurationSeconds;
  Timer? _timer;
  bool _isLoading = true;
  bool _isFinished = false;
  String? _selectedAnswer;
  bool _showingResult = false;
  List<PersonModel> _missedPeople = [];
  int? _highScore;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQuiz() async {
    try {
      final personRepo = ref.read(personRepositoryProvider);
      final quizRepo = ref.read(quizRepositoryProvider);

      _allPeople = await personRepo.getPeopleByGroup(widget.group.id);
      _highScore = await quizRepo.getHighScore(widget.group.id);
      _streak = await quizRepo.getQuizStreak(widget.group.id);

      if (_allPeople.length < AppConstants.minPeopleForQuiz) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Need at least ${AppConstants.minPeopleForQuiz} people for quiz mode',
              ),
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      setState(() => _isLoading = false);
      _startQuiz();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quiz: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startQuiz() {
    _nextQuestion();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
        if (_timeRemaining <= 0) {
          _endQuiz();
        }
      });
    });
  }

  void _nextQuestion() {
    if (_allPeople.isEmpty) return;

    final random = Random();
    
    // Pick random person as the answer
    final correctPerson = _allPeople[random.nextInt(_allPeople.length)];
    
    // Generate wrong options
    final wrongPeople = _allPeople
        .where((p) => p.id != correctPerson.id)
        .toList()
      ..shuffle();
    
    // Create options list (1 correct + 3 wrong)
    final options = <String>[correctPerson.name];
    for (int i = 0; i < 3 && i < wrongPeople.length; i++) {
      options.add(wrongPeople[i].name);
    }
    options.shuffle();

    setState(() {
      _currentPerson = correctPerson;
      _options = options;
      _selectedAnswer = null;
      _showingResult = false;
    });
  }

  void _selectAnswer(String answer) {
    if (_showingResult || _isFinished) return;

    final isCorrect = answer == _currentPerson!.name;

    setState(() {
      _selectedAnswer = answer;
      _showingResult = true;
      if (isCorrect) {
        _score++;
      } else {
        _missedPeople.add(_currentPerson!);
      }
    });

    // Auto-advance after showing result
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_isFinished) {
        _nextQuestion();
      }
    });
  }

  Future<void> _endQuiz() async {
    _timer?.cancel();

    // Save score
    final uuid = ref.read(uuidProvider);
    final quizScore = QuizScoreModel(
      id: uuid.v4(),
      groupId: widget.group.id,
      score: _score,
      date: DateTime.now(),
    );
    await ref.read(quizRepositoryProvider).saveScore(quizScore);

    // Record activity for streak
    await ref.read(userRepositoryProvider).recordActivity();

    // Update high score display
    final newHighScore = await ref.read(quizRepositoryProvider).getHighScore(widget.group.id);
    final newStreak = await ref.read(quizRepositoryProvider).getQuizStreak(widget.group.id);

    setState(() {
      _isFinished = true;
      _highScore = newHighScore;
      _streak = newStreak;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isFinished) {
      return _buildResultsScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Quiz Score $_score',
          child: Text('Score: $_score'),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildTimer(),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer progress bar
          LinearProgressIndicator(
            value: _timeRemaining / AppConstants.quizDurationSeconds,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              _timeRemaining <= 10 ? Colors.red : Theme.of(context).colorScheme.primary,
            ),
          ),

          // Photo
          Expanded(
            child: Semantics(
              label: 'Quiz Photo',
              image: true,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(
                    File(_currentPerson!.photoPath),
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
          ),

          // Options
          Semantics(
            label: 'Quiz Options',
            container: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildOptionButton(_options[0])),
                      const SizedBox(width: 12),
                      Expanded(child: _buildOptionButton(_options[1])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildOptionButton(_options[2])),
                      const SizedBox(width: 12),
                      Expanded(child: _buildOptionButton(_options[3])),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    final minutes = _timeRemaining ~/ 60;
    final seconds = _timeRemaining % 60;
    final timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Semantics(
      label: 'Time remaining $timeText',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _timeRemaining <= 10
              ? Colors.red.withOpacity(0.2)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 16,
              color: _timeRemaining <= 10 ? Colors.red : null,
            ),
            const SizedBox(width: 4),
            Text(
              timeText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _timeRemaining <= 10 ? Colors.red : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String name) {
    Color? backgroundColor;
    Color? foregroundColor;
    BorderSide? border;

    if (_showingResult) {
      final isCorrect = name == _currentPerson!.name;
      final isSelected = name == _selectedAnswer;

      if (isCorrect) {
        backgroundColor = Colors.green;
        foregroundColor = Colors.white;
      } else if (isSelected) {
        backgroundColor = Colors.red;
        foregroundColor = Colors.white;
      }
    }

    return Semantics(
      label: 'Answer option $name',
      button: true,
      child: SizedBox(
        height: 56,
        child: ElevatedButton(
          onPressed: _showingResult ? null : () => _selectAnswer(name),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
            foregroundColor: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
            elevation: 0,
            side: border ?? BorderSide(color: Theme.of(context).colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            name,
            style: const TextStyle(fontSize: 16),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final isNewHighScore = _highScore != null && _score == _highScore && _score > 0;

    return Scaffold(
      appBar: AppBar(title: Semantics(label: 'Quiz Complete', child: const Text('Quiz Complete'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isNewHighScore) ...[
                const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                Semantics(
                  label: 'New High Score',
                  child: Text(
                    '🎉 New High Score!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.amber,
                        ),
                  ),
                ),
              ] else ...[
                Icon(
                  _score > 0 ? Icons.check_circle : Icons.sentiment_neutral,
                  size: 64,
                  color: _score > 0 ? Colors.green : Colors.grey,
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: _score > 0 ? 'Nice work' : 'Keep practicing',
                  child: Text(
                    _score > 0 ? 'Nice work!' : 'Keep practicing!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Stats row
              Semantics(
                label: 'Quiz Results',
                container: true,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildResultStat('$_score', 'Score'),
                    _buildResultStat('${_highScore ?? 0}', 'High Score'),
                    _buildResultStat('$_streak', 'Day Streak'),
                  ],
                ),
              ),

              if (_missedPeople.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Missed:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: _missedPeople.take(5).map((person) {
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

              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: 'Try Again',
                      button: true,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _score = 0;
                            _timeRemaining = AppConstants.quizDurationSeconds;
                            _isFinished = false;
                            _missedPeople.clear();
                          });
                          _startQuiz();
                        },
                        child: const Text('Try Again'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(String value, String label) {
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
}
