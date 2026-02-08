import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/group_model.dart';
import '../../../data/models/person_model.dart';
import '../../../data/models/quiz_score_model.dart';
import '../../providers/app_providers.dart';

// Option button colors for neo-brutalist style
const _optionColors = [
  Color(0xFFDBEAFE), // soft blue
  Color(0xFFFCE7F3), // soft pink
  Color(0xFFFEF3C7), // soft yellow
  Color(0xFFD1FAE5), // soft green
];

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Semantics(
          label: 'Quiz Score $_score',
          child: _buildScoreChip(),
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
      body: SafeArea(
        child: Column(
          children: [
            // Timer progress bar — chunky with border
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
                      value: _timeRemaining / AppConstants.quizDurationSeconds,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _timeRemaining <= 10 ? AppTheme.errorColor : groupColor,
                      ),
                      minHeight: 10,
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: Spacing.md),

            // Photo card
            Expanded(
              flex: 5,
              child: Semantics(
                label: 'Quiz Photo',
                image: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildPhotoCard(),
                ),
              ),
            ),
            
            const SizedBox(height: Spacing.md),

            // Options — neo-brutalist with different colors
            Semantics(
              label: 'Quiz Options',
              container: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildOptionButton(_options[0], 0)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildOptionButton(_options[1], 1)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildOptionButton(_options[2], 2)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildOptionButton(_options[3], 3)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: NeoStyles.chipDecoration(
        backgroundColor: AppTheme.getChipYellow(isDark),
        isDark: isDark,
        borderRadius: 14,
        shadowOffset: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 20, color: Colors.amber[700]),
          const SizedBox(width: 6),
          Text(
            '$_score',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: NeoStyles.cardDecoration(
        isDark: isDark,
        shadowOffset: 5,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CardStyles.borderRadius - 2),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CardStyles.smallBorderRadius),
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
    );
  }

  Widget _buildTimer() {
    final minutes = _timeRemaining ~/ 60;
    final seconds = _timeRemaining % 60;
    final timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isLow = _timeRemaining <= 10;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Time remaining $timeText',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: NeoStyles.chipDecoration(
          backgroundColor: isLow
              ? AppTheme.errorColor.withOpacity(0.15)
              : (AppTheme.getChipPink(isDark)),
          isDark: isDark,
          borderRadius: 14,
          shadowOffset: 2,
          borderWidth: isLow ? 2.5 : 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: isLow ? AppTheme.errorColor : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 6),
            Text(
              timeText,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isLow ? AppTheme.errorColor : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String name, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color backgroundColor;
    Color? foregroundColor;
    Color borderColor = isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A);
    double borderWidth = 2.5;

    if (_showingResult) {
      final isCorrect = name == _currentPerson!.name;
      final isSelected = name == _selectedAnswer;

      if (isCorrect) {
        backgroundColor = AppTheme.successColor;
        foregroundColor = Colors.white;
        borderWidth = 3;
      } else if (isSelected) {
        backgroundColor = AppTheme.errorColor;
        foregroundColor = Colors.white;
        borderWidth = 3;
      } else {
        backgroundColor = isDark ? const Color(0xFF1E1E1E) : _optionColors[index % _optionColors.length];
      }
    } else {
      backgroundColor = isDark ? const Color(0xFF1E1E1E) : _optionColors[index % _optionColors.length];
    }

    return Semantics(
      label: 'Answer option $name',
      button: true,
      child: SizedBox(
        height: 60,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showingResult ? null : () => _selectAnswer(name),
            borderRadius: BorderRadius.circular(CardStyles.smallBorderRadius),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(CardStyles.smallBorderRadius),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                ),
                boxShadow: _showingResult
                    ? null
                    : NeoStyles.hardShadow(offset: 3, isDark: isDark),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: foregroundColor ?? Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsScreen() {
    final isNewHighScore = _highScore != null && _score == _highScore && _score > 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy — neo-brutalist bordered circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.getChipYellow(isDark),
                  border: Border.all(
                    color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                    width: 3,
                  ),
                  boxShadow: NeoStyles.hardShadow(offset: 4, isDark: isDark),
                ),
                child: Icon(
                  isNewHighScore ? Icons.emoji_events : Icons.check_circle,
                  size: 50,
                  color: isNewHighScore ? Colors.amber : groupColor,
                ),
              ),
              const SizedBox(height: 24),
                
                if (isNewHighScore) ...[
                  Semantics(
                    label: 'New High Score',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: NeoStyles.chipDecoration(
                        backgroundColor: AppTheme.chipYellow,
                        isDark: isDark,
                        shadowOffset: 2,
                      ),
                      child: Text(
                        '🎉 New High Score!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                Semantics(
                  label: _score > 0 ? 'Nice work' : 'Keep practicing',
                  child: Text(
                    _score > 0 ? 'Nice work!' : 'Keep practicing!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),

                const SizedBox(height: 32),

                // Stats cards
                Semantics(
                  label: 'Quiz Results',
                  container: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('$_score', 'Score', Icons.star, Colors.amber, AppTheme.chipYellow),
                      _buildStatCard('${_highScore ?? 0}', 'High Score', Icons.emoji_events, groupColor, AppTheme.chipBlue),
                      _buildStatCard('$_streak', 'Streak', Icons.local_fire_department, Colors.orange, AppTheme.chipPink),
                    ],
                  ),
                ),

                if (_missedPeople.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Missed:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _missedPeople.take(5).map((person) {
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
                            backgroundImage: FileImage(File(person.photoPath)),
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

                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: 'Try Again',
                        button: true,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _score = 0;
                              _timeRemaining = AppConstants.quizDurationSeconds;
                              _isFinished = false;
                              _missedPeople.clear();
                            });
                            _startQuiz();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Semantics(
                        label: 'Done',
                        button: true,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check),
                          label: const Text('Done'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
      );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color, Color chipBg) {
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
          Icon(icon, size: 24, color: color),
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
}
